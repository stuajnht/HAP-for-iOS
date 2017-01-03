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
//  FileProvider.swift
//  DocumentProviderFileProvider
//

import UIKit
import SwiftyJSON
import XCGLogger

class FileProvider: NSFileProviderExtension {
    
    // Loading an instance of the HAPi class, so that the
    // functions in it can be used in the document provider
    let api = HAPi()

    var fileCoordinator: NSFileCoordinator {
        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.purposeIdentifier = self.providerIdentifier
        return fileCoordinator
    }

    override init() {
        super.init()
        
        self.fileCoordinator.coordinate(writingItemAt: self.documentStorageURL, options: NSFileCoordinator.WritingOptions(), error: nil, byAccessor: { newURL in
            // ensure the documentStorageURL actually exists
            do {
                try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // Handle error
            }
        })
    }

    override func providePlaceholder(at url: URL, completionHandler: ((_ error: NSError?) -> Void)?) {
        // Should call writePlaceholderAtURL(_:withMetadata:error:) with the placeholder URL, then call the completion handler with the error if applicable.
        let fileName = url.lastPathComponent
    
        let placeholderURL = NSFileProviderExtension.placeholderURL(for: self.documentStorageURL.appendingPathComponent(fileName))
    
        // TODO: get file size for file at <url> from model
        let fileSize = 0
        let metadata = [URLResourceKey.fileSizeKey: fileSize]
        do {
            try NSFileProviderExtension.writePlaceholder(at: placeholderURL, withMetadata: metadata)
        } catch {
            // Handle error
        }

        completionHandler?(nil)
    }

    override func startProvidingItem(at url: URL, completionHandler: ((_ error: NSError?) -> Void)?) {
        let fileManager = FileManager()
        let path = url.path
        if fileManager.fileExists(atPath: path) { //1
            //if the file is already, just return
            completionHandler?(nil)
            return
        }
        
        
        api.downloadFile(url.lastPathComponent!, callback: { (result: Bool, downloading: Bool, downloadedBytes: Int64, totalBytes: Int64, downloadLocation: URL) -> Void in
                
                // There was a problem with downloading the file, so let the
                // user know about it
                if ((result == false) && (downloading == false)) {
                    logger.error("There was a problem downloading the file")
                    completionHandler?(error: nil)
                }
                
                // The file has downloaded successfuly so we can present the
                // file to the user
                if ((result == true) && (downloading == false)) {
                    var error: NSError? = nil
                    let fileData = try? Data(contentsOf: downloadLocation)
                    self.fileCoordinator.coordinate(writingItemAt: url,
                    options: .forReplacing,
                    error: &error,
                    byAccessor: { newURL in //4
                    
                        do {
                            try fileData!.write(to: newURL, options: .atomicWrite)
                            logger.debug("File written to \"\(newURL)\"")
                        }
                        catch let errorWrite as NSError {
                            logger.error("Copy failed with error: \(errorWrite.localizedDescription)")
                            completionHandler?(error: errorWrite)
                        }
                    
                    
                    })
                }
        })
    }


    override func itemChanged(at url: URL) {
        // Called at some point after the file has changed; the provider may then trigger an upload

        // TODO: mark file at <url> as needing an update in the model; kick off update process
        NSLog("Item changed at URL %@", url)
    }

    override func stopProvidingItem(at url: URL) {
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        // Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.

        do {
            _ = try FileManager.default.removeItem(at: url)
        } catch {
            // Handle error
        }
        self.providePlaceholder(at: url, completionHandler: { error in
            // TODO: handle any error, do any necessary cleanup
        })
    }
    
    override var documentStorageURL : URL {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.uk.co.stuajnht.ios.HomeAccessPlus")!
    }

}
