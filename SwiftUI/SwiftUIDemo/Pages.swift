import SwiftUI
import AotterTrekSDK

// MARK: - AotterTrek

/// One AotterTrek native ad between paragraphs of an article.
struct TrekNativePage: View {
    @State private var status = ""
    @State private var reload = 0
    @State private var scrolled = 0
    @State private var adHeight: CGFloat = 0

    var body: some View {
        ScrollCountingView(scrolled: $scrolled) {
            VStack(spacing: 16) {
                StatusText(message: status)
                Paragraph(number: 1)
                TrekNativeAdSlot(placeID: DemoConfig.nativePlaceID, reload: reload, scrolled: scrolled,
                                 status: StatusReporter { status = $0 }, height: $adHeight)
                    .frame(height: adHeight)
                Paragraph(number: 2)
            }
            .padding()
        }
        .navigationTitle("Native ad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Reload") { reload += 1 } }
    }
}

/// A feed with two ad slots: a native placement and a SuprAd placement. The same code shows both; the response
/// decides how the ad renders.
struct TrekFeedPage: View {
    private let slots = [3: DemoConfig.nativePlaceID, 10: DemoConfig.suprAdPlaceID]   // row: place
    @State private var status = ""
    @State private var heights: [Int: CGFloat] = [:]
    @State private var scrolled = 0

    var body: some View {
        ScrollCountingView(scrolled: $scrolled) {
            VStack(alignment: .leading, spacing: 0) {
                StatusText(message: status).padding()
                ForEach(0..<22, id: \.self) { row in
                    if let placeID = slots[row] {
                        TrekNativeAdSlot(placeID: placeID, scrolled: scrolled,
                                         status: StatusReporter { status = "Row \(row): \($0)" },
                                         height: Binding(get: { heights[row] ?? 0 }, set: { heights[row] = $0 }))
                            .frame(height: heights[row] ?? 0)
                            .padding(.horizontal)
                    } else {
                        Text("Post \(row)").padding()
                        Divider()
                    }
                }
            }
        }
        .navigationTitle("Native ads in a feed")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A ScrollView that counts its scrolling into `scrolled`. The AotterTrek ad slots take the count and tell their ad
/// when it changes, for SuprAd creatives that follow the scroll.
struct ScrollCountingView<Content: View>: View {
    @Binding var scrolled: Int
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            content().background(GeometryReader { proxy in
                Color.clear.preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("page")).minY)
            })
        }
        .coordinateSpace(name: "page")
        .onPreferenceChange(ScrollOffsetKey.self) { _ in scrolled += 1 }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// An AotterTrek banner. The server decides its size.
struct TrekBannerPage: View {
    @State private var status = ""
    @State private var reload = 0
    @State private var scrolled = 0
    @State private var bannerHeight: CGFloat = 0

    var body: some View {
        ScrollCountingView(scrolled: $scrolled) {
            VStack(spacing: 16) {
                StatusText(message: status)
                Paragraph(number: 1)
                TrekBannerSlot(placeID: DemoConfig.bannerPlaceID, reload: reload, scrolled: scrolled,
                               status: StatusReporter { status = $0 }, height: $bannerHeight)
                    .frame(height: bannerHeight)
                Paragraph(number: 2)
            }
            .padding()
        }
        .navigationTitle("Banner ad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Reload") { reload += 1 } }
    }
}

// MARK: - AdMob mediation

struct AdMobNativePage: View {
    @State private var status = ""
    @State private var reload = 0
    @State private var adHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                StatusText(message: status)
                Paragraph(number: 1)
                AdMobNativeAdSlot(adUnitID: DemoConfig.adMobNativeAdUnitID, reload: reload,
                                  status: StatusReporter { status = $0 }, height: $adHeight)
                    .frame(height: adHeight)
                Paragraph(number: 2)
            }
            .padding()
        }
        .navigationTitle("Native ad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Reload") { reload += 1 } }
    }
}

struct AdMobFeedPage: View {
    private let adRow = 3
    @State private var status = ""
    @State private var adHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StatusText(message: status).padding()
                ForEach(0..<21, id: \.self) { row in
                    if row == adRow {
                        AdMobNativeAdSlot(adUnitID: DemoConfig.adMobNativeAdUnitID,
                                          status: StatusReporter { status = $0 }, height: $adHeight)
                            .frame(height: adHeight)
                            .padding(.horizontal)
                    } else {
                        Text("Post \(row)").padding()
                        Divider()
                    }
                }
            }
        }
        .navigationTitle("Native ads in a feed")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdMobBannerPage: View {
    @State private var status = ""
    @State private var reload = 0
    @State private var adHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width - 32   // the app runs in portrait only, so the width does not change
            ScrollView {
                VStack(spacing: 16) {
                    StatusText(message: status)
                    Paragraph(number: 1)
                    AdMobBannerSlot(adUnitID: DemoConfig.adMobBannerAdUnitID, width: width, reload: reload,
                                    status: StatusReporter { status = $0 }, height: $adHeight)
                        .frame(height: adHeight)
                    Paragraph(number: 2)
                }
                .padding()
            }
        }
        .navigationTitle("Banner ad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Reload") { reload += 1 } }
    }
}

// MARK: - Tracker

/// Reports what the user does with ATKTracker: one tracker per report, set up by chaining, then `send`.
struct TrackerPage: View {
    @State private var status = ""
    @State private var readingTracker: ATKTracker?

    private var report: StatusReporter { StatusReporter { status = $0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatusText(message: status)
            Button("Open a post") {
                // The time spent counts from `start` until `send`; the url is required. Opening a post leaves the one
                // open before, so that one is sent.
                let leftPost = readingTracker != nil
                readingTracker?.send()
                let post = ATKTrackerEntity(type: .post, entityId: "post-1", title: "A post in your app",
                                            url: "https://example.com/posts/1")
                readingTracker = ATKTracker().entity(post).actionType(.readPost).start()
                report((leftPost ? "READ_POST sent for the post you left. " : "")
                       + "Reading the post: READ_POST is sent when you tap Leave the post.")
            }
            Button("Leave the post") {
                guard let tracker = readingTracker else { return report("Open a post first.") }
                tracker.send()
                readingTracker = nil
                report("READ_POST sent.")
            }
            Button("Report a video watched for 30 seconds") {
                // `timeSpan` sets the time spent yourself.
                let video = ATKTrackerEntity(type: .video, entityId: "video-1", title: "A video in your app",
                                             url: "https://example.com/videos/1")
                ATKTracker().entity(video).actionType(.watchVideo).timeSpan(30).send()
                report("WATCH_VIDEO sent.")
            }
            Spacer()
        }
        .buttonStyle(.bordered)
        .padding()
        .onAppear { report("A send does not report its result back.") }
        .navigationTitle("Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }
}
