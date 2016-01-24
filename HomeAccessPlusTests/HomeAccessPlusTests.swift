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
//  HomeAccessPlusTests.swift
//  HomeAccessPlusTests
//

import XCTest
@testable import HomeAccessPlus

class HomeAccessPlusTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    /// Testing the MasterViewController isFile function
    /// returns the correct value based on what is passed
    func testMasterViewControllerIsFile() {
        // Loading an instance of the master view controller
        let mvc = MasterViewController()
        
        // An empty string
        XCTAssertFalse(mvc.isFile(""), "An empty string should return false for being a file")
        
        // A drive with a letter
        XCTAssertFalse(mvc.isFile("H: Drive"), "A drive with a letter should return flase for being a file")
        
        // A drive without a letter
        XCTAssertFalse(mvc.isFile("Drive"), "A drive without a letter should return false for being a file")
        
        // A directory from the file browser
        XCTAssertFalse(mvc.isFile("Directory"), "A directory should return false for being a file")
        
        // A known file type
        XCTAssertTrue(mvc.isFile("JPEG Image"), "A known file type should return true for being a file")
        
        // A unknown file type
        XCTAssertTrue(mvc.isFile("File"), "An unknown file type should return true for being a file")
    }
    
    /// Testing the HAPi formatting of invalid file and
    /// folder names completes successfully
    func testHAPiFormatInvalidFileName() {
        // Loading an instance of the HAPi
        let api = HAPi()
        
        // A valid file name
        let validFileName = "Hello world.txt"
        XCTAssert(api.formatInvalidName(validFileName) == validFileName, validFileName + " contains no invalid characters, so shouldn't be formatted")
        
        // A valid file name less extention
        let validFileNameLessExtension = "Hello world"
        XCTAssert(api.formatInvalidName(validFileNameLessExtension) == validFileNameLessExtension, validFileNameLessExtension + " contains no invalid characters, so shouldn't be formatted")
        
        // An invalid file name
        let invalidFileName = "CON.txt"
        XCTAssert(api.formatInvalidName(invalidFileName) == "CON_.txt", invalidFileName + " should have an underscore before the file extention")
        
        // An invalid file name less extention
        let invalidFileNameLessExtention = "CON"
        XCTAssert(api.formatInvalidName(invalidFileNameLessExtention) == "CON_", invalidFileNameLessExtention + " should have an underscore after the file name")
        
        // A valid file name that begins with a forbidden name
        let validFileNameWithForbiddenString = "Console.txt"
        XCTAssert(api.formatInvalidName(validFileNameWithForbiddenString) == validFileNameWithForbiddenString, validFileNameWithForbiddenString + " contains no invalid characters, so shouldn't be formatted")
        
        // A valid folder name
        let validFolderName = "My folder"
        XCTAssert(api.formatInvalidName(validFolderName) == validFolderName, validFolderName + " contains no invalid characters, so shouldn't be formatted")
        
        // An invalid folder name
        let invalidFolderName = "My*folder"
        XCTAssert(api.formatInvalidName(invalidFolderName) == "My_folder", invalidFolderName + " should have an underscore between 'My' and 'folder'")
    }
    
}
