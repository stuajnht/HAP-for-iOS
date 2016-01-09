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
//  UploadPopoverTableViewController.swift
//  HomeAccessPlus
//

import UIKit

/// Delegate callback to master view controller to upload the
/// file passed to this app
///
/// Using delegate callbacks to allow the file to be uploaded
/// based on the user pressing the 'upload file' cell
/// See: http://stackoverflow.com/a/29399294
/// See: http://stackoverflow.com/a/30596358
///
/// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
/// - since: 0.5.0-beta
/// - version: 1
/// - date: 2016-01-07
protocol uploadFileDelegate {
    // This calls the uploadFile function in the master view
    // controller
    func uploadFile()
}

class UploadPopoverTableViewController: UITableViewController {

    @IBOutlet weak var lblUploadFile: UILabel!
    @IBOutlet weak var celUploadFile: UITableViewCell!
    
    // Creating a reference to the upload file delegate
    var delegate: uploadFileDelegate?
    
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
        if (settings.stringForKey(settingsUploadFileLocation) != nil) {
            celUploadFile.userInteractionEnabled = true
            lblUploadFile.enabled = true
            lblUploadFile.text = "Upload \"" + getFileName() + "\""
        } else {
            celUploadFile.userInteractionEnabled = false
            lblUploadFile.enabled = false
            lblUploadFile.text = "Upload file"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Returning the number of sections that are in the table
        // - todo: Create this number dynamically
        // - seealso: tableView
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Returning the number of rows in the current table section
        // - todo: Create this number dynamically
        // - seealso: tableView
        return 2
    }
    
    /// Seeing what cell the user has selected from the table, and
    /// perform the relevant action
    ///
    /// We need to know what cell the user has selected so that the
    /// relevant action can be performed
    ///
    /// - note: The table cells and sections are hardcoded, in the
    ///         following order. If there are any changes, make sure
    ///         to check this function first and make any modifications
    ///         | Section | Row |     Cell function    |
    ///         |---------|-----|----------------------|
    ///         |    0    |  0  | Upload file / photo  |
    ///         |    0    |  1  | Upload file from app |
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-07
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        logger.debug("Cell tapped section: \(section)")
        logger.debug("Cell tapped row: \(row)")
        
        // The user has selected to upload a photo or video
        if ((section == 0) && (row == 0)) {
            logger.debug("Cell function: Upload file / photo")
        }
        
        // The user has selected to upload the file from the app
        if ((section == 0) && (row == 1)) {
            logger.debug("Cell function: Uploading file from app")
            
            // Calling the upload file delegate to upload the file
            delegate?.uploadFile()
            
            // Dismissing the popover as it's done what is needed
            // See: http://stackoverflow.com/a/32521647
            self.dismissViewControllerAnimated(true, completion: nil)
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
    /// - version: 1
    /// - date: 2016-01-07
    ///
    /// - returns: The file name of the file on the device
    func getFileName() -> String {
        // Getting the name of the file that is being uploaded from the
        // location of the file on the device
        let pathArray = settings.stringForKey(settingsUploadFileLocation)!.componentsSeparatedByString("/")
        var fileName = pathArray.last!
        
        // Removing any encoded characters from the file name
        fileName = fileName.stringByRemovingPercentEncoding!
        
        return fileName
    }

}
