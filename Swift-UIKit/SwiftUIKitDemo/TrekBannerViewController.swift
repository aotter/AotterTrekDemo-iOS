import UIKit
import AotterTrekSDK

/// An AotterTrek banner, as wide as the page. The server decides its proportions.
final class TrekBannerViewController: StackPageViewController, ATKBannerAdDelegate {

    private let banner = ATKBannerAdView()
    private var bannerHeight: NSLayoutConstraint?   // zero while the ad has no size, else the ad size's proportions

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(loadAd))
        bannerHeight = banner.heightAnchor.constraint(equalToConstant: 0)
        bannerHeight?.isActive = true
        stack.addArrangedSubview(DemoText.paragraph(1))
        stack.addArrangedSubview(banner)   // as wide as the page's content
        stack.addArrangedSubview(DemoText.paragraph(2))

        banner.placeID = DemoConfig.bannerPlaceID
        banner.rootViewController = self
        banner.delegate = self
        loadAd()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent { banner.destroy() }   // leaving the page: end the ad
    }

    /// A reload keeps the current ad on screen until the next one arrives, so the banner is not destroyed first.
    @objc private func loadAd() {
        status.show("Loading a banner…")
        banner.load(nil)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        AotterTrekSDK.notifyAdScrolled()   // Native Multimedia Ads that move with the page
    }

    // MARK: ATKBannerAdDelegate

    /// The server decides the ad size. The banner keeps the page's width and takes the ad size's proportions; the
    /// creative fills it.
    func bannerAdView(_ bannerAdView: ATKBannerAdView, willChangeAdSizeTo adSize: CGSize) {
        let sized = adSize.width > 0 && adSize.height > 0   // with no size the banner folds away, as before the first ad
        bannerHeight?.isActive = false
        bannerHeight = sized
            ? banner.heightAnchor.constraint(equalTo: banner.widthAnchor, multiplier: adSize.height / adSize.width)
            : banner.heightAnchor.constraint(equalToConstant: 0)
        bannerHeight?.isActive = true
    }

    func bannerAdViewDidReceiveAd(_ bannerAdView: ATKBannerAdView) {
        let size = bannerAdView.adSize
        guard size.width > 0, size.height > 0 else { return status.show("Banner received without a size, so it is not shown") }
        status.show("Banner received: \(Int(size.width)) x \(Int(size.height))")
    }

    func bannerAdView(_ bannerAdView: ATKBannerAdView, didFailToReceiveAdWithError error: Error) {
        let error = error as NSError
        status.show("No banner (\(error.code)): \(error.localizedDescription)")
    }

    func bannerAdViewDidRecordImpression(_ bannerAdView: ATKBannerAdView) {
        status.show("Banner impression recorded")
    }

    func bannerAdViewDidRecordClick(_ bannerAdView: ATKBannerAdView) {
        status.show("Banner clicked")
    }
}
