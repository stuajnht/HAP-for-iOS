// Home Access Plus+ for iOS - A native app to access a HAP+ server
// Copyright (C) 2015  Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
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
    
    // A listing of the current drive the user is browsing,
    // as the HAP myfiles API doesn't include this
    var currentDrive = ""
    
    // A listing to the current folder the user is in, or
    // an empty string if the main drive listing is being
    // shown
    // - note: This variable should be set before the view
    //         controller is called in the 'prepareForSegue'
    var currentPath = ""
    
    // Setting the name of the folder that we are going to
    // browse into, so that it appears in the nvaigation bar
    // title. This should be called in the 'prepareForSegue'
    var newFolder = ""
    
    // Example array to be used for initial testing to hold files
    // TODO: Remove after testing?
    var files: [AnyObject] = []
    
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

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        // Setting the navigation bar colour
        self.navigationController!.navigationBar.barTintColor = UIColor(hexString: hapMainColour)
        self.navigationController!.navigationBar.tintColor = UIColor.flatWhiteColor()
        self.navigationController!.navigationBar.translucent = false
        
        // Seeing if we are showing the user their available drives
        // or if the user is browsing the folder hierarchy
        if (currentPath == "") {
            hudShow("Loading drives")
            navigationItem.title = "My Drives"
            // Getting the drives available to the user
            api.getDrives({ (result: Bool, response: AnyObject) -> Void in
                logger.verbose("\(result): \(response)")
                
                var file: [AnyObject] = []
                let json = JSON(response)
                for (_,subJson) in json {
                    let name = subJson["Name"].string
                    let path = subJson["Path"].string
                    let space = subJson["Space"].double
                    logger.debug("Drive name: \(name)")
                    logger.debug("Drive path: \(path)")
                    logger.debug("Drive usage: \(space)")
                    file = [name!, path!, String(space) + "% used", "Drive", path!]
                    self.files.append(file)
                }
                
                //var files5 = [String]()
                //files5 = ["Home", "H:", "94.94% full", "Drive"]
                //var files6 = [String]()
                //files6 = ["Super awesome sound file", "File", "98/16/9278 10:45      69.4 GB", ".au"]
                
                //self.files = [files5, files6]
                self.hudHide()
                self.tableView.reloadData()
            })
        } else {
            hudShow("Loading folder")
            // Show the files and folders in the path the
            // user has browsed to
            //loadSampleFiles()
            api.getFolder(currentPath, callback: { (result: Bool, response: AnyObject) -> Void in
                logger.verbose("\(result): \(response)")
                
                var file: [AnyObject] = []
                let json = JSON(response)
                for (_,subJson) in json {
                    let name = subJson["Name"].string
                    let type = subJson["Type"].string
                    let modified = subJson["ModifiedTime"].string
                    let fileExtension = subJson["Extension"].string
                    let size = subJson["Size"].string
                    let path = subJson["Path"].string
                    logger.verbose("Name: \(name)")
                    logger.verbose("Type: \(type)")
                    logger.verbose("Date modified: \(modified)")
                    file = [name!, type!, modified! + "    " + size!, fileExtension!, path!]
                    self.files.append(file)
                }
                self.hudHide()
                self.tableView.reloadData()
            })
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
    
    /// A test function to check that the table cells are
    /// set up correctly
    ///
    /// - note: Do not rely on this function... it may be removed
    ///         once testing is complete!
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.3.0-alpha
    /// - version: 1
    /// - date: 2015-12-12
    func loadSampleFiles() {
        var files1 = [String]()
        files1 = ["Test 1", "Text Document", "32/13/0000 11:20      323 KB", ".txt"]
        var files2 = [String]()
        files2 = ["Test 2", "Word Document", "32/13/9999 23:59       1.2 MB", ".avi"]
        var files3 = [String]()
        files3 = ["Test 3", "Image Document", "32/13/0929 03:32      300.00 Bytes", ".xlsx"]
        var files4 = [String]()
        files4 = ["My Folder", "Directory", "32/13/9210 06:22", ""]
        var files5 = [String]()
        files5 = ["Home", "H:", "94.94% full", "Drive"]
        var files6 = [String]()
        files6 = ["Super awesome sound file", "File", "98/16/9278 10:45      69.4 GB", ".au"]
        
        files = [files1, files2, files3, files4, files5, files6]
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
    /// - parameter fileExtension: The file extension of the current item
    /// - parameter fileType: The type of file according to the HAP+ server
    /// - returns: Is the current item a file or a folder/drive
    func isFile(fileExtension: String, fileType: String) -> Bool {
        if ((fileExtension == "") || (fileExtension == "Drive")) {
            return false
        } else {
            // Seeing if this is a Directory based on the file type
            // that has been passed - issue #13
            if (fileType == "Directory") {
                return false
            } else {
                return true
            }
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
        logger.debug("Adding item to file array, with details:\n --Name: \(name)\n --Path: \(path)\n --Type: \(type)\n --Extension: \(fileExtension)\n --Details: \(details)")
        
        // Adding the current item to the array
        currentItem = [name, path, type, fileExtension, details]
        self.fileItems.append(currentItem)
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
                
                let fileExtension = files[indexPath.row][3] as! String
                let fileType = files[indexPath.row][1] as! String
                if (!isFile(fileExtension, fileType: fileType)) {
                    // Stop the segue and follow the path
                    // See: http://stackoverflow.com/q/31909072
                    let controller: MasterViewController = storyboard?.instantiateViewControllerWithIdentifier("browser") as! MasterViewController
                    controller.title = newFolder
                    controller.currentPath = files[indexPath.row][4] as! String
                    controller.currentDrive = currentDrive
                    self.navigationController?.pushViewController(controller, animated: true)
                } else {
                    // Show the detail view with the file info
                    let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                    controller.detailItem = fileType
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
        return files.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "FileTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! FileTableViewCell
        
        // Fetches the appropriate meal for the data source layout.
        let file = files[indexPath.row]
        
        cell.lblFileName.text = file[0] as? String
        cell.lblFileType.text = file[1] as? String
        cell.lblFileDetails.text = file[2] as? String
        cell.fileIcon((file[3] as? String)!)
        if (!isFile((file[3] as? String)!, fileType: (file[1] as? String)!)) {
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
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
        let row = indexPath.row //2
        //let section = indexPath.section//3
        let fileName = files[row][0] //4
        newFolder = fileName as! String
        currentDrive = files[row][4] as! String
    }


}

