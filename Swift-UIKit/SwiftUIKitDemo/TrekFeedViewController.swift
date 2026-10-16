import UIKit
import AotterTrekSDK

/// A feed with two ad slots: a native placement and a SuprAd placement. The same code shows both; the response
/// decides how the ad renders.
final class TrekFeedViewController: UITableViewController, ATKAdLoaderDelegate {

    /// One ad slot. It keeps its own cell, so the table never hands the ad to another row: a second bind moves the
    /// ad, and a SuprAd that has started does not survive the move.
    private final class AdSlot {
        let row: Int
        let placeID: String
        let card = TrekNativeAdCard()
        let cell = UITableViewCell()
        var loader: ATKAdLoader?

        init(row: Int, placeID: String) {
            self.row = row
            self.placeID = placeID
            cell.selectionStyle = .none
            cell.contentView.addSubview(card)
            card.pin(to: cell.contentView, inset: 12, bottomPriority: .defaultHigh)   // the row collapses while the card is hidden
            card.isHidden = true
        }
    }

    private let status = StatusLabel()
    private let postCount = 20
    private let slots = [
        AdSlot(row: 3, placeID: DemoConfig.nativePlaceID),
        AdSlot(row: 10, placeID: DemoConfig.suprAdPlaceID),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Post")
        status.frame.size.height = 44
        tableView.tableHeaderView = status
        slots.forEach(load)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent { slots.forEach { $0.card.adView.destroy() } }   // leaving the page: end the ads
    }

    private func load(_ slot: AdSlot) {
        let loader = ATKAdLoader(placeID: slot.placeID, listener: nil)
        loader.delegate = self
        slot.loader = loader
        status.show("Loading ads…")
        loader.load(ATKAdRequest(category: "", contentURL: "", contentTitle: "", meta: [:]))
    }

    private func slot(for loader: ATKAdLoader) -> AdSlot? {
        slots.first { $0.loader === loader }
    }

    // MARK: ATKAdLoaderDelegate

    func adLoader(_ adLoader: ATKAdLoader, didReceive ad: ATKNativeAdData) {
        guard let slot = slot(for: adLoader) else { return ad.destroy() }
        slot.card.show(ad, from: self)
        slot.card.isHidden = false
        tableView.performBatchUpdates(nil)   // the slot's row grows to fit the ad
        status.show("Ad received for row \(slot.row): \(ad.title)")
    }

    func adLoader(_ adLoader: ATKAdLoader, didFailToReceiveAdWithError error: Error) {
        guard let slot = slot(for: adLoader) else { return }
        let error = error as NSError
        status.show("No ad for row \(slot.row) (\(error.code)): \(error.localizedDescription)")
    }

    // MARK: table

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postCount + slots.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let slot = slots.first(where: { $0.row == indexPath.row }) {
            return slot.cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Post", for: indexPath)
        cell.textLabel?.text = "Post \(indexPath.row)"
        return cell
    }

    /// An ad row has no height until its ad arrives, or at all when there is no ad.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let slot = slots.first { $0.row == indexPath.row }
        return slot?.card.isHidden == true ? 0 : UITableView.automaticDimension
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        slots.forEach { $0.card.adView.notifyAdScrolled() }   // SuprAd creatives that follow the scroll
    }
}
