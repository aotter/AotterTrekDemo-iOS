@import UIKit;
@import AotterTrekSDK;
@import GoogleMobileAds;
#import "DemoPages.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Start AotterTrek before anything requests an ad, the AdMob adapter included.
    [[AotterTrekSDK sharedInstance] initSDK:DemoConfig.clientID];
    [GADMobileAds.sharedInstance startWithCompletionHandler:nil];
    return YES;
}

@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[HomeViewController alloc] init]];
    [self.window makeKeyAndVisible];
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(AppDelegate.class));
    }
}
