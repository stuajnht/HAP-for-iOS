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
import MBProgressHUD
import SwiftyJSON
import XCGLogger

/// This class is a direct copy of the one MasterViewController
/// in the HomeAccessPlus group, with some functions removed
///
/// - note: This class is very hackilly put together based on the
///         existing functions from other classes, with only slight
///         modifications. THIS IS NOT GOOD CODING PRACTICE, and
///         should be tidied up
///
/// - todo: Combine most of these functions into a new class, which
///         is also used by the MasterViewController.swift file
///
/// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
/// - since: 0.7.0-alpha
/// - version: 5
/// - date: 2016-04-01
class DocumentPickerViewController: UIDocumentPickerExtensionViewController, UITableViewDelegate, UITableViewDataSource, FileManagerDelegate {
    
    // Adding a reference to the file browser table,
    // so that it can be reloaded in the code
    // See: http://stackoverflow.com/a/33724276
    @IBOutlet weak var tblFileBrowser: UITableView!
    
    // A reference to the "save" button when the extension
    // is in export or move modes, to enable it to tbe
    // disabled when just the drives are being shown
    @IBOutlet weak var btnExportMoveFile: UIBarButtonItem!
    
    // Loading an instance of the HAPi class, so that the
    // functions in it can be used in the document provider
    let api = HAPi()
    
    // MBProgressHUD variable, so that the detail label can be updated as needed
    var hud : MBProgressHUD = MBProgressHUD()
    
    /// A listing to the current folder the user is in, or
    /// an empty string if the main drive listing is being
    /// shown
    /// - note: This variable should be set before the view
    ///         controller is called in the 'prepareForSegue'
    var currentPath = ""
    
    /// Array to hold the items that are shown in the table that
    /// is used to browse the files
    ///
    /// - note: The order of and data stored in this array is in
    ///         the following order:
    ///   1. File / folder name
    ///   2. Path to the item
    ///   3. The type of item this is (Drive, Directory, File Type)
    ///   4. The extension of the file, or empty if it is a directory
    ///   5. Additional details for the file (size, modified date, etc...)
    var fileItems: [NSArray] = []
    
    /// A reference to the original URL path to the file that
    /// has been passed to the document provider
    var originalFileURL : URL?
    
    // Checked when the viewWillAppear to see if an alert
    // needs to be shown to ask the user what to do if
    // a file already exists in the current folder
    // This cannot be run in the uploadFile function, as
    // the following error is logged in the console:
    // Warning: Attempt to present <UIAlertController> on
    // <MasterViewController> while a presentation is in progress!
    // Attempting to load the view of a view controller while it is
    // deallocating is not allowed and may result in undefined behavior
    // See: https://www.cocoanetics.com/2014/08/dismissal-completion-handler/
    var showFileExistsAlert : Bool = false

    @IBAction func openDocument(_ sender: AnyObject?) {
        let documentURL = self.documentStorageURL!.appendingPathComponent("Untitled.txt")
      
        // TODO: if you do not have a corresponding file provider, you must ensure that the URL returned here is backed by a file
        self.dismissGrantingAccess(to: documentURL)
    }

    override func prepareForPresentation(in mode: UIDocumentPickerMode) {
        // TODO: present a view controller appropriate for picker mode here
        
        // Configuring the logger options
        logger.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, showDate: true, writeToFile: nil, fileLogLevel: .Debug)
        
        if let siteName = settings!.string(forKey: settingsSiteName) {
            logger.debug("HAP+ document provider opened for site: \(siteName)")
        }
        
        logger.debug("Document picker started in mode: \(mode.rawValue)")
        // Showing the bottom navigation toolbar, so that when the
        // document picker is in export or move modes the user
        // can press the 'save' button to upload the file to the
        // current folder they have browsed to
        // See: http://stackoverflow.com/a/34216809
        // See: https://github.com/xamarin/monotouch-samples/blob/master/ios8/NewBox/NBox/DocumentPickerViewController.cs#L61
        switch mode {
            case .import, .open:
                logger.verbose("Document picker toolbar is hidden")
                self.navigationController!.setToolbarHidden(true, animated: false)
            case .exportToService, .moveToService:
                logger.verbose("Document picker toolbar is visible")
                self.navigationController!.setToolbarHidden(false, animated: false)
                
                // Saving the URL to the file passed to this document
                // provider, so that it can be accessed later when the
                // user attempts to upload a file
                logger.debug("Original file located at URL: \(self.originalURL!)")
                originalFileURL = self.originalURL!
                settings!.set(originalFileURL, forKey: settingsUploadFileLocation)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Deselecting the table row if the user has browsed
        // 'back' through the navigation history
        // See: http://stackoverflow.com/a/33721607
        if let selectedTableRow = tblFileBrowser.indexPathForSelectedRow {
            tblFileBrowser.deselectRow(at: selectedTableRow, animated: true)
        }
        logger.debug("Current path: \(currentPath)")
        
        // Loading the file browser once the view has loaded,
        // as the 'prepareForPresentationInMode' is only called
        // when the view controller originally loads, so the
        // file browser isn't called again when the user taps on
        // a cell with a drive or folder
        loadFileBrowser()
        
        super.viewWillAppear(animated)
    }
    
    
    // MARK: MBProgressHUD
    // The following functions look after showing the HUD during the login
    // progress so that the user knows that something is happening. This
    // is slightly different from the login view controller one, as we need
    // to get it to show on top of the table view
    // See: http://stackoverflow.com/a/26901328
    func hudShow(_ detailLabel: String) {
        hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
        hud.labelText = "Please wait..."
        hud.detailsLabelText = detailLabel
    }
    
    // This is shown when the user selects a file to download
    func hudDownloadShow() {
        hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.detailsLabelText = "Downloading..."
        // See: http://stackoverflow.com/a/26882235
        hud.mode = MBProgressHUDMode.determinateHorizontalBar
    }
    
    /// Updating the detail label that is shown in the HUD
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.2.0-beta
    /// - version: 1
    /// - date: 2015-12-08
    /// - seealso: hudShow
    /// - seealso: hudHide
    ///
    /// - parameter labelText: The text that should be shown for the HUD label
    func hudUpdateLabel(_ labelText: String) {
        hud.detailsLabelText = labelText
    }
    
    // The following functions look after showing the HUD during the download
    // progress so that the user knows that something is happening.
    // See: http://stackoverflow.com/a/26901328
    func hudUploadingShow() {
        hud = MBProgressHUD.showAdded(to: self.navigationController!.view, animated: true)
        hud.detailsLabelText = "Uploading..."
        // See: http://stackoverflow.com/a/26882235
        hud.mode = MBProgressHUDMode.determinateHorizontalBar
    }
    
    /// Updating the progress bar that is shown in the HUD, so the user
    /// knows how far along the download is
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-alpha
    /// - version: 1
    /// - date: 2016-01-06
    /// - seealso: hudShow
    /// - seealso: hudHide
    ///
    /// - parameter currentDownloadedBytes: The amount in bytes that has been uploaded
    /// - parameter totalBytes: The total amount of bytes that is to be uploaded
    func hudUpdatePercentage(_ currentUploadedBytes: Int64, totalBytes: Int64) {
        let currentPercentage = Float(currentUploadedBytes) / Float(totalBytes)
        logger.verbose("Current uploaded percentage: \(currentPercentage * 100)%")
        hud.progress = currentPercentage
    }
    
    func hudHide() {
        MBProgressHUD.hideAllHUDs(for: self.navigationController!.view, animated: true)
    }
    
    /// Gets the list of files, folders or drives to display
    /// then in the file browser table in the master view
    ///
    /// This function is called when the folder is browsed to,
    /// to generate a list of the folders and files contained in it.
    /// This function is also called when the folder is refreshed,
    /// such as pulling down on the table view, deleting a file or
    /// adding a new folder
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.3.0-beta
    /// - version: 2
    /// - date: 2016-02-25
    func loadFileBrowser() {
        // Hiding the built in table refresh control, as the
        // HUD will replace the loading spinner
        //refreshControl.endRefreshing()
        
        // Clearing out all items in the fileItems array, otherwise
        // then the table is refreshed all items are added again
        // so the table will always double in length
        self.fileItems.removeAll()
        
        // Seeing if we are showing the user their available drives
        // or if the user is browsing the folder hierarchy
        if (currentPath == "") {
            // Preventing the "save" button being available
            // if only the drives are being shown
            btnExportMoveFile.isEnabled = false
            logger.debug("Loading the drives available to the user")
            hudShow("Loading drives")
            navigationItem.title = "My Drives"
            // Getting the drives available to the user
            api.getDrives({ (result: Bool, response: AnyObject) -> Void in
                logger.verbose("\(result): \(response)")
                
                // Making sure that the request completed successfully, or
                // let the user know if there was a problem (such as
                // no connection to the Internet)
                if (result) {
                    logger.info("Successfully collected drive JSON data")
                    let json = JSON(response)
                    for (_,subJson) in json {
                        let name = subJson["Name"].string
                        let path = subJson["Path"].string
                        // Seeing if the value returned for the drive from the HAP+
                        // server is a minus value, which should not be displayed
                        // See: https://github.com/stuajnht/HAP-for-iOS/issues/17
                        var space = ""
                        if (subJson["Space"].double! < 0) {
                            logger.debug("Available drive space is reported as less than 0")
                        } else {
                            // Removing the 'optional' text displayed when
                            // converting the space available into a string
                            // See: http://stackoverflow.com/a/25340084
                            space = String(format:"%.2f", subJson["Space"].double!) + "% used"
                        }
                        logger.debug("Drive name: \(name)")
                        logger.debug("Drive path: \(path)")
                        logger.debug("Drive usage: \(space)")
                        
                        // Creating a drive letter to show under the name of the
                        // drive, as this will be familiar to how drives are
                        // presented with letters on Windows
                        let driveLetter = path!.stringByReplacingOccurrencesOfString("\\", withString: ":")
                        
                        // Adding the current files and folders in the directory
                        // to the fileItems array
                        self.addFileItem(name!, path: path!, type: driveLetter + " Drive", fileExtension: "Drive", details: space)
                    }
                    
                    // Hiding the HUD and adding the drives available to the table
                    self.hudHide()
                    
                    // Setting the file browser table to be a delegate for itself,
                    // so that it can be reloaded to show the items returned from
                    // the HAP+ server
                    // See: http://stackoverflow.com/q/30976800
                    self.tblFileBrowser.delegate = self
                    self.tblFileBrowser.dataSource = self
                    self.tblFileBrowser.reloadData()
                } else {
                    logger.warning("There was a problem getting the drive JSON data")
                    self.hudHide()
                    
                    // The cancel and default action styles are back to front, as
                    // the cancel option is bold, which we want the 'try again'
                    // option to be chosen by the user
                    let driveCheckProblemAlert = UIAlertController(title: "Unable to load drives", message: "Please check that you have logged in to the Home Access Plus+ app, then try again", preferredStyle: UIAlertControllerStyle.alert)
                    driveCheckProblemAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                    driveCheckProblemAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.cancel, handler: {(alertAction) -> Void in
                        self.loadFileBrowser() }))
                    self.present(driveCheckProblemAlert, animated: true, completion: nil)
                }
            })
        } else {
            // Enabling the "save" button as the user is browsing
            // the folder, so they should be able to upload
            btnExportMoveFile.isEnabled = true
            logger.debug("Loading the contents of the folder: \(currentPath)")
            hudShow("Loading folder")
            // Show the files and folders in the path the
            // user has browsed to
            //loadSampleFiles()
            api.getFolder(currentPath, callback: { (result: Bool, response: AnyObject) -> Void in
                logger.verbose("\(result): \(response)")
                
                // Making sure that the request completed successfully, or
                // let the user know if there was a problem (such as
                // no connection to the Internet)
                if (result) {
                    logger.info("Successfully collected folder JSON data")
                    let json = JSON(response)
                    for (_,subJson) in json {
                        let name = subJson["Name"].string
                        let type = subJson["Type"].string
                        let modified = subJson["ModifiedTime"].string
                        let fileExtension = subJson["Extension"].string
                        let size = subJson["Size"].string
                        let path = subJson["Path"].string
                        let details = modified! + "    " + size!
                        logger.verbose("Name: \(name)")
                        logger.verbose("Type: \(type)")
                        logger.verbose("Date modified: \(modified)")
                        
                        // Adding the current files and folders in the directory
                        // to the fileItems array
                        self.addFileItem(name!, path: path!, type: type!, fileExtension: fileExtension!, details: details)
                    }
                    self.hudHide()
                    
                    // Setting the file browser table to be a delegate for itself,
                    // so that it can be reloaded to show the items returned from
                    // the HAP+ server
                    // See: http://stackoverflow.com/q/30976800
                    self.tblFileBrowser.delegate = self
                    self.tblFileBrowser.dataSource = self
                    self.tblFileBrowser.reloadData()
                } else {
                    logger.warning("There was a problem getting the folder JSON data")
                    self.hudHide()
                    
                    // The cancel and default action styles are back to front, as
                    // the cancel option is bold, which we want the 'try again'
                    // option to be chosen by the user
                    let folderCheckProblemAlert = UIAlertController(title: "Unable to load folder", message: "Please check that you have a signal, then try again", preferredStyle: UIAlertControllerStyle.alert)
                    folderCheckProblemAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                    folderCheckProblemAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.cancel, handler: {(alertAction) -> Void in
                        self.loadFileBrowser() }))
                    self.present(folderCheckProblemAlert, animated: true, completion: nil)
                }
            })
        }
    }
    
    /// Adds the current item fetched from the JSON response to the array
    /// of files in the directory
    ///
    /// To provide a standard interface to add items in the currently browsed
    /// folder to the fileItems array, this function is called with data
    /// so that the current item can be added
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.3.0-beta
    /// - version: 1
    /// - date: 2015-12-18
    ///
    /// - seealso: fileItems
    ///
    /// - parameter name: File / folder name
    /// - parameter path: Path to the item
    /// - parameter type: The type of item this is (Drive, Directory, File Type)
    /// - parameter fileExtension: The extension of the file, or empty if it is a directory
    /// - parameter details: Additional info for the file (size, modified date, etc...)
    func addFileItem(_ name: String, path: String, type: String, fileExtension: String, details: String) {
        // Creating an array to hold the current item that is being processed
        var currentItem: [AnyObject] = []
        logger.verbose("Adding item to file array, with details:\n --Name: \(name)\n --Path: \(path)\n --Type: \(type)\n --Extension: \(fileExtension)\n --Details: \(details)")
        
        // Adding the current item to the array
        currentItem = [name as AnyObject, path as AnyObject, type as AnyObject, fileExtension as AnyObject, details as AnyObject]
        self.fileItems.append(currentItem as NSArray)
    }
    
    /// Checks to see if the current item is a file or a folder/drive
    ///
    /// There are a number of functions in this class that perform a
    /// different action if the current item is a file or a folder/drive
    ///
    /// This function checks the extension of the file that is passed to
    /// it, and then lets the calling function know if the item is a
    /// folder or not
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.3.0-alpha
    /// - version: 2
    /// - date: 2015-12-15
    ///
    /// - parameter fileType: The type of file according to the HAP+ server
    /// - returns: Is the current item a file or a folder/drive
    func isFile(_ fileType: String) -> Bool {
        // Seeing if this is a Directory based on the file type
        // that has been passed - issue #13
        // The "Drive" value is looked for in any part of the
        // fileType string, as we include the drive letter in
        // the array value - issue #17
        if ((fileType == "") || (fileType.range(of: "Drive") != nil) || (fileType == "Directory")) {
            return false
        } else {
            return true
        }
    }
    
    /// Downloads the file selected by the user onto the device
    ///
    /// Once a user has selected a file to be downloaded, and it
    /// is either a small file or been allowed to download if it's
    /// a big file, then this function is called to download the
    /// file from the HAP+ server onto the device, and then let the
    /// host app know where the file is located so that it can be
    /// opened by it
    ///
    /// - Note: This function is based on the same function in the
    ///         DetailViewController in the main app
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 2
    /// - date: 2016-02-08
    ///
    /// - parameter fileDownloadPath: The location on the HAP+
    ///                               server that the file is being
    ///                               downloaded from
    func downloadFile(_ fileDownloadPath: String) {
        //1
        let filename = String(fileDownloadPath).components(separatedBy: "/").last!
        
        hudDownloadShow()
        api.downloadFile(fileDownloadPath, callback: { (result: Bool, downloading: Bool, downloadedBytes: Int64, totalBytes: Int64, downloadLocation: URL) -> Void in
            
            // There was a problem with downloading the file, so let the
            // user know about it
            if ((result == false) && (downloading == false)) {
                logger.error("There was a problem downloading the file")
                let loginUserFailController = UIAlertController(title: "Unable to download file", message: "The file was not successfully downloaded. Please check and try again", preferredStyle: UIAlertControllerStyle.alert)
                loginUserFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(loginUserFailController, animated: true, completion: nil)
            }
            
            // Seeing if the progress bar should update with the amount
            // currently downloaded, if something is downloading
            if ((result == false) && (downloading == true)) {
                self.hudUpdatePercentage(downloadedBytes, totalBytes: totalBytes)
            }
            
            // The file has downloaded successfuly so we can present the
            // file to the user
            if ((result == true) && (downloading == false)) {
                self.hudHide()
                
                let container: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.uk.co.stuajnht.ios.HomeAccessPlus")!
                
                let imageUrl = downloadLocation
                
                //2
                let outUrl = container.appendingPathComponent(filename)
                // 3
                let coordinator = NSFileCoordinator()
                coordinator.coordinate(writingItemAt: outUrl,
                    options: .forReplacing, error: nil,
                    byAccessor: { newURL in
                    //4
                    let fm = FileManager()
                    fm.delegate = self
                    do {
                        try fm.copyItem(at: imageUrl, to: newURL)
                        logger.debug("File copied from \"\(imageUrl)\" to \"\(newURL)\"")
                    }
                        catch let error as NSError {
                        logger.error("Copy failed with error: \(error.localizedDescription)")
                    }
                })
                // 5
                logger.debug("Dismissing view document picker with URL: \(outUrl)")
                self.dismissGrantingAccess(to: outUrl)
            }
        })
    }
    
    // MARK: NSFileManagerDelegate
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAt srcURL: URL,
            to dstURL: URL) -> Bool {
            return true
    }
    
    // MARK: Export/Move File
    
    /// Uploads the selected file to the HAP+ server in the current
    /// folder
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 2
    /// - date: 2016-02-24
    ///
    /// See: https://github.com/xamarin/monotouch-samples/blob/master/ios8/NewBox/NBox/DocumentPickerViewController.cs#L103
    @IBAction func exportMoveFile(_ sender: AnyObject) {
        logger.verbose("Save button pressed on document provider")
        
        // Export/Move Document Picker mode:
        // Before calling DismissGrantingAccess method, copy the file to the selected destination.
        // Your extensions also need to track the file and make sure it is synced to your server (if needed).
        // After the copy is complete, call DismissGrantingAccess method, and provide the URL to the new copy
        let container: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.uk.co.stuajnht.ios.HomeAccessPlus")!
        let fileName = originalFileURL!.lastPathComponent
        logger.debug("File name of uploaded file: \(fileName)")
        
        let destinationURL = container.appendingPathComponent(fileName)
        logger.debug("Destination URL for file being exported: \(destinationURL)")
        
        // Uploading the file to the HAP+ server
        uploadFile(false, customFileName: "", fileExistsCallback: { Void in
            self.showFileExistsMessage(false)
        })
    }
    
    // MARK: Uploading file
    
    /// Uploads the file from an external app to the HAP+ server,
    /// in the current browsed to folder
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-alpha
    /// - version: 7
    /// - date: 2016-02-25
    ///
    /// - parameter fileFromPhotoLibrary: Is the file being uploaded coming from the photo
    ///                                   library on the device, or from another app
    /// - parameter customFileName: If the file currently exists in the current folder,
    ///                             and the user has chosen to create a new file and
    ///                             not overwrite it, then this is the custom file name
    ///                             that should be used
    func uploadFile(_ fileFromPhotoLibrary: Bool, customFileName: String, fileExistsCallback:@escaping (_ fileExists: Bool) -> Void) -> Void {
        // Holding the location of the file on the device, that
        // is going to be uploaded
        var fileLocation = ""
        
        var fileDeviceLocation : URL
        
        // Seeing if we are uploading a file from another app
        // or the local photo library
        if (fileFromPhotoLibrary == false) {
            logger.debug("Attempting to upload the local file: \(settings!.stringForKey(settingsUploadFileLocation)) to the remote location: \(currentPath)")
            fileLocation = settings!.string(forKey: settingsUploadFileLocation)!
            
            // Converting the fileLocation to be a valid NSURL variable
            fileDeviceLocation = URL(fileURLWithPath: fileLocation)
        } else {
            logger.debug("Attempting to upload the photos file: \(settings!.stringForKey(settingsUploadPhotosLocation)) to the remote location: \(currentPath)")
            fileLocation = settings!.string(forKey: settingsUploadPhotosLocation)!
            
            // Converting the fileLocation to be a valid NSURL variable
            fileDeviceLocation = URL(string: fileLocation)!
        }
        
        hudUploadingShow()
        
        // Seeing if a name for the file needs to be generated
        // or one has already been created from the user choosing
        // to not overwrite a file
        var fileExistsPath = ""
        if (customFileName == "") {
            // Checking to make sure that a file doesn't already
            // exist in the current folder with the same name
            fileExistsPath = currentPath + "/" + String(fileLocation).components(separatedBy: "/").last!
        } else {
            // Use the generated file name with the current file
            // path
            // - NOTE: This shouldn't fail as we've already checked it
            fileExistsPath = currentPath + "/" + customFileName
        }
        
        api.itemExists(fileExistsPath, callback: { (result: Bool) -> Void in
            // The file doesn't currently exist in the current
            // folder, so the new one can be created here
            if (result == false) {
                logger.debug("\"\(fileExistsPath)\" file doesn't exist in \"\(self.currentPath)\", so it can be created")
                
                // Attempting to upload the file that has been passed
                // to the app
                self.api.uploadFile(fileDeviceLocation, serverFileLocation: self.currentPath, fileFromPhotoLibrary: fileFromPhotoLibrary, customFileName: customFileName, callback: { (result: Bool, uploading: Bool, uploadedBytes: Int64, totalBytes: Int64) -> Void in
                    
                    // There was a problem with uploading the file, so let the
                    // user know about it
                    if ((result == false) && (uploading == false)) {
                        let uploadFailController = UIAlertController(title: "Unable to upload file", message: "The file was not successfully uploaded. Please check and try again", preferredStyle: UIAlertControllerStyle.alert)
                        uploadFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        self.present(uploadFailController, animated: true, completion: nil)
                    }
                    
                    // Seeing if the progress bar should update with the amount
                    // currently uploaded, if something is uploading
                    if ((result == false) && (uploading == true)) {
                        self.hudUpdatePercentage(uploadedBytes, totalBytes: totalBytes)
                    }
                    
                    // The file has uploaded successfuly so we can present the
                    // refresh the current folder to show it, and delete the
                    // local copy of the file from the device
                    if ((result == true) && (uploading == false)) {
                        self.hudHide()
                        logger.debug("File has been uploaded to: \(self.currentPath)")
                        
                        // Dismissing the document provider, as the file has
                        // successfully been uploaded
                        self.dismissGrantingAccess(to: settings!.url(forKey: settingsUploadFileLocation))
                        
                        // If the file uploaded is not a photo, then set the
                        // "settingsUploadFileLocation" value to be nil so that
                        // when the user presses the 'add' button again, they
                        // cannot re-upload the file. If they have passed a file
                        // to this app, but have only uploaded a photo, then it
                        // shouldn't be set as nil so they can upload the file at
                        // another time
                        if (fileFromPhotoLibrary == false) {
                            logger.debug("Setting local file location to nil as it's been uploaded")
                            settings!.set(nil, forKey: settingsUploadFileLocation)
                        }
                        
                        // Deleting the local copy of the file that was used to
                        // upload to the HAP+ server
                        self.deleteUploadedLocalFile(fileDeviceLocation)
                    }
                })
            }
            
            // A file currently exists with the same name,
            // so ask the user what they want to do now:
            // overwrite, create a new file or cancel
            if (result == true) {
                logger.info("The \"\(fileExistsPath)\" file already exists in \"\(self.currentPath)\"")
                
                // Setting the alert to be shown when this
                // view controller is shown again to the user,
                // after the upload popover has completed
                self.showFileExistsAlert = true
                
                // Calling the showFileExists alert from the
                // upload popover callback
                fileExistsCallback(fileExists: true)
            }
        })
    }
    
    /// Delete the local version of the file on successful upload
    ///
    /// Once the file has been successfully uploaded, it is not needed
    /// to be stored on the device, so can be deleted to save space
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 2
    /// - date: 2016-01-16
    ///
    /// - parameter deviceFileLocation: The path to the file on the device (either the
    ///                                 Documents folder: photos, videos; Inbox folder: files)
    func deleteUploadedLocalFile(_ fileDeviceLocation: URL) {
        // If the file is coming from an external app, the value
        // in fileDeviceLocation may contain encoded characters
        // in the file name, which the "removeItemAtPath" function
        // doesn't like and can't find the file. These characters
        // need to be decoded before attempting to delete the file
        logger.debug("Original raw path of file to delete: \(fileDeviceLocation)")
        var pathArray = String(describing: fileDeviceLocation).components(separatedBy: "/")
        
        // Getting the name of the file, which is the last item
        // in the pathArray array
        let fileName = pathArray.last!
        
        // Removing any encoded characters from the file name, so
        // the file can be deleted successfully, and saving back
        // into the array in the last position
        let newFileName = fileName.stringByRemovingPercentEncoding!
        pathArray.remove(at: pathArray.index(of: fileName)!)
        pathArray.append(newFileName)
        
        // Joining the items in the array back together, and removing
        // the file:// protocol at the start
        var filePath = pathArray.joined(separator: "/")
        filePath = filePath.replacingOccurrences(of: "file://", with: "")
        
        // See: http://stackoverflow.com/a/32744011
        logger.debug("Attempting to delete the file at location: \(filePath)")
        do {
            try FileManager.default.removeItem(atPath: "\(filePath)")
            logger.debug("Successfully deleted file: \(filePath)")
        }
        catch let errorMessage as NSError {
            logger.error("There was a problem deleting the file: \(errorMessage)")
        }
        catch {
            logger.error("There was an unknown problem when deleting the file.")
        }
    }
    
    /// Checking to see if the file exists alert should be shown to
    /// the user after the upload popover has been dismissed
    ///
    /// As displaying an alert to the user when the upload popover
    /// is disappearing causes the app to crash, this function is
    /// called via delegate callbacks instead which checks to see
    /// if the file exists alert should be shown
    /// See: http://stackoverflow.com/a/25308842
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-beta
    /// - version: 4
    /// - date: 2016-01-29
    ///
    /// - parameter fileFromPhotoLibrary: Is the file being uploaded coming from the photo
    ///                                   library on the device, or from another app
    func showFileExistsMessage(_ fileFromPhotoLibrary: Bool) {
        // Seeing if the overwrite file alert needs to
        // be shown to the user, once the upload popover
        // has been dismissed
        if (showFileExistsAlert) {
            // Forcing a delay to happen before showing the
            // alert to the user. This is in part due to a
            // race condition between the upload popover
            // disappearing and the asynchronous uploadFile
            // returning the callback to call this function,
            // and depends on the speed of the API return.
            // We can do this as the user doesn't know if
            // the delay is due to the uploading of the file
            // starting or a delay in the network connection.
            // If there is something that is likely to break,
            // this is probably the most likely place to check
            // See: http://stackoverflow.com/a/32696605
            let time = DispatchTime(DispatchTime.now()) + Double(1 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.hudHide()
                logger.debug("Overwriting file alert is to be shown")
                
                let fileExistsController = UIAlertController(title: "File already exists", message: "The file already exists in the current folder", preferredStyle: UIAlertControllerStyle.alert)
                fileExistsController.addAction(UIAlertAction(title: "Replace file", style: UIAlertActionStyle.destructive, handler:  {(alertAction) -> Void in
                    self.overwriteFile(true, fileFromPhotoLibrary: fileFromPhotoLibrary) }))
                fileExistsController.addAction(UIAlertAction(title: "Create new file", style: UIAlertActionStyle.default, handler:  {(alertAction) -> Void in
                    self.overwriteFile(false, fileFromPhotoLibrary: fileFromPhotoLibrary) }))
                fileExistsController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                self.present(fileExistsController, animated: true, completion: nil)
                
                // Preventing the alert being shown on each
                // time the view controller is shown
                self.showFileExistsAlert = false
            }
        }
    }
    
    /// Overwrites the file that the user is attempting to
    /// upload, or creates a new file name if they want to
    /// keep both copies
    ///
    /// Based on what the user chooses from the showFileExistsMessage
    /// alert, we either need to delete the previous file in
    /// the current folder then upload the new file, or rename
    /// the file we are attempting to upload so that it doesn't
    /// conflict with any other file in the currently browsed to
    /// folder
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-beta
    /// - version: 3
    /// - date: 2016-04-01
    ///
    /// - parameter overwriteFile: Has the user chosen to overwrite the
    ///                            current file or create a new one
    /// - parameter fileFromPhotoLibrary: Is the file being uploaded coming from the photo
    ///                                   library on the device, or from another app
    func overwriteFile(_ overwriteFile: Bool, fileFromPhotoLibrary: Bool) {
        logger.debug("Overwriting file: \(overwriteFile)")
        logger.debug("File exists in photo library: \(fileFromPhotoLibrary)")
        
        // Seeing if we are uploading a file from another app
        // or the local photo library, and getting the location
        // of the file to generate the file name
        var currentFileName = ""
        if (fileFromPhotoLibrary == false) {
            logger.debug("Modifying the file name of: \(settings!.stringForKey(settingsUploadFileLocation)!)")
            currentFileName = settings!.string(forKey: settingsUploadFileLocation)!
        } else {
            logger.debug("Modifying the file name of: \(settings!.stringForKey(settingsUploadPhotosLocation)!)")
            currentFileName = settings!.string(forKey: settingsUploadPhotosLocation)!
        }
        
        // Seeing if the file should overwrite the currently
        // existing one, or to create a new one
        if (overwriteFile) {
            // Getting the file name from the uploaded path
            let pathArray = String(currentFileName).components(separatedBy: "/")
            
            // Getting just the file name
            var fileName = pathArray.last!
            
            // Removing any encoded characters from the file name
            fileName = fileName.stringByRemovingPercentEncoding!
            
            // Formatting the name of the file to make sure that it is
            // valid for storing on Windows file systems
            fileName = api.formatInvalidName(fileName)
            
            // Finding the index of the file being uploaded on
            // the local fileItems array, so that it can be used
            // in the deleteFile function
            // See: http://www.dotnetperls.com/2d-array-swift
            var indexPosition = -1
            for arrayPosition in 0 ..< fileItems.count {
                if (String(describing: fileItems[arrayPosition][1]).components(separatedBy: "/").last == fileName) {
                    logger.debug("\(fileName) found at fileItems array position: \(arrayPosition)")
                    indexPosition = arrayPosition
                }
            }
            
            // Making sure that the file was found in the fileItems
            // array, before we attempt to delete anything, as a
            // fail safe
            if (indexPosition > -1) {
                // Deleting the file from the current folder
                // See: http://stackoverflow.com/a/29428205
                let indexPath = IndexPath(row: indexPosition, section: 0)
                deleteFile(indexPath, fileOrFolder: "file", fileDeletedCallback: { (fileDeleted: Bool) -> Void in
                    // Waiting to make sure that the file has been
                    // successfully deleted before uploading the
                    // replacement file
                    // NOTE: There is no 'false' here as the deleteFile
                    //       function looks after letting the user know
                    //       that there was a problem
                    if (fileDeleted == true) {
                        // Uploading the file to the HAP+ server
                        self.uploadFile(fileFromPhotoLibrary, customFileName: "", fileExistsCallback: { (fileExists) -> Void in
                            // This callback shouldn't need to be called
                            // from this "checkGeneratedFileName" function
                            // as we should have already ascertained that
                            // the file we're uploading doesn't exist
                            // Still, best to let the user know something
                            // hasn't worked
                            logger.error("Overwriting file deletion succeeded but failed when uploading the file")
                            
                            let overwriteUploadFailedController = UIAlertController(title: "Problem uploading file", message: "Please rename the file and try uploading it again", preferredStyle: UIAlertControllerStyle.alert)
                            overwriteUploadFailedController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                            self.present(overwriteUploadFailedController, animated: true, completion: nil)
                        })
                    }
                })
            } else {
                // Letting the user know there was a problem when
                // trying to find the file in the array
                logger.error("\(fileName) was not found in the current folder")
                
                let fileNotFoundController = UIAlertController(title: "Problem uploading file", message: "Please rename the file and try uploading it again", preferredStyle: UIAlertControllerStyle.alert)
                fileNotFoundController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(fileNotFoundController, animated: true, completion: nil)
            }
        } else {
            // Showing the HUD so that the user knows that something
            // is happening while the file name is being generated
            // and checked
            hudShow("Generating file name")
            
            // Generating a new file name and seeing
            // if that can be uploaded
            checkGeneratedFileName(currentFileName, fileFromPhotoLibrary: fileFromPhotoLibrary)
        }
    }
    
    /// Deletes the file item selected by the user, once they have
    /// confirmed that that actually want to
    ///
    /// Once a user has selected to delete a file, they are alerted
    /// and need to confirm that they are actially sure the file item
    /// is to be deleted. If they confirm so, then this function is
    /// called, which in turn calls the deleteFile function from the
    /// HAPi
    ///
    /// Once a file has been deleted from the HAP+ server, the row
    /// is removed from the table list and file items array, so as
    /// to avoid having to reload the whole folder again
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-alpha
    /// - version: 4
    /// - date: 2016-02-25
    ///
    /// - parameter indexPath: The index in the table and file items array
    ///                        that we are deleting the file item from
    /// - parameter fileOrFolder: Whether the item being deleted is a file
    ///                           or a folder, so that the error message can
    ///                           be customised correctly
    func deleteFile(_ indexPath: IndexPath, fileOrFolder: String, fileDeletedCallback:@escaping (_ fileDeleted: Bool) -> Void) -> Void {
        hudShow("Deleting " + fileOrFolder)
        let deleteItemAtLocation = fileItems[indexPath.row][1] as! String
        api.deleteFile(deleteItemAtLocation, callback: { (result: Bool) -> Void in
            self.hudHide()
            
            // There was a problem with deleting the file item,
            // so let the user know about it
            if (result == false) {
                logger.error("There was a problem deleting the file item: \(deleteItemAtLocation)")
                
                // The cancel and default action styles are back to front, as
                // the cancel option is bold, which we want the 'try again'
                // option to be chosen by the user
                let deletionProblemAlert = UIAlertController(title: "Unable to delete " + fileOrFolder, message: "Please check that you have a signal, then try again", preferredStyle: UIAlertControllerStyle.alert)
                deletionProblemAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil))
                // Setting the try again button style to be cancel, so
                // that it is emboldened in the alert and looks like
                // the default button to press
                deletionProblemAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.cancel, handler: {(alertAction) -> Void in
                    self.deleteFile(indexPath, fileOrFolder: fileOrFolder, fileDeletedCallback: { (fileDeleted: Bool) -> Void in
                        // The code in here shouldn't run, as this is only
                        // used for the overwriting file function
                    })
                }))
                self.present(deletionProblemAlert, animated: true, completion: nil)
            }
            
            // The file was deleted, so remove the item from the
            // table with an animation, instead of reloading the
            // whole folder from the HAP+ server
            if (result == true) {
                logger.info("The file item has been deleted from: \(deleteItemAtLocation)")
                
                // Letting the callback know that the file has been deleted
                fileDeletedCallback(fileDeleted: true)
            }
        })
    }
    
    /// Checks to see if the file currently exists in the current
    /// folder location, and generates an updated name if so
    ///
    /// While this API call is used in uploadFile and deleteFile,
    /// this function is mainly to be used by the overwriteFile
    /// function to check that creating a new file doesn't lead
    /// to another file matching the same name. This function
    /// is designed to be called recursively until there isn't
    /// a matching file name, by repeatedly calling the generateFileName
    /// function on each call of this function
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-beta
    /// - version: 1
    /// - date: 2016-01-28
    ///
    /// - seealso: overwriteFile
    /// - seealso: generateFileName
    /// - seealso: uploadFile
    /// - seealso: deleteFile
    ///
    /// - parameter fileName: The updated name of the file that
    ///                       is to be checked to see if it exists
    /// - parameter fileFromPhotoLibrary: Is the file being uploaded coming from the photo
    ///                                   library on the device, or from another app
    func checkGeneratedFileName(_ fileName: String, fileFromPhotoLibrary: Bool) {
        // Creating a new file name for the file being uploaded
        let newFileName = generateFileName(fileName)
        
        // Checking to make sure that a file doesn't already
        // exist in the current folder with the same name
        logger.debug("Checking that the new file name \"\(newFileName)\" doesn't exist in the current folder")
        api.itemExists(currentPath + "/" + newFileName, callback: { (result: Bool) -> Void in
            // The new file doesn't currently exist in the current
            // folder, so it can be created here
            if (result == false) {
                // Stopping the "please wait" HUD from running, so
                // the upload HUD can be shown instead
                self.hudHide()
                
                logger.debug("\(newFileName) doesn't exist in \(self.currentPath) so it can be uploaded there")
                self.uploadFile(fileFromPhotoLibrary, customFileName: newFileName, fileExistsCallback: { Void in
                    // This callback shouldn't need to be called
                    // from this "checkGeneratedFileName" function
                    // as we should have already ascertained that
                    // the file we're uploading doesn't exist
                    // Still, best to let the user know something
                    // hasn't worked
                    logger.error("Generated file name checking succeeded but failed when uploading the file")
                    
                    let generatedFileNameUploadFailedController = UIAlertController(title: "Problem uploading file", message: "Please rename the file and try uploading it again", preferredStyle: UIAlertControllerStyle.alert)
                    generatedFileNameUploadFailedController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(generatedFileNameUploadFailedController, animated: true, completion: nil)
                })
            }
            
            // This newly generated file name also exists in
            // this folder, so try again with an increased number
            if (result == true) {
                logger.debug("\(newFileName) does exist in \(self.currentPath) so trying again with an updated name")
                self.checkGeneratedFileName(newFileName, fileFromPhotoLibrary: fileFromPhotoLibrary)
            }
        })
    }
    
    /// Generating a custom file name for the file being uploaded
    /// as there is already a file in the current folder with
    /// the same name
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-beta
    /// - version: 1
    /// - date: 2016-01-27
    ///
    /// - parameter currentFileName: The current name of the file
    ///                              is to renamed
    func generateFileName(_ currentFileName: String) -> String {
        logger.debug("Current file name and path: \(currentFileName)")
        // Getting the name of the file from the device location. We
        // can just split the path and get the file name from the last
        // array value
        // fullFileName = ["path", "to", "file-1.ext"]
        let fullFileName = currentFileName.components(separatedBy: "/")
        logger.verbose("fullFileName: \(fullFileName)")
        
        // Getting the name of the file from the full file name
        // fileNameExtension = ["file-1.ext"]
        let fileNameExtension = fullFileName.last!
        logger.verbose("fileNameExtension: \(fileNameExtension)")
        
        // Getting the name of the file less extension
        // fileNameArray = ["file-1", "ext"]
        var fileNameArray = fileNameExtension.components(separatedBy: ".")
        logger.verbose("fileNameArray: \(fileNameArray)")
        
        // Splitting the file name on any hyphenated last characters,
        // to get the number at the end of the name
        // fileNameNumber = ["file", "1"]
        var fileNameNumber = fileNameArray.first!.components(separatedBy: "-")
        logger.verbose("fileNameNumber: \(fileNameNumber)")
        
        // Trying to add 1 to the number at the end, or put a 1
        // if it fails
        // See: http://stackoverflow.com/a/28766901
        var number = 1
        if let myNumber = NumberFormatter().number(from: fileNameNumber.last!) {
            // number = 2
            number = myNumber.intValue + 1
            logger.verbose("number: \(number)")
            
            // Removing the last value of the array, as there was
            // a number in its place
            // fileNameNumber = ["file"]
            fileNameNumber.removeLast()
            logger.verbose("fileNameNumber: \(fileNameNumber)")
        }
        
        // Putting the number into the last element of the array
        // fileNameNumber = ["file", "2"]
        fileNameNumber.append(String(number))
        logger.verbose("fileNameNumber: \(fileNameNumber)")
        
        // Joining the file name with the number at the end
        // fileNameAppended = ["file-2"]
        let fileNameAppended = fileNameNumber.joined(separator: "-")
        logger.verbose("fileNameAppended: \(fileNameAppended)")
        
        // Joining the file name with the extension
        // fileNameArray = ["file-2", "ext"]
        fileNameArray.removeFirst()
        fileNameArray.insert(fileNameAppended, at: 0)
        logger.verbose("fileNameArray: \(fileNameArray)")
        
        // Combining the full name of the file
        // fileName = "file-2.ext"
        var fileName = fileNameArray.joined(separator: ".")
        logger.verbose("fileName: \(fileName)")
        
        // Removing any encoded characters from the file name, so
        // HAP+ saves the file with the correct file name
        // fileName = "file-2.ext"
        fileName = fileName.stringByRemovingPercentEncoding!
        logger.verbose("fileName: \(fileName)")
        
        // Formatting the name of the file to make sure that it is
        // valid for storing on Windows file systems
        // fileName = "file-2.ext"
        fileName = api.formatInvalidName(fileName)
        logger.debug("Formatted new file name: \(fileName)")
        
        return fileName
    }

    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "FileTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! DocumentProviderFileTableViewCell
        
        // Fetches the current file from the fileItems array
        let file = fileItems[indexPath.row]
        
        // Updating the details for the cell
        cell.lblFileName.text = file[0] as? String
        cell.fileIcon((file[2] as? String)!, fileExtension: (file[3] as? String)!)
        
        // Deciding if a disclosure indicator ("next arrow") should be shown
        if (!isFile((file[2] as? String)!)) {
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        } else {
            // Removing the disclosure indicator if the current row
            // is a file and not a folder - issue #13
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // The user has selected a table row, so see if it
        // is a drive or folder, and if so, browse to it.
        // Otherwise, set the file to be downloaded for the
        // host app to use
        // See: http://stackoverflow.com/q/31909072
        let itemPath = fileItems[indexPath.row][1] as! String
        let fileType = fileItems[indexPath.row][2] as! String
        let folderTitle = fileItems[indexPath.row][0] as! String
        if (!isFile(fileType)) {
            logger.debug("Browsing to new folder")
            
            let controller: DocumentPickerViewController = storyboard?.instantiateViewController(withIdentifier: "browser") as! DocumentPickerViewController
            controller.title = folderTitle
            logger.debug("Set title to: \(folderTitle)")
            controller.currentPath = itemPath
            controller.originalFileURL = originalFileURL
            self.navigationController?.pushViewController(controller, animated: true)
        } else {
            downloadFile(itemPath)
        }
    }

}
