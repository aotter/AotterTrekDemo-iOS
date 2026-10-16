import UIKit
import AotterTrekSDK
import GoogleMobileAds

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Start AotterTrek before anything requests an ad, the AdMob adapter included.
        AotterTrekSDK.sharedInstance().initSDK(DemoConfig.clientID)
        MobileAds.shared.start()
        return true
    }
}
