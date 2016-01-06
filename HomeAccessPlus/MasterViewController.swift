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

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()
    
    // Loading an instance of the HAPi
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
    var fileItems: [AnyObject] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem

        //let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        //self.navigationItem.rightBarButtonItem = addButton
        //if let split = self.splitViewController {
        //    let controllers = split.viewControllers
        //    self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        //}
        
        // Setting the navigation bar colour
        self.navigationController!.navigationBar.barTintColor = UIColor(hexString: hapMainColour)
        self.navigationController!.navigationBar.tintColor = UIColor.flatWhiteColor()
        self.navigationController!.navigationBar.translucent = false
        
        // Adding an 'add' button to the navigation bar to allow files
        // passed to this app from an external one to be uploaded
        if ((settings.stringForKey(settingsUploadFileLocation) != nil) && (currentPath != "")) {
            logger.debug("Showing the upload 'add' button")
            let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "showUploadPopover")
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
                        // Removing the 'optional' text displayed when
                        // converting the space available into a string
                        // See: http://stackoverflow.com/a/25340084
                        let space = String(format:"%.2f", subJson["Space"].double!)
                        logger.debug("Drive name: \(name)")
                        logger.debug("Drive path: \(path)")
                        logger.debug("Drive usage: \(space)")
                        
                        // Adding the current files and folders in the directory
                        // to the fileItems array
                        self.addFileItem(name!, path: path!, type: "Drive", fileExtension: "Drive", details: space + "% used")
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
        if ((fileType == "") || (fileType == "Drive") || (fileType == "Directory")) {
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
    /// - version: 1
    /// - date: 2016-01-06
    func uploadFile() {
        logger.debug("Attempting to upload the local file: \(settings.stringForKey(settingsUploadFileLocation)) to the remote location: \(currentPath)")
        hudUploadingShow()
        
        // Attempting to upload the file that has been passed
        // to the app
        api.uploadFile(settings.URLForKey(settingsUploadFileLocation)!, serverFileLocation: currentPath, callback: { (result: Bool, uploading: Bool, uploadedBytes: Int64, totalBytes: Int64) -> Void in
            
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
                
                // Hiding the 'add' button as it's not needed anymore in
                // the current active view (but the user hasn't navigated
                // anywhere else yet)
                //
                // Note: This may be removed in the future, as there needs to
                //       be a permanent way for users to add in-app files & folders
                //
                // See: http://iostechsolutions.blogspot.co.uk/2014/11/swift-add-custom-left-bar-button-item.html
                self.navigationItem.rightBarButtonItem = nil
                
                // Setting the "settingsUploadFileLocation" value to be nil
                // so that when the user browses to another view the 'add'
                // button is not shown
                settings.setURL(nil, forKey: settingsUploadFileLocation)
                
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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                //let object = objects[indexPath.row] as! NSDate
                //let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                //controller.detailItem = object
                //controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                //controller.navigationItem.leftItemsSupplementBackButton = true
                
                let fileType = fileItems[indexPath.row][2] as! String
                let folderTitle = fileItems[indexPath.row][0] as! String
                let filePath = fileItems[indexPath.row][1] as! String
                let fileName = fileItems[indexPath.row][0] as! String
                let fileExtension = fileItems[indexPath.row][3] as! String
                let fileDetails = fileItems[indexPath.row][4] as! String
                if (!isFile(fileType)) {
                    // Stop the segue and follow the path
                    // See: http://stackoverflow.com/q/31909072
                    let controller: MasterViewController = storyboard?.instantiateViewControllerWithIdentifier("browser") as! MasterViewController
                    controller.title = folderTitle
                    logger.debug("Set title to: \(folderTitle)")
                    controller.currentPath = fileItems[indexPath.row][1] as! String
                    self.navigationController?.pushViewController(controller, animated: true)
                } else {
                    // Show the detail view with the file info
                    let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                    controller.detailItem = fileType
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

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let row = indexPath.row //2
        ////let section = indexPath.section//3
        //let fileName = fileItems[row][0] //4
        //newFolder = fileName as! String
        //logger.debug("Folder heading to title: \(newFolder)")
    }
    
    // MARK: Upload popover
    func showUploadPopover() {
        // See: https://www.shinobicontrols.com/blog/ios8-day-by-day-day-21-alerts-and-popovers
        // See: http://www.edumobile.org/ios/creating-grouped-table-views-in-swift/
        // See: http://useyourloaf.com/blog/static-table-views-with-storyboards.html
        let popoverVC = (storyboard?.instantiateViewControllerWithIdentifier("fileUploadPopover"))! as UIViewController
        popoverVC.modalPresentationStyle = .Popover
        presentViewController(popoverVC, animated: true, completion: nil)
        
        let popoverController = popoverVC.popoverPresentationController
        //popoverController.sourceView = sender
        //popoverController.sourceRect = sender.bounds
        popoverController!.permittedArrowDirections = .Any
    }


}

