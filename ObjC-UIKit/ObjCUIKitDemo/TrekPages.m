#import "DemoPages.h"

#pragma mark - Native ad

@interface TrekNativeViewController () <ATKAdLoaderDelegate>
@end

@implementation TrekNativeViewController {
    TrekNativeAdCard *_card;
    ATKAdLoader *_loader;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(loadAd)];
    _card = [[TrekNativeAdCard alloc] init];
    [self.stack addArrangedSubview:DemoParagraph(1)];
    [self.stack addArrangedSubview:_card];
    [self.stack addArrangedSubview:DemoParagraph(2)];
    _card.hidden = YES;
    [self loadAd];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isMovingFromParentViewController) [_card.adView destroy];   // leaving the page: end the ad
}

- (void)loadAd {
    [_card.adView destroy];   // a reload: end the ad shown so far
    _card.hidden = YES;
    _loader = [[ATKAdLoader alloc] initWithPlaceID:DemoConfig.nativePlaceID listener:nil];
    _loader.delegate = self;
    [self.status show:@"Loading a native ad…"];
    [_loader loadAdRequest:[[ATKAdRequest alloc] initWithCategory:@"" contentURL:@"" contentTitle:@"" meta:@{}]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_card.adView notifyAdScrolled];   // SuprAd creatives that follow the scroll
}

- (void)adLoader:(ATKAdLoader *)adLoader didReceiveAd:(ATKNativeAdData *)ad {
    if (adLoader != _loader) { [ad destroy]; return; }   // a reload replaced this loader
    [_card showAd:ad fromViewController:self];
    _card.hidden = NO;
    [self.status show:[NSString stringWithFormat:@"Native ad received: %@", ad.title]];
}

- (void)adLoader:(ATKAdLoader *)adLoader didFailToReceiveAdWithError:(NSError *)error {
    if (adLoader != _loader) return;
    [self.status show:[NSString stringWithFormat:@"No native ad (%ld): %@", (long)error.code, error.localizedDescription]];
}

- (void)adLoader:(ATKAdLoader *)adLoader didRecordImpressionForAd:(ATKNativeAdData *)ad {
    [self.status show:@"Native ad impression recorded"];
}

- (void)adLoader:(ATKAdLoader *)adLoader didRecordClickForAd:(ATKNativeAdData *)ad {
    [self.status show:@"Native ad clicked"];
}

@end

#pragma mark - Native ads in a feed

/// One ad slot. It keeps its own cell, so the table never hands the ad to another row: a second bind moves the ad,
/// and a SuprAd that has started does not survive the move.
@interface TrekAdSlot : NSObject
@property (nonatomic, readonly) NSInteger row;
@property (nonatomic, readonly) NSString *placeID;
@property (nonatomic, readonly) TrekNativeAdCard *card;
@property (nonatomic, readonly) UITableViewCell *cell;
@property (nonatomic, strong) ATKAdLoader *loader;
@end

@implementation TrekAdSlot

- (instancetype)initWithRow:(NSInteger)row placeID:(NSString *)placeID {
    if (!(self = [super init])) return nil;
    _row = row;
    _placeID = placeID;
    _card = [[TrekNativeAdCard alloc] init];
    _cell = [[UITableViewCell alloc] init];
    _cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [_cell.contentView addSubview:_card];
    DemoPinInRow(_card, _cell.contentView, 12);   // the row collapses while the card is hidden
    _card.hidden = YES;
    return self;
}

@end

@interface TrekFeedViewController () <ATKAdLoaderDelegate>
@end

@implementation TrekFeedViewController {
    StatusLabel *_status;
    NSArray<TrekAdSlot *> *_slots;
}

static const NSInteger kTrekFeedPostCount = 20;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"Post"];
    _status = [[StatusLabel alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    self.tableView.tableHeaderView = _status;
    _slots = @[
        [[TrekAdSlot alloc] initWithRow:3 placeID:DemoConfig.nativePlaceID],
        [[TrekAdSlot alloc] initWithRow:10 placeID:DemoConfig.suprAdPlaceID],
    ];
    for (TrekAdSlot *slot in _slots) [self load:slot];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.isMovingFromParentViewController) return;
    for (TrekAdSlot *slot in _slots) [slot.card.adView destroy];   // leaving the page: end the ads
}

- (void)load:(TrekAdSlot *)slot {
    slot.loader = [[ATKAdLoader alloc] initWithPlaceID:slot.placeID listener:nil];
    slot.loader.delegate = self;
    [_status show:@"Loading ads…"];
    [slot.loader loadAdRequest:[[ATKAdRequest alloc] initWithCategory:@"" contentURL:@"" contentTitle:@"" meta:@{}]];
}

- (TrekAdSlot *)slotForLoader:(ATKAdLoader *)loader {
    for (TrekAdSlot *slot in _slots) if (slot.loader == loader) return slot;
    return nil;
}

- (void)adLoader:(ATKAdLoader *)adLoader didReceiveAd:(ATKNativeAdData *)ad {
    TrekAdSlot *slot = [self slotForLoader:adLoader];
    if (!slot) { [ad destroy]; return; }
    [slot.card showAd:ad fromViewController:self];
    slot.card.hidden = NO;
    [self.tableView performBatchUpdates:nil completion:nil];   // the slot's row grows to fit the ad
    [_status show:[NSString stringWithFormat:@"Ad received for row %ld: %@", (long)slot.row, ad.title]];
}

- (void)adLoader:(ATKAdLoader *)adLoader didFailToReceiveAdWithError:(NSError *)error {
    TrekAdSlot *slot = [self slotForLoader:adLoader];
    if (!slot) return;
    [_status show:[NSString stringWithFormat:@"No ad for row %ld (%ld): %@", (long)slot.row, (long)error.code, error.localizedDescription]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kTrekFeedPostCount + _slots.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    for (TrekAdSlot *slot in _slots) if (slot.row == indexPath.row) return slot.cell;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Post" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Post %ld", (long)indexPath.row];
    return cell;
}

/// An ad row has no height until its ad arrives, or at all when there is no ad.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    for (TrekAdSlot *slot in _slots) if (slot.row == indexPath.row && slot.card.hidden) return 0;
    return UITableViewAutomaticDimension;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    for (TrekAdSlot *slot in _slots) [slot.card.adView notifyAdScrolled];   // SuprAd creatives that follow the scroll
}

@end

#pragma mark - Banner

@interface TrekBannerViewController () <ATKBannerAdDelegate>
@end

@implementation TrekBannerViewController {
    ATKBannerAdView *_banner;
    NSLayoutConstraint *_bannerWidth;
    NSLayoutConstraint *_bannerHeight;   // zero while the ad has no size, else the creative's aspect ratio
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(loadAd)];
    UIView *slot = [[UIView alloc] init];   // centres the banner across the page
    _banner = [[ATKBannerAdView alloc] init];
    [slot addSubview:_banner];
    _banner.translatesAutoresizingMaskIntoConstraints = NO;
    _bannerWidth = [_banner.widthAnchor constraintEqualToConstant:0];
    _bannerWidth.priority = UILayoutPriorityDefaultHigh;
    _bannerHeight = [_banner.heightAnchor constraintEqualToConstant:0];
    [NSLayoutConstraint activateConstraints:@[
        [_banner.topAnchor constraintEqualToAnchor:slot.topAnchor],
        [_banner.bottomAnchor constraintEqualToAnchor:slot.bottomAnchor],
        [_banner.centerXAnchor constraintEqualToAnchor:slot.centerXAnchor],
        [_banner.widthAnchor constraintLessThanOrEqualToAnchor:slot.widthAnchor],
        _bannerWidth, _bannerHeight,
    ]];
    [self.stack addArrangedSubview:DemoParagraph(1)];
    [self.stack addArrangedSubview:slot];
    [self.stack addArrangedSubview:DemoParagraph(2)];

    _banner.placeID = DemoConfig.bannerPlaceID;
    _banner.rootViewController = self;
    _banner.delegate = self;
    [self loadAd];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.isMovingFromParentViewController) [_banner destroy];   // leaving the page: end the ad
}

/// A reload keeps the current ad on screen until the next one arrives, so the banner is not destroyed first.
- (void)loadAd {
    [self.status show:@"Loading a banner…"];
    [_banner loadRequest:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_banner notifyAdScrolled];   // SuprAd creatives that follow the scroll
}

/// The size the creative was built for. A creative wider than the page is scaled down to fit, keeping its shape.
- (void)bannerAdView:(ATKBannerAdView *)bannerAdView willChangeAdSizeTo:(CGSize)adSize {
    BOOL sized = adSize.width > 0 && adSize.height > 0;   // with no size the banner folds away, as before the first ad
    _bannerWidth.constant = sized ? adSize.width : 0;
    _bannerHeight.active = NO;
    _bannerHeight = sized ? [_banner.heightAnchor constraintEqualToAnchor:_banner.widthAnchor multiplier:adSize.height / adSize.width]
                          : [_banner.heightAnchor constraintEqualToConstant:0];
    _bannerHeight.active = YES;
}

- (void)bannerAdViewDidReceiveAd:(ATKBannerAdView *)bannerAdView {
    CGSize size = bannerAdView.adSize;
    if (size.width <= 0 || size.height <= 0) { [self.status show:@"Banner received without a size, so it is not shown"]; return; }
    [self.status show:[NSString stringWithFormat:@"Banner received: %.0f x %.0f", size.width, size.height]];
}

- (void)bannerAdView:(ATKBannerAdView *)bannerAdView didFailToReceiveAdWithError:(NSError *)error {
    [self.status show:[NSString stringWithFormat:@"No banner (%ld): %@", (long)error.code, error.localizedDescription]];
}

- (void)bannerAdViewDidRecordImpression:(ATKBannerAdView *)bannerAdView {
    [self.status show:@"Banner impression recorded"];
}

- (void)bannerAdViewDidRecordClick:(ATKBannerAdView *)bannerAdView {
    [self.status show:@"Banner clicked"];
}

@end
