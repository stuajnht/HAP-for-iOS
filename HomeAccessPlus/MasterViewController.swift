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
    var fileItems: [AnyObject] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem

        // Setting a delegate for the split view, to see if the file
        // browser master view should be shown instead of the detail
        // view - see: http://nshipster.com/uisplitviewcontroller/
        splitViewController?.delegate = self
        
        // Setting the navigation bar colour
        self.navigationController!.navigationBar.barTintColor = UIColor(hexString: hapMainColour)
        self.navigationController!.navigationBar.tintColor = UIColor.flatWhiteColor()
        self.navigationController!.navigationBar.translucent = false
        
        // Adding an 'add' button to the navigation bar to allow files
        // passed to this app from an external one to be uploaded, or
        // for photo and video files to be added from the device gallery
        // Note: This isn't shown if there is no path, i.e. we are looking
        // at the drives listing
        if (currentPath != "") {
            logger.debug("Showing the upload 'add' button")
            let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "showUploadPopover:")
            self.navigationItem.rightBarButtonItem = addButton
        }
        
        // Setting up the ability to refresh the table view when the
        // user is at the top and pulls down, or if there was a problem
        // loading the folder and they want to try again
        // See: https://www.andrewcbancroft.com/2015/03/17/basics-of-pull-to-refresh-for-swift-developers/
        //self.refreshControl?.addTarget(self, action: "loadFileBrowser:", forControlEvents: UIControlEvents.ValueChanged)
        
        // Loading the contents in the folder that has been browsed
        // to, or lising the drives if no folder has been navigated to
        loadFileBrowser()
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
    /// - version: 2
    /// - date: 2016-01-09
    ///
    /// - parameter fileFromPhotoLibrary: Is the file being uploaded coming from the photo
    ///                                   library on the device, or from another app
    func uploadFile(fileFromPhotoLibrary: Bool) {
        // Holding the location of the file on the device, that
        // is going to be uploaded
        var fileLocation = ""
        
        var fileDeviceLocation : NSURL
        
        // Seeing if we are uploading a file from another app
        // or the local photo library
        if (fileFromPhotoLibrary == false) {
            logger.debug("Attempting to upload the local file: \(settings.stringForKey(settingsUploadFileLocation)) to the remote location: \(currentPath)")
            fileLocation = settings.stringForKey(settingsUploadFileLocation)!
            
            // Converting the fileLocation to be a valid NSURL variable
            fileDeviceLocation = NSURL(fileURLWithPath: fileLocation)
        } else {
            logger.debug("Attempting to upload the photos file: \(settings.stringForKey(settingsUploadPhotosLocation)) to the remote location: \(currentPath)")
            fileLocation = settings.stringForKey(settingsUploadPhotosLocation)!
            
            // Converting the fileLocation to be a valid NSURL variable
            fileDeviceLocation = NSURL(string: fileLocation)!
        }
        
        hudUploadingShow()
        
        // Attempting to upload the file that has been passed
        // to the app
        api.uploadFile(fileDeviceLocation, serverFileLocation: currentPath, fileFromPhotoLibrary: fileFromPhotoLibrary, callback: { (result: Bool, uploading: Bool, uploadedBytes: Int64, totalBytes: Int64) -> Void in
            
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
                self.hudHide()
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
                    settings.setURL(nil, forKey: settingsUploadFileLocation)
                }
                
                // Deleting the local copy of the file that was used to
                // upload to the HAP+ server
                self.deleteUploadedLocalFile(fileDeviceLocation)
                
                // Refreshing the file browser table
                self.loadFileBrowser()
            }
        })
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
    /// - version: 2
    /// - date: 2016-01-23
    ///
    /// - parameter folderName: The name of the folder to be created
    func newFolder(folderName: String) {
        hudShow("Creating \"" + folderName + "\" folder")
        logger.debug("Folder name from delegate callback: \(folderName)")
        
        // Calling the HAPi to create the new folder
        api.newFolder(currentPath, newFolderName: folderName, callback: { (result: Bool) -> Void in
            self.hudHide()
            
            // There was a problem with creating the folder, so let the
            // user know about it
            if (result == false) {
                let uploadFailController = UIAlertController(title: "Unable to create folder", message: "The folder was not successfully created. Please check and try again", preferredStyle: UIAlertControllerStyle.Alert)
                uploadFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(uploadFailController, animated: true, completion: nil)
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
                self.deleteFile(indexPath, fileOrFolder: fileOrFolder) }))
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
    /// - version: 2
    /// - date: 2016-01-22
    ///
    /// - parameter indexPath: The index in the table and file items array
    ///                        that we are deleting the file item from
    /// - parameter fileOrFolder: Whether the item being deleted is a file
    ///                           or a folder, so that the error message can
    ///                           be customised correctly
    func deleteFile(indexPath: NSIndexPath, fileOrFolder: String) {
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
                deletionProblemAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Cancel, handler: {(alertAction) -> Void in
                    self.deleteFile(indexPath, fileOrFolder: fileOrFolder) }))
                self.presentViewController(deletionProblemAlert, animated: true, completion: nil)
            }
            
            // The file was deleted, so remove the item from the
            // table with an animation, instead of reloading the
            // whole folder from the HAP+ server
            if (result == true) {
                logger.info("The file item has been deleted from: \(deleteItemAtLocation)")
                self.fileItems.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
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
        vc.modalPresentationStyle = UIModalPresentationStyle.Popover
        vc.preferredContentSize = CGSize(width: 320, height: 420)
        if let popover: UIPopoverPresentationController = vc.popoverPresentationController! {
            popover.barButtonItem = sender
            popover.delegate = self
        }
        presentViewController(vc, animated: true, completion:nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.FullScreen
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        let btnCancelUploadPopover = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: "dismiss")
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


}

