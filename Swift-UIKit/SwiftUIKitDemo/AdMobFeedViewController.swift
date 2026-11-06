import UIKit
import AotterTrekSDK
import GoogleMobileAds

/// A feed with two AdMob ad slots: a native ad unit and a Native Multimedia Ad unit.
final class AdMobFeedViewController: UITableViewController, NativeAdLoaderDelegate, NativeAdDelegate {

    /// One ad slot. It keeps its own cell, so the table never hands the ad to another row.
    private final class AdSlot {
        let row: Int
        let adUnitID: String
        let card = AdMobNativeAdCard()
        let cell = UITableViewCell()
        var adLoader: AdLoader?

        init(row: Int, adUnitID: String) {
            self.row = row
            self.adUnitID = adUnitID
            cell.selectionStyle = .none
            cell.contentView.addSubview(card)
            card.pin(to: cell.contentView, inset: 12)
        }
    }

    private let status = StatusLabel()
    private let postCount = 20
    private let slots = [   // one ad unit per AotterTrek placement type
        AdSlot(row: 3, adUnitID: DemoConfig.adMobNativeAdUnitID),
        AdSlot(row: 10, adUnitID: DemoConfig.adMobNativeMultimediaAdUnitID),
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

    private func load(_ slot: AdSlot) {
        let adLoader = AdLoader(adUnitID: slot.adUnitID, rootViewController: self, adTypes: [.native], options: nil)
        adLoader.delegate = self
        slot.adLoader = adLoader
        status.show("Loading ads through AdMob…")
        adLoader.load(Request())
    }

    private func slot(for adLoader: AdLoader) -> AdSlot? {
        slots.first { $0.adLoader === adLoader }
    }

    // MARK: NativeAdLoaderDelegate

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard let slot = slot(for: adLoader) else { return }
        nativeAd.delegate = self
        slot.card.fill(nativeAd)
        let index = rows.firstIndex { $0.number > slot.row } ?? rows.count
        rows.insert((slot.row, slot), at: index)
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .none)   // the row comes in at the height of its ad
        DispatchQueue.main.async { slot.card.register(nativeAd) }   // once the row has laid the card out at its size
        status.show("AdMob native ad received for row \(slot.row) from \(AdMobResponse.network(of: nativeAd.responseInfo))")
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        guard let slot = slot(for: adLoader) else { return }
        status.show("No AdMob native ad for row \(slot.row): \(error.localizedDescription)")
    }

    // MARK: NativeAdDelegate

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        status.show("AdMob native ad impression recorded (from \(AdMobResponse.network(of: nativeAd.responseInfo)))")
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        status.show("AdMob native ad clicked")
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
        AotterTrekSDK.notifyAdScrolled()   // Native Multimedia Ads that move with the page, also through the adapter
    }
}
