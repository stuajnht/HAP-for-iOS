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
//  MasterViewController.swift
//  HomeAccessPlus
//

import UIKit
import ChameleonFramework
import Font_Awesome_Swift
import Locksmith
import MBProgressHUD
import SwiftyJSON

class MasterViewController: UITableViewController, UISplitViewControllerDelegate, UIPopoverPresentationControllerDelegate, uploadFileDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()
    
    // Loading an instance of the HAPi
    let api = HAPi()
    
    // MBProgressHUD variable, so that the detail label can be updated as needed
    var hud : MBProgressHUD = MBProgressHUD()
    
    // Seeing how the app should handle the collapse of the master
    // view in relation to the detail view
    // See: http://nshipster.com/uisplitviewcontroller/
    private var collapseDetailViewController = true
    
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
    
    /// As the loadFileBrowser() function call is inside the
    /// viewDidLoad() function, it gets called before the
    /// app restoration classes are called. This then causes
    /// the table to reload again, which increases the number
    /// of items in it. To prevent this, the loadFileBrowser()
    /// function is only called if this variable is true, and
    /// it is only set to true when the user "browses" the
    /// view controllers. As this variable is not saved in the
    /// state restoration process, it will be false when the
    /// app starts again, and the loadFileBrowser() function
    /// will not be called
    var viewLoadedFromBrowsing : Bool = false
    
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
    
    /// If the multi picker is used in the upload popover, then
    /// this variable is used to see if there is currently a file
    /// being uploaded before attempting to upload the next file
    var uploadingFile : Bool = false
    
    /// If multiple files are to be uploaded, then this variable
    /// should be set to true, so that various functions know
    /// what options to show. This function should not be used
    /// to signify that there is a file being uploaded, instead
    /// uploadingFile should be used
    var multipleFilesUploadEnabled : Bool = false
    
    /// If the multi picker is used, then this array will contain a
    /// list of on-device file path locations, that are used to
    /// know when to upload the file from
    var multipleFilesFileList: NSArray = []
    
    /// If the multi picker is used, then it is useful to know the
    /// total number of files that are to be uploaded, so that the
    /// progress bars can be filled in accordingly
    var multipleFilesTotalFiles = 0
    
    /// If multiple files are being uploaded, keep a count of the current
    /// file number that is being uploaded, so that the progress bars
    /// can be updated correctly
    var multipleFilesCurrentFileNumber = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem

        // Setting a delegate for the split view, to see if the file
        // browser master view should be shown instead of the detail
        // view - see: http://nshipster.com/uisplitviewcontroller/
        splitViewController?.delegate = self
        
        // Setting the navigation bar colour
        self.navigationController?.navigationBar.barTintColor = UIColor(hexString: hapMainColour)
        self.navigationController?.navigationBar.tintColor = UIColor.flatWhiteColor()
        self.navigationController?.navigationBar.translucent = false
        
        // Adding a 'menu' button to the navigation bar to show the
        // upload popover view controller, to allow files passed to
        // this app from an external one to be uploaded, or for photo
        // and video files to be added from the device gallery, or for
        // any other functions included in the popover (new folder, log out)
        let menuButtonImage = UIImage(icon: FAType.FABars, size: CGSizeMake(30, 30))
        let menuButton = UIBarButtonItem(image: menuButtonImage, style: .Plain, target: self, action: #selector(MasterViewController.showUploadPopover(_:)))
        self.navigationItem.rightBarButtonItem = menuButton
        
        // Setting up the ability to refresh the table view when the
        // user is at the top and pulls down, or if there was a problem
        // loading the folder and they want to try again
        // See: https://www.andrewcbancroft.com/2015/03/17/basics-of-pull-to-refresh-for-swift-developers/
        //self.refreshControl?.addTarget(self, action: "loadFileBrowser:", forControlEvents: UIControlEvents.ValueChanged)
        
        // Seeing if the loadFileBrowser() function should be called
        // This should only be called when the user is actively
        // "browsing" the folders, and not when app restoration is
        // taking place
        if (viewLoadedFromBrowsing) {
            logger.debug("Loading file browser")
            // Loading the contents in the folder that has been browsed
            // to, or lising the drives if no folder has been navigated to
            loadFileBrowser()
        } else {
            // When app restoration has taken place, the master view
            // controller does not take on its adjustable appearance, as this
            // is only set when the user browses through their drives. The
            // call to show it again is added here, so that it can be set up
            // properly again
            self.splitViewController?.showMasterView()
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = true
        logger.debug("Current path: \(currentPath)")
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
    /// - version: 1
    /// - date: 2015-12-19
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
                    self.tableView.reloadData()
                    
                    // Showing the master view controller if the device is in portrait
                    // mode (it will have to be shown when the device is in landscape)
                    // This is only done when the file browser has been shown after
                    // initial log on, rather than after browsing each folder
                    self.splitViewController?.showMasterView()
                } else {
                    logger.warning("There was a problem getting the drive JSON data")
                    self.hudHide()
                    
                    // The cancel and default action styles are back to front, as
                    // the cancel option is bold, which we want the 'try again'
                    // option to be chosen by the user
                    let driveCheckProblemAlert = UIAlertController(title: "Unable to load drives", message: "Please check that you have a signal, then try again", preferredStyle: UIAlertControllerStyle.Alert)
                    driveCheckProblemAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                    driveCheckProblemAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel, handler: {(alertAction) -> Void in
                        self.loadFileBrowser() }))
                    self.presentViewController(driveCheckProblemAlert, animated: true, completion: nil)
                }
            })
        } else {
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
                    self.tableView.reloadData()
                } else {
                    logger.warning("There was a problem getting the folder JSON data")
                    self.hudHide()
                    
                    // The cancel and default action styles are back to front, as
                    // the cancel option is bold, which we want the 'try again'
                    // option to be chosen by the user
                    let folderCheckProblemAlert = UIAlertController(title: "Unable to load folder", message: "Please check that you have a signal, then try again", preferredStyle: UIAlertControllerStyle.Alert)
                    folderCheckProblemAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                    folderCheckProblemAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel, handler: {(alertAction) -> Void in
                        self.loadFileBrowser() }))
                    self.presentViewController(folderCheckProblemAlert, animated: true, completion: nil)
                }
            })
        }
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
    func isFile(fileType: String) -> Bool {
        // Seeing if this is a Directory based on the file type
        // that has been passed - issue #13
        // The "Drive" value is looked for in any part of the
        // fileType string, as we include the drive letter in
        // the array value - issue #17
        if ((fileType == "") || (fileType.rangeOfString("Drive") != nil) || (fileType == "Directory")) {
            return false
        } else {
            return true
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
    func addFileItem(name: String, path: String, type: String, fileExtension: String, details: String) {
        // Creating an array to hold the current item that is being processed
        var currentItem: [AnyObject] = []
        logger.verbose("Adding item to file array, with details:\n --Name: \(name)\n --Path: \(path)\n --Type: \(type)\n --Extension: \(fileExtension)\n --Details: \(details)")
        
        // Adding the current item to the array
        currentItem = [name, path, type, fileExtension, details]
        self.fileItems.append(currentItem)
    }
    
    /// Uploads the file from an external app to the HAP+ server,
    /// in the current browsed to folder
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-alpha
    /// - version: 9
    /// - date: 2016-05-16
    ///
    /// - parameter fileFromPhotoLibrary: Is the file being uploaded coming from the photo
    ///                                   library on the device, or from another app
    /// - parameter customFileName: If the file currently exists in the current folder,
    ///                             and the user has chosen to create a new file and
    ///                             not overwrite it, then this is the custom file name
    ///                             that should be used
    func uploadFile(fileFromPhotoLibrary: Bool, customFileName: String, fileExistsCallback:(fileExists: Bool) -> Void) -> Void {
        // Holding the location of the file on the device, that
        // is going to be uploaded
        var fileLocation = ""
        
        var fileDeviceLocation : NSURL
        
        // Seeing if we are uploading a file from another app
        // or the local photo library
        if (fileFromPhotoLibrary == false) {
            logger.debug("Attempting to upload the local file: \(settings!.stringForKey(settingsUploadFileLocation)) to the remote location: \(currentPath)")
            fileLocation = settings!.stringForKey(settingsUploadFileLocation)!
            
            // Converting the fileLocation to be a valid NSURL variable
            fileDeviceLocation = NSURL(fileURLWithPath: fileLocation)
        } else {
            logger.debug("Attempting to upload the photos file: \(settings!.stringForKey(settingsUploadPhotosLocation)) to the remote location: \(currentPath)")
            fileLocation = settings!.stringForKey(settingsUploadPhotosLocation)!
            
            // Converting the fileLocation to be a valid NSURL variable
            fileDeviceLocation = NSURL(string: fileLocation)!
        }
        
        hudUploadingShow()
        
        // Showing the file number currently being uploaded
        // if multiple files are being processed, and there
        // is more than one file being uploaded
        if (multipleFilesTotalFiles > 1) {
            hudUpdateLabel("Uploading file \(multipleFilesCurrentFileNumber) of \(multipleFilesTotalFiles)")
        }
        
        // Seeing if a name for the file needs to be generated
        // or one has already been created from the user choosing
        // to not overwrite a file
        var fileExistsPath = ""
        if (customFileName == "") {
            // Checking to make sure that a file doesn't already
            // exist in the current folder with the same name
            fileExistsPath = currentPath + "/" + String(fileLocation).componentsSeparatedByString("/").last!
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
                        let uploadFailController = UIAlertController(title: "Unable to upload file", message: "The file was not successfully uploaded. Please check and try again", preferredStyle: UIAlertControllerStyle.Alert)
                        uploadFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(uploadFailController, animated: true, completion: nil)
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
                        logger.debug("File has been uploaded to: \(self.currentPath)")
                        
                        // If the file uploaded is not a photo, then set the
                        // "settingsUploadFileLocation" value to be nil so that
                        // when the user presses the 'add' button again, they
                        // cannot re-upload the file. If they have passed a file
                        // to this app, but have only uploaded a photo, then it
                        // shouldn't be set as nil so they can upload the file at
                        // another time
                        if (fileFromPhotoLibrary == false) {
                            logger.debug("Setting local file location to nil as it's been uploaded")
                            settings!.setURL(nil, forKey: settingsUploadFileLocation)
                        }
                        
                        // Deleting the local copy of the file that was used to
                        // upload to the HAP+ server
                        self.deleteUploadedLocalFile(fileDeviceLocation)
                        
                        // Hiding the HUD from view. If only a single file is
                        // being uploaded, then multipleFilesUploadEnabled will
                        // be false and the HUD will be hidden once the upload
                        // has taken place. If multiple files are being uploaded,
                        // then only on the last file when multipleFilesUploadEnabled
                        // is set to false again will the HUD be hidden
                        // The file browser table is also only refreshed once all
                        // files have been uploaded, due to 1) the refreshing HUD
                        // overlays the upload progress bar and looks messy and,
                        // 2) it's easier to have to write the code to only hide
                        // the HUD once all the files have been uploaded than
                        // also prevent the HUD from hiding on the loading of the
                        // file browser function
                        if (!self.multipleFilesUploadEnabled) {
                            self.hudHide()
                            
                            // Refreshing the file browser table
                            self.loadFileBrowser()
                            
                            // Resetting the multipleFilesCurrentFileNumber and
                            // multipleFilesTotalFiles so that in the future
                            // multi uploads can take place, if some uploads have
                            // already happened, and also if the user swaps to
                            // the single uploader it doesn't show an incorrect
                            // "Uploading file x of y" HUD message
                            self.multipleFilesCurrentFileNumber = 0
                            self.multipleFilesTotalFiles = 0
                        }
                        
                        // Letting any calling functions know that there are
                        // currently no files being uploaded (mainly the multiple
                        // file uploader)
                        self.uploadingFile = false
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
    
    // MARK: Multiple Files
    
    /// Processes a list of multiple files to upload, and uploads them
    ///
    /// If the multi picker is used in the upload popover, then simply
    /// calling the uploadFile() function multiple times from it results
    /// in quite a large mess (the progress bars jump, not all files are
    /// uploaded, remnants of files are left on the device as they're not
    /// deleted on upload, multiple renamings don't show) as that function
    /// is only intended to upload one file at a time
    ///
    /// This function takes a list of file locations and sets them up ready
    /// to be processed by the uploadMultipleFilesCheck function, as the timer
    /// for that function is started once this function has been called
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.8.0-alpha
    /// - version: 4
    /// - date: 2016-05-16
    ///
    /// - seealso: uploadFile
    /// - seealso: uploadMultipleFilesCheck
    ///
    /// - parameter uploadFileLocations: The on-device file locations of the
    ///                                  files to be uploaded
    func uploadMultipleFiles(uploadFileLocations: NSArray) {
        logger.debug("Uploading multiple files from the following locations: \(uploadFileLocations)")
        
        // Saving the total number of file items being uploaded, so
        // that the current upload progress can be monitored
        multipleFilesTotalFiles = uploadFileLocations.count
        
        // Adding the list of files to upload to the current class
        // multipleFilesFileList, so that it can be removed once
        // a file has been uploaded
        multipleFilesFileList = uploadFileLocations
        
        // Setting the variable to signify multiple files are to be
        // uploaded, so that the uploadFile function knows what to
        // display and remove from the array
        multipleFilesUploadEnabled = true
        
        // Starting a timer loop to check if there's a file currently
        // uploading to the server. If there is, then wait until the
        // file has been uploaded (or renamed) before attempting to
        // upload the next file. This also allows the upload popover
        // to be removed from display while the uploads carry on
        // A NSTimer isn't used here, as for some unknown reason the
        // timer will not fire when any videos are attempted to be
        // uploaded, yet will work every time multiple photos are
        // processed. I don't know why this is, and probably at some
        // point I will realise why, but until then, calling this
        // code seems to do what is needed, albeit partially hacky
        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.uploadMultipleFilesCheck()
        }
    }
    
    /// Checks to see if there are currently any files to be uploaded
    ///
    /// This function takes a list of file locations and processes them
    /// synchronously, after each file has been uploaded, by waiting
    /// until the uploadFile() function has finished uploading a file.
    /// It is called every second from the multipleFilesUploadTimer that
    /// was started in the uploadMultipleFiles function
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.8.0-alpha
    /// - version: 3
    /// - date: 2016-05-16
    ///
    /// - seealso: uploadMultipleFiles
    /// - seealso: uploadMultipleFilesCheck
    func uploadMultipleFilesCheck() {
        // Seeing if there is currently a file being uploaded,
        // or if there is an available slot to attempt the
        // upload, and we haven't reached the total number of
        // files that are to be uploaded
        if ((self.uploadingFile == false) && (self.multipleFilesCurrentFileNumber < self.multipleFilesTotalFiles)) {
            logger.debug("There are currently no files being uploaded. Attempting upload of next picked multiple file")
            
            // Setting the uploading file variable to be true, so
            // that this function doesn't get called again too early.
            // This is done here and not in the uploadFile function
            // as the fileExists checks may still be taking place
            // when this is called on the next timer tick
            self.uploadingFile = true
            
            // Updating the file number that is currently being uploaded
            // so that the progress bars can be drawn correctly
            self.multipleFilesCurrentFileNumber += 1
            logger.debug("Attempting upload of multiple file number \(self.multipleFilesCurrentFileNumber) of \(self.multipleFilesTotalFiles)")
            
            // Setting the location of the file in the settings, so
            // that the uploadFile function can access it. The path
            // used is pulled from the array index of the
            // multipleFilesCurrentFileNumber variable, less 1 as arrays
            // start on 0
            logger.debug("Attempting upload of file at on-device location: \(self.multipleFilesFileList[self.multipleFilesCurrentFileNumber - 1])")
            settings!.setObject(self.multipleFilesFileList[self.multipleFilesCurrentFileNumber - 1], forKey: settingsUploadPhotosLocation)
            
            // Uploading the file to the HAP+ server
            self.uploadFile(true, customFileName: "", fileExistsCallback: { Void in
                self.showFileExistsMessage(true)
            })
        }
        
        // Stopping the multiple files upload checks if the number
        // of files to upload has been reached. The timer check is
        // re-run on each call to this function if the number of
        // files uploaded isn't the total number to be uploaded.
        // A NSTimer isn't used here, as for some unknown reason the
        // timer will not fire when any videos are attempted to be
        // uploaded, yet will work every time multiple photos are
        // processed. I don't know why this is, and probably at some
        // point I will realise why, but until then, calling this
        // code seems to do what is needed, albeit partially hacky
        if (self.multipleFilesCurrentFileNumber < self.multipleFilesTotalFiles) {
            let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
            dispatch_after(time, dispatch_get_main_queue()) {
                logger.verbose("Files are still to be uploaded. Running multiple upload files timer check again")
                self.uploadMultipleFilesCheck()
            }
        } else {
            logger.debug("Stopping the multiple files upload timer check as all selected files have been uploaded")
            
            // Setting multiple files uploading to be false so that
            // the HUD can be hidden when the last file is uploaded
            self.multipleFilesUploadEnabled = false
        }
    }
    
    /// Creates a new folder inside the currently browsed to folder
    ///
    /// This function will be called from the upload popover delegate
    /// once the user has named the folder. This function will then
    /// format the folder name, pass it to the HAPi to create the
    /// folder, then reload the file browser table on successful
    /// folder creation
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-alpha
    /// - version: 4
    /// - date: 2016-01-29
    ///
    /// - parameter folderName: The name of the folder to be created
    func newFolder(folderName: String) {
        hudShow("Creating \"" + folderName + "\" folder")
        logger.debug("Folder name from delegate callback: \(folderName)")
        
        // Checking to make sure that a folder doesn't already
        // exist in the current folder with the same name
        api.itemExists(currentPath + "/" + api.formatInvalidName(folderName), callback: { (result: Bool) -> Void in
            // The folder doesn't currently exist in the current
            // folder, so the new one can be created here
            if (result == false) {
                logger.debug("\"\(folderName)\" folder doesn't exist in \"\(self.currentPath)\", so it can be created")
                // Calling the HAPi to create the new folder
                self.api.newFolder(self.currentPath, newFolderName: folderName, callback: { (result: Bool) -> Void in
                    self.hudHide()
                    
                    // There was a problem with creating the folder, so let the
                    // user know about it
                    if (result == false) {
                        // Forcing a delay to happen before showing the
                        // alert to the user. See explanation further down
                        // in this function (where result==false) for more
                        // information on why this is needed
                        let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
                        dispatch_after(time, dispatch_get_main_queue()) {
                            let uploadFailController = UIAlertController(title: "Unable to create folder", message: "The folder was not successfully created. Please check and try again", preferredStyle: UIAlertControllerStyle.Alert)
                            uploadFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            self.presentViewController(uploadFailController, animated: true, completion: nil)
                        }
                    }
                    
                    // The folder has been created successfuly so we can present and
                    // refresh the current folder to show it
                    if (result == true) {
                        logger.debug("A new folder has been created in: \(self.currentPath)")
                        
                        // Refreshing the file browser table
                        self.loadFileBrowser()
                    }
                })
            }
            
            // A folder currently exists with the same name,
            // so let the user know that they can't create
            // another one in it
            if (result == true) {
                // Forcing a delay to happen before showing the
                // alert to the user. This is in part due to a
                // race condition between the upload popover
                // disappearing and the asynchronous newFolder
                // returning the callback to call this function,
                // and depends on the speed of the API return.
                // We can do this as the user doesn't know if
                // the delay is due to the creation of the folder
                // starting or a delay in the network connection.
                // If there is something that is likely to break,
                // this is probably the most likely place to check
                // Seealso: showFileExistsMessage
                // See: http://stackoverflow.com/a/32696605
                let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
                dispatch_after(time, dispatch_get_main_queue()) {
                    self.hudHide()
                    logger.info("The \"\(folderName)\" folder already exists in \"\(self.currentPath)\"")
                    
                    let folderExistsController = UIAlertController(title: "Folder already exists", message: "The folder already exists in the current folder", preferredStyle: UIAlertControllerStyle.Alert)
                    folderExistsController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(folderExistsController, animated: true, completion: nil)
                }
            }
        })
    }
    
    
    // MARK: MBProgressHUD
    // The following functions look after showing the HUD during the login
    // progress so that the user knows that something is happening. This
    // is slightly different from the login view controller one, as we need
    // to get it to show on top of the table view
    // See: http://stackoverflow.com/a/26901328
    func hudShow(detailLabel: String) {
        hud = MBProgressHUD.showHUDAddedTo(self.navigationController!.view, animated: true)
        hud.labelText = "Please wait..."
        hud.detailsLabelText = detailLabel
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
    func hudUpdateLabel(labelText: String) {
        hud.detailsLabelText = labelText
    }
    
    // The following functions look after showing the HUD during the download
    // progress so that the user knows that something is happening.
    // See: http://stackoverflow.com/a/26901328
    func hudUploadingShow() {
        hud = MBProgressHUD.showHUDAddedTo(self.navigationController!.view, animated: true)
        hud.detailsLabelText = "Uploading..."
        // See: http://stackoverflow.com/a/26882235
        hud.mode = MBProgressHUDMode.DeterminateHorizontalBar
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
    func hudUpdatePercentage(currentUploadedBytes: Int64, totalBytes: Int64) {
        let currentPercentage = Float(currentUploadedBytes) / Float(totalBytes)
        logger.verbose("Current uploaded percentage: \(currentPercentage * 100)%")
        hud.progress = currentPercentage
    }
    
    func hudHide() {
        MBProgressHUD.hideAllHUDsForView(self.navigationController!.view, animated: true)
    }

    // MARK: - Segues

    /// Performs the segue to the detail view
    ///
    /// If the user has selected a file, then we can perform the
    /// segue that shows the file properties (detail) view so
    /// the user can preview and share the file to other apps
    ///
    /// This function will not be called if the selected table
    /// row item is not a file, as the user is still browsing
    /// the folder hierarchy - issue #16
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - date: 2016-01-13
    ///
    /// - seealso: shouldPerformSegueWithIdentifier
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Showing the file properties view and segue, as long as
        // it's a file that has been selected, otherwise the segue
        // is cancelled in shouldPerformSegueWithIdentifier
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let fileType = fileItems[indexPath.row][2] as! String
                let filePath = fileItems[indexPath.row][1] as! String
                let fileName = fileItems[indexPath.row][0] as! String
                let fileExtension = fileItems[indexPath.row][3] as! String
                let fileDetails = fileItems[indexPath.row][4] as! String
                
                // Show the detail view with the file info
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.fileName = fileName
                controller.fileType = fileType
                controller.fileDetails = fileDetails
                controller.fileDownloadPath = filePath
                controller.fileExtension = fileExtension
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    /// Preventing the segue to the detail view if a file
    /// has not been selected
    ///
    /// If a file has not yet been selected by the user, then
    /// they must still be browsing the folder hierarchy. We
    /// do not want to display the file properties (detail)
    /// view yet, as it will push over the current folder,
    /// impeding navigation as the user will constantly keep
    /// having to press the back button to see the folder
    /// issue #16
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-13
    ///
    /// - seealso: prepareForSegue
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        // Preventing the detail view being shown on small screen
        // devices if a file has not yet been selected by the user
        // See: https://github.com/stuajnht/HAP-for-iOS/issues/16
        if identifier == "showDetail" {
            logger.debug("Seeing if detail segue should be performed")
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let fileType = fileItems[indexPath.row][2] as! String
                let folderTitle = fileItems[indexPath.row][0] as! String
                if (!isFile(fileType)) {
                    logger.debug("Detail view segue is not being performed")
                    
                    // Stop the segue and follow the path
                    // See: http://stackoverflow.com/q/31909072
                    let controller: MasterViewController = storyboard?.instantiateViewControllerWithIdentifier("browser") as! MasterViewController
                    controller.title = folderTitle
                    logger.debug("Set title to: \(folderTitle)")
                    controller.currentPath = fileItems[indexPath.row][1] as! String
                    controller.viewLoadedFromBrowsing = true
                    self.navigationController?.pushViewController(controller, animated: true)
                    return false
                } else {
                    // A file has been selected, so perform the segue
                    logger.debug("Detail view segue will be performed")
                    return true
                }
            }
        }
        
        // By default, perform the transition
        return true
    }
    
    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "FileTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! FileTableViewCell
        
        // Fetches the current file from the fileItems array
        let file = fileItems[indexPath.row]
        
        // Updating the details for the cell
        cell.lblFileName.text = file[0] as? String
        cell.lblFileType.text = file[2] as? String
        cell.lblFileDetails.text = file[4] as? String
        cell.fileIcon((file[2] as? String)!, fileExtension: (file[3] as? String)!)
        
        // Deciding if a disclosure indicator ("next arrow") should be shown
        if (!isFile((file[2] as? String)!)) {
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        } else {
            // Removing the disclosure indicator if the current row
            // is a file and not a folder - issue #13
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    /// Preventing the swipe to delete action if "My Drives" is
    /// the currenty active view
    ///
    /// As users cannot delete their drives, if they are on the
    /// "My Drives" view then the ability to swipe to delete
    /// should be disabled
    /// See: http://stackoverflow.com/a/31040496
    ///
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.6.0-alpha
    /// - version: 1
    /// - date: 2016-01-20
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        // Seeing if we are showing the user their available drives
        // or if the user is browsing the folder hierarchy
        if (currentPath == "") {
            return UITableViewCellEditingStyle.None
        } else {
            return UITableViewCellEditingStyle.Delete
        }
    }

    // Deleting the file item on the currently selected row
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Fetches the current file from the fileItems array
            let file = fileItems[indexPath.row]
            
            // Seeing if the item selected is a file or folder, so
            // that the alert to the user is customised
            var fileOrFolder = "file"
            if (!isFile((file[2] as? String)!)) {
                fileOrFolder = "folder"
            }
            
            // Checking with the user that they actually want to
            // delete the file item that they have selected
            let deleteConfirmation = UIAlertController(title: "Delete " + fileOrFolder, message: "Are you sure that you want to delete this " + fileOrFolder + "?", preferredStyle: UIAlertControllerStyle.Alert)
            deleteConfirmation.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: {(alertAction) -> Void in
                self.deleteFile(indexPath, fileOrFolder: fileOrFolder, fileDeletedCallback: { (fileDeleted: Bool) -> Void in
                    // The code in here shouldn't run, as this is only
                    // used for the overwriting file function
                })
            }))
            deleteConfirmation.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(alertAction) -> Void in
                    // Removing the delete button being shown
                    // See: http://stackoverflow.com/a/22063692
                    self.tableView.setEditing(false, animated: true)
                }))
            self.presentViewController(deleteConfirmation, animated: true, completion: nil)
            
            //objects.removeAtIndex(indexPath.row)
            //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        //} else if editingStyle == .Insert {
            //// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let row = indexPath.row //2
        ////let section = indexPath.section//3
        //let fileName = fileItems[row][0] //4
        //newFolder = fileName as! String
        //logger.debug("Folder heading to title: \(newFolder)")
        
        // The user has selected something, so collapse the view
        collapseDetailViewController = false
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
    /// - version: 3
    /// - date: 2016-01-28
    ///
    /// - parameter indexPath: The index in the table and file items array
    ///                        that we are deleting the file item from
    /// - parameter fileOrFolder: Whether the item being deleted is a file
    ///                           or a folder, so that the error message can
    ///                           be customised correctly
    func deleteFile(indexPath: NSIndexPath, fileOrFolder: String, fileDeletedCallback:(fileDeleted: Bool) -> Void) -> Void {
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
                let deletionProblemAlert = UIAlertController(title: "Unable to delete " + fileOrFolder, message: "Please check that you have a signal, then try again", preferredStyle: UIAlertControllerStyle.Alert)
                deletionProblemAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {(alertAction) -> Void in
                    // Removing the delete button being shown, if the
                    // user cancels the deletion attempt
                    // See: http://stackoverflow.com/a/22063692
                    self.tableView.setEditing(false, animated: true)
                }))
                // Setting the try again button style to be cancel, so
                // that it is emboldened in the alert and looks like
                // the default button to press
                deletionProblemAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel, handler: {(alertAction) -> Void in
                    self.deleteFile(indexPath, fileOrFolder: fileOrFolder, fileDeletedCallback: { (fileDeleted: Bool) -> Void in
                        // The code in here shouldn't run, as this is only
                        // used for the overwriting file function
                    })
                }))
                self.presentViewController(deletionProblemAlert, animated: true, completion: nil)
            }
            
            // The file was deleted, so remove the item from the
            // table with an animation, instead of reloading the
            // whole folder from the HAP+ server
            if (result == true) {
                logger.info("The file item has been deleted from: \(deleteItemAtLocation)")
                self.fileItems.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                
                // Letting the callback know that the file has been deleted
                fileDeletedCallback(fileDeleted: true)
            }
        })
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    /// Sees if the master view should be shown instead of the detail
    /// view on small screen devices
    ///
    /// For devices that have a small screen, we want the file browser
    /// to always be shown to the user before the detail view, which
    /// is shown once a user selects a file to preview. This function
    /// looks after that happening - issue #16
    /// See: http://nshipster.com/uisplitviewcontroller/
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-13
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        logger.debug("Master view being shown: \(collapseDetailViewController)")
        return collapseDetailViewController
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
    func deleteUploadedLocalFile(fileDeviceLocation: NSURL) {
        // If the file is coming from an external app, the value
        // in fileDeviceLocation may contain encoded characters
        // in the file name, which the "removeItemAtPath" function
        // doesn't like and can't find the file. These characters
        // need to be decoded before attempting to delete the file
        logger.debug("Original raw path of file to delete: \(fileDeviceLocation)")
        var pathArray = String(fileDeviceLocation).componentsSeparatedByString("/")
        
        // Getting the name of the file, which is the last item
        // in the pathArray array
        let fileName = pathArray.last!
        
        // Removing any encoded characters from the file name, so
        // the file can be deleted successfully, and saving back
        // into the array in the last position
        let newFileName = fileName.stringByRemovingPercentEncoding!
        pathArray.removeAtIndex(pathArray.indexOf(fileName)!)
        pathArray.append(newFileName)
        
        // Joining the items in the array back together, and removing
        // the file:// protocol at the start
        var filePath = pathArray.joinWithSeparator("/")
        filePath = filePath.stringByReplacingOccurrencesOfString("file://", withString: "")
        
        // See: http://stackoverflow.com/a/32744011
        logger.debug("Attempting to delete the file at location: \(filePath)")
        do {
            try NSFileManager.defaultManager().removeItemAtPath("\(filePath)")
                        logger.debug("Successfully deleted file: \(filePath)")
        }
        catch let errorMessage as NSError {
            logger.error("There was a problem deleting the file: \(errorMessage)")
        }
        catch {
            logger.error("There was an unknown problem when deleting the file.")
        }
    }
    
    // MARK: Upload popover
    func showUploadPopover(sender: UIBarButtonItem) {
        // See: http://www.appcoda.com/presentation-controllers-tutorial/
        // See: http://stackoverflow.com/a/28291804
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("fileUploadPopover") as! UploadPopoverTableViewController
        vc.delegate = self
        if (currentPath == "") {
            vc.showingOnEmptyFilePath = true
        }
        vc.modalPresentationStyle = UIModalPresentationStyle.Popover
        vc.preferredContentSize = CGSize(width: 320, height: 480)
        if let popover: UIPopoverPresentationController = vc.popoverPresentationController! {
            popover.barButtonItem = sender
            popover.delegate = self
        }
        presentViewController(vc, animated: true, completion:nil)
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
    /// - version: 5
    /// - date: 2016-05-23
    ///
    /// - parameter fileFromPhotoLibrary: Is the file being uploaded coming from the photo
    ///                                   library on the device, or from another app
    func showFileExistsMessage(fileFromPhotoLibrary: Bool) {
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
            let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 1 * Int64(NSEC_PER_SEC))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.hudHide()
                logger.debug("Overwriting file alert is to be shown")
                
                // Generating the name of the file that is being uploaded,
                // so that the user knows what file is going to be overwritten
                // (even if it's not that useful to them, e.g. IMG_2389.png)
                // This code is a shortened version of that used in uploadFile()
                var fileLocation = ""
                if (fileFromPhotoLibrary == false) {
                    fileLocation = settings!.stringForKey(settingsUploadFileLocation)!
                } else {
                    fileLocation = settings!.stringForKey(settingsUploadPhotosLocation)!
                }
                
                let fileName = String(fileLocation).componentsSeparatedByString("/").last!
                
                let fileExistsController = UIAlertController(title: "File already exists", message: "The file \"\(fileName)\" already exists in the current folder", preferredStyle: UIAlertControllerStyle.Alert)
                fileExistsController.addAction(UIAlertAction(title: "Replace file", style: UIAlertActionStyle.Destructive, handler:  {(alertAction) -> Void in
                    self.overwriteFile(true, fileFromPhotoLibrary: fileFromPhotoLibrary) }))
                fileExistsController.addAction(UIAlertAction(title: "Create new file", style: UIAlertActionStyle.Default, handler:  {(alertAction) -> Void in
                    self.overwriteFile(false, fileFromPhotoLibrary: fileFromPhotoLibrary) }))
                fileExistsController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(fileExistsController, animated: true, completion: nil)
                
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
    func overwriteFile(overwriteFile: Bool, fileFromPhotoLibrary: Bool) {
        logger.debug("Overwriting file: \(overwriteFile)")
        logger.debug("File exists in photo library: \(fileFromPhotoLibrary)")
        
        // Seeing if we are uploading a file from another app
        // or the local photo library, and getting the location
        // of the file to generate the file name
        var currentFileName = ""
        if (fileFromPhotoLibrary == false) {
            logger.debug("Modifying the file name of: \(settings!.stringForKey(settingsUploadFileLocation)!)")
            currentFileName = settings!.stringForKey(settingsUploadFileLocation)!
        } else {
            logger.debug("Modifying the file name of: \(settings!.stringForKey(settingsUploadPhotosLocation)!)")
            currentFileName = settings!.stringForKey(settingsUploadPhotosLocation)!
        }
        
        // Seeing if the file should overwrite the currently
        // existing one, or to create a new one
        if (overwriteFile) {
            // Getting the file name from the uploaded path
            let pathArray = String(currentFileName).componentsSeparatedByString("/")
            
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
                if (String(fileItems[arrayPosition][1]).componentsSeparatedByString("/").last == fileName) {
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
                let indexPath = NSIndexPath(forRow: indexPosition, inSection: 0)
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
                            
                            let overwriteUploadFailedController = UIAlertController(title: "Problem uploading file", message: "Please rename the file and try uploading it again", preferredStyle: UIAlertControllerStyle.Alert)
                            overwriteUploadFailedController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                            self.presentViewController(overwriteUploadFailedController, animated: true, completion: nil)
                        })
                    }
                })
            } else {
                // Letting the user know there was a problem when
                // trying to find the file in the array
                logger.error("\(fileName) was not found in the current folder")
                
                let fileNotFoundController = UIAlertController(title: "Problem uploading file", message: "Please rename the file and try uploading it again", preferredStyle: UIAlertControllerStyle.Alert)
                fileNotFoundController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(fileNotFoundController, animated: true, completion: nil)
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
    func checkGeneratedFileName(fileName: String, fileFromPhotoLibrary: Bool) {
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
                    
                    let generatedFileNameUploadFailedController = UIAlertController(title: "Problem uploading file", message: "Please rename the file and try uploading it again", preferredStyle: UIAlertControllerStyle.Alert)
                    generatedFileNameUploadFailedController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(generatedFileNameUploadFailedController, animated: true, completion: nil)
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
    func generateFileName(currentFileName: String) -> String {
        logger.debug("Current file name and path: \(currentFileName)")
        // Getting the name of the file from the device location. We
        // can just split the path and get the file name from the last
        // array value
        // fullFileName = ["path", "to", "file-1.ext"]
        let fullFileName = currentFileName.componentsSeparatedByString("/")
        logger.verbose("fullFileName: \(fullFileName)")
        
        // Getting the name of the file from the full file name
        // fileNameExtension = ["file-1.ext"]
        let fileNameExtension = fullFileName.last!
        logger.verbose("fileNameExtension: \(fileNameExtension)")
        
        // Getting the name of the file less extension
        // fileNameArray = ["file-1", "ext"]
        var fileNameArray = fileNameExtension.componentsSeparatedByString(".")
        logger.verbose("fileNameArray: \(fileNameArray)")
        
        // Splitting the file name on any hyphenated last characters,
        // to get the number at the end of the name
        // fileNameNumber = ["file", "1"]
        var fileNameNumber = fileNameArray.first!.componentsSeparatedByString("-")
        logger.verbose("fileNameNumber: \(fileNameNumber)")
        
        // Trying to add 1 to the number at the end, or put a 1
        // if it fails
        // See: http://stackoverflow.com/a/28766901
        var number = 1
        if let myNumber = NSNumberFormatter().numberFromString(fileNameNumber.last!) {
            // number = 2
            number = myNumber.integerValue + 1
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
        let fileNameAppended = fileNameNumber.joinWithSeparator("-")
        logger.verbose("fileNameAppended: \(fileNameAppended)")
        
        // Joining the file name with the extension
        // fileNameArray = ["file-2", "ext"]
        fileNameArray.removeFirst()
        fileNameArray.insert(fileNameAppended, atIndex: 0)
        logger.verbose("fileNameArray: \(fileNameArray)")
        
        // Combining the full name of the file
        // fileName = "file-2.ext"
        var fileName = fileNameArray.joinWithSeparator(".")
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
    
    // MARK: Log out user
    
    /// Logs the user out of the app and shows the root view
    ///
    /// When a user has finished with using the app to browse
    /// their files, and wants to pass the device onto another
    /// person, then they should be logged out and their logon
    /// tokens and other settings removed
    ///
    /// - note: Most of this function has now moved in the to HAPi
    ///         class, so that it can be called by the AppDelegate
    ///         and this function
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 6
    /// - date: 2016-06-16
    ///
    /// - seealso: toggleMasterView
    func logOutUser() {
        // Calling the log out function
        api.logOutUser()
        
        // Stopping the app delegate check timers, so as to
        // avoid updating the last successful contact time
        // for the API if no user is logged in to the app or
        // attempting to log the user out
        logger.debug("Stopping check timers as no user is logged in")
        let delegate = UIApplication.sharedApplication().delegate as? AppDelegate
        delegate!.stopTimers()
        
        // Hiding the master view controller before the modal
        // is dismissed, as attempting to log out of the app when
        // a large screen device is in portrait mode causes the
        // master view to remain in place, which then causes the
        // app to crash from then on (app restoration won't catch
        // this, as the app starts up, but crashes when trying to
        // interact with anything as some settings are nil)
        // See: http://stackoverflow.com/a/34560694
        self.splitViewController?.hideMasterView()
        
        // Removing all of the navigation views and showing
        // the login view controller
        // See: http://sketchytech.blogspot.co.uk/2012/09/return-to-root-view-controller-from.html
        self.view.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.FullScreen
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        let btnCancelUploadPopover = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: #selector(MasterViewController.dismiss))
        navigationController.topViewController!.navigationItem.rightBarButtonItem = btnCancelUploadPopover
        // Setting the navigation bar colour
        navigationController.topViewController!.navigationController!.navigationBar.barTintColor = UIColor(hexString: hapMainColour)
        navigationController.topViewController!.navigationController!.navigationBar.tintColor = UIColor.flatWhiteColor()
        navigationController.topViewController!.navigationController!.navigationBar.translucent = false
        return navigationController
    }
    
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: App Restoration
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        // Saving the variables used in this class so that they
        // can be restored at when the app is opened again
        coder.encodeObject(detailViewController, forKey: "detailViewController")
        coder.encodeObject(objects, forKey: "objects")
        coder.encodeBool(collapseDetailViewController, forKey: "collapseDetailViewController")
        coder.encodeBool(showFileExistsAlert, forKey: "showFileExistsAlert")
        coder.encodeObject(currentPath, forKey: "currentPath")
        coder.encodeObject(self.fileItems, forKey: "fileItems")
        
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        // Restoring the variables used in this class
        // See: http://troutdev.blogspot.co.uk/2014/12/uistaterestoring-in-swift.html
        detailViewController = coder.decodeObjectForKey("detailViewController") as? DetailViewController
        objects = coder.decodeObjectForKey("objects") as! [AnyObject]
        collapseDetailViewController = coder.decodeBoolForKey("collapseDetailViewController")
        showFileExistsAlert = coder.decodeBoolForKey("showFileExistsAlert")
        currentPath = coder.decodeObjectForKey("currentPath") as! String
        self.fileItems = coder.decodeObjectForKey("fileItems") as! [NSArray]
        
        super.decodeRestorableStateWithCoder(coder)
    }


}

/// Extending the appearance of the master view controller
/// in the split view controller, so that it can be hidden
/// or shown manually, as well as toggled if needed
///
/// If the device is in portrait mode and the user logs out,
/// the master view controller doesn't become hidden, leading
/// any subsequent actions in the app to cause it to crash.
/// The only way to get out of this infinate loop is to remove
/// and reinstall the app (app restoration won't catch this
/// as the app starts up, but crashes when trying to interact
/// with anything as some settings are nil). The hide function
/// is called during logging out of the device, to cause the
/// master view controller to hide before continuing
///
/// If the device is in portrait mode when the initial log on
/// has taken place, then the master view controller will by
/// default be hidden, causing the user to have to unhide it
/// first. The show function allows the master view controller
/// to be shown as needed
///
/// See: http://stackoverflow.com/a/34560694
///
/// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
/// - since: 0.8.0-alpha
/// - version: 2
/// - date: 2016-06-16
///
/// - seealso: logOutUser
extension UISplitViewController {
    func toggleMasterView() {
        var nextDisplayMode: UISplitViewControllerDisplayMode
        switch(self.preferredDisplayMode){
        case .PrimaryHidden:
            nextDisplayMode = .AllVisible
        default:
            nextDisplayMode = .PrimaryHidden
        }
        UIView.animateWithDuration(0.5) { () -> Void in
            self.preferredDisplayMode = nextDisplayMode
        }
    }
    
    func showMasterView() {
        UIView.animateWithDuration(0.5) { () -> Void in
            self.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        }
    }
    
    func hideMasterView() {
        UIView.animateWithDuration(0.5) { () -> Void in
            self.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
        }
    }
}

