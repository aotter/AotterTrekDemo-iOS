import UIKit
import AotterTrekSDK

/// Reports what the user does with ATKTracker: one tracker per report, set up by chaining, then `send`.
final class TrackerViewController: StackPageViewController {

    private var readingTracker: ATKTracker?

    override func viewDidLoad() {
        super.viewDidLoad()
        stack.addArrangedSubview(button("Open a post") { [unowned self] in openPost() })
        stack.addArrangedSubview(button("Leave the post") { [unowned self] in leavePost() })
        stack.addArrangedSubview(button("Report a video watched for 30 seconds") { [unowned self] in reportVideo() })
        status.show("A send does not report its result back.")
    }

    /// The time spent counts from `start` until `send`. Opening a post leaves the one open before, so that one is sent.
    private func openPost() {
        let leftPost = readingTracker != nil
        readingTracker?.send()
        let post = ATKTrackerEntity(type: .post, entityId: "post-1", title: "A post in your app",
                                    url: "https://example.com/posts/1")   // the url is required
        readingTracker = ATKTracker().entity(post).actionType(.readPost).start()
        status.show((leftPost ? "READ_POST sent for the post you left. " : "")
                    + "Reading the post: READ_POST is sent when you tap Leave the post.")
    }

    private func leavePost() {
        guard let tracker = readingTracker else { return status.show("Open a post first.") }
        tracker.send()
        readingTracker = nil
        status.show("READ_POST sent.")
    }

    /// `timeSpan` sets the time spent yourself.
    private func reportVideo() {
        let video = ATKTrackerEntity(type: .video, entityId: "video-1", title: "A video in your app",
                                     url: "https://example.com/videos/1")
        ATKTracker().entity(video).actionType(.watchVideo).timeSpan(30).send()
        status.show("WATCH_VIDEO sent.")
    }

    private func button(_ title: String, action: @escaping () -> Void) -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = title
        return UIButton(configuration: configuration, primaryAction: UIAction { _ in action() })
    }
}
