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
//  DetailViewController.swift
//  HomeAccessPlus
//

import UIKit
import ChameleonFramework
import MBProgressHUD
import QuickLook

class DetailViewController: UIViewController, QLPreviewControllerDataSource {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var btnPreview: UIButton!
    @IBOutlet weak var stkFileProperties: UIStackView!
    @IBOutlet weak var lblFileName: UILabel!
    @IBOutlet weak var lblFileNameTitle: UILabel!
    @IBOutlet weak var lblFileType: UILabel!
    @IBOutlet weak var lblFileTypeTitle: UILabel!
    @IBOutlet weak var lblFileSize: UILabel!
    @IBOutlet weak var lblFileSizeTitle: UILabel!
    @IBOutlet weak var lblFileModified: UILabel!
    @IBOutlet weak var lblFileModifiedTitle: UILabel!
    @IBOutlet weak var lblFileLocation: UILabel!
    @IBOutlet weak var lblFileLocationTitle: UILabel!
    
    // Loading an instance of the HAPi
    let api = HAPi()
    
    // MBProgressHUD variable, so that a download progress bar can be shown
    var hud : MBProgressHUD = MBProgressHUD()
    
    // Holding the path that can be used to download
    // the file that the user has selected
    var fileDownloadPath = ""
    
    // Holding the name of the file to use for the QuickLook controller
    var fileName = ""
    
    // Holding the type of file the user has selected, if it is a
    // known format, or the extension if unknown
    var fileType = ""
    
    // Holding the file "details" (date modified and size), which are
    // separated in the showFileDetails function
    /// - seealso: showFileDetails
    var fileDetails = ""
    
    // Saving the extention of the file that is being downloaded
    // so that the QuickLook preview knows what to show
    var fileExtension = ""
    
    // Setting the location on the device where the file is
    var fileDeviceLocation = ""
    
    // Keeping track of if the file has been downloaded, or does
    // authorisation by the user need to be confirmed
    var fileDownloaded = false


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Adding navigation back button to detail view, to show the master view, as it is
        // removed from the AppDelegate.swift file
        // See: http://nshipster.com/uisplitviewcontroller/
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        // Setting the navigation bar colour
        self.navigationController!.navigationBar.barTintColor = UIColor(hexString: hapMainColour)
        self.navigationController!.navigationBar.tintColor = UIColor.flatWhiteColor()
        self.navigationController!.navigationBar.translucent = false
        
        // Downloading the file that the user has selected
        // The 'if' is needed to prevent any attempts to download
        // the folder the user has requested, as this class gets
        // called again on each folder browse
        if (fileDownloadPath != "") {
            logger.debug("Downloading file from the following location: \(fileDownloadPath)")
            detailDescriptionLabel.hidden = true
            
            // Displaying the file properties controls. This is located
            // here so there is something shown once a file has been
            // selected from the file browser table
            self.showFileDetails()
            
            // Seeing if the file is larger than the maximum values
            // specified, and preventing the file from being downloaded
            // if so
            let allowFileDownload = downloadLargeFile()
            logger.debug("File selected allowed to be downloaded: \(allowFileDownload)")
            
            if (allowFileDownload) {
                // The file is allowed to be downloaded, so do so
                downloadFile()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// - todo: Find out a way to delete files from the device when
    ///         they're finished with, to save space on the device
    ///         See: https://github.com/stuajnht/HAP-for-iOS/issues/15
    override func viewWillDisappear(animated: Bool) {
        // Preventing attempting to delete any files if
        // none have been downloaded yet (such as browsing through
        // the file structure but not selecting a file)
        if (fileDeviceLocation != "") {
            // Getting a list of the files currently in the caches
            // directory before any deletion attempt happens
            var cacheDirectoryPath = getLocalCacheFolderFileListing()
            
            // As the view will be disappearing, we can delete the
            // files that the user has downloaded to the caches folder
            // directory on the device
            // See: http://stackoverflow.com/a/32744011
            if let enumerator = NSFileManager.defaultManager().enumeratorAtPath(cacheDirectoryPath) {
                while let fileName = enumerator.nextObject() as? String {
                    let localFilePath = cacheDirectoryPath + "/" + fileName
                    logger.debug("Attempting to delete the file: \(localFilePath)")
                    do {
                        // Checking to see if the file currently being
                        // deleted is the one the user is looking at
                        // Also preventing attempts to delete the 'snapshots'
                        // file as deleting it is not a premitted operation
                        if ((localFilePath == formatLocalFilePath()) || (fileName == "Snapshots")) {
                            logger.debug("Skipping deleting file: \(localFilePath)")
                        } else {
                            try NSFileManager.defaultManager().removeItemAtPath("\(localFilePath)")
                            logger.debug("Successfully deleted file: \(localFilePath)")
                        }
                    }
                    catch let errorMessage as NSError {
                        logger.error("There was a problem deleting the file. Error: \(errorMessage)")
                    }
                    catch {
                        logger.error("There was an unknown problem when deleting the file.")
                    }
                }
            }
            
            // Getting a file listing again, to make sure that the
            // file was deleted
            cacheDirectoryPath = getLocalCacheFolderFileListing()
        }
        
        super.viewWillDisappear(animated)
    }
    
    // Displaying the QuickLook preview of the file when
    // the preview button is pressed, if the user pressed
    // the back button when it was displayed previously
    @IBAction func displayPreview(sender: AnyObject) {
        // Seeing if the file has already been downloaded. If it
        // has, then we can just present the QuickLook controller,
        // otherwise we'll need to ask the user if the file can be
        // downloaded to the device, as it is a large file size
        if (fileDownloaded) {
            logger.verbose("Showing the QuickLook controller")
            quickLookController()
        } else {
            // Asking the user if we can download the file from the
            // HAP+ server, as it is larger than what is allowed.
            // This is the only function that needs to be called, as
            // either the file has already been downloaded due to a
            // small file size (so the above "if" will be true) or
            // we need to ask the user if the file can be downloaded,
            // whereby the alert actions call the downloadFile function
            logger.verbose("Asking the user if the large file can be downloaded to show it")
            downloadLargeFile()
        }
    }
    
    /// Downloads the file selected by the user onto the device
    ///
    /// Once a user has selected a file to be downloaded, and it
    /// is either a small file or been allowed to download if it's
    /// a big file, then this function is called to download the
    /// file from the HAP+ server onto the device, and then call
    /// the QuickLook preview controller on a successful download
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-16
    func downloadFile() ->Void {
        hudShow()
        api.downloadFile(fileDownloadPath, callback: { (result: Bool, downloading: Bool, downloadedBytes: Int64, totalBytes: Int64, downloadLocation: NSURL) -> Void in
            
            // There was a problem with downloading the file, so let the
            // user know about it
            if ((result == false) && (downloading == false)) {
                let loginUserFailController = UIAlertController(title: "Unable to download file", message: "The file was not successfully downloaded. Please check and try again", preferredStyle: UIAlertControllerStyle.Alert)
                loginUserFailController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(loginUserFailController, animated: true, completion: nil)
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
                logger.debug("Opening file from: \(downloadLocation)")
                self.fileDeviceLocation = String(downloadLocation)
                
                // Preventing the user being asked if the file
                // should be downloaded again, if they click the
                // preview button
                self.fileDownloaded = true
                
                // Loading and creating the QuickLook controller
                self.quickLookController()
            }
        })
    }
    
    /// Showing the details of the currently selected file
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.4.0-beta
    /// - version: 1
    /// - date: 2015-12-23
    func showFileDetails() {
        lblFileName.text = fileName
        lblFileType.text = fileType
        
        // Splitting the file details string into the relevant date modified
        // and file size parts. On the master view controller, these values
        // are seperated with 4 spaces "    " so we can use this to split them
        // The file modification date comes first, followed by the file size
        // See: http://stackoverflow.com/a/25818228
        let fileDetail = fileDetails.componentsSeparatedByString("    ")
        lblFileSize.text = fileDetail[1]
        lblFileModified.text = fileDetail[0]
        
        var fileLocation = ""
        // The HAP+ server responds with a download path that has "../Download/"
        // at the beginning, so it shoud be removed before the file location
        // is shown to the user. Also, the path has forward slashes, so we should
        // replace those with backslashes, to be consistent with how Windows
        // presents file paths
        fileLocation = fileDownloadPath.stringByReplacingOccurrencesOfString("../Download/", withString: "")
        fileLocation = fileLocation.stringByReplacingOccurrencesOfString("/", withString: "\\")
        
        // If the file name or folder path contain characters that need to be
        // escaped if put into a URL, then they need to be decoded before being
        // shown to the user, as the HAP+ API will encode them. However, we cannot
        // just attempt to decode them as a pipe symbol "|" is used in the HAP+ API
        // instead of a percent "%". We can safely just replace the pipe with a
        // percent, as a pipe is not a valid character in Windows file names
        // (See: https://msdn.microsoft.com/en-us/library/aa365247#naming_conventions )
        // and then decode the encoded string
        fileLocation = fileLocation.stringByReplacingOccurrencesOfString("|", withString: "%")
        fileLocation = fileLocation.stringByRemovingPercentEncoding!
        
        // Adding a ":" character after the drive letter, as it is not included
        // in the HAP+ API JSON data, and the user will possibly expect it to
        // be included in the file location path, as they are used to this
        // See: http://stackoverflow.com/a/32466063
        fileLocation = String(fileLocation.characters.prefix(1)) + ":" + String(fileLocation.characters.suffix(fileLocation.characters.count - 1))
        lblFileLocation.text = fileLocation
        
        stkFileProperties.hidden = false
    }
    
    // MARK: MBProgressHUD
    // The following functions look after showing the HUD during the download
    // progress so that the user knows that something is happening.
    // See: http://stackoverflow.com/a/26901328
    func hudShow() {
        hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud.detailsLabelText = "Downloading..."
        // See: http://stackoverflow.com/a/26882235
        hud.mode = MBProgressHUDMode.DeterminateHorizontalBar
    }
    
    /// Updating the progress bar that is shown in the HUD, so the user
    /// knows how far along the download is
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.4.0-alpha
    /// - version: 1
    /// - date: 2015-12-21
    /// - seealso: hudShow
    /// - seealso: hudHide
    ///
    /// - parameter currentDownloadedBytes: The amount in bytes that has been downloaded
    /// - parameter totalBytes: The total amount of bytes that is to be downloaded
    func hudUpdatePercentage(currentDownloadedBytes: Int64, totalBytes: Int64) {
        let currentPercentage = Float(currentDownloadedBytes) / Float(totalBytes)
        logger.verbose("Current downloaded percentage: \(currentPercentage * 100)%")
        hud.progress = currentPercentage
    }
    
    func hudHide() {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    }
    
    // MARK: QuickLook
    
    /// Creating the QuickLook controller so the file the
    /// user selected can be displayed
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.4.0-beta
    /// - version: 1
    /// - date: 2015-12-23
    func quickLookController() {
        // Presenting the QuickLook controller to the user
        // Thanks to the following sites for helping me eventually
        // figure it out (here and other parts of this file)
        // See: http://kratinmobile.com/blog/index.php/document-preview-in-ios-with-quick-look-framework/
        // See: http://robsprogramknowledge.blogspot.co.uk/2011/02/quick-look-for-ios_21.html
        // See: https://www.invasivecode.com/weblog/quick-look-preview-controller-in-swift
        // See: http://teemusk.com/blog.html?id=108645693475
        let previewQL = QLPreviewController()
        previewQL.dataSource = self
        previewQL.currentPreviewItemIndex = 0
        self.showViewController(previewQL, sender: nil)
    }
    
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        return NSURL.fileURLWithPath(formatLocalFilePath())
    }
    
    /// Formats the path to the downloaded file from the path
    /// that is returned when the file has been downloaded
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.4.0-beta
    /// - version: 1
    /// - date: 2016-01-04
    ///
    /// - returns: A formatted path to the local copy of the downloaded file
    func formatLocalFilePath() -> String {
        // Returning the full path to the downloaded file
        // after removing the 'file://' from the beginning
        var formattedPath = fileDeviceLocation.stringByReplacingOccurrencesOfString("file://", withString: "")
        // Decoding any URL encoded characters, as the saved file
        // doesn't contain them, so it won't be found by QuickLook
        // See: http://stackoverflow.com/a/28310899
        formattedPath = formattedPath.stringByRemovingPercentEncoding!
        logger.verbose("Formatted file location for preview: \(formattedPath)")
        return formattedPath
    }
    
    /// Creates a listing of the files in the caches directory
    /// to make sure that the files are removed
    ///
    /// While this function is called when the view is disappearing,
    /// it is really only of use for debugging purposes to make sure
    /// that things are being cleared up properly
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.4.0-beta
    /// - version: 1
    /// - date: 2016-01-04
    ///
    /// - returns: A path to the device cache directory, or an empty string
    func getLocalCacheFolderFileListing() -> String {
        do {
            // Getting a list of documents in the caches folder
            // See: http://stackoverflow.com/a/24055475
            var cachesDirectories: [AnyObject] = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
            logger.verbose("Caches directories: \(cachesDirectories)")
            
            // See: http://stackoverflow.com/a/33055193
            let cachesDirectory: String = (cachesDirectories[0] as? String)!
            logger.verbose("Cache directory: \(cachesDirectory)")
            
            let listOfFiles = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(cachesDirectory)
            logger.verbose("List of files in directory: \(listOfFiles)")
            
            // Returning the path to the caches directory
            return cachesDirectory
        } catch {
            logger.error("Failed to get list of files in caches directory")
            
            // Return an empty string as we couldn't get the
            // cache directory
            return ""
        }
    }
    
    /// Checks with the user if they are happy to download a large file
    ///
    /// As the files the user can browse on the network may be large,
    /// such as video files, we need to ask the user if they are sure
    /// that they want to download a preview for the file. This is to
    /// prevent them wasting time and bandwidth if they accidentally
    /// selected the file
    ///
    /// This function should be called whenever a file is selected
    /// originally, and again if the user selects the "preview" button,
    /// to check if they have already agreed and downloaded the file
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-16
    ///
    /// - seealso: largeFileSize
    ///
    /// - returns: Can the selected file be downloaded
    func downloadLargeFile() -> Bool {
        // Seeing if the currently selected file is larger than the
        // maximum set for the device
        if (largeFileSize()) {
            // Requesting from the user if the file can be downloaded
            let confirmDownloadLargeFile = UIAlertController(title: "Download Large File", message: "This may take time or use up some of your device data allowances", preferredStyle: UIAlertControllerStyle.Alert)
            confirmDownloadLargeFile.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(alertAction) -> Void in
                self.downloadFile() }))
            confirmDownloadLargeFile.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: {(alertAction) -> Void in
                return false }))
            self.presentViewController(confirmDownloadLargeFile, animated: true, completion: nil)
            
            // The alert view is shown, and then the code continues, as
            // the choice of the user is only run once a callback from
            // the alert has executed. Therefore, the only option here
            // is to return false so the file isn't downloaded, and when
            // the user has selected the relevant alert action, then
            // the file can be downloaded if allowed
            return false
        } else {
            // The size of the file is smaller than the maximum for
            // the currently connected network, so it can be downloaded
            return true
        }
    }

    /// Sees if the file the user has selected is larger than the
    /// maximum sizes set to auto-download the file
    ///
    /// As a user could select any sized file, it is useful to know
    /// the size of the file and if it is larger than the default
    /// maximum sizes set for different network types, to prevent
    /// the user accidentally downloading it
    ///
    /// - note: Depending on the network the user is connected over,
    ///         different maximum file sizes are provided
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.5.0-beta
    /// - version: 1
    /// - date: 2016-01-16
    ///
    /// - seealso: downloadLargeFile
    ///
    /// - returns: Is the currently selected file considered "large"
    func largeFileSize() -> Bool {
        // Setting up the maximum sizes of the files that can be
        // downloaded without asking for permission
        let maximumWWANFileSize : Float = 20
        let maximumWiFiFileSize : Float = 100
        
        // Getting the size of the currently selected file (from: showFileDetails)
        // Splitting the file details string into the relevant date modified
        // and file size parts. On the master view controller, these values
        // are seperated with 4 spaces "    " so we can use this to split them
        // The file modification date comes first, followed by the file size
        // See: http://stackoverflow.com/a/25818228
        let fileDetail = fileDetails.componentsSeparatedByString("    ")
        let fileSizeFullString = fileDetail[1]
        logger.debug("File size of selected file is: \(fileSizeFullString)")
        
        // Splitting the fileSizeFullString into the numberical value and
        // capacity units in bytes
        let fileSizeSplitString = fileSizeFullString.componentsSeparatedByString(" ")
        let fileSize = Float(fileSizeSplitString[0])
        let fileBytePrefix = fileSizeSplitString[1]
        
        // Seeing how the user is connected to the Internet, as this limits
        // on what the maximum file size than can be downloaded is
        var maximumFileSize : Float = 0
        let status = Reach().connectionStatus()
        switch status {
            case .Unknown, .Offline:
                logger.warning("No available connection to the Internet")
                return false
            case .Online(.WWAN):
                logger.debug("Connection to the Intenet via WWAN, maximum file download size is: \(maximumWWANFileSize) MB")
                maximumFileSize = maximumWWANFileSize
            case .Online(.WiFi):
                logger.debug("Connection to the Internet via WiFi, maximum file download size is: \(maximumWiFiFileSize) MB")
                maximumFileSize = maximumWiFiFileSize
        }
        
        // Comparing the size of the current file with the maximum values
        // that are assigned
        switch fileBytePrefix.uppercaseString {
            case "GB", "TB", "PB", "EB", "ZB", "YB":
                // This is a really large file, so always request
                logger.debug("File being downloaded is larger than the maximum allowed")
                return true
            case "MB":
                // We need to see if the file is now above or below
                // our set maximum limits
                if (maximumFileSize <= fileSize) {
                    // The file is larger than what our maximum is
                    logger.debug("File being downloaded is larger than the maximum allowed")
                    return true
                } else {
                    logger.debug("File being downloaded is smaller than the maximum allowed")
                    return false
                }
            default:
                // The file isn't considered large, so it can be
                // downloaded
                logger.debug("File being downloaded is smaller than the maximum allowed")
                return false
        }
    }
    
    // MARK: App Restoration
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        // Saving the variables used in this class so that they
        // can be restored at when the app is opened again
        coder.encodeObject(fileDownloadPath, forKey: "fileDownloadPath")
        coder.encodeObject(fileName, forKey: "fileName")
        coder.encodeObject(fileType, forKey: "fileType")
        coder.encodeObject(fileDetails, forKey: "fileDetails")
        coder.encodeObject(fileExtension, forKey: "fileExtension")
        coder.encodeBool(fileDownloaded, forKey: "fileDownloaded")
        
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        // Restoring the variables used in this class
        // See: http://troutdev.blogspot.co.uk/2014/12/uistaterestoring-in-swift.html
        fileDownloadPath = coder.decodeObjectForKey("fileDownloadPath") as! String
        fileName = coder.decodeObjectForKey("fileName") as! String
        fileType = coder.decodeObjectForKey("fileType") as! String
        fileDetails = coder.decodeObjectForKey("fileDetails") as! String
        fileExtension = coder.decodeObjectForKey("fileExtension") as! String
        fileDownloaded = coder.decodeBoolForKey("fileDownloaded")
        
        super.decodeRestorableStateWithCoder(coder)
    }
    
    override func applicationFinishedRestoringState() {
        // Calling the showFileDetails() function after app
        // restoration, so that the details of the last
        // selected file can be shown to the user
        showFileDetails()
    }


}

