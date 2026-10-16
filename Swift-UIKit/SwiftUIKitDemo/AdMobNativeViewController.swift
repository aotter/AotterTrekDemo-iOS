import UIKit
import GoogleMobileAds

/// One native ad from an AdMob ad unit whose mediation group includes AotterTrek (custom event class
/// `AotterTrekGADMediaAdapter`).
final class AdMobNativeViewController: StackPageViewController, NativeAdLoaderDelegate, NativeAdDelegate {

    private let card = AdMobNativeAdCard()
    private var adLoader: AdLoader?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(loadAd))
        stack.addArrangedSubview(DemoText.paragraph(1))
        stack.addArrangedSubview(card)
        stack.addArrangedSubview(DemoText.paragraph(2))
        card.isHidden = true
        loadAd()
    }

    @objc private func loadAd() {
        let adLoader = AdLoader(adUnitID: DemoConfig.adMobNativeAdUnitID, rootViewController: self, adTypes: [.native], options: nil)
        adLoader.delegate = self
        self.adLoader = adLoader
        status.show("Loading a native ad through AdMob…")
        adLoader.load(Request())
    }

    // MARK: NativeAdLoaderDelegate

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard adLoader === self.adLoader else { return }   // a reload replaced this loader
        nativeAd.delegate = self
        card.isHidden = false   // before show, which registers the ad with the card's views at their size
        card.show(nativeAd)
        status.show("AdMob native ad received from \(AdMobResponse.network(of: nativeAd.responseInfo))")
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        guard adLoader === self.adLoader else { return }
        status.show("No AdMob native ad: \(error.localizedDescription)")
    }

    // MARK: NativeAdDelegate

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        status.show("AdMob native ad impression recorded (from \(AdMobResponse.network(of: nativeAd.responseInfo)))")
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        status.show("AdMob native ad clicked")
    }
}
