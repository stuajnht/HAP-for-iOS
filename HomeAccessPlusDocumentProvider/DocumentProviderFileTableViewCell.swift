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
//  DocumentProviderFileTableViewCell.swift
//  HomeAccessPlus
//

import UIKit
import Font_Awesome_Swift

/// This class is a direct copy of the one in the main
/// HomeAccessPlus group, just with two of the IBoutlets
/// removed and the manual HAP+ colour used as Chameleon
/// Framework cannot be used in extensions
///
/// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
/// - since: 0.7.0-alpha
/// - version: 1
/// - date: 2016-02-07
class DocumentProviderFileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblFileName: UILabel!
    @IBOutlet weak var imgFileIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
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
    /// - note: Due to the response from the HAP+ API, if a folder contains
    ///         a '.' in it, then it incorrectly adds a folder extension
    ///         into the JSON response, based on whatever is listed after
    ///         the last '.' e.g. 'folder.example' returns '.example' - issue #13
    ///         This may change in a future version of the HAP+ API, so bare
    ///         in mind that someday this function may break!
    ///
    /// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
    /// - since: 0.7.0-alpha
    /// - version: 2
    /// - date: 2016-04-01
    ///
    /// - parameter fileType: The type of the file of the table cell
    /// - parameter fileExtension: The extension of the file in the table cell
    func fileIcon(_ fileType: String, fileExtension: String) {
        var icon : FAType
        logger.verbose("Setting icon for the file type: \(fileType)")
        
        // Assigning a local variable to hold the file extension, as using
        // 'var' in the function parameter is depricated from Swift 2.2
        // See: https://github.com/apple/swift-evolution/blob/master/proposals/0003-remove-var-parameters.md
        var fileExtension = fileExtension
        
        // Setting the file extension to be "" if the file type is a folder,
        // but contains a '.' in the name somewhere - issue #13
        if (fileType == "Directory") {
            fileExtension = ""
        }
        
        // Setting the file extension to be something custom if the file type
        // is a file, but it contains no extension in the name - issue #13
        let emptyFileExtension = "uk.co.stuajnht.ios.HomeAccessPlus.fileTableViewCell.fileIcon.emptyFileExtension"
        if ((fileType == "File") && (fileExtension == "")) {
            fileExtension = emptyFileExtension
        }
        
        // Seeing what icon should be displayed
        switch fileExtension.lowercased() {
            // Network drive
        case "drive":
            icon = FAType.FAHddO
            
            // File folder
        case "", "directory":
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
        case ".jpg", ".png", ".gif", ".bmp", ".ico", ".svg":
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
        case ".avi", ".mp4", ".mov":
            icon = FAType.FAFileVideoO
            
            // Unknown file with no extension - issue #13
        case emptyFileExtension:
            icon = FAType.FAFileO
            
            // Unknown file type
        default:
            icon = FAType.FAFileO
        }
        
        // Displaying the icon
        imgFileIcon.setFAIconWithName(icon, textColor: UIColor.init(colorLiteralRed: 0, green: 0.36470588240000001, blue: 0.6705882353, alpha: 1))
    }
    
}
