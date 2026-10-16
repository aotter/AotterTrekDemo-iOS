#import "DemoPages.h"

@implementation TrackerViewController {
    ATKTracker *_readingTracker;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.stack addArrangedSubview:[self buttonTitled:@"Open a post" action:@selector(openPost)]];
    [self.stack addArrangedSubview:[self buttonTitled:@"Leave the post" action:@selector(leavePost)]];
    [self.stack addArrangedSubview:[self buttonTitled:@"Report a video watched for 30 seconds" action:@selector(reportVideo)]];
    [self.status show:@"A send does not report its result back."];
}

/// The time spent counts from `start` until `send`. Opening a post leaves the one open before, so that one is sent.
- (void)openPost {
    BOOL leftPost = _readingTracker != nil;
    [_readingTracker send];
    ATKTrackerEntity *post = [[ATKTrackerEntity alloc] initWithType:ATKTrackerEntityTypePost entityId:@"post-1"
                                                              title:@"A post in your app"
                                                                url:@"https://example.com/posts/1"];   // the url is required
    _readingTracker = [[[[[ATKTracker alloc] init] entity:post] actionType:ATKTrackerActionTypeReadPost] start];
    [self.status show:[NSString stringWithFormat:@"%@Reading the post: READ_POST is sent when you tap Leave the post.",
                       leftPost ? @"READ_POST sent for the post you left. " : @""]];
}

- (void)leavePost {
    if (!_readingTracker) { [self.status show:@"Open a post first."]; return; }
    [_readingTracker send];
    _readingTracker = nil;
    [self.status show:@"READ_POST sent."];
}

/// `timeSpan:` sets the time spent yourself.
- (void)reportVideo {
    ATKTrackerEntity *video = [[ATKTrackerEntity alloc] initWithType:ATKTrackerEntityTypeVideo entityId:@"video-1"
                                                               title:@"A video in your app"
                                                                 url:@"https://example.com/videos/1"];
    [[[[[[ATKTracker alloc] init] entity:video] actionType:ATKTrackerActionTypeWatchVideo] timeSpan:30] send];
    [self.status show:@"WATCH_VIDEO sent."];
}

- (UIButton *)buttonTitled:(NSString *)title action:(SEL)action {
    UIButtonConfiguration *configuration = UIButtonConfiguration.tintedButtonConfiguration;
    configuration.title = title;
    UIButton *button = [UIButton buttonWithConfiguration:configuration primaryAction:nil];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
