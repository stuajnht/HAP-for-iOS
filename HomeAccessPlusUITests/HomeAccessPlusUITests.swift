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
    let hapServerFull = "7061682F6B 752E6F632E 657367732E 7061682F2F 3A7370747468"
    let hapServerPartial = "6B752E6F63 2E65736773 2E706168"
    let hapUsername = "736976 617274"
    let hapPassword = "58535732 7A617131"
    
    // Setting the correct username value for the
    // authenticated user who is allowed to log the
    // user out when the device is in "single" mode
    // Note: For some reason, this string cannot be
    //       reversed, as it decodes to the incorrect:
    //       4757f6d276f6c6d237f696d2071686 -> GWöÒvöÆÒ7ö–Ò†
    let logOutAuthenticatedUsername = "6861702D69 6F732D6C6F 672D6F7574"
    
    // Setting up the predicate to wait for an object
    // to be available before the test continues.
    // This is needed as asynchronous calls may take
    // some time, but the test will carry on straight
    // away without waiting long enough
    // See: http://stackoverflow.com/a/32228104
    let exists = NSPredicate(format: "exists == 1")
    let expectationsTimeout : TimeInterval = 30
        
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
    func decryptString(_ encryptedString: String) -> String {
        // Removing any characters from the string that shouldn't
        // be there, namely '<', '>' and ' '
        var formattedString = String(encryptedString)
        formattedString = formattedString?.replacingOccurrences(of: " ", with: "")
        
        // Converting the hex string into Unicode values, to check
        // that the file item from the server has been successfully
        // deleted
        // See: http://stackoverflow.com/a/30795372
        var formattedStringCharacters = [Character]()
        
        for characterPosition in (formattedString?.characters)! {
            formattedStringCharacters.append(characterPosition)
        }
        
        // This version of Swift is different from the
        // hex to ascii example used above, so we need
        // to call a different function
        // See: http://stackoverflow.com/a/24372631
        let characterMap =  stride(from: 0, to: formattedStringCharacters.count, by: 2).map{
            strtoul(String(formattedStringCharacters[$0 ..< $0+2]), nil, 16)
        }
        
        var decodedString = ""
        var characterMapPosition = 0
        
        while characterMapPosition < characterMap.count {
            decodedString.append(Character(UnicodeScalar(Int(characterMap[characterMapPosition]))!))
            characterMapPosition = (characterMapPosition + 1)
        }
        
        // Reversing the string, just to obscure it a bit more
        decodedString = String(decodedString.characters.reversed())
        
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
    func testUILoginViewControllerInvalidTextboxes() {
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
        expectation(for: exists, evaluatedWith: invalidAddressAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        
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
        expectation(for: exists, evaluatedWith: invalidUsernameAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        
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
        expectation(for: exists, evaluatedWith: invalidPasswordAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        
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
        expectation(for: exists, evaluatedWith: deviceTypeAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
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
        expectation(for: exists, evaluatedWith: deviceTypeAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
    }
    
    /// Sets the device into "personal" mode once a successful
    /// log in has taken place
    ///
    /// To preform the login the testLoginViewControllerSuccessfulFullURLLogin
    /// function is called
    ///
    /// - note: This function can be used in other functions to
    ///         assist with logon attempts which requre the
    ///         device to be set up in "personal" mode
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSuccessfulFullURLLogin
    func testLoginViewControllerSetDeviceInPersonalMode() {
        testLoginViewControllerSuccessfulFullURLLogin()
        
        let app = XCUIApplication()
        
        // Setting the device into "personal" mode
        let deviceTypeAlert = app.alerts["Please Select Device Type"]
        expectation(for: exists, evaluatedWith: deviceTypeAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        deviceTypeAlert.collectionViews.buttons["Personal"].tap()
    }
    
    /// Sets the device into "shared" mode once a successful
    /// log in has taken place
    ///
    /// To preform the login the testLoginViewControllerSuccessfulFullURLLogin
    /// function is called
    ///
    /// - note: This function can be used in other functions to
    ///         assist with logon attempts which requre the
    ///         device to be set up in "shared" mode
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSuccessfulFullURLLogin
    func testLoginViewControllerSetDeviceInSharedMode() {
        testLoginViewControllerSuccessfulFullURLLogin()
        
        let app = XCUIApplication()
        
        // Setting the device into "shared" mode
        let deviceTypeAlert = app.alerts["Please Select Device Type"]
        expectation(for: exists, evaluatedWith: deviceTypeAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        deviceTypeAlert.collectionViews.buttons["Shared"].tap()
    }
    
    /// Sets the device into "single" mode once a successful
    /// log in has taken place
    ///
    /// To preform the login the testLoginViewControllerSuccessfulFullURLLogin
    /// function is called
    ///
    /// - note: This function can be used in other functions to
    ///         assist with logon attempts which requre the
    ///         device to be set up in "single" mode
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSuccessfulFullURLLogin
    func testLoginViewControllerSetDeviceInSingleMode() {
        testLoginViewControllerSuccessfulFullURLLogin()
        
        let app = XCUIApplication()
        
        // Setting the device into "single" mode
        let deviceTypeAlert = app.alerts["Please Select Device Type"]
        expectation(for: exists, evaluatedWith: deviceTypeAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        deviceTypeAlert.collectionViews.buttons["Single"].tap()
    }
    
    
    //MARK: MasterViewController Tests
    
    /// Browsing though a pre-defined list of folders and use
    /// of the navigation 'back' button
    ///
    /// One of the main functions of the HAP+ app is to browse
    /// through folders and drives on the network. This function
    /// looks after browsing through a number of drives on the
    /// HAP+ server
    ///
    /// To preform the login the testLoginViewControllerSetDeviceInPersonalMode
    /// function is called
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 2
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSetDeviceInPersonalMode
    func testMasterViewControllerBrowseDrive() {
        testLoginViewControllerSetDeviceInPersonalMode()
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        
        let drive = tablesQuery.staticTexts["H: Drive"]
        expectation(for: exists, evaluatedWith: drive, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        drive.tap()
    }
    
    //MARK: UploadPopoverViewController Tests
    
    /// Tests to see if the device can be logged successfully
    /// out when set up in "personal" mode
    ///
    /// When the app is set up in "personal" mode, the user is
    /// able to log out at any time from the upload popover
    ///
    /// To preform the login the testLoginViewControllerSetDeviceInPersonalMode
    /// function is called
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSetDeviceInPersonalMode
    func testUploadPopoverViewControllerLogOutPersonalMode() {
        testLoginViewControllerSetDeviceInPersonalMode()
        
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        let loginButton = elementsQuery.buttons["Login"]
        let okButton = app.alerts["Incorrect Information"].collectionViews.buttons["OK"]
        
        // Opening the upload popover
        app.navigationBars["My Drives"].children(matching: .button).element(boundBy: 1).tap()
        
        // Logging out the user
        app.tables.staticTexts["Log Out"].tap()
        
        // We can check that we're on the login screen by the
        // presense of the login button
        loginButton.tap()
        okButton.tap()
    }
    
    /// Tests to see if the device can be logged successfully
    /// out when set up in "shared" mode
    ///
    /// When the app is set up in "shared" mode, the user is
    /// able to log out at any time from the upload popover
    ///
    /// To preform the login the testLoginViewControllerSetDeviceInSharedMode
    /// function is called
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSetDeviceInSharedMode
    func testUploadPopoverViewControllerLogOutSharedMode() {
        testLoginViewControllerSetDeviceInSharedMode()
        
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        let loginButton = elementsQuery.buttons["Login"]
        let okButton = app.alerts["Incorrect Information"].collectionViews.buttons["OK"]
        
        // Opening the upload popover
        app.navigationBars["My Drives"].children(matching: .button).element(boundBy: 1).tap()
        
        // Logging out the user
        app.tables.staticTexts["Log Out"].tap()
        
        // We can check that we're on the login screen by the
        // presense of the login button
        loginButton.tap()
        okButton.tap()
    }
    
    /// Tests to see if the alert is shown to the user when
    /// trying to log out when set up in "single" mode, and the
    /// user pressing cancel should keep the upload popover in
    /// place
    ///
    /// When the app is set up in "single" mode, the user is
    /// prompted to type a authenticated username to log them
    /// out of the device, presented in an alert
    ///
    /// To preform the login the testLoginViewControllerSetDeviceInSingleMode
    /// function is called
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSetDeviceInSingleMode
    func testUploadPopoverViewControllerLogOutSingleModeUsernameCancel() {
        testLoginViewControllerSetDeviceInSingleMode()
        
        let app = XCUIApplication()
        
        // Opening the upload popover
        app.navigationBars["My Drives"].children(matching: .button).element(boundBy: 1).tap()
        
        let logOutStaticText = app.tables.staticTexts["Log Out"]
        logOutStaticText.tap()
        
        // In the alert that is shown to the user, pressing the
        // "cancel" button should keep the upload popover in place.
        // This can be checked by pressing the "log out" button again
        let cancelButton = app.alerts["Log Out User"].collectionViews.buttons["Cancel"]
        cancelButton.tap()
        logOutStaticText.tap()
        cancelButton.tap()
    }
    
    /// Tests to see if the alert is shown to the user when
    /// trying to log out when set up in "single" mode, and the
    /// user typing an incorrect password should alert the user
    /// that they weren't able to be logged out
    ///
    /// When the app is set up in "single" mode, the user is
    /// prompted to type a authenticated username to log them
    /// out of the device, presented in an alert
    ///
    /// To preform the login the testLoginViewControllerSetDeviceInSingleMode
    /// function is called
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSetDeviceInSingleMode
    func testUploadPopoverViewControllerLogOutSingleModeUsernameIncorrect() {
        testLoginViewControllerSetDeviceInSingleMode()
        
        let app = XCUIApplication()
        
        // Opening the upload popover
        app.navigationBars["My Drives"].children(matching: .button).element(boundBy: 1).tap()
        
        let logOutStaticText = app.tables.staticTexts["Log Out"]
        logOutStaticText.tap()
        
        // Typing in an incorrect authenticated username should
        // alert the user that it was not correct, and they haven't
        // been logged out
        let collectionViewsQuery = app.alerts["Log Out User"].collectionViews
        collectionViewsQuery.textFields["Username"].typeText("incorrect")
        collectionViewsQuery.buttons["Continue"].tap()
        
        // As the HAPi needs to be used to check the username, wait
        // for the alert to be shown to the user
        let logOutAlert = app.alerts["Unable to Log Out"]
        expectation(for: exists, evaluatedWith: logOutAlert, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        logOutAlert.collectionViews.buttons["OK"].tap()
    }
    
    /// Tests to see if the alert is shown to the user when
    /// trying to log out when set up in "single" mode, and the
    /// user typing a correct password should log the user out
    ///
    /// When the app is set up in "single" mode, the user is
    /// prompted to type a authenticated username to log them
    /// out of the device, presented in an alert
    ///
    /// To preform the login the testLoginViewControllerSetDeviceInSingleMode
    /// function is called
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 1
    /// - date: 2016-03-12
    ///
    /// - seealso: testLoginViewControllerSetDeviceInSingleMode
    func testUploadPopoverViewControllerLogOutSingleModeUsernameCorrect() {
        testLoginViewControllerSetDeviceInSingleMode()
        
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        let loginButton = elementsQuery.buttons["Login"]
        let okButton = app.alerts["Incorrect Information"].collectionViews.buttons["OK"]
        
        // Opening the upload popover
        app.navigationBars["My Drives"].children(matching: .button).element(boundBy: 1).tap()
        
        let logOutStaticText = app.tables.staticTexts["Log Out"]
        logOutStaticText.tap()
        
        // Decoding the decrypted string, then reversing it as the
        // decryptString function will correctly reverse it, but
        // for some reason the initial string cannot be reversed
        var correctUsername = decryptString(logOutAuthenticatedUsername)
        correctUsername = String(correctUsername.characters.reversed())
        
        // Typing in a correct authenticated username should
        // log the user out and take them back to the login view
        let collectionViewsQuery = app.alerts["Log Out User"].collectionViews
        collectionViewsQuery.textFields["Username"].typeText(correctUsername)
        collectionViewsQuery.buttons["Continue"].tap()
        
        // As the HAPi needs to be used to check the username, wait
        // for the login view to be shown to the user, then try logging
        // in with empty fields
        expectation(for: exists, evaluatedWith: loginButton, handler: nil)
        waitForExpectations(timeout: expectationsTimeout, handler: nil)
        loginButton.tap()
        okButton.tap()
    }

    
}
