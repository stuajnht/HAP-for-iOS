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
//  HomeAccessPlusUITests.swift
//  HomeAccessPlusUITests
//

import XCTest

class HomeAccessPlusUITests: XCTestCase {
    
    // Setting the correct encoded values for the
    // HAP+ server, username and password for use
    // with the login tests. They're hex encoded
    // and reversed to obscure them
    let hapServerFull = "7061682F6B 752E6F632E 74686E6A61 7574732E70 61682F2F3A 7370747468"
    let hapServerPartial = "6B752E6F632E 74686E6A6175 74732E706168"
    let hapUsername = "736976 617274"
    let hapPassword = "58535732 7A617131"
    
    // Setting up the predicate to wait for an object
    // to be available before the test continues.
    // This is needed as asynchronous calls may take
    // some time, but the test will carry on straight
    // away without waiting long enough
    // See: http://stackoverflow.com/a/32228104
    let exists = NSPredicate(format: "exists == 1")
    let expectationsTimeout : NSTimeInterval = 30
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        // Resetting all of the settings for the app, so
        // that it starts in a 'clean' state
        // See: http://stackoverflow.com/a/33774166
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING_RESET_SETTINGS"]
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    
    //MARK: Helper functions
    
    /// Decoding the HAP+ server, username and password
    /// that are used for testing
    ///
    /// *** THIS IS NOT PASSWORD ENCRYPTION ***
    ///
    /// The encrypted strings are quite easilly decodable, as
    /// is shown by running this function. The point of it is
    /// to stop the password being shown in plain text to any
    /// bots that are scraping the web to find addresses and
    /// passwords, while being quickly decodable for the tests
    ///
    /// Most of this function is copied directly from the HAPi
    /// deleteFile function. It converts the reversed hex encoded
    /// string into normal text
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 1
    /// - date: 2016-01-31
    func decryptString(encryptedString: String) -> String {
        // Removing any characters from the string that shouldn't
        // be there, namely '<', '>' and ' '
        var formattedString = String(encryptedString)
        formattedString = formattedString.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        // Converting the hex string into Unicode values, to check
        // that the file item from the server has been successfully
        // deleted
        // See: http://stackoverflow.com/a/30795372
        var formattedStringCharacters = [Character]()
        
        for characterPosition in formattedString.characters {
            formattedStringCharacters.append(characterPosition)
        }
        
        // This version of Swift is different from the
        // hex to ascii example used above, so we need
        // to call a different function
        // See: http://stackoverflow.com/a/24372631
        let characterMap =  0.stride(to: formattedStringCharacters.count, by: 2).map{
            strtoul(String(formattedStringCharacters[$0 ..< $0+2]), nil, 16)
        }
        
        var decodedString = ""
        var characterMapPosition = 0
        
        while characterMapPosition < characterMap.count {
            decodedString.append(Character(UnicodeScalar(Int(characterMap[characterMapPosition]))))
            characterMapPosition++
        }
        
        // Reversing the string, just to obscure it a bit more
        decodedString = String(decodedString.characters.reverse())
        
        return decodedString
    }
    
    
    //MARK: LoginViewController Tests
    
    /// Checks to make sure that an alert is shown if there
    /// isn't any text in the login text fields
    ///
    /// If there isn't anything typed into any of the login
    /// view text fields, an alert is shown to the user
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 1
    /// - date: 2016-01-30
    func testUILoginViewControllerTextboxesValid() {
        let app = XCUIApplication()
        let scrollViewsQuery = app.scrollViews
        scrollViewsQuery.otherElements.buttons["Login"].tap()
        app.alerts["Incorrect Information"].collectionViews.buttons["OK"].tap()
    }
    
    /// Testing to make sure that an invalid HAP+ URL entered
    /// alerts the user
    ///
    /// If the user types something incorrect in the HAP+ URL
    /// then we need to let them know that there was a problem
    /// with it, and we couldn't connect to the HAP+ server
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 2
    /// - date: 2016-01-30
    func testLoginViewControllerInvalidURL() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        let enterServerTextField = elementsQuery.textFields["Enter HAP+ server address"]
        enterServerTextField.tap()
        enterServerTextField.typeText("hap.example.com")
        
        let enterUsernameTextField = elementsQuery.textFields["Enter username"]
        enterUsernameTextField.tap()
        enterUsernameTextField.typeText(decryptString(hapUsername))
        
        let enterPasswordSecureTextField = elementsQuery.secureTextFields["Enter password"]
        enterPasswordSecureTextField.tap()
        enterPasswordSecureTextField.typeText(decryptString(hapPassword))
        
        let loginButton = elementsQuery.buttons["Login"]
        loginButton.tap()
        
        // Pausing for a number of seconds to let the
        // checks take place, as they're asynchronous, and
        // the test would fail otherwise
        let invalidAddressAlert = app.alerts["Invalid HAP+ Address"]
        expectationForPredicate(exists, evaluatedWithObject: invalidAddressAlert, handler: nil)
        waitForExpectationsWithTimeout(expectationsTimeout, handler: nil)
        
        invalidAddressAlert.collectionViews.buttons["OK"].tap()
    }
    
    /// Testing to make sure that an invalid username entered
    /// alerts the user
    ///
    /// If the user types something incorrect in the username
    /// then we need to let them know that there was a problem
    /// with it, and we couldn't log in to the HAP+ server
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 1
    /// - date: 2016-01-30
    func testLoginViewControllerInvalidUsername() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        let enterServerTextField = elementsQuery.textFields["Enter HAP+ server address"]
        enterServerTextField.tap()
        enterServerTextField.typeText(decryptString(hapServerFull))
        
        let enterUsernameTextField = elementsQuery.textFields["Enter username"]
        enterUsernameTextField.tap()
        enterUsernameTextField.typeText("incorrect")
        
        let enterPasswordSecureTextField = elementsQuery.secureTextFields["Enter password"]
        enterPasswordSecureTextField.tap()
        enterPasswordSecureTextField.typeText(decryptString(hapPassword))
        
        let loginButton = elementsQuery.buttons["Login"]
        loginButton.tap()
        
        // Pausing for a number of seconds to let the
        // checks take place, as they're asynchronous, and
        // the test would fail otherwise
        let invalidUsernameAlert = app.alerts["Invalid Username or Password"]
        expectationForPredicate(exists, evaluatedWithObject: invalidUsernameAlert, handler: nil)
        waitForExpectationsWithTimeout(expectationsTimeout, handler: nil)
        
        invalidUsernameAlert.collectionViews.buttons["OK"].tap()
    }
    
    /// Testing to make sure that an invalid password entered
    /// alerts the user
    ///
    /// If the user types something incorrect in the password
    /// then we need to let them know that there was a problem
    /// with it, and we couldn't log in to the HAP+ server
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 1
    /// - date: 2016-01-30
    func testLoginViewControllerInvalidPassword() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        let enterServerTextField = elementsQuery.textFields["Enter HAP+ server address"]
        enterServerTextField.tap()
        enterServerTextField.typeText(decryptString(hapServerFull))
        
        let enterUsernameTextField = elementsQuery.textFields["Enter username"]
        enterUsernameTextField.tap()
        enterUsernameTextField.typeText(decryptString(hapUsername))
        
        let enterPasswordSecureTextField = elementsQuery.secureTextFields["Enter password"]
        enterPasswordSecureTextField.tap()
        enterPasswordSecureTextField.typeText("incorrect")
        
        let loginButton = elementsQuery.buttons["Login"]
        loginButton.tap()
        
        // Pausing for a number of seconds to let the
        // checks take place, as they're asynchronous, and
        // the test would fail otherwise
        let invalidPasswordAlert = app.alerts["Invalid Username or Password"]
        expectationForPredicate(exists, evaluatedWithObject: invalidPasswordAlert, handler: nil)
        waitForExpectationsWithTimeout(expectationsTimeout, handler: nil)
        
        invalidPasswordAlert.collectionViews.buttons["OK"].tap()
    }
    
    /// Performs a login to the HAP+ server using the partial
    /// HAP+ server address
    ///
    /// A partial address to the HAP+ server is given and an
    /// attempt to login with the username and password takes
    /// place. The address should be formatted to the full
    /// address too
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 1
    /// - date: 2016-01-31
    func testLoginViewControllerSuccessfulPartialURLLogin() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        let enterServerTextField = elementsQuery.textFields["Enter HAP+ server address"]
        enterServerTextField.tap()
        enterServerTextField.typeText(decryptString(hapServerPartial))
        
        let enterUsernameTextField = elementsQuery.textFields["Enter username"]
        enterUsernameTextField.tap()
        enterUsernameTextField.typeText(decryptString(hapUsername))
        
        let enterPasswordSecureTextField = elementsQuery.secureTextFields["Enter password"]
        enterPasswordSecureTextField.tap()
        enterPasswordSecureTextField.typeText(decryptString(hapPassword))
        
        let loginButton = elementsQuery.buttons["Login"]
        loginButton.tap()
        
        // The login is successful if the alert asking for
        // the device type is presented
        let deviceTypeAlert = app.alerts["Please Select Device Type"]
        expectationForPredicate(exists, evaluatedWithObject: deviceTypeAlert, handler: nil)
        waitForExpectationsWithTimeout(expectationsTimeout, handler: nil)
    }
    
    /// Performs a login to the HAP+ server using the full
    /// HAP+ server address
    ///
    /// A full address to the HAP+ server is given and an
    /// attempt to login with the username and password takes
    /// place.
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 1
    /// - date: 2016-01-31
    func testLoginViewControllerSuccessfulFullURLLogin() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        let enterServerTextField = elementsQuery.textFields["Enter HAP+ server address"]
        enterServerTextField.tap()
        enterServerTextField.typeText(decryptString(hapServerFull))
        
        let enterUsernameTextField = elementsQuery.textFields["Enter username"]
        enterUsernameTextField.tap()
        enterUsernameTextField.typeText(decryptString(hapUsername))
        
        let enterPasswordSecureTextField = elementsQuery.secureTextFields["Enter password"]
        enterPasswordSecureTextField.tap()
        enterPasswordSecureTextField.typeText(decryptString(hapPassword))
        
        let loginButton = elementsQuery.buttons["Login"]
        loginButton.tap()
        
        // The login is successful if the alert asking for
        // the device type is presented
        let deviceTypeAlert = app.alerts["Please Select Device Type"]
        expectationForPredicate(exists, evaluatedWithObject: deviceTypeAlert, handler: nil)
        waitForExpectationsWithTimeout(expectationsTimeout, handler: nil)
        deviceTypeAlert.collectionViews.buttons["Personal"].tap()
    }

    
}
