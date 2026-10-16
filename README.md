# AotterTrek iOS demo

Sample apps that show AotterTrek ads the way a publisher app does, with
[AotterTrekSDK](https://github.com/aotter/AotterTrekSDK-iOS) and the AdMob adapter from
[AotterTrekMediation](https://github.com/aotter/AotterTrekMediation-iOS). The integration guide is at
[aotter.gitbook.io/ios](https://aotter.gitbook.io/ios).

The same app, three ways:

| Folder | Language and UI | Installs the SDK with |
|---|---|---|
| `ObjC-UIKit` | Objective-C, UIKit | CocoaPods |
| `Swift-UIKit` | Swift, UIKit | CocoaPods |
| `SwiftUI` | Swift, SwiftUI | Swift Package Manager |

Each one is a standalone project, with its own `.gitignore`: copy the folder you need.

## Run it

Requirements: Xcode 27 or later, and iOS 15 or later.

```sh
cd Swift-UIKit
pod install
open SwiftUIKitDemo.xcworkspace   # in ObjC-UIKit: ObjCUIKitDemo.xcworkspace
```

`Podfile.lock` keeps the versions `pod install` picked; run `pod update` to move to a newer release.

The SwiftUI project needs no setup: open `SwiftUI/SwiftUIDemo.xcodeproj` and Xcode fetches the packages. That includes
the AppLovin MAX package, which the AotterTrekMediation package declares for its MAX adapter; the demo does not use it.
`Package.resolved` keeps the versions Xcode resolved; run Xcode's Update to Latest Package Versions command to move to
a newer release.

To run on a device, set your own team and bundle identifier under Signing & Capabilities.

With AotterTrekSDK 5.0.0 from Swift Package Manager (or added by hand), the app target has to link with `-ObjC`
(Build Settings > Other Linker Flags): part of the SDK is Objective-C categories, which a static link leaves out
otherwise, and the app stops when it shows an ad. The SwiftUI project sets it. CocoaPods adds the flag for you.

## What the pages show

| Page | Shows |
|---|---|
| AotterTrek / Native ad | `ATKAdLoader` loads one ad; `ATKNativeAdView` with an `ATKMediaView` shows it between paragraphs |
| AotterTrek / Native ads in a feed | Two ad slots in a list, a native placement and a SuprAd placement, shown by the same code |
| AotterTrek / Banner ad | `ATKBannerAdView`, sized by the server |
| AdMob mediation / Native ad, feed, banner | The same through Google Mobile Ads, with AotterTrek in the ad unit's mediation group; the feed has one native slot |
| Tracker | `ATKTracker` reports what the user does: one tracker per report, sent with `send`, which does not report its result back |

Every page has a status line at the top that says what the ad did last; the same line goes to the console.

A few rules the code follows, from the [SDK README](https://github.com/aotter/AotterTrekSDK-iOS) and the
[integration guide](https://aotter.gitbook.io/ios):

- One ad, one view. Binding an ad into a second view moves it there, and a SuprAd that has started does not survive
  the move. In a UIKit feed each ad slot keeps a cell of its own, so a reused cell never takes an ad from another row.
  The SwiftUI AotterTrek feed puts its slots in a `VStack`, where each slot keeps its place; a `List` recycles its rows.
  A `VStack` builds every row at once, and that page redraws as it scrolls because it counts the scrolling for SuprAd
  creatives. Both suit this short feed; a long feed needs a lazy container and its own way to keep each slot's ad.
- `rootViewController` is always set: videos, popups and the in-app browser present from it.
- `ATKMediaView` has no intrinsic size; the card gives it the ad's aspect ratio.
- Each native card labels its ad. The AotterTrek card shows `sponsor`, the label text the server sends (such as
  "Sponsored"), or "Sponsored" when it is empty; the integration guide requires native ads to display it. The AdMob
  card shows the same label for the ads AotterTrek fills, from `extraAssets["Sponsor"]`, and "Ad" for the others. The
  label is at least 15 points on each side, which meets Google's 15 px minimum, and a long title gives way to it.
- The AdMob card shows the icon whenever the ad provides one, as Google requires. The AotterTrek adapter provides it
  as a URL only, so the card downloads it.
- AotterTrek ads are destroyed when the page goes away. A native slot also destroys its ad before it reloads; a
  banner keeps its ad on screen until the next one arrives.

## The IDs

`Config.xcconfig` in each folder holds the IDs; the app reads them from `Info.plist`.

- **AotterTrek**: the public test client and placements from the AotterTrek docs. They serve test ads. Replace them
  with your own before you ship.
- **AdMob**: Google's sample app ID and demo ad units. They always serve Google's own test ads, so with them the
  AdMob pages never reach the AotterTrek adapter. To see AotterTrek ads through AdMob, copy `Local.xcconfig.example`
  to `Local.xcconfig` (git ignores it) and put in your own AdMob app ID and ad units. In the AdMob console, add a
  custom event to each ad unit's mediation group, pointing the native ad unit at a native or SuprAd placement and
  the banner ad unit at a banner placement:

  | Field | Value |
  |---|---|
  | Class Name | `AotterTrekGADMediaAdapter` |
  | Parameter | `{"clientId": "<client id>", "adPlace": "<place uid>"}` |

  Use the client id the app initialises the SDK with (the one in `Config.xcconfig`, or yours): when the two differ,
  the adapter fails the request rather than switch accounts. Console setups that name the earlier classes
  `AotterTrekGADCustomEventNativeAd` and `AotterTrekGADCustomEventBannerAd` keep working; new setups use
  `AotterTrekGADMediaAdapter`.

  While you try live ad units, register the device you test on as a test device in the AdMob console. That puts only
  the AdMob Network's own ads in test mode, not the ads AotterTrek fills, so also point the custom event at the
  AotterTrek test client and placements from `Config.xcconfig`, and leave the AotterTrek keys in `Local.xcconfig`
  unset so the app initialises the SDK with the same client. Before the ad unit serves your released app, change the
  custom event and the client your app starts the SDK with to your own, together. From then on the ads AotterTrek
  fills are live, so do not tap them yourself.

  Through AdMob, SuprAd creatives that follow the scroll do not get the page's scrolling: the adapter has no way to
  pass it on.

## About the Podfiles

- The Podfiles list AotterTrek's own spec repo, `https://github.com/aotter/AotterTrekSpecs-iOS.git`, next to
  CocoaPods trunk. CocoaPods trunk takes no new versions after December 2, 2026, so later AotterTrek versions are
  published only to that spec repo. While a version is on both, `pod install` says it found multiple
  specifications: both carry the same podspec.
- Google Mobile Ads and the pods it depends on still declare iOS 12, which Xcode 27 no longer builds for; the
  `post_install` hook raises every pod below iOS 15 to 15 and leaves the ones that need a later version alone.

The AppLovin MAX adapter is not covered here.

## Support

sdk@aotter.net
