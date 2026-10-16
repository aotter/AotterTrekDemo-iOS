@import UIKit;
@import AotterTrekSDK;
@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

/// The IDs from Config.xcconfig (and Local.xcconfig, when present), read from Info.plist.
@interface DemoConfig : NSObject
+ (NSString *)clientID;
+ (NSString *)nativePlaceID;
+ (NSString *)suprAdPlaceID;
+ (NSString *)bannerPlaceID;
+ (NSString *)adMobNativeAdUnitID;
+ (NSString *)adMobBannerAdUnitID;
@end

/// The line at the top of every page that says what the ad did last. It also goes to the console.
@interface StatusLabel : UILabel
- (void)show:(NSString *)message;
@end

/// A scrolling page that stacks views vertically, with a status line on top. The AotterTrek pages implement
/// scrollViewDidScroll: to tell the ad that the page scrolled, for SuprAd creatives that follow the scroll.
@interface StackPageViewController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, readonly) StatusLabel *status;
@property (nonatomic, readonly) UIStackView *stack;
@end

/// Stand-in for the app's own content around the ads.
UILabel *DemoParagraph(NSInteger number);

/// Pins `view` to every edge of `container`, inset by `inset`.
void DemoPin(UIView *view, UIView *container, CGFloat inset);
/// Same, with the bottom edge below required, so a table row can collapse while `view` is hidden.
void DemoPinInRow(UIView *view, UIView *contentView, CGFloat inset);

/// Shows one AotterTrek native ad. The asset views sit inside an ATKNativeAdView, which the SDK measures, and one
/// ATKMediaView renders every creative type: an image, HTML5, a web page or a VAST video.
@interface TrekNativeAdCard : UIView
@property (nonatomic, readonly) ATKNativeAdView *adView;
/// Fills in the assets and binds the ad, which starts measuring it. Call it once per ad: binding an image ad again
/// loads and reports its picture again.
- (void)showAd:(ATKNativeAdData *)ad fromViewController:(UIViewController *)viewController;
@end

/// Shows one native ad from Google Mobile Ads. Every ad goes through a GADNativeAdView with a GADMediaView inside
/// it: that is how Google Mobile Ads, and through it the AotterTrek adapter, knows the ad is on screen.
@interface AdMobNativeAdCard : UIView
/// Fills in the assets, then hands the ad to the GADNativeAdView, which registers it.
- (void)showAd:(GADNativeAd *)nativeAd;
@end

/// Which network filled the request, as the mediation report names it.
NSString *DemoAdMobNetwork(GADResponseInfo *_Nullable responseInfo);

NS_ASSUME_NONNULL_END
