import UIKit
import AotterTrekSDK

/// A feed with two ad slots: a native placement and a Native Multimedia Ad placement. The same code shows both; the
/// response decides how the ad renders.
final class TrekFeedViewController: UITableViewController, ATKAdLoaderDelegate {

    /// One ad slot. It keeps its own cell, so the table never hands the ad to another row: a second bind moves the
    /// ad, and a Native Multimedia Ad that has started does not survive the move.
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
            card.pin(to: cell.contentView, inset: 12)
        }
    }

    private let status = StatusLabel()
    private let postCount = 20
    private let slots = [
        AdSlot(row: 3, placeID: DemoConfig.nativePlaceID),
        AdSlot(row: 10, placeID: DemoConfig.nativeMultimediaPlaceID),
    ]
    /// The rows on screen, by their number in the full feed: the posts, and a slot's row once its ad has arrived.
    private lazy var rows: [(number: Int, slot: AdSlot?)] =
        (0..<postCount + slots.count).filter { number in !slots.contains { $0.row == number } }.map { ($0, nil) }

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
        let index = rows.firstIndex { $0.number > slot.row } ?? rows.count
        rows.insert((slot.row, slot), at: index)
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .none)   // the row comes in at the height of its ad
        status.show("Ad received for row \(slot.row): \(ad.title)")
    }

    func adLoader(_ adLoader: ATKAdLoader, didFailToReceiveAdWithError error: Error) {
        guard let slot = slot(for: adLoader) else { return }
        let error = error as NSError
        status.show("No ad for row \(slot.row) (\(error.code)): \(error.localizedDescription)")
    }

    // MARK: table

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        if let slot = row.slot {
            return slot.cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Post", for: indexPath)
        cell.textLabel?.text = "Post \(row.number)"
        return cell
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        AotterTrekSDK.notifyAdScrolled()   // Native Multimedia Ads that move with the page
    }
}
