import UIKit
import GoogleMobileAds

/// Shows one native ad from Google Mobile Ads. Every ad goes through a NativeAdView with a MediaView inside it: that
/// is how Google Mobile Ads, and through it the AotterTrek adapter, knows the ad is on screen.
final class AdMobNativeAdCard: UIView {

    private let nativeAdView = NativeAdView()
    private let mediaView = MediaView()
    private let iconView = UIImageView()
    private let badge = UILabel()
    private let headlineLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let bodyLabel = UILabel()
    private let callToActionButton = UIButton(type: .system)
    private var mediaHeight: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(nativeAdView)
        nativeAdView.pin(to: self)
        nativeAdView.backgroundColor = .secondarySystemBackground
        nativeAdView.layer.cornerRadius = 8
        nativeAdView.clipsToBounds = true

        badge.font = .preferredFont(forTextStyle: .caption2)   // the label that marks the ad as an ad
        badge.textAlignment = .center
        badge.textColor = .white
        badge.backgroundColor = UIColor(red: 0xC9 / 255.0, green: 0x34 / 255.0, blue: 0, alpha: 1)   // white text reads at 5.3:1
        // The label keeps its own width: a long title gives way to it.
        badge.setContentHuggingPriority(UILayoutPriority(999), for: .horizontal)
        badge.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        badge.layer.cornerRadius = 3
        badge.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        headlineLabel.font = .preferredFont(forTextStyle: .headline)
        headlineLabel.numberOfLines = 2
        advertiserLabel.font = .preferredFont(forTextStyle: .caption1)
        advertiserLabel.textColor = .secondaryLabel
        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.numberOfLines = 3
        callToActionButton.configuration = .filled()
        callToActionButton.isUserInteractionEnabled = false   // the ad network's SDK handles the tap

        let titles = UIStackView(arrangedSubviews: [headlineLabel, advertiserLabel])
        titles.axis = .vertical
        titles.spacing = 2
        let header = UIStackView(arrangedSubviews: [iconView, titles, badge])
        header.spacing = 8
        header.alignment = .center
        let content = UIStackView(arrangedSubviews: [header, mediaView, bodyLabel, callToActionButton])
        content.axis = .vertical
        content.spacing = 8
        nativeAdView.addSubview(content)
        content.pin(to: nativeAdView, inset: 12)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 15),   // Google's minimum for the label
            badge.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),
        ])

        nativeAdView.mediaView = mediaView
        nativeAdView.iconView = iconView
        nativeAdView.headlineView = headlineLabel
        nativeAdView.advertiserView = advertiserLabel
        nativeAdView.bodyView = bodyLabel
        nativeAdView.callToActionView = callToActionButton
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Fills in the assets, then hands the ad to the NativeAdView, which registers it.
    func show(_ nativeAd: NativeAd) {
        headlineLabel.text = nativeAd.headline
        advertiserLabel.text = nativeAd.advertiser
        bodyLabel.text = nativeAd.body
        badge.text = " \(Self.label(for: nativeAd)) "
        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        callToActionButton.isHidden = nativeAd.callToAction?.isEmpty ?? true
        iconView.image = nativeAd.icon?.image
        iconView.isHidden = nativeAd.icon == nil
        if iconView.image == nil, let url = nativeAd.icon?.imageURL { loadIcon(from: url, for: nativeAd) }

        let ratio = nativeAd.mediaContent.aspectRatio > 0 ? nativeAd.mediaContent.aspectRatio : 16.0 / 9.0
        mediaHeight?.isActive = false
        mediaHeight = mediaView.heightAnchor.constraint(equalTo: mediaView.widthAnchor, multiplier: 1 / ratio)
        mediaHeight?.isActive = true
        mediaView.mediaContent = nativeAd.mediaContent

        // Last, after the asset views are set and laid out: Google Mobile Ads checks their sizes when the ad is registered.
        layoutIfNeeded()
        nativeAdView.nativeAd = nativeAd
    }

    /// Google requires the icon an ad provides. The AotterTrek adapter provides it as a URL only, so the card downloads it.
    private func loadIcon(from url: URL, for nativeAd: NativeAd) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                guard let self, self.nativeAdView.nativeAd === nativeAd else { return }   // still the ad this icon belongs to
                self.iconView.image = image
            }
        }.resume()
    }

    /// AotterTrek's ads carry their own sponsored label in `extraAssets["Sponsor"]`; other ads get Google's "Ad".
    private static func label(for nativeAd: NativeAd) -> String {
        guard let sponsor = nativeAd.extraAssets?["Sponsor"] as? String else { return "Ad" }
        return sponsor.isEmpty ? "Sponsored" : sponsor
    }
}

enum AdMobResponse {
    /// Which network filled the request, as the mediation report names it.
    static func network(of responseInfo: ResponseInfo?) -> String {
        responseInfo?.loadedAdNetworkResponseInfo?.adNetworkClassName ?? "unknown network"
    }
}
