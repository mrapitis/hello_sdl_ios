//
//  AppDelegate.m
//  HelloSDL
//
//  Created by James Sokoll on 10/7/15.
//  Copyright © 2015 Ford Motor Company. All rights reserved.
//

#import "AppDelegate.h"
#import "HSDLHMIManager.h"
#import "HSDLVehicleDataManager.h"
#import "SDLManager.h"

#warning TODO : Replace these constants with your app's name, assigned ID, and company logo
static NSString *const appName = @"HelloSDL";
static NSString *const appId = @"8675309";
static NSString *const companyLogo = @"Ford_logo_no_background.png";

@interface AppDelegate ()

@property UIViewController *lockScreenViewController;
@property UIViewController *mainViewController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *lockVC = [storyBoard instantiateViewControllerWithIdentifier:@"LockScreenViewController"];

    [self setLockScreenViewController:lockVC];
    [self setMainViewController:[[self window] rootViewController]];

    // Start the proxy with default configuration

    SDLManager *proxyManager = nil;
    HSDLHMIManager *hmiManager = nil;
    HSDLVehicleDataManager *vdManager = nil;

    proxyManager = [SDLManager sharedManager];
    SDLLifecycleConfiguration *appConfig = [SDLLifecycleConfiguration defaultConfigurationWithAppName:appName appId:appId];
    SDLLockScreenConfiguration *lockScreenConfig = [SDLLockScreenConfiguration enabledConfigurationWithBackgroundColor:[UIColor blackColor] appIcon:[UIImage imageNamed:companyLogo]];
    SDLConfiguration *appAndLSConfig = [SDLConfiguration configurationWithLifecycle:appConfig lockScreen:lockScreenConfig];

    [proxyManager startProxyWithConfiguration:appAndLSConfig];
    hmiManager = [HSDLHMIManager sharedManager];
    vdManager = [HSDLVehicleDataManager sharedManager];

    // Register for notifications
    [self registerForSDLNotifications];

    return YES;
}

- (void)registerForSDLNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(didChangeLockScreenStatus:) name:SDLDidChangeLockScreenStatusNotification object:nil];
    [center addObserver:self selector:@selector(didDisconnect:) name:SDLDidDisconnectNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Manage lockscreen
- (void)didChangeLockScreenStatus:(NSNotification *)notification {
    // Delegate method to handle changes in lockscreen status

    SDLOnLockScreenStatus *lockScreenStatus = nil;
    if (notification && notification.userInfo) {
        lockScreenStatus = notification.userInfo[SDLNotificationUserInfoNotificationObject];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      if (lockScreenStatus && ![[SDLLockScreenStatus OFF] isEqualToEnum:lockScreenStatus.lockScreenStatus]) {
          [self lockScreen];
      } else {
          [self unlockScreen];
      }
    });
}

- (void)lockScreen {
    @synchronized(self) {
        // Display the lock screen if it is not presented already
        if ([self.window.rootViewController isEqual:self.lockScreenViewController] == NO) {
            [self.window setRootViewController:self.lockScreenViewController];
        }
    }
}

- (void)unlockScreen {
    @synchronized(self) {
        // Display the regular screen if it is not presented already
        if ([self.window.rootViewController isEqual:self.mainViewController] == NO) {
            [self.window setRootViewController:self.mainViewController];
        }
    }
}

#pragma mark Proxy notifications
- (void)didDisconnect:(NSNotification *)notification {
    // Delegate method to perform actions on disconnect from SYNC

    // Clear the lockscreen
    dispatch_async(dispatch_get_main_queue(), ^{
      [self unlockScreen];
    });
}

#pragma mark Default methods
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
