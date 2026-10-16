#import "DemoViews.h"

@implementation AdMobNativeAdCard {
    GADNativeAdView *_nativeAdView;
    GADMediaView *_mediaView;
    UIImageView *_iconView;
    UILabel *_badge;
    UILabel *_headlineLabel;
    UILabel *_advertiserLabel;
    UILabel *_bodyLabel;
    UIButton *_callToActionButton;
    NSLayoutConstraint *_mediaHeight;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    _nativeAdView = [[GADNativeAdView alloc] init];
    [self addSubview:_nativeAdView];
    DemoPin(_nativeAdView, self, 0);
    _nativeAdView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    _nativeAdView.layer.cornerRadius = 8;
    _nativeAdView.clipsToBounds = YES;

    _badge = [[UILabel alloc] init];
    _badge.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];   // the label that marks the ad as an ad
    _badge.textAlignment = NSTextAlignmentCenter;
    _badge.textColor = UIColor.whiteColor;
    _badge.backgroundColor = [UIColor colorWithRed:0xC9 / 255.0 green:0x34 / 255.0 blue:0 alpha:1];   // white text reads at 5.3:1
    // The label keeps its own width: a long title gives way to it.
    [_badge setContentHuggingPriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisHorizontal];
    [_badge setContentCompressionResistancePriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisHorizontal];
    _badge.layer.cornerRadius = 3;
    _badge.clipsToBounds = YES;
    _mediaView = [[GADMediaView alloc] init];
    _iconView = [[UIImageView alloc] init];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _headlineLabel = [[UILabel alloc] init];
    _headlineLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _headlineLabel.numberOfLines = 2;
    _advertiserLabel = [[UILabel alloc] init];
    _advertiserLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _advertiserLabel.textColor = UIColor.secondaryLabelColor;
    _bodyLabel = [[UILabel alloc] init];
    _bodyLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _bodyLabel.numberOfLines = 3;
    _callToActionButton = [UIButton buttonWithConfiguration:UIButtonConfiguration.filledButtonConfiguration primaryAction:nil];
    _callToActionButton.userInteractionEnabled = NO;   // the ad network's SDK handles the tap

    UIStackView *titles = [[UIStackView alloc] initWithArrangedSubviews:@[_headlineLabel, _advertiserLabel]];
    titles.axis = UILayoutConstraintAxisVertical;
    titles.spacing = 2;
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[_iconView, titles, _badge]];
    header.spacing = 8;
    header.alignment = UIStackViewAlignmentCenter;
    UIStackView *content = [[UIStackView alloc] initWithArrangedSubviews:@[header, _mediaView, _bodyLabel, _callToActionButton]];
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 8;
    [_nativeAdView addSubview:content];
    DemoPin(content, _nativeAdView, 12);
    [NSLayoutConstraint activateConstraints:@[
        [_iconView.widthAnchor constraintEqualToConstant:40],
        [_iconView.heightAnchor constraintEqualToConstant:40],
        [_badge.widthAnchor constraintGreaterThanOrEqualToConstant:15],   // Google's minimum for the label
        [_badge.heightAnchor constraintGreaterThanOrEqualToConstant:15],
    ]];

    _nativeAdView.mediaView = _mediaView;
    _nativeAdView.iconView = _iconView;
    _nativeAdView.headlineView = _headlineLabel;
    _nativeAdView.advertiserView = _advertiserLabel;
    _nativeAdView.bodyView = _bodyLabel;
    _nativeAdView.callToActionView = _callToActionButton;
    return self;
}

- (void)showAd:(GADNativeAd *)nativeAd {
    _headlineLabel.text = nativeAd.headline;
    _advertiserLabel.text = nativeAd.advertiser;
    _bodyLabel.text = nativeAd.body;
    _badge.text = [NSString stringWithFormat:@" %@ ", [AdMobNativeAdCard labelForAd:nativeAd]];
    [_callToActionButton setTitle:nativeAd.callToAction forState:UIControlStateNormal];
    _callToActionButton.hidden = nativeAd.callToAction.length == 0;
    _iconView.image = nativeAd.icon.image;
    _iconView.hidden = nativeAd.icon == nil;
    if (!_iconView.image && nativeAd.icon.imageURL) [self loadIconFrom:nativeAd.icon.imageURL forAd:nativeAd];

    CGFloat ratio = nativeAd.mediaContent.aspectRatio > 0 ? nativeAd.mediaContent.aspectRatio : 16.0 / 9.0;
    _mediaHeight.active = NO;
    _mediaHeight = [_mediaView.heightAnchor constraintEqualToAnchor:_mediaView.widthAnchor multiplier:1 / ratio];
    _mediaHeight.active = YES;
    _mediaView.mediaContent = nativeAd.mediaContent;

    // Last, after the asset views are set and laid out: Google Mobile Ads checks their sizes when the ad is registered.
    [self layoutIfNeeded];
    _nativeAdView.nativeAd = nativeAd;
}

/// Google requires the icon an ad provides. The AotterTrek adapter provides it as a URL only, so the card downloads it.
- (void)loadIconFrom:(NSURL *)url forAd:(GADNativeAd *)nativeAd {
    __weak typeof(self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *image = data ? [UIImage imageWithData:data] : nil;
        if (!image) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            AdMobNativeAdCard *card = weakSelf;
            if (!card || card->_nativeAdView.nativeAd != nativeAd) return;   // still the ad this icon belongs to
            card->_iconView.image = image;
        });
    }] resume];
}

/// AotterTrek's ads carry their own sponsored label in `extraAssets[@"Sponsor"]`; other ads get Google's "Ad".
+ (NSString *)labelForAd:(GADNativeAd *)nativeAd {
    id sponsor = nativeAd.extraAssets[@"Sponsor"];
    if (![sponsor isKindOfClass:NSString.class]) return @"Ad";
    return [sponsor length] > 0 ? sponsor : @"Sponsored";
}

@end
