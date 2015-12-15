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
import SwiftyJSON

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()
    
    // Loading an instance of the HAPi
    let api = HAPi()
    
    // A listing to the current folder the user is in, or
    // an empty string if the main drive listing is being
    // shown
    // - note: This variable should be set before the view
    //         controller is called in the 'prepareForSegue'
    var currentPath = ""
    
    // Example array to be used for initial testing to hold files
    // TODO: Remove after testing?
    var files: [AnyObject] = []


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
            // Getting the drives available to the user
            api.getDrives({ (result: Bool, response: AnyObject) -> Void in
                logger.debug("\(result): \(response)")
                
                var file: [AnyObject] = []
                let json = JSON(response)
                for (_,subJson) in json {
                    let name = subJson["Name"].string
                    let path = subJson["Path"].string
                    let space = subJson["Space"].double
                    logger.debug("Drive name: \(name)")
                    logger.debug("Drive path: \(path)")
                    logger.debug("Drive usage: \(space)")
                    file = [name!, path!, String(space) + "% used", "Drive"]
                    self.files.append(file)
                }
                
                //var files5 = [String]()
                //files5 = ["Home", "H:", "94.94% full", "Drive"]
                //var files6 = [String]()
                //files6 = ["Super awesome sound file", "File", "98/16/9278 10:45      69.4 GB", ".au"]
                
                //self.files = [files5, files6]
                
                self.tableView.reloadData()
            })
        } else {
            // Show the files and folders in the path the
            // user has browsed to
            loadSampleFiles()
        }
        
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = true
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
    /// - version: 1
    /// - date: 2015-12-15
    ///
    /// - parameter fileExtension: The file extension of the current item
    /// - returns: Is the current item a file or a folder/drive
    func isFile(fileExtension: String) -> Bool {
        if ((fileExtension == "") || (fileExtension == "Drive")) {
            return false
        } else {
            return true
        }
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
                
                let fileType = files[indexPath.row][3] as! String
                if (!isFile(fileType)) {
                    // Stop the segue and follow the path
                    // See: http://stackoverflow.com/q/31909072
                    let controller: MasterViewController = storyboard?.instantiateViewControllerWithIdentifier("browser") as! MasterViewController
                    controller.title = "Folder Browsed"
                    controller.currentPath = "Folder"
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
        if (!isFile((file[3] as? String)!)) {
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
        navigationItem.title = fileName as? String
    }


}

