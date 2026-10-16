import UIKit
import AotterTrekSDK

/// One AotterTrek native ad between paragraphs of an article.
final class TrekNativeViewController: StackPageViewController, ATKAdLoaderDelegate {

    private let card = TrekNativeAdCard()
    private var loader: ATKAdLoader?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(loadAd))
        stack.addArrangedSubview(DemoText.paragraph(1))
        stack.addArrangedSubview(card)
        stack.addArrangedSubview(DemoText.paragraph(2))
        card.isHidden = true
        loadAd()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent { card.adView.destroy() }   // leaving the page: end the ad
    }

    @objc private func loadAd() {
        card.adView.destroy()   // a reload: end the ad shown so far
        card.isHidden = true
        let loader = ATKAdLoader(placeID: DemoConfig.nativePlaceID, listener: nil)
        loader.delegate = self
        self.loader = loader
        status.show("Loading a native ad…")
        loader.load(ATKAdRequest(category: "", contentURL: "", contentTitle: "", meta: [:]))
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        card.adView.notifyAdScrolled()   // SuprAd creatives that follow the scroll
    }

    // MARK: ATKAdLoaderDelegate

    func adLoader(_ adLoader: ATKAdLoader, didReceive ad: ATKNativeAdData) {
        guard adLoader === loader else { return ad.destroy() }   // a reload replaced this loader
        card.show(ad, from: self)
        card.isHidden = false
        status.show("Native ad received: \(ad.title)")
    }

    func adLoader(_ adLoader: ATKAdLoader, didFailToReceiveAdWithError error: Error) {
        guard adLoader === loader else { return }
        let error = error as NSError
        status.show("No native ad (\(error.code)): \(error.localizedDescription)")
    }

    func adLoader(_ adLoader: ATKAdLoader, didRecordImpressionFor ad: ATKNativeAdData) {
        status.show("Native ad impression recorded")
    }

    func adLoader(_ adLoader: ATKAdLoader, didRecordClickFor ad: ATKNativeAdData) {
        status.show("Native ad clicked")
    }
}
