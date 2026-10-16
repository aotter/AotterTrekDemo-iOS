import UIKit

/// The line at the top of every page that says what the ad did last. It also goes to the console.
final class StatusLabel: UILabel {

    init() {
        super.init(frame: .zero)
        font = .preferredFont(forTextStyle: .footnote)
        textColor = .secondaryLabel
        numberOfLines = 0
        accessibilityIdentifier = "status"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func show(_ message: String) {
        text = message
        print("[AotterTrekDemo] \(message)")
    }
}

enum DemoText {
    /// Stand-in for the app's own content around the ads.
    static func paragraph(_ number: Int) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.text = "Paragraph \(number). Your app's own content goes here, above and below the ad, the way a "
            + "reader meets it in an article or a feed."
        return label
    }
}

extension UIView {
    /// Pins the view to every edge of `container`, inset by `inset`. A bottom priority below required lets the
    /// container be shorter than the view (a table row that hides its ad).
    func pin(to container: UIView, inset: CGFloat = 0, bottomPriority: UILayoutPriority = .required) {
        translatesAutoresizingMaskIntoConstraints = false
        let bottom = bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset)
        bottom.priority = bottomPriority
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            bottom,
        ])
    }
}

/// A scrolling page that stacks views vertically, with a status line on top.
class StackPageViewController: UIViewController, UIScrollViewDelegate {

    let status = StatusLabel()
    let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let scrollView = UIScrollView()
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        scrollView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
        stack.addArrangedSubview(status)
    }

    /// The AotterTrek pages tell their ad here that the page scrolled, for SuprAd creatives that follow the scroll.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
}
