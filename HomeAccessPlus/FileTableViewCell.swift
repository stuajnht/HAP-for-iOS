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
//  FileTableViewCell.swift
//  HomeAccessPlus
//

import UIKit
import Font_Awesome_Swift

class FileTableViewCell: UITableViewCell {

    @IBOutlet weak var lblFileName: UILabel!
    @IBOutlet weak var lblFileType: UILabel!
    @IBOutlet weak var lblFileDetails: UILabel!
    @IBOutlet weak var imgFileIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // Setting the colours of the file type and details
        // labels, so that they're not too distracting
        lblFileType.textColor = UIColor.flatGrayColor()
        lblFileDetails.textColor = UIColor.flatGrayColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    /// Setting the icon for the file or folder, based on what the
    /// extention is of the file type, or a folder if empty
    ///
    /// To help users identify what type of a file is quickly, the
    /// relevant icon should be shown on the table cell, before the
    /// name and description is of the file. The icons used are part
    /// of the FontAwesome font, as file icons do not seem to be
    /// included in the default icons for iOS
    ///
    /// This data is extracted from the JSON response from the HAP+
    /// server when a folder path is specified, and a custom option
    /// is specified here for a network drive.
    ///
    /// Additional file extentions should be added to their relevant
    /// section if they have been missed from this list (which many have!)
    ///
    /// - note: All file types and names are trademarks of their
    ///         respective owners
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.3.0-alpha
    /// - version: 1
    /// - date: 2015-12-13
    ///
    /// - parameter fileExtension: The extension of the file of the table cell
    func fileIcon(fileExtension: String) {
        var icon : FAType
        logger.verbose("Setting icon for the file type: \(fileExtension)")
        
        // Seeing what icon should be displayed
        switch fileExtension.lowercaseString {
            // Network drive
            case "drive":
                icon = FAType.FAHddO
            
            // File folder
            case "":
                icon = FAType.FAFolderO
            
            // Adobe Acrobat documents
            case ".pdf":
                icon = FAType.FAFilePdfO
            
            // Archive documents
            case ".zip", ".7z":
                icon = FAType.FAFileArchiveO
            
            // Audio documents
            case ".mp3", ".wav":
                icon = FAType.FAFileAudioO
            
            // Code documents
            case ".xml", ".html", ".css":
                icon = FAType.FAFileCodeO
            
            // Image documents
            case ".jpg", ".png", ".gif", ".bmp":
                icon = FAType.FAFileImageO
            
            // Microsoft Excel documents
            case ".xls", ".xlsx", ".xlsm", ".csv":
                icon = FAType.FAFileExcelO
            
            // Microsoft PowerPoint documents
            case ".ppt", ".pptx", ".pptm":
                icon = FAType.FAFilePowerpointO
            
            // Microsoft Word documents
            case ".doc", ".docx", ".dotm":
                icon = FAType.FAFileWordO
            
            // Text documents
            case ".txt", ".rtf", ".log":
                icon = FAType.FAFileTextO
            
            // Video documents
            case ".avi", ".mp4":
                icon = FAType.FAFileVideoO
            
            // Unknown file type
            default:
                icon = FAType.FAFileO
        }
        
        // Displaying the icon
        imgFileIcon.setFAIconWithName(icon, textColor: UIColor(hexString: hapMainColour))
    }

}
