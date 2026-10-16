import Foundation

/// The IDs from Config.xcconfig (and Local.xcconfig, when present), read from Info.plist.
enum DemoConfig {
    static let clientID = value("AotterTrekClientID")
    static let nativePlaceID = value("AotterTrekNativePlaceID")
    static let suprAdPlaceID = value("AotterTrekSuprAdPlaceID")
    static let bannerPlaceID = value("AotterTrekBannerPlaceID")
    static let adMobNativeAdUnitID = value("AdMobNativeAdUnitID")
    static let adMobBannerAdUnitID = value("AdMobBannerAdUnitID")

    private static func value(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            print("[AotterTrekDemo] Info.plist has no \(key): see Config.xcconfig")
            return ""
        }
        return value
    }
}
