#import "DemoPages.h"

@implementation HomeViewController {
    NSArray<NSString *> *_sectionTitles;
    NSArray<NSArray<NSString *> *> *_rowTitles;
    NSArray<NSArray<Class> *> *_rowPages;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStyleInsetGrouped])) return nil;
    self.title = @"AotterTrek Demo";
    _sectionTitles = @[@"AotterTrek", @"AdMob mediation", @"Tracker"];
    _rowTitles = @[
        @[@"Native ad", @"Native ads in a feed", @"Banner ad"],
        @[@"Native ad", @"Native ads in a feed", @"Banner ad"],
        @[@"Report what the user does"],
    ];
    _rowPages = @[
        @[TrekNativeViewController.class, TrekFeedViewController.class, TrekBannerViewController.class],
        @[AdMobNativeViewController.class, AdMobFeedViewController.class, AdMobBannerViewController.class],
        @[TrackerViewController.class],
    ];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"Row"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return _sectionTitles.count; }

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return _sectionTitles[section]; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return _rowTitles[section].count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Row" forIndexPath:indexPath];
    cell.textLabel.text = _rowTitles[indexPath.section][indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *page = [[_rowPages[indexPath.section][indexPath.row] alloc] init];
    page.title = _rowTitles[indexPath.section][indexPath.row];
    [self.navigationController pushViewController:page animated:YES];
}

@end
