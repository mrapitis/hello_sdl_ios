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
    let lockQueue = dispatch_queue_create("com.ford.HelloSDL.vclock", nil)

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Store references to the 2 view controllers
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        self.lockScreenViewController = storyBoard.instantiateViewControllerWithIdentifier("LockScreenViewController")
        self.mainViewController = self.window?.rootViewController
        
        self.hsdl_registerForLockScreenNotifications()
        
        // Start the proxy
        HSDLProxyManager.manager.startProxy()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func hsdl_lockScreen() {
        // Display the lock screen if it is not presented already.
        dispatch_sync(self.lockQueue) {
            if self.window?.rootViewController !== self.lockScreenViewController {
                self.window?.rootViewController = self.lockScreenViewController
            }
        }
    }
    
    func hsdl_unlockScreen() {
        // Display the regular screen if it is not presented already.
        dispatch_sync(self.lockQueue) {
            if self.window?.rootViewController !== self.mainViewController {
                self.window?.rootViewController = self.mainViewController
            }
        }
    }
    
    func hsdl_registerForLockScreenNotifications() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()
        
        notificationCenter.addObserverForName(HSDLLockScreenStatusNotification, object: nil, queue: mainQueue) { notification in
            // Block to handle changes in lockscreen status
            print("AppDelegate received LockScreenStatus notification: \(notification)")
            let lockScreenStatus = notification.userInfo?[HSDLNotificationUserInfoObject]
            
            if lockScreenStatus?.lockScreenStatus != SDLLockScreenStatus.OFF() {
                self.hsdl_lockScreen()
            } else {
                self.hsdl_unlockScreen()
            }
        }
        
        notificationCenter.addObserverForName(HSDLDisconnectNotification, object: nil, queue: mainQueue) { notification in
            // Block to perform actions on disconnect from SYNC
            // Clear the lockscreen
            print("AppDelegate received proxy Disconnect notification: \(notification)")
            self.hsdl_unlockScreen()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

