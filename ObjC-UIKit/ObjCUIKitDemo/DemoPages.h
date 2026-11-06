#import "DemoViews.h"

NS_ASSUME_NONNULL_BEGIN

@interface HomeViewController : UITableViewController
@end

/// One AotterTrek native ad between paragraphs of an article.
@interface TrekNativeViewController : StackPageViewController
@end

/// A feed with two AotterTrek ad slots: a native placement and a Native Multimedia Ad placement.
@interface TrekFeedViewController : UITableViewController
@end

/// An AotterTrek banner, as wide as the page. The server decides its proportions.
@interface TrekBannerViewController : StackPageViewController
@end

/// One native ad from an AdMob ad unit whose mediation group includes AotterTrek (custom event class
/// `AotterTrekGADMediaAdapter`).
@interface AdMobNativeViewController : StackPageViewController
@end

/// A feed with two AdMob ad slots: a native ad unit and a Native Multimedia Ad unit.
@interface AdMobFeedViewController : UITableViewController
@end

/// A banner from an AdMob ad unit whose mediation group includes AotterTrek.
@interface AdMobBannerViewController : StackPageViewController
@end

/// Reports what the user does with ATKTracker: one tracker per report, set up by chaining, then `send`.
@interface TrackerViewController : StackPageViewController
@end

NS_ASSUME_NONNULL_END
