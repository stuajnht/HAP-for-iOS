// Home Access Plus+ for iOS - A native app to access a HAP+ server
// Copyright (C) 2015, 2016  Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

//
//  AppDelegate.swift
//  HomeAccessPlus
//

import UIKit
import Locksmith
import XCGLogger

// Declaring a global constant to the default XCGLogger instance
let logger = XCGLogger.defaultInstance()

// Declaring a global constant to the HAP+ main app colour
let hapMainColour = "#005DAB"

// Declaring a global constant to NSUserDefaults to access settings
// throughout the app, and also the variables to these settings, to
// prevent accidental typos with incorrect names
// See: http://www.codingexplorer.com/nsuserdefaults-a-swift-introduction/
// Also using the suiteName group for the NSUserDefaults, so that the
// settings can be accessed from the document provider
// See: http://stackoverflow.com/a/31927904
let settings = NSUserDefaults(suiteName: "group.uk.co.stuajnht.ios.HomeAccessPlus")
let settingsHAPServer = "hapServer"
let settingsSiteName = "siteName"
let settingsFirstName = "firstName"
let settingsUsername = "username"
let settingsPassword = "password"
let settingsToken1 = "token1"
let settingsToken2 = "token2"
let settingsToken2Name = "token2Name"
let settingsDeviceType = "deviceType"
let settingsUserRoles = "userRoles"
let settingsUploadFileLocation = "uploadFileLocation"
let settingsUploadPhotosLocation = "uploadPhotosLocation"
let settingsLastAPIAccessTime = "lastAPIAccessTime"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Configuring the logger options
        logger.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, showDate: true, writeToFile: nil, fileLogLevel: .Debug)
        
        // Seeing if this code is being compiled for the main app
        // or the app extensions. This hacky way is needed as app
        // extensions don't allow the use of sharedApplication()
        // See: http://stackoverflow.com/a/25048511
        // See: http://stackoverflow.com/a/24152730
        #if TARGET_IS_APP
            // Enabling background fetches, to ideally automatically
            // renew the HAP+ user tokens
            // See: http://www.raywenderlich.com/92428/background-modes-ios-swift-tutorial
            UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        #endif
        
        // Clearing any settings that are set when UI Testing
        // is taking place, to start the app in a 'clean' state
        // See: http://stackoverflow.com/a/33774166
        // See: http://onefootball.github.io/resetting-application-data-after-each-test-with-xcode7-ui-testing/
        let args = NSProcessInfo.processInfo().arguments
        if args.contains("UI_TESTING_RESET_SETTINGS") {
            logger.info("App has been launched in UI testing mode. Clearing all settings")
            for key in settings!.dictionaryRepresentation().keys {
                settings!.removeObjectForKey(key)
            }
        }
        
        return true
    }
    
    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // Preventing the file browser modal animating into view
        // when app restoration has taken place
        // See: http://stackoverflow.com/a/26591842
        self.window?.makeKeyAndVisible()
        
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
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        // Called when an extrnal app sends a file to this app so that it can be uploaded to the HAP+ server
        // See: https://dzone.com/articles/ios-file-association-preview
        // See: http://www.infragistics.com/community/blogs/stevez/archive/2013/03/15/ios-tips-and-tricks-associate-a-file-type-with-your-app-part-3.aspx
        logger.debug("App invoked with OpenURL by: \(sourceApplication)")
        logger.debug("File passed from external app located at: \(url)")
        
        // Saving the location of the file on the device so that it
        // can be accessed later to upload to the HAP+ server
        settings!.setURL(url, forKey: settingsUploadFileLocation)
        
        return true
    }
    
    // MARK: App restoration
    // See: http://www.raywenderlich.com/117471/state-restoration-tutorial
    func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    // MARK: Background fetch
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        logger.debug("Beginning background fetch to update HAP+ user tokens")
        
        // Preventing any background fetches taking place if there
        // is no user logged in to the app
        if let username = settings!.stringForKey(settingsUsername) {
            // Loading an instance of the HAPi
            let api = HAPi()
            
            // Attempting to log the user in with the provided details
            // saved in the NSSettings
            let hapServer = settings!.stringForKey(settingsHAPServer)
            let dictionary = Locksmith.loadDataForUserAccount(username)
            let password = (dictionary?[settingsPassword])!
            
            // Calling the HAPi to attempt to log the user in, to generate
            // new user logon tokens on the HAP+ server
            api.loginUser(hapServer!, username: username, password: String(password), callback: { (result: Bool) -> Void in
                // Seeing if the attempt to log the user in has been
                // successful, or if there was a problem of some sort
                // (most likely no connection, as the user will have
                // already logged in, or the password has now expired)
                if (result == true) {
                    logger.debug("Background fetch completed successfully")
                    completionHandler(.NewData)
                } else {
                    logger.debug("Background fetch failed to update user tokens")
                    completionHandler(.Failed)
                }
            })
        } else {
            logger.debug("Background fetch cancelled as no user is logged in to the app")
            completionHandler(.NoData)
        }
    }

}

