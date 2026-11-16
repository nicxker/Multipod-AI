#import "AppDelegate.h"
#import "ChatViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor colorWithRed:0.05 green:0.03 blue:0.12 alpha:1.0];

    ChatViewController *chatVC = [[ChatViewController alloc] init];
    self.navController = [[UINavigationController alloc] initWithRootViewController:chatVC];
    
    // Cyberpunk Dark Purple Navigation Bar
    self.navController.navigationBar.barStyle = UIBarStyleBlack;
    self.navController.navigationBar.tintColor = [UIColor colorWithRed:0.66 green:0.33 blue:0.97 alpha:1.0]; // Neon Purple
    
    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end

