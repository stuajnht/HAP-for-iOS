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

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    // Loading an instance of the HAPi
    let api = HAPi()
    
    // MBProgressHUD variable, so that a download progress bar can be shown
    var hud : MBProgressHUD = MBProgressHUD()
    
    // Holding the path that can be used to download
    // the file that the user has selected
    var fileDownloadPath = ""


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
            api.downloadFile(fileDownloadPath, callback: { (result: Bool, downloadedBytes: Int64, totalBytes: Int64, downloadLocation: String) -> Void in
                logger.debug("File downloaded to: \(downloadLocation)")
                self.hudUpdatePercentage(downloadedBytes, totalBytes: totalBytes)
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
        logger.debug("Current downloaded percentage: \(currentPercentage * 100)%")
        hud.progress = currentPercentage
    }
    
    func hudHide() {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    }


}

