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
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

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
    /// - version: 1
    /// - date: 2016-01-30
    func testLoginViewControllerInvalidURL() {
        let app = XCUIApplication()
        let elementsQuery = app.scrollViews.otherElements
        
        let enterServerTextField = elementsQuery.textFields["Enter HAP+ server address"]
        enterServerTextField.tap()
        enterServerTextField.typeText("https://hap.example.com")
        
        let enterUsernameTextField = elementsQuery.textFields["Enter username"]
        enterUsernameTextField.tap()
        enterUsernameTextField.typeText("teststudent")
        
        let enterPasswordSecureTextField = elementsQuery.secureTextFields["Enter password"]
        enterPasswordSecureTextField.tap()
        enterPasswordSecureTextField.typeText("123456")
        
        let loginButton = elementsQuery.buttons["Login"]
        loginButton.tap()
        
        // Pausing for a number of seconds to let the
        // checks take place, as they're asynchronous, and
        // the test would fail otherwise
        let exists = NSPredicate(format: "exists == 1")
        let alert = app.alerts["Invalid HAP+ Address"]
        expectationForPredicate(exists, evaluatedWithObject: alert, handler: nil)
        waitForExpectationsWithTimeout(20, handler: nil)
        
        alert.collectionViews.buttons["OK"].tap()
    }
    
}
