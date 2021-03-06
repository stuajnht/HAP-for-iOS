// Home Access Plus+ for iOS - A native app to access a HAP+ server
// Copyright (C) 2015-2017  Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
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

// Declaring a global constant to the XCGLogger instance
let logger = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

// Declaring a global constant to the HAP+ main app colour
let hapMainColour = "#005DAB"

// Declaring a global constant to NSUserDefaults to access settings
// throughout the app, and also the variables to these settings, to
// prevent accidental typos with incorrect names
// See: http://www.codingexplorer.com/nsuserdefaults-a-swift-introduction/
// Also using the suiteName group for the NSUserDefaults, so that the
// settings can be accessed from the document provider
// See: http://stackoverflow.com/a/31927904
let settings = UserDefaults(suiteName: "group.uk.co.stuajnht.ios.HomeAccessPlus")
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
let settingsAutoLogOutEnabled = "autoLogOutEnabled"
let settingsAutoLogOutTime = "autoLogOutTime"
let settingsVersionBuildNumber = "versionBuildNumber"
let settingsBasicPhotoUploaderEnabled = "basicPhotoUploaderEnabled"
let settingsBasicVideoUploaderEnabled = "basicVideoUploaderEnabled"
let settingsFileLoggingEnabled = "fileLoggingEnabled"
let settingsFileLoggingLevel = "fileLoggingLevel"
let settingsPasteMode = "pasteMode"
let settingsPasteItems = "pasteItems"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // Loading an instance of the HAPi
    let api = HAPi()
    
    // Creating a timer to connect to the HAP+ server API
    // test, to keep the user session tokens active
    var apiTestCheckTimer : Timer = Timer()
    
    // Creating a time to see if the device should be automatically
    // logged out for the current user, and to alert them
    // when this time is coming near
    var autoLogOutCheckTimer : Timer = Timer()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Configuring the logger options
        loggerSetup()
        
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
        let args = ProcessInfo.processInfo.arguments
        if args.contains("UI_TESTING_RESET_SETTINGS") {
            logger.info("App has been launched in UI testing mode. Clearing all settings")
            for key in settings!.dictionaryRepresentation().keys {
                settings!.removeObject(forKey: key)
            }
        }
        
        // Generating a version and build number to display in the
        // settings app, so that users know what build / version
        // they are currently on. This will show "- (-)" in the main
        // iOS settings app until this app is run once. Doing it this
        // way also seems to get around the problem of addind a new
        // setting to the Root.plist breaks any scripts that look for
        // a specific node number
        // See: http://dev.iachieved.it/iachievedit/a-technique-for-displaying-ios-build-versions-in-swift/
        let appInfo = Bundle.main.infoDictionary! as Dictionary<String, AnyObject>
        let versionNumber = appInfo["CFBundleShortVersionString"] as! String
        let buildNumber = appInfo["CFBundleVersion"] as! String
        settings!.set(versionNumber + " (" + buildNumber + ")", forKey: settingsVersionBuildNumber)
        
        return true
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Preventing the file browser modal animating into view
        // when app restoration has taken place
        // See: http://stackoverflow.com/a/26591842
        self.window?.makeKeyAndVisible()
        
        logger.debug("Application starting")
        
        // Seeing if the user should be auto-logged out, and
        // starting the timer to perform it when needed
        // Note: This needs to go before calls to renewUserSessionTokens,
        //       so that if a user should be logged out, there's no point
        //       in renewing the session tokens for them, and also to
        //       speed up their log out from the device
        logger.info("Seeing if the user should be logged out of the app")
        autoLogOutCheck()
        logger.debug("Starting auto-log out timer")
        startAutoLogOutCheckTimer()
        
        // Seeing if the user session tokens need to be renewed
        // since the app has been brought to the foreground
        logger.debug("Preparing to check last API access and renew session tokens if needed")
        renewUserSessionTokens()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        // Stopping the API test timer as the app is going
        // into the background
        logger.debug("App transitioning to background state, so disabling timers")
        stopTimers()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        logger.debug("Application entering foreground")
        
        // Seeing if the user should be auto-logged out, and
        // starting the timer to perform it when needed
        // Note: This needs to go before calls to renewUserSessionTokens,
        //       so that if a user should be logged out, there's no point
        //       in renewing the session tokens for them, and also to
        //       speed up their log out from the device
        logger.info("Seeing if the user should be logged out of the app")
        autoLogOutCheck()
        logger.debug("Starting auto-log out timer")
        startAutoLogOutCheckTimer()
        
        // Seeing if the user session tokens need to be renewed
        // since the app has been brought to the foreground
        logger.debug("Preparing to check last API access and renew session tokens if needed")
        renewUserSessionTokens()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        // Called when an extrnal app sends a file to this app so that it can be uploaded to the HAP+ server
        // See: https://dzone.com/articles/ios-file-association-preview
        // See: http://www.infragistics.com/community/blogs/stevez/archive/2013/03/15/ios-tips-and-tricks-associate-a-file-type-with-your-app-part-3.aspx
        logger.debug("App invoked with OpenURL by: \(sourceApplication as String?)")
        logger.debug("File passed from external app located at: \(url)")
        
        // Saving the location of the file on the device so that it
        // can be accessed later to upload to the HAP+ server
        settings!.set(url, forKey: settingsUploadFileLocation)
        
        return true
    }
    
    // MARK: App restoration
    // See: http://www.raywenderlich.com/117471/state-restoration-tutorial
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    // MARK: Background fetch
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        logger.info("Beginning background fetch to update HAP+ user tokens")
        
        // Preventing any background fetches taking place if there
        // is no user logged in to the app
        if let username = settings!.string(forKey: settingsUsername) {
            // Attempting to log the user in with the provided details
            // saved in the NSSettings
            let hapServer = settings!.string(forKey: settingsHAPServer)
            let dictionary = Locksmith.loadDataForUserAccount(userAccount: username)
            let password = (dictionary?[settingsPassword])!
            
            // Calling the HAPi to attempt to log the user in, to generate
            // new user logon tokens on the HAP+ server
            api.loginUser(hapServer!, username: username, password: String(describing: password), callback: { (result: Bool) -> Void in
                // Seeing if the attempt to log the user in has been
                // successful, or if there was a problem of some sort
                // (most likely no connection, as the user will have
                // already logged in, or the password has now expired)
                if (result == true) {
                    logger.info("Background fetch completed successfully")
                    completionHandler(.newData)
                } else {
                    logger.warning("Background fetch failed to update user tokens")
                    completionHandler(.failed)
                }
            })
        } else {
            logger.debug("Background fetch cancelled as no user is logged in to the app")
            completionHandler(.noData)
        }
    }
    
    /// Sees if new user session tokens need to be generated,
    /// if the last successful API access is over 20 minutes
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 5
    /// - date: 2016-04-20
    func renewUserSessionTokens() {
        // Preventing any API last access checks taking place if there
        // is no user logged in to the app, as there will be no session
        // on the HAP+ server that needs to be kept alive / created
        if let username = settings!.string(forKey: settingsUsername) {
            // Seeing when the last successful API access took place
            logger.debug("Checking time since last API access")
            let timeDifference = Date().timeIntervalSince1970 - TimeInterval(settings!.double(forKey: settingsLastAPIAccessTime))
            logger.debug("Time since last API access is: \(timeDifference)")
            
            // Seeing if the time since last API access is over 18 minutes
            // 1080 seconds, and if so, attempt to log the user in again
            // This is needed as IIS and ASP.net keeps session cookies for
            // 20 minutes, and discard them if no activity has taken place
            // during this time. This check is also put in place just in case
            // the background fetch hasn't run, or has run but longer than
            // 18 minutes ago. It is designed as a final attempt to log the
            // user in without them noticing, or at least, only having to press
            // any "try again" alerts once (depending on connection speed)
            // 18 minutes has been chosen to try and beat a condition where
            // the user opens the app again, but it's been 19 minutes 59 seconds
            // since it was last opened, so this check will pass, and the
            // API test check will not take place for another minute, leading
            // to a time of 20 minutes 59 seconds, which would then have
            // prompted the user to "try again" for the last minute (or suspend /
            // open the app). 18 minutes gives just enough time to renew the
            // tokens before the session tokens expire on the server, hopefully
            // not inconveniencing the user while this takes place
            // Also a check is in place for any time difference under 0 seconds,
            // as this has most likely happened due to a user changing the time
            // for some reason
            if ((timeDifference < 0) || (timeDifference > 1080)) {
                logger.debug("Attempting to log the user in, to generate new session tokens")
                
                // Attempting to log the user in with the provided details
                // saved in the NSSettings
                let hapServer = settings!.string(forKey: settingsHAPServer)
                let dictionary = Locksmith.loadDataForUserAccount(userAccount: username)
                let password = (dictionary?[settingsPassword])!
                
                // Calling the HAPi to attempt to log the user in, to generate
                // new user logon tokens on the HAP+ server
                api.loginUser(hapServer!, username: username, password: String(describing: password), callback: { (result: Bool) -> Void in
                    // Seeing if the attempt to log the user in has been
                    // successful, or if there was a problem of some sort
                    // (most likely no connection, as the user will have
                    // already logged in, or the password has now expired)
                    if (result == true) {
                        logger.debug("User logon completed successfully, new user session tokens generated")
                        
                        // The last API access has been reset, so start
                        // the API test check timer
                        self.startAPITestCheckTimer()
                    } else {
                        logger.warning("User logon failed to update user tokens")
                    }
                })
            } else {
                // The last API access was less than 20 minutes ago,
                // so start the API test check timer
                startAPITestCheckTimer()
            }
        } else {
            logger.debug("Last API access check ignored as no user is currently logged in to the app")
        }
    }
    
    // MARK: Start Timers
    
    /// Starting all timers in one go, in a centralised location
    ///
    /// There can be multiple timers that run during this apps
    /// lifecycle. While each timer has its own start function
    /// that can be accessed individually, this function starts
    /// all that are listed in it during app start-up and restoration
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-04-16
    ///
    /// - seealso: startAPITestCheckTimer
    /// - seealso: startAutoLogOutCheckTimer
    func startTimers() {
        startAPITestCheckTimer()
        startAutoLogOutCheckTimer()
    }
    
    /// Starting the API test check timer, so that the API can be
    /// periodically checked to ensure the user session tokens
    /// stay active
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 2
    /// - date: 2016-04-01
    ///
    /// - seealso: renewUserSessionTokens
    /// - seealso: apiTestCheck
    /// - seealso: startTimers
    func startAPITestCheckTimer() {
        apiTestCheckTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(AppDelegate.apiTestCheck), userInfo: nil, repeats: true)
    }
    
    /// Starting the auto log out test check timer, so that the
    /// currently logged in user can be logged out at the end of
    /// their current lesson
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-04-16
    ///
    /// - seealso: startTimers
    /// - seealso: autoLogOutCheck
    func startAutoLogOutCheckTimer() {
        autoLogOutCheckTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(AppDelegate.autoLogOutCheck), userInfo: nil, repeats: true)
    }
    
    // MARK: Stop Timers
    
    /// Stopping all timers in one go, in a centralised location
    ///
    /// There can be multiple timers that run during this apps
    /// lifecycle. While each timer has its own stop function
    /// that can be accessed individually, this function stops
    /// all that are listed in it during app backgrounding
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-04-16
    ///
    /// - seealso: stopAPITestCheckTimer
    /// - seealso: stopAutoLogOutCheckTimer
    func stopTimers() {
        stopAPITestCheckTimer()
        stopAutoLogOutCheckTimer()
    }
    
    /// Stopping the API test check timer, to avoid updating the
    /// last successful API contact time if the user has logged out
    /// or the app is backgrounded
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-15
    ///
    /// - seealso: renewUserSessionTokens
    /// - seealso: apiTestCheck
    /// - seealso: stopTimers
    func stopAPITestCheckTimer() {
        apiTestCheckTimer.invalidate()
    }
    
    /// Stopping the API test check timer, to avoid updating the
    /// last successful API contact time if the user has logged out
    /// or the app is backgrounded
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-04-16
    ///
    /// - seealso: stopTimers
    /// - seealso: autoLogOutCheck
    func stopAutoLogOutCheckTimer() {
        autoLogOutCheckTimer.invalidate()
    }
    
    /// Connects to the HAP+ server test API function periodically
    /// to renew the user session tokens
    ///
    /// As the IIS session cookie tokens expire after 20 minutes of
    /// inactivity, a connection to the HAP+ API test function is
    /// scheduled to take place every 6 minutes to provide activity
    /// on the server, so the session cookies remain active
    ///
    /// A value of 1 minute has been chosen, instead of a higher value,
    /// as the user may open the app and it would have been 19 minutes
    /// since they used it last. This function would then not be called
    /// for another 6 minutes, at which point the last API contact would
    /// be 25 minutes, which is after the 20 minute session expiration
    ///
    /// If the app remains active, then this function will be called
    /// periodically, and the user sessions will remain active. If the
    /// app is backgrounded / screen locked, then the renewUserSessionTokens
    /// function will be called when the app becomes active to either
    /// renew the user session tokens, or if the tokens are still valid,
    /// call this function from the timer straight away
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 5
    /// - date: 2016-04-20
    ///
    /// - seealso: renewUserSessionTokens
    func apiTestCheck() {
        // Seeing if there is currently an active connection to
        // the Internet
        logger.debug("Running API test check")
        if (api.checkConnection()) {
            // Seeing when the last successful API access took place
            logger.verbose("Checking time since last API access")
            let timeDifference = Date().timeIntervalSince1970 - TimeInterval(settings!.double(forKey: settingsLastAPIAccessTime))
            logger.verbose("Time since last API access is: \(timeDifference)")
            
            // Seeing if the time since last API access is over 18 minutes
            // 1080 seconds, and if so, attempt to log the user in again
            // Also a check is in place for any time difference under 0 seconds,
            // as this has most likely happened due to a user changing the time
            // for some reason
            // Note: While the lower bound check isn't really needed here, as
            //       this function gets called after renewUserSessionTokens is
            //       called, which should reset the time difference, if the
            //       device is offline during that attempt then this check will
            //       be used instead
            if ((timeDifference < 0) || (timeDifference > 1080)) {
                // Invalidating the timer, as it'll be recreated again
                // once the renewUserSessionTokens function completes
                stopAPITestCheckTimer()
                
                // Attempting to log the user back in and collect new
                // user session tokens
                logger.debug("Attempting to generate new session tokens instead of renewing through the test API")
                renewUserSessionTokens()
            } else {
                // The last API access was less than 20 minutes ago, so
                // just attempt to connect to the test API function
                let hapServer = String(describing: settings!.object(forKey: settingsHAPServer)!)
                api.checkAPI(hapServer, callback: { (result: Bool) -> Void in
                    if (result) {
                        // Successful HAP+ API check, so update the last time the
                        // API has been contacted
                        logger.debug("API test check completed successfully")
                        logger.verbose("Updating last successful API access time to: \(Date().timeIntervalSince1970)")
                        settings!.set(Date().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                    } else {
                        logger.warning("API test check failed due to: \(result)")
                    }
                })
            }
        } else {
            logger.error("API test check failed due to lack of connectivity")
        }
    }
    
    /// Checks to see if the currently logged in user should be logged
    /// out, as their lesson has finished
    ///
    /// If the currently logged in user has a timetable and is currently
    /// inside a lesson and the device is set up in "shared" mode then
    /// see if it is time to show them an alert to let them know that
    /// they will be logged out automatically in 5 minutes or, if it is
    /// the end of the lesson, log them out of the device
    ///
    /// - note: Due to the fact that this function is called every minute,
    ///         there are some situations whereby it will be the following
    ///         minute that the user is logged out. For instance, it has
    ///         happened where the lesson finishes at 16:00 and this check
    ///         was called at 15:59:59.959 (true story)
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 2
    /// - date: 2016-04-16
    ///
    /// - seealso: startAutoLogOutCheckTimer
    /// - seealso: stopAutoLogOutCheckTimer
    func autoLogOutCheck() {
        // Seeing if auto-log out is enabled, as this can be
        // set only when a user with a valid timetable and lesson
        // logs in. If the setting is false, then call the stop
        // timer function for this check
        if (settings!.bool(forKey: settingsAutoLogOutEnabled)) {
            // Getting the current date and time, so that it can be
            // compated with the time that the user should be logged
            // out of the app by, and when the warning alerts at to
            // be shown to them
            let timeNow = Date().timeIntervalSince1970
            logger.verbose("The current time on the device is (UNIX Epoch): \(timeNow)")
            logger.info("Checking if the user should be logged out of the device")
            
            // Seeing if the current time is at or after the time the
            // user should be auto-logged out from the device by
            if (TimeInterval(settings!.double(forKey: settingsAutoLogOutTime)) <= timeNow) {
                // It is past the end of the lesson, so call the logOutUser()
                // function
                logger.info("Logging the user out of the device, as it is at or past the end of the lesson: \(TimeInterval(settings!.double(forKey: settingsAutoLogOutTime)))")
                
                // Calling the log out function
                api.logOutUser()
                
                // Stopping the app delegate check timers, so as to
                // avoid updating the last successful contact time
                // for the API if no user is logged in to the app or
                // attempting to log the user out
                logger.debug("Stopping check timers as no user is logged in")
                stopTimers()
                
                // Removing all of the navigation views and showing
                // the login view controller
                // See: http://sketchytech.blogspot.co.uk/2012/09/return-to-root-view-controller-from.html
                self.window?.rootViewController?.dismiss(animated: true, completion: nil)
            } else {
                // Seeing if a warning message should be shown to the user
                // that they are about to be logged off (in 5 minutes) so
                // that they don't think something weird happened to the
                // app. If they're not looking at the time, then there's
                // probably nothing that can be done for them. To prevent
                // this alert constantly re-appearing, another bound is
                // put on this so that it will only shown when between
                // 4 and 5 minutes until auto-logoff
                // Note: Trying to work this out made my brain hurt. There's
                //       probably something stupid going on here, but am
                //       not entirely sure. Working outs:
                //       Time now: 11:55:30
                //       Log off:  12:00:00
                //
                //       Lower bound: 11:55:30 + 4 mins = 11:59:30
                //       Upper bound: 11:55:30 + 5 mins = 12:00:30
                //
                //       'if' order: 11:59:30 <= 12:00:00 <= 12:00:30
                // See: http://stackoverflow.com/a/29465300
                let alertLowerBound = TimeInterval(timeNow) + TimeInterval(4.0 * 60.0)
                let alertUpperBound = TimeInterval(timeNow) + TimeInterval(5.0 * 60.0)
                let logOutTime = TimeInterval(settings!.double(forKey: settingsAutoLogOutTime))
                if ((alertLowerBound <= logOutTime) && (logOutTime <= alertUpperBound)) {
                    logger.info("There is less than 5 minutes before the user will be logged out. Showing alert to user")
                    
                    // Creating the alert message to the user
                    let autoLogOutController = UIAlertController(title: "Automatic Log Out", message: "The lesson will finish in 5 minutes. You will be logged out automatically", preferredStyle: UIAlertControllerStyle.alert)
                    autoLogOutController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    // Being creative to show the log out alert on the top
                    // most view controller, as the file browsers are presented
                    // modally
                    // See: http://stackoverflow.com/a/33128884
                    var hostVC = self.window?.rootViewController
                    while let next = hostVC?.presentedViewController {
                        hostVC = next
                    }
                    hostVC?.present(autoLogOutController, animated: true, completion: nil)
                }
            }
        } else {
            logger.info("Auto log out is not enabled, so disabling the auto log out check timer")
            stopAutoLogOutCheckTimer()
        }
    }
    
    // MARK: XCGLogger Setup Options
    
    /// Setting up advanced logging functions of XCGLogger, such
    /// as to a file or different levels for debug or release
    ///
    /// By default, during building of this app, the logger will
    /// be in debug mode and log to the console only. When it is
    /// in production, this level will be set to warning, as there
    /// isn't normally a need for end users to have it lower during
    /// day-to-day running of the app
    ///
    /// There is also be the ability to log to a file, so should
    /// this app run into problems when it is out in the open, the
    /// logs can be submitted and processed to see what caused the
    /// problem. The level recorded in the log can be adjusted via
    /// a slider in the main settings app
    ///
    /// This function has been put here instead of in the
    /// application(:didFinishLaunchingWithOptions) so that the
    /// code is easier to read by keeping that function clear
    ///
    /// See: https://github.com/DaveWoodCom/XCGLogger#advanced-usage-recommended
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.9.0-alpha
    /// - version: 2
    /// - date: 2016-01-14
    func loggerSetup() {
        //logger.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: true, writeToFile: nil)
        
        // Create a destination for the system console log (via NSLog)
        let consoleLogger = AppleSystemLogDestination(identifier: "advancedLogger.consoleLogger")
        
        // Optionally set some configuration options
        consoleLogger.outputLevel = .debug
        consoleLogger.showLogIdentifier = false
        consoleLogger.showFunctionName = true
        consoleLogger.showThreadName = true
        consoleLogger.showLevel = true
        consoleLogger.showFileName = true
        consoleLogger.showLineNumber = true
        consoleLogger.showDate = true
        
        // Add the destination to the logger
        logger.add(destination: consoleLogger)
        
        // Create a file log destination, if enabled in the main settings app
        if (settings!.bool(forKey: settingsFileLoggingEnabled)) {
            let fileManager: FileManager = FileManager.default
            
            let logFileDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("logs", isDirectory: true)
            
            // The logs directory needs to be created first as
            // XCGLogger will fail to create the file otherwise
            // See: https://github.com/DaveWoodCom/XCGLogger/issues/31
            // See: http://stackoverflow.com/a/24696209
            do {
                var isDir : ObjCBool = true
                let folderExists: Bool = fileManager.fileExists(atPath: logFileDirectory.path, isDirectory:&isDir)
                if (!folderExists) {
                    try fileManager.createDirectory(atPath: logFileDirectory.path.removingPercentEncoding!, withIntermediateDirectories: true, attributes: nil)
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            // Creating a date for the log, based on when this
            // app was first run
            let logFileDate = DateFormatter()
            logFileDate.dateFormat = "yyyy-MM-dd"
            let logFileDateString = logFileDate.string(from: Date())
            
            let logFile = String(describing: logFileDirectory) + logFileDateString + "--hap-ios-app.log"
            
            let fileLogger = FileDestination(writeToFile: NSURL(string: logFile)!, identifier: "advancedLogger.fileLogger", shouldAppend: true, appendMarker: "******* Home Access Plus+ App Relaunched *******")
            
            // Optionally set some configuration options
            switch settings!.string(forKey: settingsFileLoggingLevel) {
                case "severe"?:
                    fileLogger.outputLevel = .severe
                case "error"?:
                    fileLogger.outputLevel = .error
                case "warning"?:
                    fileLogger.outputLevel = .warning
                case "info"?:
                    fileLogger.outputLevel = .info
                case "debug"?:
                    fileLogger.outputLevel = .debug
                default:
                    fileLogger.outputLevel = .warning
            }
            fileLogger.showLogIdentifier = false
            fileLogger.showFunctionName = true
            fileLogger.showThreadName = true
            fileLogger.showLevel = true
            fileLogger.showFileName = true
            fileLogger.showLineNumber = true
            fileLogger.showDate = true
            
            // Process this destination in the background
            fileLogger.logQueue = XCGLogger.logQueue
            
            // Add the destination to the logger
            logger.add(destination: fileLogger)
        }
        
        // Add basic app info, version info etc, to the start of the logs
        logger.logAppDetails()
    }

}

