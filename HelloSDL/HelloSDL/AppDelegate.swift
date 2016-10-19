//
//  AppDelegate.swift
//  HelloSDL
//
//  Created by Ford Developer on 11/3/15.
//  Copyright © 2015 Ford. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var mainViewController: UIViewController?
    var lockScreenViewController: UIViewController?
    let lockQueue = DispatchQueue(label: "com.ford.HelloSDL.vclock", attributes: [])

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Store references to the 2 view controllers
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        self.lockScreenViewController = storyBoard.instantiateViewController(withIdentifier: "LockScreenViewController")
        self.mainViewController = self.window?.rootViewController
        
        self.hsdl_registerForLockScreenNotifications()
        
        // Start the proxy
        HSDLProxyManager.manager.startProxy()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func hsdl_lockScreen() {
        // Display the lock screen if it is not presented already.
        self.lockQueue.sync {
            if self.window?.rootViewController !== self.lockScreenViewController {
                self.window?.rootViewController = self.lockScreenViewController
            }
        }
    }
    
    func hsdl_unlockScreen() {
        // Display the regular screen if it is not presented already.
        self.lockQueue.sync {
            if self.window?.rootViewController !== self.mainViewController {
                self.window?.rootViewController = self.mainViewController
            }
        }
    }
    
    func hsdl_registerForLockScreenNotifications() {
        let notificationCenter = NotificationCenter.default
        let mainQueue = OperationQueue.main
        
        notificationCenter.addObserver(forName: NSNotification.Name(rawValue: HSDLLockScreenStatusNotification), object: nil, queue: mainQueue) { notification in
            // Block to handle changes in lockscreen status
            print("AppDelegate received LockScreenStatus notification: \(notification)")
            if let lockScreenStatusNotification = notification.userInfo?[HSDLNotificationUserInfoObject] as? SDLOnLockScreenStatus,
                lockScreenStatusNotification.lockScreenStatus.isEqual(to: SDLLockScreenStatus.off()) == false {
                    self.hsdl_lockScreen()
            } else {
                self.hsdl_unlockScreen()
            }
        }
        
        notificationCenter.addObserver(forName: NSNotification.Name(rawValue: HSDLDisconnectNotification), object: nil, queue: mainQueue) { notification in
            // Block to perform actions on disconnect from SYNC
            // Clear the lockscreen
            print("AppDelegate received proxy Disconnect notification: \(notification)")
            self.hsdl_unlockScreen()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

