import SwiftUI
import AotterTrekSDK
import GoogleMobileAds

@main
struct SwiftUIDemoApp: App {

    init() {
        // Start AotterTrek before anything requests an ad, the AdMob adapter included.
        AotterTrekSDK.sharedInstance().initSDK(DemoConfig.clientID)
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            List {
                Section("AotterTrek") {
                    NavigationLink("Native ad") { TrekNativePage() }
                    NavigationLink("Native ads in a feed") { TrekFeedPage() }
                    NavigationLink("Banner ad") { TrekBannerPage() }
                }
                Section("AdMob mediation") {
                    NavigationLink("Native ad") { AdMobNativePage() }
                    NavigationLink("Native ads in a feed") { AdMobFeedPage() }
                    NavigationLink("Banner ad") { AdMobBannerPage() }
                }
                Section("Tracker") {
                    NavigationLink("Report what the user does") { TrackerPage() }
                }
            }
            .navigationTitle("AotterTrek Demo")
        }
        .navigationViewStyle(.stack)
    }
}
