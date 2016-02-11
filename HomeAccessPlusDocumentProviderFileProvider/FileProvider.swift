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
        fileCoordinator.purposeIdentifier = self.providerIdentifier()
        return fileCoordinator
    }

    override init() {
        super.init()
        
        self.fileCoordinator.coordinateWritingItemAtURL(self.documentStorageURL(), options: NSFileCoordinatorWritingOptions(), error: nil, byAccessor: { newURL in
            // ensure the documentStorageURL actually exists
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(newURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                // Handle error
            }
        })
    }

    override func providePlaceholderAtURL(url: NSURL, completionHandler: ((error: NSError?) -> Void)?) {
        // Should call writePlaceholderAtURL(_:withMetadata:error:) with the placeholder URL, then call the completion handler with the error if applicable.
        let fileName = url.lastPathComponent!
    
        let placeholderURL = NSFileProviderExtension.placeholderURLForURL(self.documentStorageURL().URLByAppendingPathComponent(fileName))
    
        // TODO: get file size for file at <url> from model
        let fileSize = 0
        let metadata = [NSURLFileSizeKey: fileSize]
        do {
            try NSFileProviderExtension.writePlaceholderAtURL(placeholderURL, withMetadata: metadata)
        } catch {
            // Handle error
        }

        completionHandler?(error: nil)
    }

    override func startProvidingItemAtURL(url: NSURL, completionHandler: ((error: NSError?) -> Void)?) {
        let fileManager = NSFileManager()
        let path = url.path!
        if fileManager.fileExistsAtPath(path) { //1
            //if the file is already, just return
            completionHandler?(error: nil)
            return
        }
        
        
        api.downloadFile(url.lastPathComponent!, callback: { (result: Bool, downloading: Bool, downloadedBytes: Int64, totalBytes: Int64, downloadLocation: NSURL) -> Void in
                
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
                    let fileData = NSData(contentsOfURL: downloadLocation)
                    self.fileCoordinator.coordinateWritingItemAtURL(url,
                    options: .ForReplacing,
                    error: &error,
                    byAccessor: { newURL in //4
                    
                        do {
                            try fileData!.writeToURL(newURL, options: .AtomicWrite)
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


    override func itemChangedAtURL(url: NSURL) {
        // Called at some point after the file has changed; the provider may then trigger an upload

        // TODO: mark file at <url> as needing an update in the model; kick off update process
        NSLog("Item changed at URL %@", url)
    }

    override func stopProvidingItemAtURL(url: NSURL) {
        // Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
        // Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.

        do {
            _ = try NSFileManager.defaultManager().removeItemAtURL(url)
        } catch {
            // Handle error
        }
        self.providePlaceholderAtURL(url, completionHandler: { error in
            // TODO: handle any error, do any necessary cleanup
        })
    }
    
    override func documentStorageURL() -> NSURL {
        return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.uk.co.stuajnht.ios.HomeAccessPlus")!
    }

}
