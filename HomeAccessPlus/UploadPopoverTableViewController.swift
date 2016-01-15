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
import PermissionScope
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
    
    // Creating an instance of the PermissionScope, so
    // that we can ask the user for access to the photos
    // library
    let pscope = PermissionScope()
    
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
        
        // Setting the image picker to show inside the popover
        // and not full screen on large screen devices
        // See: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImagePickerController_Class/
        imagePicker.modalPresentationStyle = .CurrentContext
        
        // Formatting the image picker navigation bar so the colours
        // are the same as the rest of the app
        // See: http://stackoverflow.com/a/32011882
        imagePicker.navigationBar.barTintColor = UIColor(hexString: hapMainColour)
        imagePicker.navigationBar.tintColor = UIColor.flatWhiteColor()
        imagePicker.navigationBar.translucent = false
        imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.flatWhiteColor()]
        
        // Setting up the permissions needed to access the
        // photos library
        pscope.addPermission(PhotosPermission(), message: "Enable this to upload\r\nyour photos and videos")
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
            
            // Showing the permissions request to access
            // the photos library
            pscope.show({ finished, results in
                logger.debug("Got permission results: \(results)")
                logger.debug("Permissions granted to access the photos library")
                
                // Calling the image picker
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = .PhotoLibrary
                self.imagePicker.mediaTypes = [kUTTypeImage as String]
                
                self.presentViewController(self.imagePicker, animated: true, completion: nil)
                
                }, cancelled: { (results) -> Void in
                    logger.warning("Permissions to access the photos library were denied")
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
            })
        }
        
        // The user has selected to upload a video
        if ((section == 0) && (row == 1)) {
            logger.debug("Cell function: Upload video")
            
            // Showing the permissions request to access
            // the photos library
            pscope.show({ finished, results in
                logger.debug("Got permission results: \(results)")
                logger.debug("Permissions granted to access the photos library")
                
                // Calling the image picker
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = .PhotoLibrary
                self.imagePicker.mediaTypes = [kUTTypeMovie as String]
                
                self.presentViewController(self.imagePicker, animated: true, completion: nil)
                
                }, cancelled: { (results) -> Void in
                    logger.warning("Permissions to access the photos library were denied")
                    tableView.deselectRowAtIndexPath(indexPath, animated: true)
            })
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
        var imagePath = ""
        
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            newImage = possibleImage
            logger.debug("Selected image from \"UIImagePickerControllerEditedImage\": \(possibleImage)")
            imagePath = createLocalImage(newImage, fileLocation: fileDeviceLocation as! NSURL)
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            newImage = possibleImage
            logger.debug("Selected image from \"UIImagePickerControllerOriginalImage\": \(possibleImage)")
            imagePath = createLocalImage(newImage, fileLocation: fileDeviceLocation as! NSURL)
        } else {
            if (fileMediaType as! String == "public.movie") {
                logger.debug("Media file selected is a video")
                imagePath = createLocalVideo(info[UIImagePickerControllerMediaURL] as! NSURL)
            } else {
                logger.error("Unable to get the selected image")
                return
            }
        }
        
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
    
    /// Creates a local copy of the selected image in the documents
    /// directory, to upload it to the HAP+ server
    ///
    /// As the image in the asset library cannot be uploaded directly,
    /// it needs to be created locally in the app before it can be
    /// uploaded to the HAP+ server
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-11
    ///
    /// - parameter newImage: A reference to the image from the asset library
    /// - parameter fileLocation: The location in the asset library, to generate
    ///                           the name of the file from
    /// - returns: The path to the image in the app
    func createLocalImage(newImage: UIImage, fileLocation: NSURL) -> String {
        let imagePath = getDocumentsDirectory().stringByAppendingPathComponent(createFileName(fileLocation, imageFile: true))
        
        if let jpegData = UIImageJPEGRepresentation(newImage, 80) {
            logger.verbose("Before writing image to documents folder")
            
            jpegData.writeToFile(imagePath, atomically: true)
            
            logger.verbose("JPEG file raw data: \(jpegData)")
            logger.verbose("After writing image to documents folder")
        }
        
        logger.debug("Selected media file written to: \(imagePath)")
        return imagePath
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
    func createLocalVideo(fileLocation: NSURL) -> String {
        let videoData = NSData(contentsOfURL: fileLocation)
        logger.debug("Location of video data: \(fileLocation)")
        
        let dataPath = getDocumentsDirectory().stringByAppendingPathComponent(createFileName(fileLocation, imageFile: false))
        
        logger.verbose("Before writing video file")
        
        videoData?.writeToFile(dataPath, atomically: true)
        
        logger.verbose("Video file raw data: \(videoData)")
        logger.verbose("After writing video file")
        
        logger.debug("Selected video file written to: \(dataPath)")
        return dataPath
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
    func createFileName(fileLocation: NSURL, imageFile: Bool) -> String {
        // Storing the name of the file that we will be showing the user
        var fileName = ""
        
        // Seeing if we are dealing with an image file or a video
        if (imageFile) {
            // Splitting the string into before and after the '?', so we
            // have the name and extension at fileNameQuery[1]
            let fileNameQuery = String(fileLocation).componentsSeparatedByString("?")
            
            // Splitting the string into before and after the '&', so we
            // have the name at fileNameParameters[0] and extension at fileNameParameters[1]
            let fileNameParameters = String(fileNameQuery[1]).componentsSeparatedByString("&")
            
            // Splitting the string into before and after the '=', so we
            // have the name at fileNameValue[1]
            let fileNameValue = String(fileNameParameters[0]).componentsSeparatedByString("=")
            
            // Getting the first hex string from the UUID, so that the name isn't
            // too long to display
            let fileNameUUID = String(fileNameValue[1]).componentsSeparatedByString("-")
            
            // Hardcoding the extension, as we are generating JPEG images
            fileName = fileNameUUID[0] + ".jpg"
        } else {
            // The below code is based on the HAPI.uploadFile function
            let pathArray = String(fileLocation).componentsSeparatedByString("/")
            
            // Getting the last value from the path
            var fullFileName = pathArray.last!
            
            // Removing the "trim." from the start of the string
            fullFileName = fullFileName.stringByReplacingOccurrencesOfString("trim.", withString: "")
            
            // Getting the file name and extension from the fullFileName,
            // with the name stored at fileNameParameters[0] and the extension at
            // fileNameParameters[1]
            let fileNameParameters = fullFileName.componentsSeparatedByString(".")
            
            // Getting the first hex string from the UUID, so that the name isn't
            // too long to display
            let fileNameUUID = String(fileNameParameters[0]).componentsSeparatedByString("-")
            
            // Joining the file name and extension to create the full file name
            // for video files
            fileName = fileNameUUID[0] + "." + fileNameParameters[1]
        }
        
        logger.debug("File name for generated media: \(fileName)")
        return fileName
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
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        logger.debug("Documents directory path: \(documentsDirectory)")
        return documentsDirectory
    }

}
