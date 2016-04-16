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
//  HAPi.swift
//  HomeAccessPlus
//

import Foundation
import Alamofire
import Locksmith
import SwiftyJSON
import XCGLogger

/// HAPi class to format, get and return data from the HAP+ API
///
/// The main class that is to be used to access the HAP+ API on the
/// remote HAP+ server. All functions in the app that need to access
/// the API on the HAP+ server should send their requests to this
/// class, so that all API calls are standardised and central.
///
/// Oh, and the reason for the name of this class? Well...
/// * HAP(i) - Home Access Plus+
/// * (H)APi - Application Programming Interface
/// * HAPi - Who doesn't want to be HAPi?
///   * The small 'i'? Well, why not?
///
/// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
/// - since: 0.2.0-alpha
class HAPi {
    
    /// Checks to see if there is currently a connection available to the Internet
    ///
    /// As we are never sure if a user is connected to the Internet, and
    /// any use of the features of the HAP+ API need an available connection,
    /// this function checks to see if there is a reachable connection before
    /// attempting to do any network related functions
    ///
    /// This function uses the Reach.swift class, based on the file from
    /// here: [Reach](https://github.com/Isuru-Nanayakkara/Reach)
    ///
    /// - note: All functions in the class should call this first before attempting
    ///         to do any Internet related functions. This function can also be called
    ///         from anywhere else in the code if a Internet connection check is needed
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    /// - version: 1
    /// - date: 2015-12-05
    ///
    /// - returns: Is there an available Internet connection
    func checkConnection() -> Bool {
        logger.debug("Checking connection to the Internet")
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            logger.warning("No available connection to the Internet")
            return false
        case .Online(.WWAN):
            logger.info("Connection to the Intenet via WWAN")
            return true
        case .Online(.WiFi):
            logger.info("Connection to the Internet via WiFi")
            return true
        }
    }
    
    
    /// Checks to make sure that the HAP+ server is available and is able to
    /// connect to the API
    ///
    /// All HAP+ servers have the ability to check that the API is available
    /// to use. This check is located at "<HAP server URL>/api/test" and on
    /// result of a successful API test the server returns "OK"
    ///
    /// - note: Since iOS9, TLS 1.2 is required for any https connections. If
    ///         this function keeps failing after verifying the HAP+ address
    ///         is valid, then it is a good idea to check that the server
    ///         has TLS 1.2 enabled. See: [StackOverflow](http://stackoverflow.com/a/31138106)
    ///         See: [Apple Developer](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html#//apple_ref/doc/uid/TP40016198-SW14)
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    ///
    /// - parameter hapServer: The full URL to the main HAP+ root
    /// - returns: Can the HAP+ server API be contacted
    func checkAPI(hapServer: String, callback:(Bool) -> Void) -> Void {
        // Use Alamofire to try to connect to the passed HAP+ server
        // and check the API connection is working
        Alamofire.request(.GET, hapServer + "/api/test")
            .responseString { response in switch response.result {
                // Seeing if there is a successful contact from the HAP+
                // server, so as to not try and get a value from a variable
                // that is never set - issue #11
                // See: https://github.com/stuajnht/HAP-for-iOS/issues/11
                case.Success(_):
                    logger.verbose("Successful contact of server: \(response.result.isSuccess)")
                    logger.verbose("Response string from server API : \(response.result.value)")
                    // Seeing if the response is 'OK'
                    if (response.result.value! == "OK") {
                        callback(true)
                    } else {
                        callback(false)
                    }
                // We were not able to contact any HAP+ server at the address
                // given to this function, such as a non-existent DNS address
                // It could also be that the server is not running TLS 1.2, which
                // iOS 9 requires (the error logged below would have the following
                // message: Error Domain=NSURLErrorDomain Code=-1200 "An SSL error
                // has occurred and a secure connection to the server cannot be made.")
                case .Failure(let error):
                    logger.verbose("Connection to API failed with error: \(error)")
                    callback(false)
                }
            }
    }
    
    /// Attempts to log in the user with the username and password provided
    ///
    /// Once it has been confirmed that the HAP+ server is contactable and has
    /// a valid API interface, we can attempt to log the user in with the username
    /// and password that they have entered. If the login is successful we will
    /// have their name and also the needed tokens that we can use to authenticate
    /// the user through all future activities
    ///
    /// - note: The callback from this function returns a string of either true
    ///         or false depending if the user logon was valid (which is collected
    ///         from the JSON response). The other values that are stored are saved
    ///         in this function from the JSON response
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-alpha
    /// - version: 3
    /// - date: 2016-04-16
    ///
    /// - parameter hapServer: The full URL to the main HAP+ root
    /// - parameter username: The username of the user we are trying to log in
    /// - parameter password: The password entered for the username provided
    func loginUser(hapServer: String, username: String, password: String, callback:(Bool) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            // Setting the json http content type header, as the HAP+
            // API expects incomming messages in "xml" or "json"
            let httpHeaders = [
                "Content-Type": "application/json"
            ]
            
            // Connecting to the API to log in the user with the credentials
            logger.debug("Attempting to connect to \(hapServer)/api/ad/? with the username: \(username)")
            Alamofire.request(.POST, hapServer + "/api/ad/?", parameters: ["username": username, "password": password], headers: httpHeaders, encoding: .JSON)
                // Parsing the JSON response
                // See: http://stackoverflow.com/a/33022923
                .responseJSON { response in switch response.result {
                    case .Success(let JSON):
                        logger.verbose("Response JSON for login attempt: \(JSON)")
                        
                        // Seeing if there is a valid logon attempt, from the returned JSON
                        let validLogon = JSON["isValid"]!!.stringValue
                        logger.info("Logon username and password valid: \(validLogon)")
                        if (validLogon == "1") {
                            // We have successfully logged in, so save some settings
                            // the NSUserDefaults settings variable
                            let siteName = JSON["SiteName"]
                            logger.debug("Site name from JSON: \(siteName)")
                            settings!.setObject(siteName, forKey: settingsSiteName)
                            settings!.setObject(JSON["FirstName"], forKey: settingsFirstName)
                            settings!.setObject(JSON["Username"], forKey: settingsUsername)
                            settings!.setObject(JSON["Token1"], forKey: settingsToken1)
                            settings!.setObject(JSON["Token2"], forKey: settingsToken2)
                            settings!.setObject(JSON["Token2Name"], forKey: settingsToken2Name)
                            
                            // Saving the password for future logon attempts
                            // and for when the logon tokens expire
                            do {
                                try Locksmith.updateData([settingsPassword: password], forUserAccount: settings!.stringForKey(settingsUsername)!)
                                logger.debug("Securely saved user password")
                            } catch {
                                logger.error("Failed to securely save password")
                            }
                            
                            // Logging the last successful contact to the HAP+
                            // API, to reset the session cookies. This is saved
                            // as a time since Unix epoch
                            logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                            settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                            
                            // Setting the groups the user is part of
                            self.setRoles({ (result: Bool) -> Void in
                                if (result) {
                                    logger.info("Successfully set the roles for \(settings!.stringForKey(settingsUsername)!)")
                                    logger.debug("Roles for \(settings!.stringForKey(settingsUsername)!): \(settings!.stringForKey(settingsUserRoles)!)")
                                } else {
                                    logger.warning("Failed to set the roles for \(settings!.stringForKey(settingsUsername)!)")
                                }
                            })
                            
                            // Attempting to get the timetable for the current user,
                            // only if the device type is not set up or in "shared" mode
                            if ((settings!.stringForKey(settingsDeviceType) == "shared") || (settings!.stringForKey(settingsDeviceType) == nil)) {
                                logger.debug("Device is new or in shared mode, so attempting to retreive a timetable for the current user")
                                
                                self.getTimetable({ (result: Bool) -> Void in
                                    if (result) {
                                        logger.info("Successfully collected a timetable for \(settings!.stringForKey(settingsUsername)!)")
                                        
                                        // Enabling auto-logout for the current logged in user
                                        logger.info("Enabling auto-logout for the current user")
                                        settings!.setBool(true, forKey: settingsAutoLogOutEnabled)
                                    } else {
                                        logger.warning("Did not get a timetable for \(settings!.stringForKey(settingsUsername)!), or it is currently outside a timetabled lesson")
                                        logger.info("Not enabling auto-logout for the current user")
                                    }
                                })
                            }
                            
                            // Letting the callback know we have successfully logged in
                            callback(true)
                        } else {
                            callback(false)
                        }
                    
                    case .Failure(let error):
                        logger.warning("Request failed with error: \(error)")
                        callback(false)
                    }
                }
        } else {
            logger.warning("The connection to the Internet has been lost")
            callback(false)
        }
    }
    
    /// Sets the roles of the user that has logged in, to see what they
    /// are able to do
    ///
    /// Once a user has successfully logged in, we can set their roles and
    /// groups that they are in from the HAP+ server. While this is not
    /// really that useful for this app, as the groups will make more sense
    /// to the Windows network and what permissions they have avaiable there,
    /// we need to know if they're a domain admin if the device is going to
    /// be put into a shared or single mode.
    ///
    /// The reason for this is to prevent "exploring" students from being able
    /// to access the settings and remove the iOS device from the HAP+ server,
    /// meaning that no-one will be able to use the app until a technical staff
    /// member has connected it up again (which they will begrudgingly do (I
    /// know I would!))
    ///
    /// This function will normally only be called after a successful login, as
    /// there isn't much point in getting groups a user is in after the first
    /// login. As this function is asynchronous, it can be called in the
    /// loginUser function without affecting logon speed
    ///
    /// - note: Upon checking the HAP+ API documentation, it has come to my
    ///         attention that there are no checks performed on this API call
    ///         to make sure that a valid user is accessing it. This may change
    ///         in a future version of the HAP+ API, so bare in mind that
    ///         someday this function may break!
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-beta
    /// - version: 1
    /// - date: 2015-12-12
    /// - seealso: loginUser
    func setRoles(callback:(Bool) -> Void) -> Void {
        Alamofire.request(.GET, settings!.stringForKey(settingsHAPServer)! + "/api/ad/roles/" + settings!.stringForKey(settingsUsername)!)
            .responseString { response in switch response.result {
                // Seeing if there is a successful contact from the HAP+
                // server, so as to not try and get a value from a variable
                // that is never set
            case.Success(_):
                logger.verbose("Successful contact of server: \(response.result.isSuccess)")
                logger.verbose("\(settings!.stringForKey(settingsUsername)!) is a member of the following groups: \(response.result.value)")
                // Saving the groups the user is part of
                settings!.setObject(response.result.value, forKey: settingsUserRoles)
                
                // Logging the last successful contact to the HAP+
                // API, to reset the session cookies. This is saved
                // as a time since Unix epoch
                logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                
                callback(true)
                
                // We were not able to contact the HAP+ server, so we cannot
                // put the user into any groups
            case .Failure(let error):
                logger.verbose("Connection to API failed with error: \(error)")
                // Creating an empty escaped string -- [""] -- so that the setting
                /// value exists and is over-written from a previous logged on user
                settings!.setObject("[\"\"]", forKey: settingsUserRoles)
                callback(false)
                }
        }
    }
    
    /// Attempts to get the timetable for the currently logged in user
    ///
    /// Once a user has successfully logged in, attempt to load their timetable
    /// from the HAP+ server, so that if the device is set up in "Shared" mode,
    /// they can be logged out automatically when the lesson its over (as some
    /// students may forget to do this and just put the device away)
    ///
    /// This check is always completed on the first successful log in as it is
    /// not yet known what mode the device is going to be in. All future successful
    /// log in attempts will call this function only if the device is set up in
    /// "shared" mode, to prevent unneeded server API calls
    ///
    /// The API call used in this function is "/api/timetable/LoadUser/{username}"
    /// and not "/api/timetable/LoadUser/" as this didn't always seem to work as
    /// expected during initial testing, even though it calls pretty much the same
    /// functions on the HAP+ server. It is currently unclear why this is (but
    /// most likely due to the author doing something stupid! Besides, we know
    /// the username, why not utilise it?)
    ///
    /// If the timetabled user logs on to the device outside of their timetabled
    /// lessons (such as they have logged in to the device during a breaktime)
    /// then it is up to the user to log themselves out of the app. It cannot be
    /// assumed that the start time of their first lesson the next day should be used
    /// to log them out, as they may not have a lesson during period 1 (for example,
    /// sixth form students) when another student (a year 7) would, meaning they
    /// would still be logged in
    ///
    /// If there is no timetable for the user loaded from the HAP+ server (such
    /// as a member of the IT department logs in to the device) the HAP+ server
    /// will return an empty array. As it is not a good idea to log this user
    /// out if they have borrowed the device with a reason of "Your lesson has
    /// come to an end" due to it being unexpected for them. Therefore, the app
    /// will behave as though it is in "personal" mode
    ///
    /// - seealso: loginUser
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-04-16
    func getTimetable(callback:(Bool) -> Void) -> Void {
        // Seeing if auto-logout should be enabled. This is set to
        // false by default as we don't want users being logged out
        // of the device if they are not in a lesson, and only set
        // to true when it has been confirmed that a user is using
        // the device during a timetabled lesson
        var enableAutoLogout = false
        
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            // Setting the json http content type header, as the HAP+
            // API expects incomming messages in "xml" or "json"
            let httpHeaders = [
                "Content-Type": "application/json"
            ]
            
            // Connecting to the API to attempt to load the users timetable
            logger.debug("Attempting to get the timetable for: \(settings!.stringForKey(settingsUsername)!)")
            Alamofire.request(.GET, settings!.stringForKey(settingsHAPServer)! + "/api/timetable/LoadUser/" + settings!.stringForKey(settingsUsername)!, headers: httpHeaders, encoding: .JSON)
                // Parsing the JSON response
                // See: http://stackoverflow.com/a/33022923
                .responseString { response in
                    
                    logger.debug("Timetable API response successful: \(response.result.isSuccess)")
                    logger.verbose("Timetable API data: \(response.result.value!)")
                    
                    switch response.result {
                    case .Success:
                        // Formatting the JSON response as a string, to
                        // see if there is any content returned
                        let jsonString = JSON(response.result.value!)
                        logger.verbose("Response JSON for tabletable (string): \(jsonString)")
                        
                        // Logging the last successful contact to the HAP+
                        // API, to reset the session cookies. This is saved
                        // as a time since Unix epoch
                        logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                        settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                        
                        // Seeing if the timetable returned has anything in it
                        // This can be checked by having at least one timetabled
                        // day and lesson, otherwise the returned API JSON is []
                        if jsonString.rawString() != "[]" {
                            logger.info("Valid timetable found for \(settings!.stringForKey(settingsUsername)!)")
                            logger.info("Enabling automatic log out of user at the end of the current lesson, if applicable")
                            
                            // Converting the JSON string returned from the server
                            // into a JSON object, otherwise it's not possible to
                            // access any data
                            // See: https://www.hackingwithswift.com/example-code/libraries/how-to-parse-json-using-swiftyjson
                            if let data = response.result.value!.dataUsingEncoding(NSUTF8StringEncoding) {
                                let json = JSON(data: data)
                                logger.verbose("Response JSON for timetable (JSON): \(json)")
                                
                                /// Array to hold the lessons that the user takes
                                ///
                                /// - note: The order of and data stored in this array is in
                                ///         the following order:
                                ///   1. Day number
                                ///   2. Lesson period
                                ///   3. The start time of the lesson
                                ///   4. The end time of the lesson
                                var lessons: [NSArray] = []
                                
                                // Looping through the days presented, to save the timetable
                                for (_,subJson) in json {
                                    let dayNumber = subJson["Day"].stringValue
                                    logger.debug("Getting lessons for \(settings!.stringForKey(settingsUsername)!) on day: \(dayNumber)")
                                    
                                    // Retreiving details for the days lessons
                                    for lesson in subJson["Lessons"].arrayValue {
                                        let period = lesson["Period"].stringValue
                                        let startTime = lesson["StartTime"].stringValue
                                        let endTime = lesson["EndTime"].stringValue
                                        logger.debug("Day: \(dayNumber), Lesson: \(period), Starts: \(startTime), Ends: \(endTime)")
                                        
                                        // Adding the current lesson to the array
                                        var lesson: [String] = []
                                        lesson = [dayNumber, period, startTime, endTime]
                                        lessons.append(lesson)
                                    }
                                }
                                
                                logger.verbose("Lessons array for current user: \(lessons)")
                                
                                // Getting the yyyy-MM-dd format of today, as the response
                                // from the HAP+ API only includes a time, so the timeFormatter
                                // variable will put the date as 2001-01-01 if todays date is
                                // not included
                                // See: http://stackoverflow.com/a/28347285
                                let formatShortDate = NSDateFormatter()
                                formatShortDate.dateFormat = "yyyy-MM-dd"
                                let today = formatShortDate.stringFromDate(NSDate())
                                logger.debug("Todays date is: \(today)")
                                
                                // Getting a time the current lesson ends, if applicable
                                // Note: HAP+ returns the days as Monday - 1, Tuesday - 2, etc...
                                //       the following code does Sun - 1, Mon - 2, etc...
                                //       so 1 is taken from the result
                                // See: http://stackoverflow.com/a/35006174
                                let cal: NSCalendar = NSCalendar.currentCalendar()
                                let comp: NSDateComponents = cal.components(.Weekday, fromDate: NSDate())
                                let dayNumberToday = comp.weekday - 1
                                logger.debug("Today is day number: \(dayNumberToday)")
                                
                                // Setting up a formatter so that the dates that are returned
                                // from the JSON request, along with the current date time, are
                                // formatted in a standard way so that they can be compared
                                // See: http://stackoverflow.com/a/28627873
                                let timeFormatter = NSDateFormatter()
                                timeFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
                                timeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                
                                // Getting the date time as of now, so that it can be
                                // compared against the lesson start and end times
                                let timeNow = timeFormatter.stringFromDate(NSDate())
                                logger.debug("Date time now is: \(timeNow)")
                                
                                // Looping around the items in the lessons array, to find
                                // what lesson we are currently in
                                for arrayPosition in 0 ..< lessons.count {
                                    // Seeing if the lesson array is the same as today, and
                                    // skip it if not
                                    let lessonDayNumber = lessons[arrayPosition][0] as! String
                                    if (lessonDayNumber == String(dayNumberToday)) {
                                        logger.debug("Lesson found happening today: \(lessons[arrayPosition][1])")
                                        
                                        // Formatting the time from the string to be a valid
                                        // NSDate, composed of todays date and the time returned
                                        // from the JSON response
                                        let lessonStartTime = timeFormatter.dateFromString(today + " " + (lessons[arrayPosition][2] as! String) + ":00")!
                                        let lessonEndTime = timeFormatter.dateFromString(today + " " + (lessons[arrayPosition][3] as! String) + ":00")!
                                        logger.debug("Lesson being checked starts at \(lessonStartTime) and ends at \(lessonEndTime)")
                                        
                                        // Seeing if the current time is between the lesson
                                        // start and end times
                                        // Note: There seems to be many ways to do this from
                                        //       the stackoverflow answers, so this may not be
                                        //       entirely efficient
                                        // See: http://stackoverflow.com/a/29653553
                                        let currentTime = timeFormatter.dateFromString(timeNow)!
                                        if lessonStartTime.compare(currentTime) == .OrderedAscending && lessonEndTime.compare(currentTime) == .OrderedDescending {
                                            // The user is currently using the device in a timetabled
                                            // lesson, so we can auto log them out
                                            logger.info("Currently in lesson: \(lessons[arrayPosition][1])")
                                            enableAutoLogout = true
                                        } else {
                                            logger.debug("Currently outside of lesson: \(lessons[arrayPosition][1])")
                                        }
                                    }
                                }
                            }
                            
                            // Letting the callback know if we have successfully collected
                            // a timetable for the logged in user, and if the auto-logout
                            // should be enabled
                            callback(enableAutoLogout)
                        } else {
                            // No timetable was found for the user, so disable
                            // automatically logging out the logged in user
                            logger.warning("No timetable found for \(settings!.stringForKey(settingsUsername)!). This is expected if the user does not have a timetable and the device is in \"shared\" mode")
                            callback(enableAutoLogout)
                        }
                        
                    case .Failure(let error):
                        logger.warning("Request failed with error: \(error)")
                        callback(enableAutoLogout)
                    }
            }
        } else {
            logger.warning("The connection to the Internet has been lost")
            callback(enableAutoLogout)
        }
    }
    
    /// Lists the network drives that are available to the user
    ///
    /// The user is presented with a list of available network
    /// drives that they have access to. This list will vary for
    /// each user, depending on what has been set up for them in
    /// the HAP+ config. From here, the user is then able to navigate
    /// through the folder hierarchy to find the file or folder
    /// that they are looking for
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.3.0-alpha
    /// - version: 1
    /// - date: 2015-12-14
    func getDrives(callback:(result: Bool, response: AnyObject) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            // Setting the json http content type header, as the HAP+
            // API expects incomming messages in "xml" or "json"
            // As the user is logged in, we also need to send the
            // tokens that are collected from the login, so the HAP+
            // server knows which user has sent this request
            let httpHeaders = [
                "Content-Type": "application/json",
                "Cookie": "token=" + settings!.stringForKey(settingsToken1)! + "; " + settings!.stringForKey(settingsToken2Name)! + "=" + settings!.stringForKey(settingsToken2)!
            ]
            
            // Connecting to the API to get the drive listing
            logger.debug("Attempting to get drives available")
            Alamofire.request(.GET, settings!.stringForKey(settingsHAPServer)! + "/api/myfiles/Drives", headers: httpHeaders, encoding: .JSON)
                // Parsing the JSON response
                .responseJSON { response in switch response.result {
                    case .Success(let JSON):
                        logger.verbose("Response JSON for drive listing: \(JSON)")
                        
                        // Logging the last successful contact to the HAP+
                        // API, to reset the session cookies. This is saved
                        // as a time since Unix epoch
                        logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                        settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                        
                        // Letting the callback know we have successfully logged in
                        callback(result: true, response: JSON)
                    
                    case .Failure(let error):
                        logger.warning("Request failed with error: \(error)")
                        callback(result: false, response: "")
                    }
            }
        } else {
            logger.warning("The connection to the Internet has been lost")
            callback(result: false, response: "")
        }
    }
    
    /// Gets the contents of the selected folder
    ///
    /// The user has selected a folder to browse to and we need to
    /// display the contents of it to them
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.3.0-alpha
    /// - version: 1
    /// - date: 2015-12-15
    ///
    /// - parameter folderPath: The path of the folder the user has browsed to
    func getFolder(folderPath: String, callback:(result: Bool, response: AnyObject) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            // Setting the json http content type header, as the HAP+
            // API expects incomming messages in "xml" or "json"
            // As the user is logged in, we also need to send the
            // tokens that are collected from the login, so the HAP+
            // server knows which user has sent this request
            let httpHeaders = [
                "Content-Type": "application/json",
                "Cookie": "token=" + settings!.stringForKey(settingsToken1)! + "; " + settings!.stringForKey(settingsToken2Name)! + "=" + settings!.stringForKey(settingsToken2)!
            ]
            
            // Replacing the escaped slashes with a forward slash
            logger.debug("Folder being browsed raw path: \(folderPath)")
            var formattedPath = folderPath.stringByReplacingOccurrencesOfString("\\\\", withString: "/")
            formattedPath = formattedPath.stringByReplacingOccurrencesOfString("\\", withString: "/")
            // Escaping any non-allowed URL characters - see: http://stackoverflow.com/a/24552028
            formattedPath = formattedPath.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            logger.debug("Folder being browsed formatted path: \(formattedPath)")
            
            // Connecting to the API to get the folder listing
            logger.debug("Attempting to get folder listing")
            Alamofire.request(.GET, settings!.stringForKey(settingsHAPServer)! + "/api/myfiles/" + formattedPath, headers: httpHeaders, encoding: .JSON)
                // Parsing the JSON response
                .responseJSON { response in switch response.result {
                case .Success(let JSON):
                    logger.verbose("Response JSON for folder listing: \(JSON)")
                    
                    // Logging the last successful contact to the HAP+
                    // API, to reset the session cookies. This is saved
                    // as a time since Unix epoch
                    logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                    settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                    
                    // Letting the callback know we have successfully logged in
                    callback(result: true, response: JSON)
                    
                case .Failure(let error):
                    logger.warning("Request failed with error: \(error)")
                    callback(result: false, response: "")
                    }
            }
        } else {
            logger.warning("The connection to the Internet has been lost")
            callback(result: false, response: "")
        }
    }
    
    /// Downloads the selected file from the HAP+ server
    ///
    /// Once a user has selected a file that they would like
    /// to use or view, it needs to be downloaded onto the device
    /// so that the QuickLook controller can preview the file (if
    /// supported) and for it to be shared to other apps
    ///
    /// - note: The download path to get the file from the HAP+ server
    ///         is in the format <hapServer>/Download/Drive/Path/File.ext
    ///         and doesn't need to have 'api' in the URL (a 404 is
    ///         generated otherwise)
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.4.0-alpha
    /// - version: 1
    /// - date: 2015-12-19
    ///
    /// - parameter fileLocation: The path to the file the user has selected
    func downloadFile(fileLocation: String, callback:(result: Bool, downloading: Bool, downloadedBytes: Int64, totalBytes: Int64, downloadLocation: NSURL) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            // Setting the json http content type header, as the HAP+
            // API expects incomming messages in "xml" or "json"
            // As the user is logged in, we also need to send the
            // tokens that are collected from the login, so the HAP+
            // server knows which user has sent this request
            let httpHeaders = [
                "Content-Type": "application/json",
                "Cookie": settings!.stringForKey(settingsToken2Name)! + "=" + settings!.stringForKey(settingsToken2)! + "; token=" + settings!.stringForKey(settingsToken1)!
            ]
            
            // Replacing the '../' navigation browsing up that the HAP+
            // API adds to the file path, so that it removes the 'myfiles'
            // section from the URL and replaces it with 'Download'
            // e.g. <hapServer>/api/myfiles/H/file.txt had a path from the
            // HAP+ server as <hapServer>/api/myfiles/../Download/H/file.txt
            // but needs to be <hapServer>/api/Download/H/file.txt
            logger.debug("File being downloaded raw path: \(fileLocation)")
            var formattedPath = fileLocation.stringByReplacingOccurrencesOfString("../", withString: "")
            // Escaping any non-allowed URL characters - see: http://stackoverflow.com/a/24552028
            formattedPath = formattedPath.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            logger.debug("File being downloaded formatted path: \(formattedPath)")
            
            // Setting the download directory to be the caches folder on the
            // device
            // See: https://github.com/Alamofire/Alamofire/issues/907
            let destination = Alamofire.Request.suggestedDownloadDestination(
                directory: .CachesDirectory,
                domain: .UserDomainMask
            )
            
            // Downloading the file
            Alamofire.download(.GET, settings!.stringForKey(settingsHAPServer)! + "/" + formattedPath, headers: httpHeaders, destination: destination)
                .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                    logger.verbose("Total size of file being downloaded: \(totalBytesExpectedToRead)")
                    logger.verbose("Downloaded \(totalBytesRead) bytes out of \(totalBytesExpectedToRead)")
                    callback(result: false, downloading: true, downloadedBytes: totalBytesRead, totalBytes: totalBytesExpectedToRead, downloadLocation: NSURL(fileURLWithPath: ""))
                }
                .response { request, response, _, error in
                    logger.verbose("Server response: \(response)")
                    logger.debug("File saved to the following location: \(destination(NSURL(string: "")!, response!))")
                    
                    // Logging the last successful contact to the HAP+
                    // API, to reset the session cookies. This is saved
                    // as a time since Unix epoch
                    logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                    settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                    
                    callback(result: true, downloading: false, downloadedBytes: 0, totalBytes: 0, downloadLocation: destination(NSURL(string: "")!, response!))
            }
            
        } else {
            logger.warning("The connection to the Internet has been lost")
            callback(result: false, downloading: false, downloadedBytes: 0, totalBytes: 0, downloadLocation: NSURL(fileURLWithPath: ""))
        }
    }
    
    /// Uploads the selected file to the HAP+ server
    ///
    /// Once a user has browsed to the folder that they would like to
    /// upload a file they have exported from an extrnal app, it can
    /// be uploaded to the HAP+ server, so that it can be browsed from
    /// other network devices that have access to the share / folder
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-alpha
    /// - version: 3
    /// - date: 2016-01-27
    ///
    /// - parameter deviceFileLocation: The path to the file on the device (normally
    ///                                 stored in a folder called "inbox" which can
    ///                                 be found in the documents directory)
    /// - parameter serverFileLocation: The location on the HAP+ server that the file
    ///                                 is going to be uploaded to
    /// - parameter fileFromPhotoLibrary: Is the file being uploaded coming from the photo
    ///                                   library on the device, or from another app
    /// - parameter customFileName: If the file currently exists in the current folder,
    ///                             and the user has chosen to create a new file and
    ///                             not overwrite it, then this is the custom file name
    ///                             that should be used
    func uploadFile(deviceFileLocation: NSURL, serverFileLocation: String, fileFromPhotoLibrary: Bool, customFileName: String, callback:(result: Bool, uploading: Bool, uploadedBytes: Int64, totalBytes: Int64) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            // Getting the name of the file that is being uploaded from the
            // location of the file on the device, which is needed when setting
            // the httpHeaders
            logger.debug("Location of file on device: \(deviceFileLocation)")
            logger.debug("File coming from photos library: \(fileFromPhotoLibrary)")
            
            var fileName = ""
            
            // Seeing if a name for the file needs to be generated
            // or one has already been created from the user choosing
            // to not overwrite a file
            if (customFileName == "") {
                // As the file is coming from an external app, it will be saved
                // on the device in a physical location with an extension. We
                // can just split the path and get the file name from the last
                // array value
                let pathArray = String(deviceFileLocation).componentsSeparatedByString("/")
                
                // Forcing an unwrap of the value, otherwise the file name
                // is Optional("<nale>") which causes the HAP+ server to
                // do a 500 HTTP error
                // See: http://stackoverflow.com/a/25848016
                fileName = pathArray.last!
                
                // Removing any encoded characters from the file name, so
                // HAP+ saves the file with the correct file name
                fileName = fileName.stringByRemovingPercentEncoding!
                
                // Formatting the name of the file to make sure that it is
                // valid for storing on Windows file systems
                fileName = formatInvalidName(fileName)
            } else {
                // A custom file name has already been created and formatted,
                // so that should be used instead
                fileName = customFileName
            }
            
            logger.debug("Name of file being uploaded: \(fileName)")
            
            // Setting the tokens that are collected from the login, so the HAP+
            // server knows which user has sent this request, and creating a
            // custom header so that the HAP+ server knows the name of the file
            // (assuming here, as it's based on what is currently used in the
            // Windows app, inside the "private async void upload()" function
            // See: https://hap.codeplex.com/SourceControl/latest#CHS%20Extranet/HAP.Win.MyFiles/Browser.xaml.cs )
            let httpHeaders = [
                "X_FILENAME": fileName,
                "Cookie": settings!.stringForKey(settingsToken2Name)! + "=" + settings!.stringForKey(settingsToken2)! + "; token=" + settings!.stringForKey(settingsToken1)!
            ]
            
            // Formatting the path that we are going to be using to upload
            // to, so that it is a valid URL, and also swapping the backslashes '\'
            // from the string passed with slashes '/'
            logger.debug("Upload location raw path: \(serverFileLocation)")
            var uploadLocation = serverFileLocation.stringByReplacingOccurrencesOfString("\\", withString: "/")
            uploadLocation = uploadLocation.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            logger.debug("Upload location formatted path: \(uploadLocation)")
            
            // Uploading the file
            Alamofire.upload(.POST, settings!.stringForKey(settingsHAPServer)! + "/api/myfiles-upload/" + uploadLocation, headers: httpHeaders, file: deviceFileLocation)
                .progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                    logger.verbose("Total size of file being uploaded: \(totalBytesExpectedToWrite)")
                    logger.verbose("Uploaded \(totalBytesWritten) bytes out of \(totalBytesExpectedToWrite)")
                    callback(result: false, uploading: true, uploadedBytes: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
                }
                .response { request, response, _, error in
                    logger.verbose("Server response: \(response)")
                    
                    // Logging the last successful contact to the HAP+
                    // API, to reset the session cookies. This is saved
                    // as a time since Unix epoch
                    logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                    settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                    
                    callback(result: true, uploading: false, uploadedBytes: 0, totalBytes: 0)
            }
        } else {
            logger.warning("The connection to the Internet has been lost")
            callback(result: false, uploading: false, uploadedBytes: 0, totalBytes: 0)
        }
    }
    
    /// Deletes the selected file or folder
    ///
    /// If a user has requested that a file or folder should be deleted,
    /// then this needs to be sent to the HAP+ server.
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-alpha
    /// - version: 5
    /// - date: 2016-04-01
    ///
    /// - parameter deleteItemAtPath: The path to the file on the HAP+ server
    ///                               that the user has requested to be deleted
    func deleteFile(deleteItemAtPath: String, callback:(result: Bool) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            // Replacing the '../Download' navigation path that the HAP+
            // API adds to the file path, so that it can be used to locate
            // the file item directly to be able to delete it
            logger.debug("Item being deleted raw path: \(deleteItemAtPath)")
            var formattedPath = deleteItemAtPath.stringByReplacingOccurrencesOfString("../Download/", withString: "")
            
            // Converting any backslashes from a folder path into forward
            // slashes, so that the HAP+ server is able to delete folders
            formattedPath = formattedPath.stringByReplacingOccurrencesOfString("\\", withString: "/")
            
            // The HTTP request body need to have the file name enclosed in
            // square brackets and quotes, e.g. ["<filePath>"]
            let formattedJSONPath = "[\"" + formattedPath + "\"]"
            logger.debug("Item being deleted formatted path: \(formattedJSONPath)")
            
            // Getting the name of the file or folder that is being deleted,
            // so that it can be checked against the response from the HAP+
            // server if the file item has been deleted properly
            // - seealso: uploadFile
            var fileName = ""
            let pathArray = String(formattedPath).componentsSeparatedByString("/")
            fileName = pathArray.last!
            fileName = fileName.stringByRemovingPercentEncoding!
            fileName = formatInvalidName(fileName)
            logger.debug("Name of file item being deleted: \(fileName)")
            
            // Setting the tokens that are collected from the login, so the HAP+
            // server knows which user has sent this request
            let httpHeaders = [
                "Content-Type": "application/json",
                "Cookie": settings!.stringForKey(settingsToken2Name)! + "=" + settings!.stringForKey(settingsToken2)! + "; token=" + settings!.stringForKey(settingsToken1)!
            ]
            
            // Connecting to the API to delete the file item
            // The file that is to be deleted is passed to the API in the
            // request body, i.e. the URL is <hapServer>/api/myfiles/Delete
            // and the string passed to this URL is the name of the file
            // item to delete e.g. H/file.txt
            // See: http://stackoverflow.com/a/28552198
            logger.debug("Attempting to delete the selected file item")
            Alamofire.request(.POST, settings!.stringForKey(settingsHAPServer)! + "/api/myfiles/Delete", parameters: [:], headers: httpHeaders, encoding: .Custom({
                    (convertible, params) in
                    let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
                    mutableRequest.HTTPBody = formattedJSONPath.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                    return (mutableRequest, nil)
                }))
                // Parsing the response
                .response { request, response, data, error in
                    logger.verbose("Request: \(request)")
                    logger.verbose("Response: \(response)")
                    logger.verbose("Data: \(data)")
                    logger.verbose("Error: \(error)")
                    
                    // The response body that the HAP+ server responds
                    // with is ["Deleted <file item name>"] so we need
                    // to check to see if this is returned. If it is,
                    // then let the user know the file was deleted
                    // otherwise let them know there was a problem
                    let deletionResponse = data!
                    logger.verbose("Raw response from server from deleting file item: \(deletionResponse)")
                    
                    // For some reason, the response body data is also
                    // hex encoded, which means it needs to be decoded
                    // first before any checks can be done to see if the
                    // file item has been successfully deleted
                    
                    // Removing any characters from the string that shouldn't
                    // be there, namely '<', '>' and ' ', as these cause
                    // problems parsing the string result
                    var deletionString = String(deletionResponse)
                    deletionString = deletionString.stringByReplacingOccurrencesOfString("<", withString: "")
                    deletionString = deletionString.stringByReplacingOccurrencesOfString(">", withString: "")
                    deletionString = deletionString.stringByReplacingOccurrencesOfString(" ", withString: "")
                    
                    // Converting the hex string into Unicode values, to check
                    // that the file item from the server has been successfully
                    // deleted
                    // See: http://stackoverflow.com/a/30795372
                    var deletionStringCharacters = [Character]()
                    
                    for characterPosition in deletionString.characters {
                        deletionStringCharacters.append(characterPosition)
                    }
                    
                    // This version of Swift is different from the
                    // hex to ascii example used above, so we need
                    // to call a different function
                    // See: http://stackoverflow.com/a/24372631
                    let characterMap =  0.stride(to: deletionStringCharacters.count, by: 2).map{
                        strtoul(String(deletionStringCharacters[$0 ..< $0+2]), nil, 16)
                    }
                    
                    var decodedString = ""
                    var characterMapPosition = 0
                    
                    while characterMapPosition < characterMap.count {
                        decodedString.append(Character(UnicodeScalar(Int(characterMap[characterMapPosition]))))
                        characterMapPosition = characterMapPosition.successor()
                    }
                    
                    let formattedDeletionResponse = decodedString
                    logger.debug("Formatted response from server from deleting file item: \(formattedDeletionResponse)")
                    
                    // Seeing if the file was deleted successfully or not
                    if (formattedDeletionResponse == "[\"Deleted \(fileName)\"]") {
                        logger.debug("\(fileName) was successfully deleted from the server")
                        
                        // Logging the last successful contact to the HAP+
                        // API, to reset the session cookies. This is saved
                        // as a time since Unix epoch
                        logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                        settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                        
                        callback(result: true)
                    } else {
                        logger.error("There was a problem deleting the file from the server")
                        callback(result: false)
                    }
                }
        }
    }
    
    /// Creates a new folder in the currently viewed folder
    ///
    /// The user can create a folder in the currently browsed
    /// to folder from the upload popover, and this function
    /// calls the relevant HAP+ API to create the folder. It also
    /// checks to make sure there are no forbidden characters in
    /// the name of the folder, and converts the current folder
    /// and new folder name into URL encoded strings, so that the
    /// HAP+ server can create the folder correctly
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-alpha
    /// - version: 1
    /// - date: 2016-01-23
    ///
    /// - parameter currentFolder: Path to the folder that is currently
    ///                            being shown to the user
    /// - parameter newFolderName: The name of the new folder that is to
    ///                            be created
    func newFolder(currentFolder: String, newFolderName: String, callback:(result: Bool) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            logger.debug("New folder to be created in location: \(currentFolder)")
            logger.debug("New folder raw name: \(newFolderName)")
            
            // Removing invalid characters from the new folder name
            let formattedNewFolderName = formatInvalidName(newFolderName)
            
            // Replacing the escaped slashes with a forward slash
            // from the current folder path
            var folderFormattedPath = currentFolder.stringByReplacingOccurrencesOfString("\\\\", withString: "/")
            folderFormattedPath = folderFormattedPath.stringByReplacingOccurrencesOfString("\\", withString: "/")
            
            // Combining the path of the current folder with the name
            // of the new folder
            var fullNewFolderPath = folderFormattedPath + "/" + formattedNewFolderName
            
            // Escaping any non-allowed URL characters - see: http://stackoverflow.com/a/24552028
            fullNewFolderPath = fullNewFolderPath.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            
            logger.debug("New folder being created in formatted location path: \(fullNewFolderPath)")
            
            // Setting the json http content type header, as the HAP+
            // API expects incomming messages in "xml" or "json"
            // As the user is logged in, we also need to send the
            // tokens that are collected from the login, so the HAP+
            // server knows which user has sent this request
            let httpHeaders = [
                "Content-Type": "application/json",
                "Cookie": "token=" + settings!.stringForKey(settingsToken1)! + "; " + settings!.stringForKey(settingsToken2Name)! + "=" + settings!.stringForKey(settingsToken2)!
            ]
            
            // Connecting to the API to create the new folder
            logger.debug("Attempting to create the new folder")
            Alamofire.request(.POST, settings!.stringForKey(settingsHAPServer)! + "/api/myfiles/new/" + fullNewFolderPath, headers: httpHeaders, encoding: .JSON)
                // Parsing the JSON response
                .responseJSON { response in switch response.result {
                case .Success:
                    logger.debug("Response from creating new folder: \(response.data)")
                    
                    // Logging the last successful contact to the HAP+
                    // API, to reset the session cookies. This is saved
                    // as a time since Unix epoch
                    logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                    settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                    
                    // Letting the callback know we have successfully logged in
                    callback(result: true)
                    
                case .Failure(let error):
                    logger.warning("Request failed with error: \(error)")
                    callback(result: false)
                    }
            }
        } else {
            logger.warning("The connection to the Internet has been lost")
            callback(result: false)
        }
    }
    
    /// Checks to see if the file item exists in the current folder
    /// before uploading a file or creating a folder
    ///
    /// As a user may attempt to upload a same named file item into
    /// the currently viewed folder, it needs to be checked if there
    /// is something currently there that matches the same name, and
    /// ask the user if it can be overwritten or should it be created
    /// as a new file item
    ///
    /// - note: Looking at the response from the HAP+ API calls to the
    ///         exists function <hapServer>/api/MyFiles/Exists/<path>
    ///         only the JSON values of "DateCreated", "Icon", "Location",
    ///         "Name", "Size" give different values for folders and
    ///         files, and for ones that exist or don't. It is decided
    ///         to check the value of "Name" to make sure if it's
    ///         null (doesn't exist) or not null (item exists)
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-beta
    /// - version: 1
    /// - date: 2016-01-25
    ///
    /// - parameter itemPath: Path to the file item that is currently
    ///                       being checked to see if it exists in the
    ///                       current folder already
    func itemExists(itemPath: String, callback:(result: Bool) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            logger.debug("Checking to see if a file item exists at: \(itemPath)")
            
            // Replacing the escaped slashes with a forward slash
            // from the current folder path
            var fileItemPath = itemPath.stringByReplacingOccurrencesOfString("\\\\", withString: "/")
            fileItemPath = fileItemPath.stringByReplacingOccurrencesOfString("\\", withString: "/")
            
            // Escaping any non-allowed URL characters - see: http://stackoverflow.com/a/24552028
            fileItemPath = fileItemPath.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            
            logger.debug("Checking to see if a file item exists at formatted path: \(fileItemPath)")
            
            // Setting the json http content type header, as the HAP+
            // API expects incomming messages in "xml" or "json"
            // As the user is logged in, we also need to send the
            // tokens that are collected from the login, so the HAP+
            // server knows which user has sent this request
            let httpHeaders = [
                "Content-Type": "application/json",
                "Cookie": "token=" + settings!.stringForKey(settingsToken1)! + "; " + settings!.stringForKey(settingsToken2Name)! + "=" + settings!.stringForKey(settingsToken2)!
            ]
            
            // Connecting to the API to log in the user with the credentials
            logger.debug("Attempting to check if the file item already exists")
            Alamofire.request(.GET, settings!.stringForKey(settingsHAPServer)! + "/api/myfiles/exists/" + fileItemPath, headers: httpHeaders, encoding: .JSON)
                // Parsing the JSON response
                // See: http://stackoverflow.com/a/33022923
                .responseJSON { response in switch response.result {
                case .Success(let JSON):
                    logger.verbose("Response JSON for file item existing: \(JSON)")
                    
                    // Logging the last successful contact to the HAP+
                    // API, to reset the session cookies. This is saved
                    // as a time since Unix epoch
                    logger.verbose("Updating last successful API access time to: \(NSDate().timeIntervalSince1970)")
                    settings!.setDouble(NSDate().timeIntervalSince1970, forKey: settingsLastAPIAccessTime)
                    
                    // Seeing if there is a valid name from the returned JSON
                    // The JSON returns "null" if the file item doesn't exist
                    // See: http://stackoverflow.com/a/24128720
                    let validFileItemName = JSON["Name"] as? String
                    logger.debug("API 'Name' response for checking if file exists: \(validFileItemName)")
                    if (validFileItemName == nil) {
                        // Letting the callback know that there isn't
                        // a file item in the current location, so any
                        // functions called after this can continue
                        logger.debug("File item doesn't currently exist in the current folder")
                        callback(result: false)
                    } else {
                        // A file item exists in the current folder with
                        // the same name as what is attempting to be
                        // uploaded or created, so any functions called
                        // after this need to be confirmed by the user
                        callback(result: true)
                    }
                    
                case .Failure(let error):
                    // There was a problem checking to see if there
                    // is a file item existing in the current folder
                    // so assume that there is to prevent any accidental
                    // overwriting of files
                    logger.warning("Request failed with error: \(error)")
                    callback(result: true)
                    }
            }
        } else {
            // There was a problem checking to see if there
            // is a file item existing in the current folder
            // so assume that there is to prevent any accidental
            // overwriting of files
            logger.warning("The connection to the Internet has been lost")
            callback(result: true)
        }
    }
    
    /// Checking to make sure that the file or folder name doesn't
    /// contain any names not allowed by Windows
    ///
    /// Apps allow you to name files whatever you want to, as they
    /// are not under the same restrictions as Windows. However, if
    /// one of these files is uploaded via HAP+, then the file will
    /// not be accessable to the user, meaning they may loose some
    /// of their work, which shouldn't happen
    ///
    /// The name of the file should be checked to make sure that it
    /// is not one of the invalid file names, and if so, append an
    /// underscore "_" to the end of it
    ///
    /// Since 0.6.0-aplha new folders can also be created via the app,
    /// and this function is also called to make sure that the name
    /// of the folder does also not contain any invalid characters
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 2
    /// - date: 2016-01-23
    ///
    /// - parameter fullName: The full name (and extension for files)
    ///                       that is going to be given to the HAP+
    ///                       server to create the resource
    /// - returns: The item name with reserved characters modified
    func formatInvalidName(fullName: String) -> String {
        // Making sure that the file name doesn't contain any reserved
        // names, which Windows forbids, meaning the file will be
        // inaccessable. See: https://msdn.microsoft.com/en-gb/library/windows/desktop/aa365247(v=vs.85).aspx#naming_conventions
        let reservedNames = ["CON","PRN","AUX","NUL",
            "COM1","COM2","COM3","COM4","COM5","COM6","COM7","COM8","COM9",
            "LPT1","LPT2","LPT3","LPT4","LPT5","LPT6","LPT7","LPT8","LPT9"]
        let reservedCharacters = ["<",">",":","\"","/","\\","|","?","*"]
        
        // Looping around the full name to check that there aren't
        // any reserved characters in the name. This should be done
        // before the file name is checked for reserved characters
        // as any part of the file or folder name should not contain
        // any reserved characters. Any reserved character that are
        // found are replaced with an underscore "_"
        var formattedFullName = fullName
        for reservedCharacter in reservedCharacters {
            formattedFullName = formattedFullName.stringByReplacingOccurrencesOfString(reservedCharacter, withString: "_")
        }
        
        // Invalid file names are in the format <reservedNames>.<ext>
        // but <anything><reservedNames><anything>.<ext> are allowed
        // so we only really need to check if fileName[0] is invalid
        var fileName = formattedFullName.componentsSeparatedByString(".")
        
        // Looping around each item in the reserved names array to see
        // if fileName[0] matches any of the items
        for reservedName in reservedNames {
            if (reservedName.lowercaseString == fileName[0].lowercaseString) {
                // An invalid file name has been found, so modify it to
                // contain an underscore at the end
                logger.warning("Reserved file name found: \(fullName)")
                fileName[0] = fileName[0] + "_"
            }
        }
        
        // Joining the file name array back up to pass it back to the
        // calling function
        return fileName.joinWithSeparator(".")
    }
}