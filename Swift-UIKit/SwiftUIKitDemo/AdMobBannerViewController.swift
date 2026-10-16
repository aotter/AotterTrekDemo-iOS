import UIKit
import GoogleMobileAds

/// A banner from an AdMob ad unit whose mediation group includes AotterTrek.
final class AdMobBannerViewController: StackPageViewController, BannerViewDelegate {

    private var bannerView: BannerView?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(loadAd))
        stack.addArrangedSubview(DemoText.paragraph(1))
        let slot = UIView()
        stack.addArrangedSubview(slot)
        stack.addArrangedSubview(DemoText.paragraph(2))

        let width = view.bounds.width - 32   // the app runs in portrait only, so the width does not change
        // Inline adaptive: the size for a banner inside scrolling content. Its height comes with the ad.
        let bannerView = BannerView(adSize: currentOrientationInlineAdaptiveBanner(width: width))
        bannerView.adUnitID = DemoConfig.adMobBannerAdUnitID
        bannerView.rootViewController = self
        bannerView.delegate = self
        slot.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: slot.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: slot.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: slot.centerXAnchor),
        ])   // the banner takes its size from its ad size
        self.bannerView = bannerView
        loadAd()
    }

    @objc private func loadAd() {
        status.show("Loading a banner through AdMob…")
        bannerView?.load(Request())
    }

    // MARK: BannerViewDelegate

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        status.show("AdMob banner received from \(AdMobResponse.network(of: bannerView.responseInfo))")
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        status.show("No AdMob banner: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        status.show("AdMob banner impression recorded (from \(AdMobResponse.network(of: bannerView.responseInfo)))")
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        status.show("AdMob banner clicked")
    }
}
