import SwiftUI
import UIKit

/// The line at the top of every page that says what the ad did last.
struct StatusText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("status")
    }
}

/// Stand-in for the app's own content around the ads.
struct Paragraph: View {
    let number: Int

    var body: some View {
        Text("Paragraph \(number). Your app's own content goes here, above and below the ad, the way a reader meets it "
             + "in an article or a feed.")
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Keeps the status line and the console in step. Callbacks report through it; the update waits for the next turn
/// of the main loop because they can arrive while SwiftUI is updating a view.
struct StatusReporter {
    let set: (String) -> Void

    func callAsFunction(_ message: String) {
        print("[AotterTrekDemo] \(message)")
        DispatchQueue.main.async { set(message) }
    }
}

extension UIView {
    /// Pins the view to every edge of `container`, inset by `inset`.
    func pin(to container: UIView, inset: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: container.topAnchor, constant: inset),
            leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -inset),
        ])
    }
}

/// A UIKit view controller that hosts one ad view inside SwiftUI and reports the height its content takes. The ad
/// SDKs present videos, popups and the in-app browser from a view controller, and this one is it.
class AdHostViewController: UIViewController {
    var onHeight: (CGFloat) -> Void = { _ in }
    private var reportedHeight: CGFloat = -1

    /// The view whose height is reported; subclasses return their ad view. It is pinned to the top of this view and
    /// sizes itself, so its frame after layout is the height to report.
    var content: UIView { view }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let height = content.isHidden ? 0 : content.frame.height
        guard abs(height - reportedHeight) > 0.5 else { return }
        reportedHeight = height
        DispatchQueue.main.async { self.onHeight(height) }
    }
}
