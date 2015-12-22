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
//  DetailViewController.swift
//  HomeAccessPlus
//

import UIKit
import ChameleonFramework
import MBProgressHUD
import QuickLook

class DetailViewController: UIViewController, QLPreviewControllerDataSource {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    // Loading an instance of the HAPi
    let api = HAPi()
    
    // MBProgressHUD variable, so that a download progress bar can be shown
    var hud : MBProgressHUD = MBProgressHUD()
    
    // Holding the path that can be used to download
    // the file that the user has selected
    var fileDownloadPath = ""
    
    // Holding the name of the file to use for the QuickLook controller
     var fileName = ""
    
    // Saving the extention of the file that is being downloaded
    // so that the QuickLook preview knows what to show
    var fileExtension = ""
    
    // Setting the location on the device where the file is
    var fileDeviceLocation = ""


    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem {
            //if let label = self.detailDescriptionLabel {
            //    label.text = detail.description
            //}
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        
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
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(controller: QLPreviewController, previewItemAtIndex index: Int) -> QLPreviewItem {
        // Below fails with: Couldn't issue file extension for path:
        //return NSURL.fileURLWithPath(fileDeviceLocation)
        
        var cachesDirectories: [AnyObject] = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        logger.debug("Caches directories: \(cachesDirectories)")
        // See: http://stackoverflow.com/a/33055193
        let cachesDirectory: String = (cachesDirectories[0] as? String)!
        logger.debug("Cache directory: \(cachesDirectory)")
        
        // Generating a full path to the downloaded file
        let fullPath = cachesDirectory + "/" + fileName + fileExtension
        logger.debug("Attempting to open file located at: \(fullPath)")
        return NSURL.fileURLWithPath(fullPath)
    }


}

