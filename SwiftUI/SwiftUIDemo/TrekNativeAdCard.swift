import UIKit
import AotterTrekSDK

/// Shows one AotterTrek native ad. The asset views sit inside an ATKNativeAdView, which the SDK measures, and one
/// ATKMediaView renders every creative type: an image, HTML5, a web page or a VAST video.
final class TrekNativeAdCard: UIView {

    let adView = ATKNativeAdView()
    private let mediaView = ATKMediaView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let sponsorBadge = UILabel()
    private let bodyLabel = UILabel()
    private let callToActionButton = UIButton(type: .system)
    private var mediaHeight: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(adView)
        adView.pin(to: self)
        adView.backgroundColor = .secondarySystemBackground
        adView.layer.cornerRadius = 8
        adView.clipsToBounds = true

        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 6
        iconView.clipsToBounds = true
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 2
        advertiserLabel.font = .preferredFont(forTextStyle: .caption1)
        advertiserLabel.textColor = .secondaryLabel
        sponsorBadge.font = .preferredFont(forTextStyle: .caption2)   // the label that marks the ad as an ad
        sponsorBadge.textAlignment = .center
        sponsorBadge.textColor = .white
        sponsorBadge.backgroundColor = UIColor(red: 0xC9 / 255.0, green: 0x34 / 255.0, blue: 0, alpha: 1)   // white text reads at 5.3:1
        // The label keeps its own width: a long title gives way to it.
        sponsorBadge.setContentHuggingPriority(UILayoutPriority(999), for: .horizontal)
        sponsorBadge.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        sponsorBadge.layer.cornerRadius = 3
        sponsorBadge.clipsToBounds = true
        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.numberOfLines = 3
        callToActionButton.configuration = .filled()

        let titles = UIStackView(arrangedSubviews: [titleLabel, advertiserLabel])
        titles.axis = .vertical
        titles.spacing = 2
        let header = UIStackView(arrangedSubviews: [iconView, titles, sponsorBadge])
        header.spacing = 8
        header.alignment = .center
        let content = UIStackView(arrangedSubviews: [header, mediaView, bodyLabel, callToActionButton])
        content.axis = .vertical
        content.spacing = 8
        adView.addSubview(content)
        content.pin(to: adView, inset: 12)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            sponsorBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 15),
            sponsorBadge.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),
        ])

        adView.mediaView = mediaView
        adView.callToActionButton = callToActionButton
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Fills in the assets and binds the ad, which starts measuring it. Call it once per ad: binding an image ad again
    /// loads and reports its picture again.
    func show(_ ad: ATKNativeAdData, from viewController: UIViewController) {
        titleLabel.text = ad.title
        advertiserLabel.text = ad.advertiserName
        sponsorBadge.text = " \(ad.sponsor.isEmpty ? "Sponsored" : ad.sponsor) "
        bodyLabel.text = ad.text
        callToActionButton.setTitle(ad.callToAction.isEmpty ? "Learn more" : ad.callToAction, for: .normal)
        loadIcon(from: ad.imgIconHd.isEmpty ? ad.imgIcon : ad.imgIconHd)

        // ATKMediaView has no intrinsic size: give it the ad's aspect ratio (width / height).
        let ratio = ad.mediaContentAspectRatio > 0 ? ad.mediaContentAspectRatio : 1200.0 / 628.0
        mediaHeight?.isActive = false
        mediaHeight = mediaView.heightAnchor.constraint(equalTo: mediaView.widthAnchor, multiplier: 1 / ratio)
        mediaHeight?.isActive = true

        adView.rootViewController = viewController   // a video, a popup and the in-app browser present from it
        adView.nativeAd = ad
    }

    private func loadIcon(from urlString: String) {
        iconView.image = nil
        iconView.isHidden = urlString.isEmpty   // a SuprAd can come without an icon
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                guard let self, self.adView.nativeAd?.imgIconHd == urlString || self.adView.nativeAd?.imgIcon == urlString else { return }
                self.iconView.image = image   // still the ad this icon belongs to
            }
        }.resume()
    }
}
