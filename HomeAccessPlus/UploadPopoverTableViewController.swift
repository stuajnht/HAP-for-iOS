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

import MobileCoreServices
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
    func uploadFile(fileFromPhotoLibrary: Bool)
}

class UploadPopoverTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var lblUploadFile: UILabel!
    @IBOutlet weak var celUploadFile: UITableViewCell!
    
    // Creating an instance of an image picker controller
    // See: http://www.codingexplorer.com/choosing-images-with-uiimagepickercontroller-in-swift/
    let imagePicker = UIImagePickerController()
    
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
        
        // Creating a delegate for the image picker
        imagePicker.delegate = self
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
        return 3
    }
    
    /// Seeing what cell the user has selected from the table, and
    /// perform the relevant action
    ///
    /// We need to know what cell the user has selected so that the
    /// relevant action can be performed. As there doesn't seem to
    /// be any way to access both the photos and videos on the same
    /// image picker, it is split into 2 cells
    ///
    /// - note: The table cells and sections are hardcoded, in the
    ///         following order. If there are any changes, make sure
    ///         to check this function first and make any modifications
    ///         | Section | Row |     Cell function    |
    ///         |---------|-----|----------------------|
    ///         |    0    |  0  | Upload photo         |
    ///         |    0    |  1  | Upload video         |
    ///         |    0    |  2  | Upload file from app |
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
        
        // The user has selected to upload a photo
        if ((section == 0) && (row == 0)) {
            logger.debug("Cell function: Upload photo")
            
            // Calling the image picker
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .PhotoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            
            presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        // The user has selected to upload a video
        if ((section == 0) && (row == 1)) {
            logger.debug("Cell function: Upload video")
            
            // Calling the image picker
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .PhotoLibrary
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            
            presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        // The user has selected to upload the file from the app
        if ((section == 0) && (row == 2)) {
            logger.debug("Cell function: Uploading file from app")
            
            // Calling the upload file delegate to upload the file
            delegate?.uploadFile(false)
            
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
    
    /// Gets the location of the file the user has picked from the
    /// image picker, so that it can be uploaded
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-09
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
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
        
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            newImage = possibleImage
            logger.debug("Selected image from \"UIImagePickerControllerEditedImage\": \(possibleImage)")
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            newImage = possibleImage
            logger.debug("Selected image from \"UIImagePickerControllerOriginalImage\": \(possibleImage)")
        } else {
            logger.error("Unable to get the selected image")
            return
        }
        
        var imageName = NSUUID().UUIDString
        logger.debug("UUID for selected image: \(imageName)")
        // Getting the first hex string from the UUID, so that the name isn't
        // too long to display
        let imageArray = imageName.componentsSeparatedByString("-")
        imageName = imageArray[0]
        logger.debug("Short file name for image: \(imageName)")
        
        let imagePath = getDocumentsInboxDirectory().stringByAppendingPathComponent(imageName)
        
        if let jpegData = UIImageJPEGRepresentation(newImage, 80) {
            logger.debug("Before writing image to Inbox folder")
            jpegData.writeToFile(imagePath, atomically: true)
            logger.verbose("JPEG file: \(jpegData)")
            logger.debug("After writing image to Inbox folder")
        }
        logger.debug("Selected media file written to: \(imagePath)")
        
        // Setting the location of the image file in the settings
        settings.setObject(String(imagePath), forKey: settingsUploadPhotosLocation)
        
        // Uploading the file to the HAP+ server
        delegate?.uploadFile(true)
        
        // Dismissing the image file picker
        dismissViewControllerAnimated(true, completion: nil)
        
        // Dismissing the popover as it's done what is needed
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// Dismissing the image picker
    ///
    /// While not needed as pressing the image picker cancel button
    /// works on it's own, but Apple says it's needed, so it's going in
    /// See: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImagePickerControllerDelegate_Protocol/index.html#//apple_ref/occ/intfm/UIImagePickerControllerDelegate/imagePickerControllerDidCancel:
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-09
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    /// Gets the Documents Inbox directory for the current app
    ///
    /// See: https://www.hackingwithswift.com/read/10/4/importing-photos-with-uiimagepickercontroller
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-10
    func getDocumentsInboxDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        var documentsDirectory = paths[0]
        // Appending the Inbox directory to the documents path
        //documentsDirectory = documentsDirectory + "/Inbox"
        logger.debug("Documents directory inbox path: \(documentsDirectory)")
        return documentsDirectory
    }

}
