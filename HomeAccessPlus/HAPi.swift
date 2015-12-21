// Home Access Plus+ for iOS - A native app to access a HAP+ server
// Copyright (C) 2015  Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
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
    /// - version: 1
    /// - date: 2015-12-07
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
                            settings.setObject(siteName, forKey: settingsSiteName)
                            settings.setObject(JSON["FirstName"], forKey: settingsFirstName)
                            settings.setObject(JSON["Username"], forKey: settingsUsername)
                            settings.setObject(JSON["Token1"], forKey: settingsToken1)
                            settings.setObject(JSON["Token2"], forKey: settingsToken2)
                            settings.setObject(JSON["Token2Name"], forKey: settingsToken2Name)
                            
                            // Saving the password for future logon attempts
                            // and for when the logon tokens expire
                            do {
                                try Locksmith.updateData([settingsPassword: password], forUserAccount: settings.stringForKey(settingsUsername)!)
                                logger.debug("Securely saved user password")
                            } catch {
                                logger.error("Failed to securely save password")
                            }
                            
                            // Setting the groups the user is part of
                            self.setRoles({ (result: Bool) -> Void in
                                if (result) {
                                    logger.info("Successfully set the roles for \(settings.stringForKey(settingsUsername)!)")
                                    logger.debug("Roles for \(settings.stringForKey(settingsUsername)!): \(settings.stringForKey(settingsUserRoles)!)")
                                } else {
                                    logger.warning("Failed to set the roles for \(settings.stringForKey(settingsUsername)!)")
                                }
                            })
                            
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
        Alamofire.request(.GET, settings.stringForKey(settingsHAPServer)! + "/api/ad/roles/" + settings.stringForKey(settingsUsername)!)
            .responseString { response in switch response.result {
                // Seeing if there is a successful contact from the HAP+
                // server, so as to not try and get a value from a variable
                // that is never set
            case.Success(_):
                logger.verbose("Successful contact of server: \(response.result.isSuccess)")
                logger.verbose("\(settings.stringForKey(settingsUsername)!) is a member of the following groups: \(response.result.value)")
                // Saving the groups the user is part of
                settings.setObject(response.result.value, forKey: settingsUserRoles)
                callback(true)
                
                // We were not able to contact the HAP+ server, so we cannot
                // put the user into any groups
            case .Failure(let error):
                logger.verbose("Connection to API failed with error: \(error)")
                // Creating an empty escaped string -- [""] -- so that the setting
                /// value exists and is over-written from a previous logged on user
                settings.setObject("[\"\"]", forKey: settingsUserRoles)
                callback(false)
                }
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
                "Cookie": "token=" + settings.stringForKey(settingsToken1)! + "; " + settings.stringForKey(settingsToken2Name)! + "=" + settings.stringForKey(settingsToken2)!
            ]
            
            // Connecting to the API to get the drive listing
            logger.debug("Attempting to get drives available")
            Alamofire.request(.GET, settings.stringForKey(settingsHAPServer)! + "/api/myfiles/Drives", headers: httpHeaders, encoding: .JSON)
                // Parsing the JSON response
                .responseJSON { response in switch response.result {
                    case .Success(let JSON):
                        logger.verbose("Response JSON for drive listing: \(JSON)")
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
                "Cookie": "token=" + settings.stringForKey(settingsToken1)! + "; " + settings.stringForKey(settingsToken2Name)! + "=" + settings.stringForKey(settingsToken2)!
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
            Alamofire.request(.GET, settings.stringForKey(settingsHAPServer)! + "/api/myfiles/" + formattedPath, headers: httpHeaders, encoding: .JSON)
                // Parsing the JSON response
                .responseJSON { response in switch response.result {
                case .Success(let JSON):
                    logger.verbose("Response JSON for folder listing: \(JSON)")
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
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.4.0-alpha
    /// - version: 1
    /// - date: 2015-12-19
    ///
    /// - parameter fileLocation: The path to the file the user has selected
    func downloadFile(fileLocation: String, callback:(result: Bool, response: AnyObject, downloadLocation: String) -> Void) -> Void {
        // Checking that we still have a connection to the Internet
        if (checkConnection()) {
            // Setting the json http content type header, as the HAP+
            // API expects incomming messages in "xml" or "json"
            // As the user is logged in, we also need to send the
            // tokens that are collected from the login, so the HAP+
            // server knows which user has sent this request
            let httpHeaders = [
                "Content-Type": "application/json",
                "Cookie": settings.stringForKey(settingsToken2Name)! + "=" + settings.stringForKey(settingsToken2)! + "; token=" + settings.stringForKey(settingsToken1)!
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
            
            // Download file here!
            
        } else {
            logger.warning("The connection to the Internet has been lost")
            callback(result: false, response: "", downloadLocation: "")
        }
    }
}