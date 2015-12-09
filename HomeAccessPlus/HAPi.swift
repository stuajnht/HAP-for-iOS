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
                case.Success(let result):
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
                case .Failure(let error):
                    logger.warning("Connection to API failed with error: \(error)")
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
}