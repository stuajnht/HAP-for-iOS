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
//  DocumentPickerViewController.swift
//  DocumentProvider
//

import UIKit
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

class DocumentPickerViewController: UIDocumentPickerExtensionViewController {

    @IBAction func openDocument(sender: AnyObject?) {
        let documentURL = self.documentStorageURL!.URLByAppendingPathComponent("Untitled.txt")
      
        // TODO: if you do not have a corresponding file provider, you must ensure that the URL returned here is backed by a file
        self.dismissGrantingAccessToURL(documentURL)
    }

    override func prepareForPresentationInMode(mode: UIDocumentPickerMode) {
        // TODO: present a view controller appropriate for picker mode here
        
        // Configuring the logger options
        logger.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, showDate: true, writeToFile: nil, fileLogLevel: .Debug)
        
        if let siteName = settings!.stringForKey(settingsSiteName) {
            logger.debug("HAP+ document provider opened for site: : \(siteName)")
        }
    }

}
