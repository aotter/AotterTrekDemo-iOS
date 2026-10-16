#import "DemoViews.h"

@implementation TrekNativeAdCard {
    ATKMediaView *_mediaView;
    UIImageView *_iconView;
    UILabel *_titleLabel;
    UILabel *_advertiserLabel;
    UILabel *_sponsorBadge;
    UILabel *_bodyLabel;
    UIButton *_callToActionButton;
    NSLayoutConstraint *_mediaHeight;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    _adView = [[ATKNativeAdView alloc] init];
    [self addSubview:_adView];
    DemoPin(_adView, self, 0);
    _adView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    _adView.layer.cornerRadius = 8;
    _adView.clipsToBounds = YES;

    _mediaView = [[ATKMediaView alloc] init];
    _iconView = [[UIImageView alloc] init];
    _iconView.contentMode = UIViewContentModeScaleAspectFit;
    _iconView.layer.cornerRadius = 6;
    _iconView.clipsToBounds = YES;
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.numberOfLines = 2;
    _advertiserLabel = [[UILabel alloc] init];
    _advertiserLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    _advertiserLabel.textColor = UIColor.secondaryLabelColor;
    _sponsorBadge = [[UILabel alloc] init];
    _sponsorBadge.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];   // the label that marks the ad as an ad
    _sponsorBadge.textAlignment = NSTextAlignmentCenter;
    _sponsorBadge.textColor = UIColor.whiteColor;
    _sponsorBadge.backgroundColor = [UIColor colorWithRed:0xC9 / 255.0 green:0x34 / 255.0 blue:0 alpha:1];   // white text reads at 5.3:1
    // The label keeps its own width: a long title gives way to it.
    [_sponsorBadge setContentHuggingPriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisHorizontal];
    [_sponsorBadge setContentCompressionResistancePriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisHorizontal];
    _sponsorBadge.layer.cornerRadius = 3;
    _sponsorBadge.clipsToBounds = YES;
    _bodyLabel = [[UILabel alloc] init];
    _bodyLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _bodyLabel.numberOfLines = 3;
    _callToActionButton = [UIButton buttonWithConfiguration:UIButtonConfiguration.filledButtonConfiguration primaryAction:nil];

    UIStackView *titles = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _advertiserLabel]];
    titles.axis = UILayoutConstraintAxisVertical;
    titles.spacing = 2;
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[_iconView, titles, _sponsorBadge]];
    header.spacing = 8;
    header.alignment = UIStackViewAlignmentCenter;
    UIStackView *content = [[UIStackView alloc] initWithArrangedSubviews:@[header, _mediaView, _bodyLabel, _callToActionButton]];
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 8;
    [_adView addSubview:content];
    DemoPin(content, _adView, 12);
    [NSLayoutConstraint activateConstraints:@[
        [_iconView.widthAnchor constraintEqualToConstant:40],
        [_iconView.heightAnchor constraintEqualToConstant:40],
        [_sponsorBadge.widthAnchor constraintGreaterThanOrEqualToConstant:15],
        [_sponsorBadge.heightAnchor constraintGreaterThanOrEqualToConstant:15],
    ]];

    _adView.mediaView = _mediaView;
    _adView.callToActionButton = _callToActionButton;
    return self;
}

- (void)showAd:(ATKNativeAdData *)ad fromViewController:(UIViewController *)viewController {
    _titleLabel.text = ad.title;
    _advertiserLabel.text = ad.advertiserName;
    _sponsorBadge.text = [NSString stringWithFormat:@" %@ ", ad.sponsor.length > 0 ? ad.sponsor : @"Sponsored"];
    _bodyLabel.text = ad.text;
    [_callToActionButton setTitle:(ad.callToAction.length > 0 ? ad.callToAction : @"Learn more") forState:UIControlStateNormal];
    [self loadIconFrom:(ad.imgIconHd.length > 0 ? ad.imgIconHd : ad.imgIcon)];

    // ATKMediaView has no intrinsic size: give it the ad's aspect ratio (width / height).
    CGFloat ratio = ad.mediaContentAspectRatio > 0 ? ad.mediaContentAspectRatio : 1200.0 / 628.0;
    _mediaHeight.active = NO;
    _mediaHeight = [_mediaView.heightAnchor constraintEqualToAnchor:_mediaView.widthAnchor multiplier:1 / ratio];
    _mediaHeight.active = YES;

    self.adView.rootViewController = viewController;   // a video, a popup and the in-app browser present from it
    self.adView.nativeAd = ad;
}

- (void)loadIconFrom:(NSString *)urlString {
    _iconView.image = nil;
    _iconView.hidden = urlString.length == 0;   // a SuprAd can come without an icon
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    __weak typeof(self) weakSelf = self;
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *image = data ? [UIImage imageWithData:data] : nil;
        if (!image) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            TrekNativeAdCard *card = weakSelf;
            ATKNativeAdData *ad = card.adView.nativeAd;
            if (!card || (![ad.imgIconHd isEqualToString:urlString] && ![ad.imgIcon isEqualToString:urlString])) return;
            card->_iconView.image = image;   // still the ad this icon belongs to
        });
    }] resume];
}

@end
