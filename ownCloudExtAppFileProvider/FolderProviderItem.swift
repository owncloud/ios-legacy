//
//  FolderProviderItem.swift
//  ownCloudExtAppFileProvider
//
//  Created by Pablo Carrascal on 14/11/2017.
//

import UIKit

class FolderProviderItem: NSObject, NSFileProviderItem {
    var itemIdentifier: NSFileProviderItemIdentifier
    var parentItemIdentifier: NSFileProviderItemIdentifier
    var filename: String = ""
    var typeIdentifier: String = ""
    
    var childItemCount: NSNumber?
    
    init(folder: FileDto) {
        self.itemIdentifier = NSFileProviderItemIdentifier(folder.etag)
//        self.parentItemIdentifier = NSFileProviderItemIdentifier(String(folder.fileId))

        if #available(iOSApplicationExtension 11.0, *) {
            self.parentItemIdentifier = NSFileProviderItemIdentifier.rootContainer
        } else {
            self.parentItemIdentifier = NSFileProviderItemIdentifier(String(folder.fileId))
        }
        
        self.filename = folder.fileName
        self.typeIdentifier = "dir"
        
        //TODO: We need to change this with the real number of child files the folder has.
        self.childItemCount = 10
    }
    
    deinit {
        print("\(filename) item is being deallocated")
    }

}
