import SwiftUI
import GoogleMobileAds

/// One native ad from an AdMob ad unit whose mediation group includes AotterTrek (custom event class
/// `AotterTrekGADMediaAdapter`). Like the AotterTrek slot, it keeps its ad while its place in the page stays the same.
struct AdMobNativeAdSlot: UIViewControllerRepresentable {
    let adUnitID: String
    var reload = 0
    let status: StatusReporter
    @Binding var height: CGFloat

    func makeUIViewController(context: Context) -> AdMobNativeAdHostController {
        let host = AdMobNativeAdHostController(adUnitID: adUnitID, status: status)
        host.onHeight = { height = $0 }
        host.loadAd()
        context.coordinator.reload = reload
        return host
    }

    func updateUIViewController(_ host: AdMobNativeAdHostController, context: Context) {
        if context.coordinator.reload != reload {
            context.coordinator.reload = reload
            host.loadAd()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var reload = 0
    }
}

final class AdMobNativeAdHostController: AdHostViewController, NativeAdLoaderDelegate, NativeAdDelegate {
    private let card = AdMobNativeAdCard()
    private let adUnitID: String
    private let status: StatusReporter
    private var adLoader: AdLoader?

    init(adUnitID: String, status: StatusReporter) {
        self.adUnitID = adUnitID
        self.status = status
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var content: UIView { card }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.topAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        card.isHidden = true
    }

    func loadAd() {
        loadViewIfNeeded()
        let adLoader = AdLoader(adUnitID: adUnitID, rootViewController: self, adTypes: [.native], options: nil)
        adLoader.delegate = self
        self.adLoader = adLoader
        status("Loading a native ad through AdMob…")
        adLoader.load(Request())
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        guard adLoader === self.adLoader else { return }   // a reload replaced this loader
        nativeAd.delegate = self
        card.isHidden = false   // before show, which registers the ad with the card's views at their size
        card.show(nativeAd)
        view.setNeedsLayout()
        status("AdMob native ad received from \(AdMobResponse.network(of: nativeAd.responseInfo))")
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        guard adLoader === self.adLoader else { return }
        status("No AdMob native ad: \(error.localizedDescription)")
    }

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        status("AdMob native ad impression recorded (from \(AdMobResponse.network(of: nativeAd.responseInfo)))")
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        status("AdMob native ad clicked")
    }
}

/// A banner from an AdMob ad unit whose mediation group includes AotterTrek.
struct AdMobBannerSlot: UIViewControllerRepresentable {
    let adUnitID: String
    let width: CGFloat
    var reload = 0
    let status: StatusReporter
    @Binding var height: CGFloat

    func makeUIViewController(context: Context) -> AdMobBannerHostController {
        let host = AdMobBannerHostController(adUnitID: adUnitID, width: width, status: status)
        host.onHeight = { height = $0 }
        context.coordinator.reload = reload
        return host
    }

    func updateUIViewController(_ host: AdMobBannerHostController, context: Context) {
        if context.coordinator.reload != reload {
            context.coordinator.reload = reload
            host.loadAd()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var reload = 0
    }
}

final class AdMobBannerHostController: AdHostViewController, BannerViewDelegate {
    private let bannerView: BannerView
    private let status: StatusReporter

    init(adUnitID: String, width: CGFloat, status: StatusReporter) {
        // Inline adaptive: the size for a banner inside scrolling content. Its height comes with the ad.
        bannerView = BannerView(adSize: currentOrientationInlineAdaptiveBanner(width: width))
        bannerView.adUnitID = adUnitID
        self.status = status
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var content: UIView { bannerView }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(bannerView)
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: view.topAnchor),
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        bannerView.rootViewController = self
        bannerView.delegate = self
        loadAd()
    }

    func loadAd() {
        status("Loading a banner through AdMob…")
        bannerView.load(Request())
    }

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        view.setNeedsLayout()
        status("AdMob banner received from \(AdMobResponse.network(of: bannerView.responseInfo))")
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        status("No AdMob banner: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        status("AdMob banner impression recorded (from \(AdMobResponse.network(of: bannerView.responseInfo)))")
    }

    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        status("AdMob banner clicked")
    }
}
