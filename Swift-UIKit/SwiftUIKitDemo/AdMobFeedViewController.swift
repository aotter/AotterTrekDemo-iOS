import UIKit
import GoogleMobileAds

/// A feed with one AdMob native ad slot.
final class AdMobFeedViewController: UITableViewController, NativeAdLoaderDelegate, NativeAdDelegate {

    private let status = StatusLabel()
    private let postCount = 20
    private let adRow = 3
    /// The ad row keeps its own cell, so the table never hands the ad to another row.
    private let adCell = UITableViewCell()
    private let card = AdMobNativeAdCard()
    private var adLoader: AdLoader?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Post")
        status.frame.size.height = 44
        tableView.tableHeaderView = status
        adCell.selectionStyle = .none
        adCell.contentView.addSubview(card)
        card.pin(to: adCell.contentView, inset: 12, bottomPriority: .defaultHigh)   // the row collapses while the card is hidden
        card.isHidden = true

        let adLoader = AdLoader(adUnitID: DemoConfig.adMobNativeAdUnitID, rootViewController: self, adTypes: [.native], options: nil)
        adLoader.delegate = self
        self.adLoader = adLoader
        status.show("Loading a native ad through AdMob…")
        adLoader.load(Request())
    }

    // MARK: NativeAdLoaderDelegate

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self
        card.isHidden = false   // before show, which registers the ad with the card's views at their size
        card.show(nativeAd)
        tableView.performBatchUpdates(nil)   // the ad row grows to fit the ad
        status.show("AdMob native ad received from \(AdMobResponse.network(of: nativeAd.responseInfo))")
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        status.show("No AdMob native ad: \(error.localizedDescription)")
    }

    // MARK: NativeAdDelegate

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        status.show("AdMob native ad impression recorded (from \(AdMobResponse.network(of: nativeAd.responseInfo)))")
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        status.show("AdMob native ad clicked")
    }

    // MARK: table

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { postCount + 1 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == adRow { return adCell }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Post", for: indexPath)
        cell.textLabel?.text = "Post \(indexPath.row)"
        return cell
    }

    /// The ad row has no height until its ad arrives, or at all when there is no ad.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.row == adRow && card.isHidden ? 0 : UITableView.automaticDimension
    }
}
