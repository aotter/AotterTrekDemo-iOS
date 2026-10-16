import SwiftUI
import AotterTrekSDK

/// One AotterTrek native ad slot. It loads its own ad and keeps it until SwiftUI removes the view: SwiftUI keeps the
/// slot alive while its place in the page stays the same, so lay slots out where their identity does not change
/// (a VStack, not a List that recycles rows).
struct TrekNativeAdSlot: UIViewControllerRepresentable {
    let placeID: String
    /// Change it to load a new ad.
    var reload = 0
    /// Change it as the page scrolls, for SuprAd creatives that follow the scroll.
    var scrolled = 0
    let status: StatusReporter
    @Binding var height: CGFloat

    func makeUIViewController(context: Context) -> TrekNativeAdHostController {
        let host = TrekNativeAdHostController(placeID: placeID, status: status)
        host.onHeight = { height = $0 }
        host.loadAd()
        context.coordinator.reload = reload
        return host
    }

    func updateUIViewController(_ host: TrekNativeAdHostController, context: Context) {
        if context.coordinator.reload != reload {
            context.coordinator.reload = reload
            host.loadAd()
        }
        if context.coordinator.scrolled != scrolled {
            context.coordinator.scrolled = scrolled
            host.card.adView.notifyAdScrolled()
        }
    }

    /// SwiftUI removed the slot: end its ad.
    static func dismantleUIViewController(_ host: TrekNativeAdHostController, coordinator: Coordinator) {
        host.card.adView.destroy()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var reload = 0
        var scrolled = 0
    }
}

final class TrekNativeAdHostController: AdHostViewController, ATKAdLoaderDelegate {
    let card = TrekNativeAdCard()
    private let placeID: String
    private let status: StatusReporter
    private var loader: ATKAdLoader?

    init(placeID: String, status: StatusReporter) {
        self.placeID = placeID
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
        card.adView.destroy()   // a reload: end the ad shown so far
        card.isHidden = true
        view.setNeedsLayout()
        let loader = ATKAdLoader(placeID: placeID, listener: nil)
        loader.delegate = self
        self.loader = loader
        status("Loading an ad…")
        loader.load(ATKAdRequest(category: "", contentURL: "", contentTitle: "", meta: [:]))
    }

    func adLoader(_ adLoader: ATKAdLoader, didReceive ad: ATKNativeAdData) {
        guard adLoader === loader else { return ad.destroy() }   // a reload replaced this loader
        card.show(ad, from: self)
        card.isHidden = false
        view.setNeedsLayout()
        status("Ad received: \(ad.title)")
    }

    func adLoader(_ adLoader: ATKAdLoader, didFailToReceiveAdWithError error: Error) {
        guard adLoader === loader else { return }
        let error = error as NSError
        status("No ad (\(error.code)): \(error.localizedDescription)")
    }

    func adLoader(_ adLoader: ATKAdLoader, didRecordImpressionFor ad: ATKNativeAdData) {
        status("Impression recorded: \(ad.title)")
    }

    func adLoader(_ adLoader: ATKAdLoader, didRecordClickFor ad: ATKNativeAdData) {
        status("Clicked: \(ad.title)")
    }
}

/// An AotterTrek banner. The server decides its size; a creative wider than the page is scaled down to fit, keeping
/// its shape.
struct TrekBannerSlot: UIViewControllerRepresentable {
    let placeID: String
    var reload = 0
    /// Change it as the page scrolls, for SuprAd creatives that follow the scroll.
    var scrolled = 0
    let status: StatusReporter
    @Binding var height: CGFloat

    func makeUIViewController(context: Context) -> TrekBannerHostController {
        let host = TrekBannerHostController(placeID: placeID, status: status)
        host.onHeight = { height = $0 }
        host.loadAd()
        context.coordinator.reload = reload
        return host
    }

    func updateUIViewController(_ host: TrekBannerHostController, context: Context) {
        if context.coordinator.reload != reload {
            context.coordinator.reload = reload
            host.loadAd()
        }
        if context.coordinator.scrolled != scrolled {
            context.coordinator.scrolled = scrolled
            host.banner.notifyAdScrolled()
        }
    }

    static func dismantleUIViewController(_ host: TrekBannerHostController, coordinator: Coordinator) {
        host.banner.destroy()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var reload = 0
        var scrolled = 0
    }
}

final class TrekBannerHostController: AdHostViewController, ATKBannerAdDelegate {
    let banner = ATKBannerAdView()
    private let status: StatusReporter
    private var bannerWidth: NSLayoutConstraint?
    private var bannerHeight: NSLayoutConstraint?   // zero while the ad has no size, else the creative's aspect ratio

    init(placeID: String, status: StatusReporter) {
        self.status = status
        super.init(nibName: nil, bundle: nil)
        banner.placeID = placeID
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var content: UIView { banner }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        bannerWidth = banner.widthAnchor.constraint(equalToConstant: 0)
        bannerWidth?.priority = .defaultHigh
        bannerHeight = banner.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.topAnchor),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
            bannerWidth!, bannerHeight!,
        ])
        banner.rootViewController = self
        banner.delegate = self
    }

    /// A reload keeps the current ad on screen until the next one arrives, so the banner is not destroyed first.
    func loadAd() {
        loadViewIfNeeded()
        status("Loading a banner…")
        banner.load(nil)
    }

    func bannerAdView(_ bannerAdView: ATKBannerAdView, willChangeAdSizeTo adSize: CGSize) {
        let sized = adSize.width > 0 && adSize.height > 0   // with no size the banner folds away, as before the first ad
        bannerWidth?.constant = sized ? adSize.width : 0
        bannerHeight?.isActive = false
        bannerHeight = sized
            ? banner.heightAnchor.constraint(equalTo: banner.widthAnchor, multiplier: adSize.height / adSize.width)
            : banner.heightAnchor.constraint(equalToConstant: 0)
        bannerHeight?.isActive = true
        view.setNeedsLayout()
    }

    func bannerAdViewDidReceiveAd(_ bannerAdView: ATKBannerAdView) {
        let size = bannerAdView.adSize
        guard size.width > 0, size.height > 0 else { return status("Banner received without a size, so it is not shown") }
        status("Banner received: \(Int(size.width)) x \(Int(size.height))")
    }

    func bannerAdView(_ bannerAdView: ATKBannerAdView, didFailToReceiveAdWithError error: Error) {
        let error = error as NSError
        status("No banner (\(error.code)): \(error.localizedDescription)")
    }

    func bannerAdViewDidRecordImpression(_ bannerAdView: ATKBannerAdView) {
        status("Banner impression recorded")
    }

    func bannerAdViewDidRecordClick(_ bannerAdView: ATKBannerAdView) {
        status("Banner clicked")
    }
}
