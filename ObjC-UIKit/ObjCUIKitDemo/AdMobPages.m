#import "DemoPages.h"

#pragma mark - Native ad

@interface AdMobNativeViewController () <GADNativeAdLoaderDelegate, GADNativeAdDelegate>
@end

@implementation AdMobNativeViewController {
    AdMobNativeAdCard *_card;
    GADAdLoader *_adLoader;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(loadAd)];
    _card = [[AdMobNativeAdCard alloc] init];
    [self.stack addArrangedSubview:DemoParagraph(1)];
    [self.stack addArrangedSubview:_card];
    [self.stack addArrangedSubview:DemoParagraph(2)];
    _card.hidden = YES;
    [self loadAd];
}

- (void)loadAd {
    _adLoader = [[GADAdLoader alloc] initWithAdUnitID:DemoConfig.adMobNativeAdUnitID rootViewController:self
                                              adTypes:@[GADAdLoaderAdTypeNative] options:nil];
    _adLoader.delegate = self;
    [self.status show:@"Loading a native ad through AdMob…"];
    [_adLoader loadRequest:[GADRequest request]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [AotterTrekSDK notifyAdScrolled];   // Native Multimedia Ads that move with the page, also through the adapter
}

- (void)adLoader:(GADAdLoader *)adLoader didReceiveNativeAd:(GADNativeAd *)nativeAd {
    if (adLoader != _adLoader) return;   // a reload replaced this loader
    nativeAd.delegate = self;
    _card.hidden = NO;   // before showAd:, which registers the ad with the card's views at their size
    [_card showAd:nativeAd];
    [self.status show:[NSString stringWithFormat:@"AdMob native ad received from %@", DemoAdMobNetwork(nativeAd.responseInfo)]];
}

- (void)adLoader:(GADAdLoader *)adLoader didFailToReceiveAdWithError:(NSError *)error {
    if (adLoader != _adLoader) return;
    [self.status show:[NSString stringWithFormat:@"No AdMob native ad: %@", error.localizedDescription]];
}

- (void)nativeAdDidRecordImpression:(GADNativeAd *)nativeAd {
    [self.status show:[NSString stringWithFormat:@"AdMob native ad impression recorded (from %@)", DemoAdMobNetwork(nativeAd.responseInfo)]];
}

- (void)nativeAdDidRecordClick:(GADNativeAd *)nativeAd {
    [self.status show:@"AdMob native ad clicked"];
}

@end

#pragma mark - Native ads in a feed

/// One ad slot. It keeps its own cell, so the table never hands the ad to another row.
@interface AdMobAdSlot : NSObject
@property (nonatomic, readonly) NSInteger row;
@property (nonatomic, readonly) NSString *adUnitID;
@property (nonatomic, readonly) AdMobNativeAdCard *card;
@property (nonatomic, readonly) UITableViewCell *cell;
@property (nonatomic, strong) GADAdLoader *adLoader;
@end

@implementation AdMobAdSlot

- (instancetype)initWithRow:(NSInteger)row adUnitID:(NSString *)adUnitID {
    if (!(self = [super init])) return nil;
    _row = row;
    _adUnitID = adUnitID;
    _card = [[AdMobNativeAdCard alloc] init];
    _cell = [[UITableViewCell alloc] init];
    _cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [_cell.contentView addSubview:_card];
    DemoPin(_card, _cell.contentView, 12);
    return self;
}

@end

@interface AdMobFeedViewController () <GADNativeAdLoaderDelegate, GADNativeAdDelegate>
@end

@implementation AdMobFeedViewController {
    StatusLabel *_status;
    NSArray<AdMobAdSlot *> *_slots;
    NSMutableArray *_rows;   // the rows on screen: a post's number (NSNumber), and a slot once its ad has arrived
}

static const NSInteger kAdMobFeedPostCount = 20;

/// A row's number in the full feed.
static NSInteger AdMobFeedRowNumber(id row) {
    return [row isKindOfClass:AdMobAdSlot.class] ? ((AdMobAdSlot *)row).row : [row integerValue];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"Post"];
    _status = [[StatusLabel alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    self.tableView.tableHeaderView = _status;
    _slots = @[   // one ad unit per AotterTrek placement type
        [[AdMobAdSlot alloc] initWithRow:3 adUnitID:DemoConfig.adMobNativeAdUnitID],
        [[AdMobAdSlot alloc] initWithRow:10 adUnitID:DemoConfig.adMobNativeMultimediaAdUnitID],
    ];
    _rows = [NSMutableArray array];
    for (NSInteger number = 0; number < kAdMobFeedPostCount + (NSInteger)_slots.count; number++) {
        BOOL isSlot = NO;
        for (AdMobAdSlot *slot in _slots) if (slot.row == number) isSlot = YES;
        if (!isSlot) [_rows addObject:@(number)];
    }
    for (AdMobAdSlot *slot in _slots) [self load:slot];
}

- (void)load:(AdMobAdSlot *)slot {
    slot.adLoader = [[GADAdLoader alloc] initWithAdUnitID:slot.adUnitID rootViewController:self
                                                  adTypes:@[GADAdLoaderAdTypeNative] options:nil];
    slot.adLoader.delegate = self;
    [_status show:@"Loading ads through AdMob…"];
    [slot.adLoader loadRequest:[GADRequest request]];
}

- (AdMobAdSlot *)slotForLoader:(GADAdLoader *)adLoader {
    for (AdMobAdSlot *slot in _slots) if (slot.adLoader == adLoader) return slot;
    return nil;
}

- (void)adLoader:(GADAdLoader *)adLoader didReceiveNativeAd:(GADNativeAd *)nativeAd {
    AdMobAdSlot *slot = [self slotForLoader:adLoader];
    if (!slot) return;
    nativeAd.delegate = self;
    [slot.card fillAd:nativeAd];
    NSUInteger index = _rows.count;
    for (NSUInteger i = 0; i < _rows.count; i++) if (AdMobFeedRowNumber(_rows[i]) > slot.row) { index = i; break; }
    [_rows insertObject:slot atIndex:index];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                          withRowAnimation:UITableViewRowAnimationNone];   // the row comes in at the height of its ad
    AdMobNativeAdCard *card = slot.card;
    dispatch_async(dispatch_get_main_queue(), ^{ [card registerAd:nativeAd]; });   // once the row has laid the card out at its size
    [_status show:[NSString stringWithFormat:@"AdMob native ad received for row %ld from %@", (long)slot.row,
                   DemoAdMobNetwork(nativeAd.responseInfo)]];
}

- (void)adLoader:(GADAdLoader *)adLoader didFailToReceiveAdWithError:(NSError *)error {
    AdMobAdSlot *slot = [self slotForLoader:adLoader];
    if (!slot) return;
    [_status show:[NSString stringWithFormat:@"No AdMob native ad for row %ld: %@", (long)slot.row, error.localizedDescription]];
}

- (void)nativeAdDidRecordImpression:(GADNativeAd *)nativeAd {
    [_status show:[NSString stringWithFormat:@"AdMob native ad impression recorded (from %@)", DemoAdMobNetwork(nativeAd.responseInfo)]];
}

- (void)nativeAdDidRecordClick:(GADNativeAd *)nativeAd {
    [_status show:@"AdMob native ad clicked"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id row = _rows[indexPath.row];
    if ([row isKindOfClass:AdMobAdSlot.class]) return ((AdMobAdSlot *)row).cell;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Post" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Post %ld", (long)AdMobFeedRowNumber(row)];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [AotterTrekSDK notifyAdScrolled];   // Native Multimedia Ads that move with the page, also through the adapter
}

@end

#pragma mark - Banner

@interface AdMobBannerViewController () <GADBannerViewDelegate>
@end

@implementation AdMobBannerViewController {
    GADBannerView *_bannerView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(loadAd)];
    [self.stack addArrangedSubview:DemoParagraph(1)];
    UIView *slot = [[UIView alloc] init];
    [self.stack addArrangedSubview:slot];
    [self.stack addArrangedSubview:DemoParagraph(2)];

    CGFloat width = CGRectGetWidth(self.view.bounds) - 32;   // the app runs in portrait only, so the width does not change
    // Inline adaptive: the size for a banner inside scrolling content. Its height comes with the ad.
    _bannerView = [[GADBannerView alloc] initWithAdSize:GADCurrentOrientationInlineAdaptiveBannerAdSizeWithWidth(width)];
    _bannerView.adUnitID = DemoConfig.adMobBannerAdUnitID;
    _bannerView.rootViewController = self;
    _bannerView.delegate = self;
    [slot addSubview:_bannerView];
    _bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_bannerView.topAnchor constraintEqualToAnchor:slot.topAnchor],
        [_bannerView.bottomAnchor constraintEqualToAnchor:slot.bottomAnchor],
        [_bannerView.centerXAnchor constraintEqualToAnchor:slot.centerXAnchor],
    ]];   // the banner takes its size from its ad size
    [self loadAd];
}

- (void)loadAd {
    [self.status show:@"Loading a banner through AdMob…"];
    [_bannerView loadRequest:[GADRequest request]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [AotterTrekSDK notifyAdScrolled];   // Native Multimedia Ads that move with the page, also through the adapter
}

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView {
    [self.status show:[NSString stringWithFormat:@"AdMob banner received from %@", DemoAdMobNetwork(bannerView.responseInfo)]];
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    [self.status show:[NSString stringWithFormat:@"No AdMob banner: %@", error.localizedDescription]];
}

- (void)bannerViewDidRecordImpression:(GADBannerView *)bannerView {
    [self.status show:[NSString stringWithFormat:@"AdMob banner impression recorded (from %@)", DemoAdMobNetwork(bannerView.responseInfo)]];
}

- (void)bannerViewDidRecordClick:(GADBannerView *)bannerView {
    [self.status show:@"AdMob banner clicked"];
}

@end
