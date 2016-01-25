//
//  AppDelegate.swift
//  SneakPreviewNL
//
//  Created by Rick Thijssen on 23-01-16.
//  Copyright © 2016 Rick Thijssen. All rights reserved.
//

import UIKit
import Parse
import ParseCrashReporting
import Locksmith

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Set up Parse
        ParseCrashReporting.enable()
        Parse.setApplicationId("vuE4TYYwNBaLoSkFmJs4MiEBVRnL4uPR6cxHZdkp", clientKey: "vCooedJ2SpUoh71TS70UaPFZX6dKnkH8KiwaOxWu")
        
        // Track Parse Analytics
        if application.applicationState != .Background {
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
            }
        }
        
        // Register for push notifications, registering this way is available in iOS 8.0 and up
        // The minimum deployment target guarantees this
        let types: UIUserNotificationType = [.Alert, .Badge, .Sound]
        let settings = UIUserNotificationSettings(forTypes: types, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        // Initially set the upgrade value to false in the kaychain
        // This should only happen on the first ever launch of the app
        do {
            try Locksmith.saveData([kIAPKeychainKey:kIAPKeychainValueFalse], forUserAccount: kIAPKeychainUserAccount, inService: kIAPKeychainService)
        } catch {
            
        }
        
        // Observe the purchase/restore of the ad free upgrade
        // Unlock the upgrade in the keychain if transaction is valid
        PFPurchase.addObserverForProduct(kIAPProductId) { (transaction) -> Void in
            PFPurchase.downloadAssetForTransaction(transaction, completion: { (filepath, error) -> Void in
                do {
                    // Try saveData, in case the initial saveData above did not work for whatever reason
                    try Locksmith.saveData([kIAPKeychainKey:kIAPKeychainValueTrue], forUserAccount: kIAPKeychainUserAccount, inService: kIAPKeychainService)
                } catch LocksmithError.Duplicate {
                    do {
                        // The "upgraded" key already exists, update it
                        try Locksmith.updateData([kIAPKeychainKey:kIAPKeychainValueTrue], forUserAccount: kIAPKeychainUserAccount, inService: kIAPKeychainService)
                    } catch {
                        print(kIAPKeychainUpdateErrorMessage)
                        return
                    }
                } catch {
                    print(kIAPKeychainUpdateErrorMessage)
                    return
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName(kIAPAcquiredNotification, object: nil)
            })
        }
        
        // Change global appearance of certain UI elements
        UINavigationBar.appearance().barTintColor = UIColor.blackColor()
        UINavigationBar.appearance().barStyle = UIBarStyle.Black
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
        
        // Change the color of a selected UITableView cell (semi-transparent white)
        let colorView = UIView()
        colorView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2)
        UITableViewCell.appearance().selectedBackgroundView = colorView
        
        //TODO: remove before distribution!
        try! Locksmith.updateData([kIAPKeychainKey:kIAPKeychainValueFalse], forUserAccount: kIAPKeychainUserAccount, inService: kIAPKeychainService)
        
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
        let currentInstallation = PFInstallation.currentInstallation()
        if currentInstallation.badge != 0 {
            currentInstallation.badge = 0
            currentInstallation.saveEventually()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        // Add or update device info in Parse backend
        let currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation["osVersion"] = UIDevice.currentDevice().systemVersion
        currentInstallation["deviceName"] = UIDevice.currentDevice().name
        currentInstallation["deviceModel"] = UIDevice.currentDevice().model
        let keychainData = Locksmith.loadDataForUserAccount(kIAPKeychainUserAccount, inService: kIAPKeychainService)
        if let actualData = keychainData {
            currentInstallation["upgraded"] = actualData[kIAPKeychainKey] as! String == kIAPKeychainValueTrue
        }
        
        currentInstallation.saveInBackground()
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        // Handle the push notification
        PFPush.handlePush(userInfo)
        if application.applicationState == .Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }

}

