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
//  UploadPopoverTableViewController.swift
//  HomeAccessPlus
//

import DKImagePickerController
import MobileCoreServices
import PermissionScope
import UIKit
import Zip

/// Delegate callback to master view controller to upload the
/// file passed to this app, or to log out the user
///
/// Using delegate callbacks to allow the file to be uploaded
/// based on the user pressing the 'upload file' cell
/// See: http://stackoverflow.com/a/29399294
/// See: http://stackoverflow.com/a/30596358
///
/// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
/// - since: 0.5.0-beta
/// - version: 4
/// - date: 2016-05-14
protocol uploadFileDelegate {
    // This calls the uploadFile function in the master view
    // controller
    func uploadFile(_ fileFromPhotoLibrary: Bool, customFileName: String, fileExistsCallback:@escaping (_ fileExists: Bool) -> Void)
    
    // This calls the newFolder function in the master view
    // controller
    func newFolder(_ folderName: String)
    
    // This calls the showFileExistsMessage function to see
    // if the user needs to confirm what to do with a file
    // that already exists in the current folder
    func showFileExistsMessage(_ fileFromPhotoLibrary: Bool)
    
    // This calls the logOutUser function to destroy any login
    // tokens and stored settings, and pop all views back to the
    // root view controller (login view)
    // See: http://stackoverflow.com/a/16825683
    func logOutUser()
    
    // This uploads multipe files from the device, selected
    // when the multi picker is in use
    func uploadMultipleFiles(_ uploadFileLocations: NSArray)
}

class UploadPopoverTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIDocumentPickerDelegate {

    @IBOutlet weak var lblUploadPhoto: UILabel!
    @IBOutlet weak var celUploadPhoto: UITableViewCell!
    @IBOutlet weak var lblUploadVideo: UILabel!
    @IBOutlet weak var celUploadVideo: UITableViewCell!
    @IBOutlet weak var lblUploadCloud: UILabel!
    @IBOutlet weak var celUploadCloud: UITableViewCell!
    @IBOutlet weak var lblUploadFile: UILabel!
    @IBOutlet weak var celUploadFile: UITableViewCell!
    @IBOutlet weak var lblNewFolder: UILabel!
    @IBOutlet weak var celNewFolder: UITableViewCell!
    @IBOutlet weak var lblTakePhoto: UILabel!
    @IBOutlet weak var celTakePhoto: UITableViewCell!
    @IBOutlet weak var lblLogOut: UILabel!
    @IBOutlet weak var celSaveLogFiles: UITableViewCell!
    @IBOutlet weak var lblSaveLogFiles: UILabel!
    
    // Creating an instance of an image picker controller
    // See: http://www.codingexplorer.com/choosing-images-with-uiimagepickercontroller-in-swift/
    let imagePicker = UIImagePickerController()
    
    // Creating a reference to the upload file delegate
    var delegate: uploadFileDelegate?
    
    // Creating an instance of the PermissionScope, so
    // that we can ask the user for access to the photos
    // library, and a separate instance to ask for access
    // to the camera and microphone
    let pscopePhotos = PermissionScope()
    let pscopeCamera = PermissionScope()
    
    // Holding a reference to see if the popover is being
    // shown on the file browser "My Drives" view, so that
    // it can be used to disable access to most table cells
    var showingOnEmptyFilePath = false
    
    // Used to hold a string of if the alert being shown to
    // the user is to create a new folder or to prompt for a
    // username of an authenticated user to log them out with
    // This variable is set when a user selects a table cell,
    // and is read when the "Continue" button is pressed on the
    // keyboard
    // - seealso: textFieldShouldReturn
    // - seealso: tableView:didSelectRowAtIndexPath
    var alertMode = ""
    
    // Holding a reference to the currently selected table
    // row, so that if the user cancels the image picker,
    // it can be deselected
    var currentlySelectedRow : IndexPath?
    
    /// Array to hold the number of table sections and rows
    /// shown in the popover
    ///
    /// This nested array should hold the names of the table
    /// sections, along with the number of rows in that section.
    /// When numberOfSectionsInTableView is called, it uses this
    /// array to generate the correct number of rows to display
    ///
    /// If there are any additional sections or rows added to
    /// the table, then this array needs to also be updated to
    /// allow them to be shown to the user
    let tableSections : [[String]] = [["Upload", "4"], ["Create", "2"], ["LogOut", "1"], ["Debug", "1"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Setting the upload file label to display the name of the
        // file passed to the app, if any, and disabling the user
        // from pressing on the file upload cell if there isn't a file
        // to upload from another app
        if (settings!.string(forKey: settingsUploadFileLocation) != nil) {
            celUploadFile.isUserInteractionEnabled = true
            lblUploadFile.isEnabled = true
            lblUploadFile.text = "Upload \"" + getFileName() + "\""
        } else {
            celUploadFile.isUserInteractionEnabled = false
            lblUploadFile.isEnabled = false
            lblUploadFile.text = "Upload file"
        }
        
        // Disabling most of the table cells from the view controller,
        // as the popover has been shown on the "My Drives" view,
        // so most of the options should not be available as they
        // wouldn't work
        // Note: This happens after updating the file name that has
        //       been passed to this app, otherwise it'll enable
        //       one of the cells again, which isn't correct
        if (showingOnEmptyFilePath) {
            lblUploadPhoto.isEnabled = false
            celUploadPhoto.isUserInteractionEnabled = false
            lblUploadVideo.isEnabled = false
            celUploadVideo.isUserInteractionEnabled = false
            lblUploadCloud.isEnabled = false
            celUploadCloud.isUserInteractionEnabled = false
            lblUploadFile.isEnabled = false
            celUploadFile.isUserInteractionEnabled = false
            lblNewFolder.isEnabled = false
            celNewFolder.isUserInteractionEnabled = false
            lblTakePhoto.isEnabled = false
            celTakePhoto.isUserInteractionEnabled = false
            lblSaveLogFiles.isEnabled = false
            celSaveLogFiles.isUserInteractionEnabled = false
        }
        
        // Changing the colour of the log out button to be a red
        // colour, to alert the user it's a 'dangerous' action. It's
        // done in code so that we can use the ChameleonFramework
        // colours, and not the built in Xcode ones
        lblLogOut.textColor = UIColor.flatRed()
        
        // Creating a delegate for the image picker
        imagePicker.delegate = self
        
        // Setting the image picker to show inside the popover
        // and not full screen on large screen devices
        // See: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImagePickerController_Class/
        imagePicker.modalPresentationStyle = .currentContext
        
        // Setting up the permissions needed to access the
        // photos library, camera and the microphone on the device
        pscopePhotos.addPermission(PhotosPermission(), message: "Enable this to upload\r\nyour photos and videos")
        pscopeCamera.addPermission(CameraPermission(), message: "Enable this to take\r\nphotos and videos in-app")
        pscopeCamera.addPermission(MicrophonePermission(), message: "Enable this to use the\r\nmicrophone when recording videos")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Formatting the image picker navigation bar so the colours
        // are the same as the rest of the app, but only if this view
        // controller is inside a modal view, and not a popover
        // See: http://stackoverflow.com/a/31656088
        let popoverPresentationController = self.parent?.popoverPresentationController
        if (UIPopoverArrowDirection.unknown == popoverPresentationController?.arrowDirection) {
            logger.verbose("Current view is inside a modal window, so formatting image picker navigation bar colours")
            // See: http://stackoverflow.com/a/32011882
            imagePicker.navigationBar.barTintColor = UIColor(hexString: hapMainColour)
            imagePicker.navigationBar.tintColor = UIColor.flatWhite()
            imagePicker.navigationBar.isTranslucent = false
            imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.flatWhite()]
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Returning the number of sections that are in the table,
        // unless file logging isn't enabled, when we return 1 less
        // to hide the section (as it's at the end of the table)
        // - seealso: tableView
        var sectionsInTable = self.tableSections.count
        
        if (!settings!.bool(forKey: settingsFileLoggingEnabled)) {
            logger.debug("File logging is not enabled, so returning one less table section")
            sectionsInTable -= 1
        }
        
        logger.verbose("Number of sections in upload popover: \(sectionsInTable)")
        return sectionsInTable
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Returning the number of rows in the current table section
        // - seealso: tableView
        logger.verbose("Number of rows in table section \(section): \(Int(self.tableSections[section][1])!)")
        return Int(tableSections[section][1])!
    }
    
    /// Adding user log in details to the 'Log Out' section footer,
    /// to help identify which user is currently logged in to the app
    ///
    /// As it's diffucult to know who is currently logged in to the app,
    /// a message is appended to the footer of the 'Log Out' section so
    /// that if someone picks up a logged in device, they can see if it
    /// is them or another user who is currently logged in. It is also
    /// useful to see who has not logged out of the device when they should
    /// See: http://www.adventuresofanentrepreneur.net/creating-a-mobile-appsgames-company/headers-and-footers-in-ios-tableview
    /// See: http://www.ioscreator.com/tutorials/customizing-header-footer-table-view-ios8-swift
    ///
    /// - note: This uses the hard coded table sections that are defined
    ///         in the 'tableSections' array, and this function needs to
    ///         be udated according if there are any changes
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-beta
    /// - version: 3
    /// - date: 2016-04-09
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var footerMessage = ""
        
        switch (section) {
        case 0:
            footerMessage = "Upload a photo, video or file from another app on your device to the current folder"
        case 1:
            footerMessage = "Create a new folder, photo or video inside the current folder you are viewing"
        case 2:
            footerMessage = "Log out from this device so another user can access their files"
            footerMessage += ". Currently logged in as " + settings!.string(forKey: settingsFirstName)! + " (" + settings!.string(forKey: settingsUsername)! + ")"
        case 3:
            footerMessage = "Save log files from this device as a zip file to the current folder"
        default:
            footerMessage = ""
        }
        
        logger.verbose("Footer message for upload popover section \(section) is \(footerMessage)")
        return footerMessage
    }
    
    /// Seeing what cell the user has selected from the table, and
    /// perform the relevant action
    ///
    /// We need to know what cell the user has selected so that the
    /// relevant action can be performed. As there doesn't seem to
    /// be any way to access both the photos and videos on the same
    /// image picker, it is split into 2 cells
    ///
    /// The default UIImagePickerController() only allows selecting
    /// a single photo or video for uploading, so DKImagePickerController()
    /// is also used to allow selecting multiple photos or videos to
    /// upload to the HAP+ server. The user is able to choose what
    /// picker they want to use by making a choice in the main iOS
    /// Settings app; the default is to use the multi picker
    ///
    /// - note: The table cells and sections are hardcoded, in the
    ///         following order. If there are any changes, make sure
    ///         to check this function first and make any modifications
    ///         | Section | Row |     Cell function    |
    ///         |---------|-----|----------------------|
    ///         |    0    |  0  | Upload photo         |
    ///         |    0    |  1  | Upload video         |
    ///         |    0    |  2  | Upload from cloud    |
    ///         |    0    |  3  | Upload file from app |
    ///         |---------|-----|----------------------|
    ///         |    1    |  0  | New folder           |
    ///         |    1    |  1  | Take a photo or video|
    ///         |---------|-----|----------------------|
    ///         |    2    |  0  | Log Out              |
    ///         |---------|-----|----------------------|
    ///         |    3    |  0  | Save log files       |
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 15
    /// - date: 2016-05-12
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        logger.debug("Cell tapped section: \(section)")
        logger.debug("Cell tapped row: \(row)")
        
        // Saving the currently selected row, so that if the user
        // presses cancel on the image picker, it can be deselected
        currentlySelectedRow = indexPath
        
        // The user has selected to upload a photo
        if ((section == 0) && (row == 0)) {
            logger.debug("Cell function: Upload photo")
            
            // Showing the permissions request to access
            // the photos library
            pscopePhotos.show({ finished, results in
                logger.debug("Got permission results: \(results)")
                
                // Seeing if access to the photos library has been granted
                if PermissionScope().statusPhotos() == .authorized {
                    logger.debug("Permissions granted to access the photos library")
                    
                    // Seeing if the basic or multi photo uploader shoud
                    // be used to select the file (chosen by the user in
                    // the main settings app)
                    if (settings!.bool(forKey: settingsBasicPhotoUploaderEnabled)) {
                        logger.debug("Using basic photo uploader")
                        
                        // Calling the image picker
                        self.imagePicker.allowsEditing = false
                        self.imagePicker.sourceType = .photoLibrary
                        self.imagePicker.mediaTypes = [kUTTypeImage as String]
                        
                        self.present(self.imagePicker, animated: true, completion: nil)
                    } else {
                        logger.debug("Using multi photo uploader")
                        
                        // Calling the multi image picker
                        self.showMultiPicker(.allPhotos, selectedRowIndexPath: indexPath)
                    }
                } else {
                    logger.warning("Permissions to access the photos library were denied")
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                
                }, cancelled: { (results) -> Void in
                    logger.warning("Permissions to access the photos library were denied")
                    tableView.deselectRow(at: indexPath, animated: true)
            })
        }
        
        // The user has selected to upload a video
        if ((section == 0) && (row == 1)) {
            logger.debug("Cell function: Upload video")
            
            // Showing the permissions request to access
            // the photos library
            pscopePhotos.show({ finished, results in
                logger.debug("Got permission results: \(results)")
                
                // Seeing if access to the photos library has been granted
                if PermissionScope().statusPhotos() == .authorized {
                    logger.debug("Permissions granted to access the photos library")
                    
                    // Seeing if the basic or multi video uploader shoud
                    // be used to select the file (chosen by the user in
                    // the main settings app)
                    if (settings!.bool(forKey: settingsBasicVideoUploaderEnabled)) {
                        logger.debug("Using basic video uploader")
                        
                        // Calling the image picker
                        self.imagePicker.allowsEditing = false
                        self.imagePicker.sourceType = .photoLibrary
                        self.imagePicker.mediaTypes = [kUTTypeMovie as String]
                        
                        self.present(self.imagePicker, animated: true, completion: nil)
                    } else {
                        logger.debug("Using multi video uploader")
                        
                        // Calling the multi video picker
                        self.showMultiPicker(.allVideos, selectedRowIndexPath: indexPath)
                    }
                } else {
                    logger.warning("Permissions to access the photos library were denied")
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                
                }, cancelled: { (results) -> Void in
                    logger.warning("Permissions to access the photos library were denied")
                    tableView.deselectRow(at: indexPath, animated: true)
            })
        }
        
        // The user has selected to browse for a file from another app,
        // using the document picker and a cloud storage provider
        if ((section == 0) && (row == 2)) {
            logger.debug("Cell function: Browsing for a file from a cloud storage provider")
            
            // Setting up the document picker to present it to the user
            // See: https://www.shinobicontrols.com/blog/ios8-day-by-day-day-28-document-picker
            let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeContent as String], in: .import)
            
            documentPicker.delegate = self
            
            // Setting the document picker to show inside the popover
            // and not full screen on large screen devices
            // NOTE: I cannot find any documentation by Apple on how
            //       the document picker should be presented, so for
            //       now it will be the same as the image picker
            documentPicker.modalPresentationStyle = .currentContext
            
            // Showing the document picker to the user
            present(documentPicker, animated: true, completion: nil)
        }
        
        // The user has selected to upload the file from the app
        if ((section == 0) && (row == 3)) {
            logger.debug("Cell function: Uploading file from app")
            
            // Dismissing the popover as it's done what is needed
            // See: http://stackoverflow.com/a/32521647
            self.dismiss(animated: true, completion: nil)
            
            // Calling the upload file delegate to upload the file
            delegate?.uploadFile(false, customFileName: "", fileExistsCallback: { Void in
                self.delegate?.showFileExistsMessage(false)
            })
        }
        
        // The user has selected to create a new folder
        if ((section == 1) && (row == 0)) {
            logger.debug("Cell function: Create new folder")
            
            // Setting the "mode" of the alert so that the
            // keyboard continue button calls the right
            // function
            alertMode = "newFolder"
            
            // Displaying an alert view with a textbox for the
            // user to type in the name of the folder
            // See: http://peterwitham.com/swift/intermediate/alert-with-user-entry/
            var newFolderAlert:UIAlertController?
            newFolderAlert = UIAlertController(title: "New folder", message: "Please enter the name of the folder", preferredStyle: .alert)
            
            newFolderAlert!.addTextField(
                configurationHandler: {(textField: UITextField!) in
                    textField.placeholder = "Folder name"
                    textField.keyboardType = .asciiCapable
                    textField.autocapitalizationType = .words
                    textField.enablesReturnKeyAutomatically = true
                    textField.keyboardAppearance = .dark
                    textField.returnKeyType = .continue
                    textField.delegate = self
            })
            
            // Setting the create button style to be cancel, so
            // that it is emboldened in the alert and looks like
            // the default button to press
            // Note: Continue is used instead of create, as it
            //       then keeps the same description as the
            //       keyboard return key
            let action = UIAlertAction(title: "Continue", style: UIAlertActionStyle.cancel, handler: {(paramAction:UIAlertAction!) in
                    if let textFields = newFolderAlert?.textFields{
                        let theTextFields = textFields as [UITextField]
                        let enteredText = theTextFields[0].text
                        if (enteredText! != "") {
                            // Creating the new folder from the
                            // Master View Controller
                            self.createFolder(enteredText!)
                        } else {
                            self.tableView.deselectRow(at: indexPath, animated: true)
                        }
                    }
                })
            
            newFolderAlert!.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { Void in
                self.tableView.deselectRow(at: indexPath, animated: true)
            }))
            
            newFolderAlert?.addAction(action)
            self.present(newFolderAlert!, animated: true, completion: nil)
        }
        
        // The user wants to take a photo or video
        if ((section == 1) && (row == 1)) {
            logger.debug("Cell function: Take a photo or video")
            
            // Showing the permissions request to access
            // the camera and microphone
            pscopeCamera.show({ finished, results in
                logger.debug("Got permission results: \(results)")
                
                // Seeing if access to the camera and microphone
                // has been granted
                if ((PermissionScope().statusCamera() == .authorized) && (PermissionScope().statusMicrophone() == .authorized)) {
                    logger.debug("Permissions granted to access the camera and microphone")
                    
                    // Showing the camera controller to allow the user
                    // to take a photo or video
                    self.showCamera(selectedRowIndexPath: indexPath)
                } else {
                    logger.warning("Permission to access the camera or microphone was denied")
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                
            }, cancelled: { (results) -> Void in
                logger.warning("Permission to access the camera or microphone was denied")
                tableView.deselectRow(at: indexPath, animated: true)
            })
        }
        
        // The user wants to log out of the app
        if ((section == 2) && (row == 0)) {
            logger.debug("Cell function: Log out user")
            
            // Setting the "mode" of the alert so that the
            // keyboard continue button calls the right
            // function
            alertMode = "logOut"
            
            // Seeing what "mode" the device is in, and what groups the
            // currently logged in user is part of. "Personal" and
            // "Shared" devices can be logged out at any time, but devices
            // in "Single" mode need to have a username entered of someone
            // who is in an Active Directory group of "Domain Admins" or "hap-ios-admins",
            // otherwise a log out alert will be shown to make sure
            // that permission has been sought to log out the user.
            // The reasoning behind this is if the device is in "Single"
            // mode, then it's deliberatley been logged in to one
            // specific account, so it shouldn't be logged out by
            // anyone who picks up the device
            // - note: It is important that your normal log in account
            //         is not included in the "hap-ios-admins" group,
            //         otherwise users can just type it in and log out
            //         of the app. It is recommended to create a new
            //         Active Directory user whose account will only
            //         be used to log out of this app, that doesn't have
            //         an easilly guessable username but can be remembered,
            //         e.g. hap-log-out-1029384756
            //         It is fine for you to be part of the "Domain Admins"
            //         group when logged in yourself to this app under "Single"
            //         mode, as you can log out without any problems
            logger.info("Device is currently in \"\(settings!.string(forKey: settingsDeviceType)!)\" mode")
            logger.debug("Groups current user (\"\(settings!.string(forKey: settingsUsername)!)\") is part of: \(settings!.string(forKey: settingsUserRoles)!)")
            if (settings!.string(forKey: settingsDeviceType) == "single") {
                // Seeing if the user is included in the "Domain Admins"
                // or "hap-ios-admins" groups
                // - note: This is the only time that a check for "Domain
                //         Admins" should take place, as it's checking the
                //         logged in user, and to prevent the usernames of
                //         valid domain admins being typed into the alert
                if ((settings!.string(forKey: settingsUserRoles)?.range(of: "Domain Admins") == nil) && (settings!.string(forKey: settingsUserRoles)?.range(of: "hap-ios-admins") == nil)) {
                    // We need to check that the device is allowed to
                    // be logged out by alerting the user and getting
                    // a user with domain admin permissions to log in
                    logger.info("Confirming user has permission to log out of the device")
                    
                    // Displaying an alert view with textboxes for the
                    // user to type in the username of a user who is
                    // part of the "hap-ios-admins" group
                    // See: http://peterwitham.com/swift/intermediate/alert-with-user-entry/
                    var userLogOutAlert:UIAlertController?
                    userLogOutAlert = UIAlertController(title: "Log Out User", message: "Please enter an authenticated username to log out of this device", preferredStyle: .alert)
                    
                    userLogOutAlert!.addTextField(
                        configurationHandler: {(textField: UITextField!) in
                            textField.placeholder = "Username"
                            textField.keyboardType = .asciiCapable
                            textField.enablesReturnKeyAutomatically = true
                            textField.keyboardAppearance = .dark
                            textField.returnKeyType = .continue
                            textField.delegate = self
                            textField.autocorrectionType = .no
                    })
                    
                    // Setting the log out button style to be cancel, so
                    // that it is emboldened in the alert and looks like
                    // the default button to press
                    // Note: Continue is used instead of create, as it
                    //       then keeps the same description as the
                    //       keyboard return key
                    let action = UIAlertAction(title: "Continue", style: UIAlertActionStyle.cancel, handler: {(paramAction:UIAlertAction!) in
                        if let textFields = userLogOutAlert?.textFields{
                            let theTextFields = textFields as [UITextField]
                            let usernameText = theTextFields[0].text
                            if (usernameText! != "") {
                                // Attempting to check that the username
                                // entered contains a valid user with
                                // "hap-ios-admins" in their group memberships
                                self.logOutUser(false, username: usernameText!)
                            } else {
                                logger.debug("Missing username to confirm log out request")
                                self.tableView.deselectRow(at: indexPath, animated: true)
                            }
                        }
                    })
                    
                    userLogOutAlert!.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { Void in
                        self.tableView.deselectRow(at: indexPath, animated: true)
                    }))
                    
                    userLogOutAlert?.addAction(action)
                    self.present(userLogOutAlert!, animated: true, completion: nil)
                    
                } else {
                    // A "Domain Admin" or "hap-ios-admin" user
                    // is logged in, so the user can be logged
                    // out of the device without being questioned
                    logger.info("Logging user out of device, as they are a member of \"Domain Admins\" or \"hap-ios-admins\"")
                    
                    // Logging out the user from the device
                    logOutUser(true, username: "")
                }
            } else {
                // The device is set up in either "Personal" or "Shared"
                // mode, so it can be logged out straight away
                logger.info("Logging user out of device, as it is in \"Personal\" or \"Shared\" mode")
                
                // Logging out the user from the device
                logOutUser(true, username: "")
            }
        }
        
        // The user has selected to upload the log files from the device
        if ((section == 3) && (row == 0)) {
            logger.debug("Cell function: Uploading log files from device")
            
            // Attempting to create a zip file of the logs on the device
            // and upload them to the current folder
            if (zipLogFiles()) {
                // Dismissing the popover as it's done what is needed
                // See: http://stackoverflow.com/a/32521647
                self.dismiss(animated: true, completion: nil)
                
                // Calling the upload file delegate to upload the file
                delegate?.uploadFile(true, customFileName: "", fileExistsCallback: { Void in
                    self.delegate?.showFileExistsMessage(true)
                })
            } else {
                logger.error("There was a problem creating the zipped log files")
                
                let zipFailController = UIAlertController(title: "Unable to zip log files", message: "The log files were not able to be zipped for upload", preferredStyle: UIAlertControllerStyle.alert)
                zipFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { Void in
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }))
                self.present(zipFailController, animated: true, completion: nil)
            }
        }
    }
    
    /// Gets the file name from the location on the device of the file
    ///
    /// Gets the name of the file that has been passed to this app from
    /// another external one, so that it can be shown to the user
    ///
    /// - note: This function is a simplified and less commented one as
    ///         from the HAPi file -> uploadFile function
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 2
    /// - date: 2016-01-07
    ///
    /// - returns: The file name of the file on the device
    func getFileName() -> String {
        // Getting the name of the file that is being uploaded from the
        // location of the file on the device
        let pathArray = settings!.string(forKey: settingsUploadFileLocation)!.components(separatedBy: "/")
        var fileName = pathArray.last!
        
        // Removing any encoded characters from the file name
        fileName = fileName.removingPercentEncoding!
        
        return fileName
    }
    
    /// Gets the location of the file the user has picked from the
    /// image picker, so that it can be uploaded
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 4
    /// - date: 2016-05-14
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Getting the type of file the user has selected, as it
        // is stored in different locations based on what it is
        let fileMediaType = info[UIImagePickerControllerMediaType]!
        logger.debug("The media file picked by the user is a: \(fileMediaType)")
        
        // Getting the location of the image on the deivce. This is
        // not a standard file:// url but a special assets-library://
        let fileDeviceLocation = info[UIImagePickerControllerReferenceURL]!
        logger.debug("Picked media file location on device: \(fileDeviceLocation)")
        
        // Writing the file that has been selected from the library
        // to a file in the current Inbox folder in the Documents
        // directory, as there's not an easy way to upload the file
        // directly from the asset-library:// URL
        // See: https://www.hackingwithswift.com/read/10/4/importing-photos-with-uiimagepickercontroller
        var newImage: UIImage
        var imagePath = ""
        
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            newImage = possibleImage
            logger.debug("Selected image from \"UIImagePickerControllerEditedImage\": \(possibleImage)")
            imagePath = createLocalImage(newImage, fileLocation: fileDeviceLocation as! URL, multiPickerUsed: false)
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            newImage = possibleImage
            logger.debug("Selected image from \"UIImagePickerControllerOriginalImage\": \(possibleImage)")
            imagePath = createLocalImage(newImage, fileLocation: fileDeviceLocation as! URL, multiPickerUsed: false)
        } else {
            if (fileMediaType as! String == "public.movie") {
                logger.debug("Media file selected is a video")
                imagePath = createLocalVideo(info[UIImagePickerControllerMediaURL] as! URL)
            } else {
                logger.error("Unable to get the selected image")
                return
            }
        }
        
        // Setting the location of the image file in the settings
        settings!.set(String(imagePath), forKey: settingsUploadPhotosLocation)
        
        // Dismissing the image file picker
        dismiss(animated: true, completion: nil)
        
        // Dismissing the popover as it's done what is needed
        self.dismiss(animated: true, completion: nil)
        
        // Uploading the file to the HAP+ server
        delegate?.uploadFile(true, customFileName: "", fileExistsCallback: { Void in
            self.delegate?.showFileExistsMessage(true)
        })
    }
    
    /// Dismissing the image picker
    ///
    /// While not needed as pressing the image picker cancel button
    /// works on it's own, but Apple says it's needed, so it's going in
    /// See: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImagePickerControllerDelegate_Protocol/index.html#//apple_ref/occ/intfm/UIImagePickerControllerDelegate/imagePickerControllerDidCancel:
    ///
    /// However, if the user cancels the image picker, then we use this
    /// function to deselect the table row, so that they know something
    /// else can be chosen
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 2
    /// - date: 2016-01-16
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: {
            // Deselecting the selected row, so that it is not kept
            // selected if the user cancels the image picker
            self.tableView.deselectRow(at: self.currentlySelectedRow!, animated: true)
        })
    }
    
    /// Gets the location of the file that the user has picked
    /// from the document picker, and uploading it to the HAP+
    /// server
    ///
    /// Once the user has selected the file that they would like
    /// to upload from an external app, then we can collect its
    /// location on the device and then upload it to the HAP+
    /// server
    /// See: https://www.shinobicontrols.com/blog/ios8-day-by-day-day-28-document-picker
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 5
    /// - date: 2016-02-05
    ///
    /// - seealso: createLocalFile
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        logger.debug("File picked from document picker at URL: \(url)")
        
        // Creating a copy of the file selected from the document
        // picker, as once it is removed from the view it seems
        // to remove the file in the temp path, and logs a message
        // of: "plugin com.apple.UIKit.fileprovider.default invalidated"
        let filePath = createLocalFile(url)
        
        // Seeing if the file being created has had a valid file name
        // created in the createLocalFile function and either upload
        // the file or let the user know they are unable to send the
        // file to the HAP+ server
        if (filePath == "") {
            logger.error("The file is not able to be uploaded to the HAP+ server")
            
            // Showing a message to the user that the file was not able
            // to be uploaded
            let invalidFileNameController = UIAlertController(title: "Unable to Upload File", message: "This file is not able to be uploaded to the Home Access Plus+ server", preferredStyle: UIAlertControllerStyle.alert)
            invalidFileNameController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(invalidFileNameController, animated: true, completion: nil)
            
            // Deselecting the selected row, so that it is not kept
            // selected if the file cannot be uploaded
            self.tableView.deselectRow(at: self.currentlySelectedRow!, animated: true)
        } else {
            logger.debug("File picked copied to on device location: \(filePath)")
            
            // Saving the location of the file on the device so that it
            // can be accessed when uploading to the HAP+ server
            settings!.set(filePath, forKey: settingsUploadFileLocation)
            
            // Dismissing the document picker
            dismiss(animated: true, completion: nil)
            
            // Dismissing the popover as it's done what is needed
            self.dismiss(animated: true, completion: nil)
            
            // Uploading the file to the HAP+ server
            delegate?.uploadFile(false, customFileName: "", fileExistsCallback: { Void in
                self.delegate?.showFileExistsMessage(false)
            })
        }
    }
    
    /// Dismissing the document picker
    ///
    /// If the user cancels the document picker, then the
    /// current row highlighted in the upload popover needs
    /// to be de-selected, so that it doesn't look as though
    /// the app is 'stuck'
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 1
    /// - date: 2016-02-02
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // Deselecting the selected row, so that it is not kept
        // selected if the user cancels the document picker
        self.tableView.deselectRow(at: self.currentlySelectedRow!, animated: true)
    }
    
    // MARK: Multi Picker & Camera
    
    /// Shows the multi picker to the user
    ///
    /// To reduce repetition of the code that is used to show
    /// the multi picker to the user, both the upload photos and
    /// upload videos cells when tapped call this function, if the
    /// basic uploader settings option isn't enabled
    ///
    /// The multi picker is then shown to the user to allow them to
    /// select either a single or multiple photos or videos from the
    /// photos library on the device
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.8.0-alpha
    /// - version: 6
    /// - date: 2016-05-14
    ///
    /// - parameter mediaType: The type of media that is to be shown in the multi picker
    /// - parameter selectedRowIndexPath: The currently selected upload popover table row
    ///                                   so it can be deselected if the user cancels the
    ///                                   multi picker
    func showMultiPicker(_ mediaType: DKImagePickerControllerAssetType, selectedRowIndexPath: IndexPath) {
        // Creating an instance of the multi picker, so that
        // users can upload multiple photos or videos at once
        let multiPickerController = DKImagePickerController()
        
        // Setting the multi picker to show in the current popover
        multiPickerController.modalPresentationStyle = .currentContext
        
        // Setting options for the multi picker that are against
        // the default settings
        multiPickerController.showsCancelButton = true
        multiPickerController.showsEmptyAlbums = false
        
        // Hiding the 'camera' option from the multi picker,
        // as we don't want users taking items now
        multiPickerController.sourceType = .photo
        
        // Selecting the source file type for the multi picker,
        // based on the tapped table cell in the popover
        multiPickerController.assetType = mediaType
        
        // Setting up a call to the function to process and
        // upload all of the selected files
        multiPickerController.didSelectAssets = { (assets: [DKAsset]) in
            logger.debug("User selected the following assets from the multi picker: \(assets)")
            
            // Used to hold the in-app file location of the currently
            // processing file
            var filePath = ""
            
            // Used to hold the array of on-device file locations, that
            // will be passed to the multiple file uploader delegate
            var filePaths = [String]()
            
            // Getting the information for each the selected image
            // See: https://github.com/zhangao0086/DKImagePickerController/issues/53#issuecomment-167327653
            // See: https://codedump.io/share/YprjGK8k1AE/1/images-duplicating-when-adding-to-array
            for asset in assets {
                // Seeing if we are uploading images or videos from
                // the multi picker, and generating a local file
                // to be used to upload the file from
                if (mediaType == DKImagePickerControllerAssetType.allPhotos) {
                    // An image is to be uploaded
                    asset.fetchOriginalImageWithCompleteBlock { (image, info) -> Void in
                        logger.verbose("Asset file image: \(image!)")
                        logger.verbose("Asset file info: \(info!)")
                        logger.debug("Uploading asset image file from on device location: \(info!["PHImageFileURLKey"]!)")
                        
                        filePath = self.createLocalImage(image!, fileLocation: (info!["PHImageFileURLKey"]! as! NSURL) as URL, multiPickerUsed: true)
                        
                        // Adding the currently selected file to the array of files
                        filePaths.append(filePath)
                        
                        // Uploading the files to the HAP+ server
                        self.delegate?.uploadMultipleFiles(filePaths as NSArray)
                    }
                } else {
                    // A video is to be uploaded
                    // See: https://github.com/zhangao0086/DKImagePickerController/issues/53#issuecomment-167025363
                    asset.fetchAVAssetWithCompleteBlock({ (AVAsset, info) in
                        logger.debug("Uploading asset video file from on device location: \(AVAsset!)")
                        logger.verbose("Asset file info: \(info!)")
                        //logger.verbose("Raw asset file video data: \(NSData(contentsOfURL: AVAsset!.URL)!)")
                        
                        // There doesn't seem to be an easy way to get the name of the
                        // file we are using, as AVAsset!.URL seems to cause problems.
                        // Converting the value returned to a string and then parsing
                        // out the URL section is a hacky-but-doable way
                        // - Example input: <AVURLAsset: 0x126, URL = file:///var/mobile/Media/DCIM/100APPLE/IMG_0001.MOV>
                        let assetURL = String(describing: AVAsset!).components(separatedBy: " = ")
                        let fullFilePath = assetURL.last!.replacingOccurrences(of: ">", with: "")
                        
                        filePath = self.createLocalVideo(URL(string: fullFilePath)!)
                        
                        // Adding the currently selected file to the array of files
                        filePaths.append(filePath)
                        
                        // Uploading the files to the HAP+ server
                        self.delegate?.uploadMultipleFiles(filePaths as NSArray)
                    })
                }
            }
            
            // Dismissing the popover as it's done what is needed
            self.dismiss(animated: true, completion: nil)
        }
        
        // Setting up the 'cancel' option for the multi picker, so
        // that the selected popover table row can be deselected
        multiPickerController.didCancel = { Void in
            logger.debug("User cancelled the multi picker")
            self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
        
        // Showing the multi picker to the user, so that they can
        // select any photos or videos they want to upload
        self.present(multiPickerController, animated: true, completion: nil)
    }
    
    /// Shows the camera to the user
    ///
    /// While the user can use the camera app outside of this app,
    /// should they want to quickly take a photo or video and have it
    /// uploaded automatically to the folder they have browsed to,
    /// this ability can be chosen from a upload popover menu item
    ///
    /// This uses the UploadPopoverCustomCamera class, as this then
    /// allows the ability to take either a photo or a video, and
    /// uses the interface of the built-in camera app. While it is
    /// possible to call the DKImagePickerController with a sourceType
    /// of .camera, during testing this did not provide the ability
    /// to record video or orentate properly should the device be rotated
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.9.0-beta
    /// - version: 1
    /// - date: 2016-01-25
    ///
    /// - seealso: UploadPopoverCustomCamera
    /// - seealso: https://github.com/zhangao0086/DKImagePickerController/tree/develop/DKImagePickerControllerDemo/CustomCameraUIDelegate
    ///
    /// - parameter selectedRowIndexPath: The currently selected upload popover table row
    ///                                   so it can be deselected if the user cancels the
    ///                                   camera
    func showCamera(selectedRowIndexPath: IndexPath) {
        // Creating an instance of the custom camera class, so
        // that photos and videos can be taken
        let cameraController = UploadPopoverCustomCamera()
        
        // An image has been taken with the camera, so process
        // the image for it to be uploaded
        cameraController.didFinishCapturingImage = {(image: UIImage) in
            logger.info("A photo has been taken with the camera")
            logger.debug("Image information: \(image)")
            
            self.dismiss(animated: true, completion: nil)
            self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
        
        // A videos has been taken with the camera, so process
        // the video for it to be uploaded
        cameraController.didFinishCapturingVideo = {(videoURL: URL) in
            logger.info("A video has been taken with the camera")
            logger.debug("Video information: \(videoURL)")
            
            // Setting the location of the video file in the settings
            settings!.set(String(describing: videoURL), forKey: settingsUploadPhotosLocation)
            
            // Dismissing the camera
            self.dismiss(animated: true, completion: nil)
            
            // Dismissing the popover as it's done what is needed
            self.dismiss(animated: true, completion: nil)
            
            // Uploading the file to the HAP+ server
            self.delegate?.uploadFile(true, customFileName: "", fileExistsCallback: { Void in
                self.delegate?.showFileExistsMessage(true)
            })
        }
        
        // If the user cancels the camera, then remove the view
        // controller for it and deselect the tapped row on the
        // upload popover
        cameraController.didCancel = { () in
            logger.debug("Taking a photo or video with the camera has been cancelled")
            
            self.dismiss(animated: true, completion: nil)
            self.tableView.deselectRow(at: selectedRowIndexPath, animated: true)
        }
        
        // Showing the camera to the user so that it can be used
        self.present(cameraController, animated: true, completion: nil)
    }
    
    /// Creates a local copy of the selected image in the documents
    /// directory, to upload it to the HAP+ server
    ///
    /// As the image in the asset library cannot be uploaded directly,
    /// it needs to be created locally in the app before it can be
    /// uploaded to the HAP+ server
    ///
    /// If the multi picker was used to select the file, then it already
    /// contains a usable file name stored in the fileLocation variable,
    /// so a file name is not needed to be generated from the file name from
    /// the photos library
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 3
    /// - date: 2016-05-14
    ///
    /// - parameter newImage: A reference to the image from the asset library
    /// - parameter fileLocation: The location in the asset library, to generate
    ///                           the name of the file from
    /// - parameter multiPickerUsed: If the multi picker was used to select the file
    /// - returns: The path to the image in the app
    func createLocalImage(_ newImage: UIImage, fileLocation: URL, multiPickerUsed: Bool) -> String {
        // Seeing if the file name should be generated from the on
        // device location, or just to use the last part of the path.
        // This depends on if the multi picker was used, as it puts a
        // full file path in the fileLocation variable, whereas the
        // imagePicker controller passes obscure file locations and
        // a name needs to be generated from it
        var imagePath = getDocumentsDirectory()
        if (multiPickerUsed) {
            logger.debug("Using the file name from the multi picker")
            let fileName = String(describing: fileLocation).components(separatedBy: "/").last!.removingPercentEncoding!
            imagePath = imagePath.appendingPathComponent(fileName) as NSString
        } else {
            logger.debug("Generating a file name for the image")
            imagePath = imagePath.appendingPathComponent(createFileName(fileLocation, imageFile: true)) as NSString
        }
        
        if let jpegData = UIImageJPEGRepresentation(newImage, 80) {
            logger.verbose("Before writing image to documents folder")
            
            try? jpegData.write(to: URL(fileURLWithPath: imagePath as String), options: [.atomic])
            
            logger.verbose("JPEG file raw data: \(jpegData)")
            logger.verbose("After writing image to documents folder")
        }
        
        logger.debug("Selected media file written to: \(imagePath)")
        return imagePath as String
    }
    
    /// Creates a local copy of the selected video in the documents
    /// directory, to upload it to the HAP+ server
    ///
    /// As the video in the asset library cannot be uploaded directly,
    /// it needs to be created locally in the app before it can be
    /// uploaded to the HAP+ server
    /// See: http://stackoverflow.com/a/31853916
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-11
    ///
    /// - parameter fileLocation: The location in the asset library, to generate
    ///                           the name of the file from
    /// - returns: The path to the video in the app
    func createLocalVideo(_ fileLocation: URL) -> String {
        let videoData = try? Data(contentsOf: fileLocation)
        logger.debug("Location of video data: \(fileLocation)")
        
        let dataPath = getDocumentsDirectory().appendingPathComponent(createFileName(fileLocation, imageFile: false))
        
        logger.verbose("Before writing video file")
        
        try? videoData?.write(to: URL(fileURLWithPath: dataPath), options: [.atomic])
        
        logger.verbose("Video file raw data: \(videoData)")
        logger.verbose("After writing video file")
        
        logger.debug("Selected video file written to: \(dataPath)")
        return dataPath
    }
    
    /// Creates a local copy of the selected file in the documents
    /// directory, to upload it to the HAP+ server
    ///
    /// As the file in the document picker cannot be uploaded directly,
    /// it needs to be created locally in the app before it can be
    /// uploaded to the HAP+ server
    /// See: http://stackoverflow.com/a/31853916
    ///
    /// - note: Most of this function replicates that in the
    ///         createLocalVideo function. If there's changes in that
    ///         function, then they may also apply here too
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 3
    /// - date: 2016-02-05
    ///
    /// - seealso: createLocalVideo
    ///
    /// - parameter fileLocation: The location the document picker has
    ///                           put the temporary file, to generate
    ///                           the name of the file from
    /// - returns: The path to the file in the app, or an empty string
    ///            if a valid file name could not be generated
    func createLocalFile(_ fileLocation: URL) -> String {
        let fileData = try? Data(contentsOf: fileLocation)
        logger.debug("Location of file data: \(fileLocation)")
        
        // Creating the file name to save the file into
        var fileName = String(describing: fileLocation).components(separatedBy: "/").last!
        
        // The fileName also needs to not be percent-encoded, as
        // functions called later on add them back in before uploading
        // to the HAP+ server. Without the percent-encoding being
        // removed, the app thinks there is already a file existing
        // even if there is not. Namely, this is the 'fileExists'
        // function in the HAPi, as it encodes the string of
        // file%20name%20here.ext to file%2520name%2520%2520here.ext
        // which causes the HAP+ API to respond with an error
        fileName = fileName.removingPercentEncoding!
        
        // Checking to see if the file that has been selected contains
        // an extension, i.e. fileName.ext and not just fileName, as
        // the HAP+ server fails to upload a file with no extension.
        // This seems to mainly happen with files uploaded from the
        // Google Drive document picker that are created with Google
        // docs, sheets or slides. This is done via a regex
        // See: http://stackoverflow.com/a/9001636
        let fileNamePattern = "[^\\\\]*\\.(\\w+)"
        let fileNameValid = NSPredicate(format:"SELF MATCHES %@", argumentArray:[fileNamePattern])
        if (fileNameValid.evaluate(with: fileName) == false) {
            // The file name is missing an extension, so return an
            // epmty string, so that the calling function knows
            // there was a problem and doesn't attempt to upload
            // the file
            logger.warning("File name \"\(fileName)\" is not a valid format")
            return ""
        } else {
            // The file name is in a format that the HAP+ server
            // will like, so we can generate a local file to upload
            let dataPath = getDocumentsDirectory().appendingPathComponent(fileName)
            
            logger.verbose("Before writing file")
            
            try? fileData?.write(to: URL(fileURLWithPath: dataPath), options: [.atomic])
            
            logger.verbose("File raw data: \(fileData)")
            logger.verbose("After writing file")
            
            logger.debug("Selected file written to: \(dataPath)")
            return dataPath
        }
    }
    
    /// Creating a usable file name from the photo library
    ///
    /// The file is coming from the devices photo library, so the
    /// location of the file on the device is a virtual one, and
    /// the file name can not just be collected from the last
    /// value. The value passed to fileLocation will be
    /// assets-library://asset/asset.<EXT>?id=<UUID>&ext=<EXT>
    /// so we need to get the hex string from the UUID for the name
    /// of the file, and the extention as well. It's not the best
    /// file name in the world, but it's something
    ///
    /// However, if the user is uploading a video, its location on
    /// the device is ~/tmp/trim.<UUID>.<EXT> which means that it
    /// can be formatted as a file name just without the "trim" at
    /// the beginning. Who knew it would be this... easy?!
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 2
    /// - date: 2016-01-11
    /// - seealso: HAPi.uploadFile
    ///
    /// - parameter fileLocation: The location in the asset library, to generate
    ///                           the name of the file from
    /// - parameter iamgeFile: If the file being processed is an image file, then
    ///                        a hardcoded extension of ".jpg" needs to be added,
    ///                        as the app is creating a JPEG file
    /// - returns: The name of the file
    func createFileName(_ fileLocation: URL, imageFile: Bool) -> String {
        // Storing the name of the file that we will be showing the user
        var fileName = ""
        
        // Seeing if we are dealing with an image file or a video
        if (imageFile) {
            // Splitting the string into before and after the '?', so we
            // have the name and extension at fileNameQuery[1]
            let fileNameQuery = String(describing: fileLocation).components(separatedBy: "?")
            
            // Splitting the string into before and after the '&', so we
            // have the name at fileNameParameters[0] and extension at fileNameParameters[1]
            let fileNameParameters = String(fileNameQuery[1]).components(separatedBy: "&")
            
            // Splitting the string into before and after the '=', so we
            // have the name at fileNameValue[1]
            let fileNameValue = String(fileNameParameters[0]).components(separatedBy: "=")
            
            // Getting the first hex string from the UUID, so that the name isn't
            // too long to display
            let fileNameUUID = String(fileNameValue[1]).components(separatedBy: "-")
            
            // Hardcoding the extension, as we are generating JPEG images
            fileName = fileNameUUID[0] + ".jpg"
        } else {
            // The below code is based on the HAPI.uploadFile function
            let pathArray = String(describing: fileLocation).components(separatedBy: "/")
            
            // Getting the last value from the path
            var fullFileName = pathArray.last!
            
            // Removing the "trim." from the start of the string
            fullFileName = fullFileName.replacingOccurrences(of: "trim.", with: "")
            
            // Getting the file name and extension from the fullFileName,
            // with the name stored at fileNameParameters[0] and the extension at
            // fileNameParameters[1]
            let fileNameParameters = fullFileName.components(separatedBy: ".")
            
            // Getting the first hex string from the UUID, so that the name isn't
            // too long to display
            let fileNameUUID = String(fileNameParameters[0]).components(separatedBy: "-")
            
            // Joining the file name and extension to create the full file name
            // for video files
            fileName = fileNameUUID[0] + "." + fileNameParameters[1]
        }
        
        logger.debug("File name for generated media: \(fileName)")
        return fileName
    }
    
    /// Gets the value from the textfield in the new folder alert
    /// controller, to pass it back via delegates to the Master
    /// View Controller to create it in the current folder
    ///
    /// As the user can type in the name of the new folder and
    /// press "Continue" on the keyboard, or the "Continue" button
    /// on the alert, both routes need to come here so that there
    /// is a standardised function for it
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-beta
    /// - version: 1
    /// - date: 2016-01-29
    ///
    /// - parameter folderName: The name of the folder that is to
    ///                         be created
    func createFolder(_ folderName: String) {
        logger.debug("New folder name: \(folderName)")
        
        // Calling the newFolder delegate function, so that
        // the folder can be created
        self.delegate?.newFolder(folderName)
        
        // Dismissing the popover as it's done what is needed
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Logs the user out of the app providing they have provided
    /// valid user credentials
    ///
    /// If the device is in "Shared" or "Personal" mode, then this
    /// function can be called from the table cell tap in the popover
    /// view. If the device is in "Single" mode, then this function
    /// is also called if the user is in the "Domain Admins" group,
    /// otherwise an authenticated username needs to be entered
    /// before the user can log themselves out of the device
    ///
    /// This function is either called with a "true" parameter if it
    /// is able to log the user out (such as a "Personal" device or
    /// the authenticated username is entered) or "false" if the
    /// username needs to be checked to see if it is in the correct
    /// groups. Upon successful checking, this function is called
    /// recursively with the "true" option
    ///
    /// The second parameter is the username to check to see if it is
    /// authenticated, otherwise an empty string can be passed if the
    /// first parameter is "true"
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 2
    /// - date: 2016-03-01
    ///
    /// - parameter performLogOut: If the user can be logged out,
    ///                            of if checks need to be completed first
    func logOutUser(_ performLogOut: Bool, username: String) {
        // Allowing the user to be logged out if the checks have
        // come back successfully
        if (performLogOut) {
            logger.debug("Performing log out")
            
            // Dismissing the popover as it's done what is needed
            // There shouldn't be any animation, as we want the popover
            // to disappear straight away as the logout should be
            // 'quick' for the user. The completion handler can then
            // call the delegare logOutUser function instead of being
            // called sequentially, as it is needed to prevent the popover
            // remaining shown to the user on a small screen device,
            // leading them to press the log out button again, which
            // then crashes the app
            // See: http://stackoverflow.com/a/16825683
            self.dismiss(animated: false, completion: {
                // Calling the log out function from the Master
                // View Controller
                self.delegate?.logOutUser()
            })
        } else {
            logger.info("Checking the username passed is for an authenticated user to log out of the device")
            
            // Saving the username and groups of the currently logged
            // in user, as calling the api.setRoles function overwrites
            // them
            // - Todo: Rewrite the api.setRoles function to include
            //         username parameters to be passed, along with a,
            //         boolean to not save the values, to avoid this?
            let currentUsername = settings!.string(forKey: settingsUsername)
            let currentUserRoles = settings!.string(forKey: settingsUserRoles)
            
            // Setting the username to be stored in the settings, so
            // the it can be accessed in the api.setRoles function
            settings!.set(username, forKey: settingsUsername)
            
            // Calling the HAPi to collect the roles the provided user
            // is part of
            let api = HAPi()
            api.setRoles({ (result: Bool) -> Void in
                // Seeing if the attempt to collect the groups was successful
                if (result == true) {
                    // Checking to see if the user entered is in the "hap-ios-admins"
                    // group
                    if (settings!.string(forKey: settingsUserRoles)?.range(of: "hap-ios-admins") == nil) {
                        // The username passed was not for an authenticated
                        // user, so reset the settings values back and let the
                        // current user know
                        logger.error("Unable to log out \"\(currentUsername!)\" as the username entered (\(username)) is not an authenticated user")
                        settings!.set(currentUsername, forKey: settingsUsername)
                        settings!.set(currentUserRoles, forKey: settingsUserRoles)
                        
                        let invalidUserNameController = UIAlertController(title: "Unable to Log Out", message: "The username entered is not an authenticated user", preferredStyle: UIAlertControllerStyle.alert)
                        invalidUserNameController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(alertAction) -> Void in
                            self.tableView.deselectRow(at: self.currentlySelectedRow!, animated: true) }))
                        self.present(invalidUserNameController, animated: true, completion: nil)
                    } else {
                        // A correct authenticated username was entered, so
                        // proceed with logging the current user out
                        logger.info("An authenticated username was entered")
                        self.logOutUser(true, username: "")
                    }
                }
                
                // There was an unknown problem in collecing the user groups, so
                // let the user know and reset the settings values back ane let the
                // current user know
                if (result == false) {
                    logger.error("Unable to log out user as there was a problem checking the username")
                    settings!.set(currentUsername, forKey: settingsUsername)
                    settings!.set(currentUserRoles, forKey: settingsUserRoles)
                    
                    let userNameProblemController = UIAlertController(title: "Unable to Log Out", message: "There was a problem checking the username. Please try again", preferredStyle: UIAlertControllerStyle.alert)
                    userNameProblemController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {(alertAction) -> Void in
                        self.tableView.deselectRow(at: self.currentlySelectedRow!, animated: true) }))
                    userNameProblemController.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.cancel, handler: {(alertAction) -> Void in
                        self.logOutUser(false, username: username) }))
                    self.present(userNameProblemController, animated: true, completion: nil)
                }
            })
        }
    }
    
    /// Gets the Documents directory for the current app
    ///
    /// See: https://www.hackingwithswift.com/read/10/4/importing-photos-with-uiimagepickercontroller
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-11
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        logger.debug("Documents directory path: \(documentsDirectory)")
        return documentsDirectory as NSString
    }
    
    /// Calling the "createFolder" or "logOutUser" functions
    /// when the user presses the return key on the keyboard
    /// when an alert is being shown to them
    ///
    /// If the user presses the return key on the keyboard,
    /// by default it dismisses the alert for typing in the
    /// name of the new folder or username to attempt a log
    /// out with. This function looks after calling the
    /// "createFolder" or "logOutUser" functions
    /// See: http://stackoverflow.com/a/26288341
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-beta
    /// - version: 3
    /// - date: 2016-03-01
    ///
    /// - seealso: createFolder
    /// - seealso: logOutUser
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        // Seeing what "mode" the alert box is in, so that the
        // keyboard performs the right function
        switch alertMode {
            case "newFolder":
                createFolder(textField.text!)
            case "logOut":
                logOutUser(false, username: textField.text!)
            default:
                break
        }
        
        // We need to dismiss the view controller here, as it
        // doesn't seem to remove the popover when the return
        // key is pressed
        self.dismiss(animated: true, completion: nil)
        
        return true
    }
    
    // MARK: Log Files
    
    /// Saves all log files on the device into a zip file to
    /// be uploaded to the current folder
    ///
    /// If file logging is enabled from the main iOS Settings
    /// app, then log files are generated on the device in the
    /// applicationSupportDirectory under a "logs" folder. When
    /// the user wants to upload these files to aid in debugging
    /// they will select the reveleant option from the upload
    /// popover to call this function. It will zip all log files
    /// together so that they can be uploaded
    ///
    /// See: http://stackoverflow.com/a/27722526
    /// See: https://github.com/marmelroy/Zip
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.9.0-alpha
    /// - version: 2
    /// - date: 2017-01-15
    ///
    /// - returns: Were the logs able to be zipped
    func zipLogFiles() -> Bool {
        logger.info("Creating zip file of all device logs")
        
        let logFileDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("logs", isDirectory: true)
        
        logger.debug("Using logs located in: \(logFileDirectory)")
        
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: logFileDirectory, includingPropertiesForKeys: nil, options: [])
            logger.verbose("Contents of logs directory: \(directoryContents)")
            
            let zipFile = logFileDirectory.appendingPathComponent("hap-ios-app-logs.zip")
            
            // Attempting to delete any previous zip files so that the one
            // being uploaded can be created fresh
            logger.debug("Attempting to delete any previous zip files")
            do {
                try FileManager.default.removeItem(at: zipFile)
                    logger.debug("Successfully deleted previous zip file")
            }
            catch let errorMessage as NSError {
                logger.error("There was a problem deleting the file. Error: \(errorMessage)")
            }
            catch {
                logger.error("There was an unknown problem when deleting the previous zip file")
            }
            
            // Creating the zip file of all log files
            try Zip.zipFiles(paths: [logFileDirectory], zipFilePath: zipFile, password: nil, progress: nil)
            logger.debug("Logs zip file created and located at: \(zipFile)")
            
            // Due to the way the URL location of the file on the device is
            // processed in the HAPi upload function, we cannot just save the
            // zip file path to the settingsUploadFileLocation value, so it is
            // saved in the location normally used for uploading media files
            settings!.set(String(describing: zipFile), forKey: settingsUploadPhotosLocation)
            
            // Attempting to delete log files, to save space on the device and prevent
            // them appearing in future zip files
            let logFiles = directoryContents.filter{ $0.pathExtension == "log" }
            for (_, logFile) in logFiles.enumerated() {
                do {
                    try FileManager.default.removeItem(at: logFile)
                    logger.debug("Successfully deleted log file: \(logFile)")
                }
                catch let errorMessage as NSError {
                    logger.error("There was a problem deleting the file. Error: \(errorMessage)")
                }
                catch {
                    logger.error("There was an unknown problem when deleting the log file")
                }
            }
            
            return true
        } catch let error as NSError {
            logger.error("There was a problem creating the zipped logs file: \(error.localizedDescription)")
            logger.error("If we've ended up here then there's not an option to get the log files from the device")
            logger.error("Hopefully on another run of this app they are able to be collected")
            return false
        }
    }

}
