#import "DemoViews.h"

static NSString *DemoInfoValue(NSString *key) {
    id value = [NSBundle.mainBundle objectForInfoDictionaryKey:key];
    if ([value isKindOfClass:NSString.class] && [value length] > 0) return value;
    NSLog(@"[AotterTrekDemo] Info.plist has no %@: see Config.xcconfig", key);
    return @"";
}

@implementation DemoConfig
+ (NSString *)clientID { return DemoInfoValue(@"AotterTrekClientID"); }
+ (NSString *)nativePlaceID { return DemoInfoValue(@"AotterTrekNativePlaceID"); }
+ (NSString *)suprAdPlaceID { return DemoInfoValue(@"AotterTrekSuprAdPlaceID"); }
+ (NSString *)bannerPlaceID { return DemoInfoValue(@"AotterTrekBannerPlaceID"); }
+ (NSString *)adMobNativeAdUnitID { return DemoInfoValue(@"AdMobNativeAdUnitID"); }
+ (NSString *)adMobBannerAdUnitID { return DemoInfoValue(@"AdMobBannerAdUnitID"); }
@end

@implementation StatusLabel

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        self.textColor = UIColor.secondaryLabelColor;
        self.numberOfLines = 0;
        self.accessibilityIdentifier = @"status";
    }
    return self;
}

- (void)show:(NSString *)message {
    self.text = message;
    NSLog(@"[AotterTrekDemo] %@", message);
}

@end

@implementation StackPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.delegate = self;
    [self.view addSubview:scrollView];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    _stack = [[UIStackView alloc] init];
    _stack.axis = UILayoutConstraintAxisVertical;
    _stack.spacing = 16;
    _stack.layoutMarginsRelativeArrangement = YES;
    _stack.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(16, 16, 16, 16);
    [scrollView addSubview:_stack];
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_stack.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [_stack.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor],
        [_stack.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor],
        [_stack.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [_stack.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor],
    ]];
    _status = [[StatusLabel alloc] init];
    [_stack addArrangedSubview:_status];
}

@end

UILabel *DemoParagraph(NSInteger number) {
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.text = [NSString stringWithFormat:@"Paragraph %ld. Your app's own content goes here, above and below the ad, "
                  @"the way a reader meets it in an article or a feed.", (long)number];
    return label;
}

static void DemoPinWithBottomPriority(UIView *view, UIView *container, CGFloat inset, UILayoutPriority bottomPriority) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *bottom = [view.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-inset];
    bottom.priority = bottomPriority;
    [NSLayoutConstraint activateConstraints:@[
        [view.topAnchor constraintEqualToAnchor:container.topAnchor constant:inset],
        [view.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:inset],
        [view.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-inset],
        bottom,
    ]];
}

void DemoPin(UIView *view, UIView *container, CGFloat inset) {
    DemoPinWithBottomPriority(view, container, inset, UILayoutPriorityRequired);
}

void DemoPinInRow(UIView *view, UIView *contentView, CGFloat inset) {
    DemoPinWithBottomPriority(view, contentView, inset, UILayoutPriorityDefaultHigh);
}

NSString *DemoAdMobNetwork(GADResponseInfo *responseInfo) {
    return responseInfo.loadedAdNetworkResponseInfo.adNetworkClassName ?: @"unknown network";
}
