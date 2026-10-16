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

@interface AdMobFeedViewController () <GADNativeAdLoaderDelegate, GADNativeAdDelegate>
@end

@implementation AdMobFeedViewController {
    StatusLabel *_status;
    UITableViewCell *_adCell;   // the ad row keeps its own cell, so the table never hands the ad to another row
    AdMobNativeAdCard *_card;
    GADAdLoader *_adLoader;
}

static const NSInteger kAdMobFeedPostCount = 20;
static const NSInteger kAdMobFeedAdRow = 3;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"Post"];
    _status = [[StatusLabel alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    self.tableView.tableHeaderView = _status;
    _card = [[AdMobNativeAdCard alloc] init];
    _adCell = [[UITableViewCell alloc] init];
    _adCell.selectionStyle = UITableViewCellSelectionStyleNone;
    [_adCell.contentView addSubview:_card];
    DemoPinInRow(_card, _adCell.contentView, 12);   // the row collapses while the card is hidden
    _card.hidden = YES;

    _adLoader = [[GADAdLoader alloc] initWithAdUnitID:DemoConfig.adMobNativeAdUnitID rootViewController:self
                                              adTypes:@[GADAdLoaderAdTypeNative] options:nil];
    _adLoader.delegate = self;
    [_status show:@"Loading a native ad through AdMob…"];
    [_adLoader loadRequest:[GADRequest request]];
}

- (void)adLoader:(GADAdLoader *)adLoader didReceiveNativeAd:(GADNativeAd *)nativeAd {
    nativeAd.delegate = self;
    _card.hidden = NO;   // before showAd:, which registers the ad with the card's views at their size
    [_card showAd:nativeAd];
    [self.tableView performBatchUpdates:nil completion:nil];   // the ad row grows to fit the ad
    [_status show:[NSString stringWithFormat:@"AdMob native ad received from %@", DemoAdMobNetwork(nativeAd.responseInfo)]];
}

- (void)adLoader:(GADAdLoader *)adLoader didFailToReceiveAdWithError:(NSError *)error {
    [_status show:[NSString stringWithFormat:@"No AdMob native ad: %@", error.localizedDescription]];
}

- (void)nativeAdDidRecordImpression:(GADNativeAd *)nativeAd {
    [_status show:[NSString stringWithFormat:@"AdMob native ad impression recorded (from %@)", DemoAdMobNetwork(nativeAd.responseInfo)]];
}

- (void)nativeAdDidRecordClick:(GADNativeAd *)nativeAd {
    [_status show:@"AdMob native ad clicked"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kAdMobFeedPostCount + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == kAdMobFeedAdRow) return _adCell;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Post" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"Post %ld", (long)indexPath.row];
    return cell;
}

/// The ad row has no height until its ad arrives, or at all when there is no ad.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row == kAdMobFeedAdRow && _card.hidden ? 0 : UITableViewAutomaticDimension;
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
