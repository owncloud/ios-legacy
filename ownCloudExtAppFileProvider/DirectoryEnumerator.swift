//
//  DirectoryEnumerator.swift
//  ownCloudExtAppFileProvider
//
//  Created by Pablo Carrascal on 06/11/2017.
//

import UIKit

class DirectoryEnumerator: FileProviderEnumerator {
    
    deinit {
        print("Directory Enumerator being deallocated")
    }
    
    override func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        var listing: [NSFileProviderItemProtocol] = []
        
        do {
            try listing = listDirectory(path: enumeratedItemIdentifier.rawValue, parent: enumeratedItemIdentifier) 
        } catch {
            print("LOG ---> error enumerateItems\(error.localizedDescription)")
            observer.finishEnumeratingWithError(error)
            return
        }
        
        // inspect the page to determine whether this is an initial or a follow-up request
//        switch page {
//        case NSFileProviderPage.initialPageSortedByName:
//            listing = sortByName(listing: listing)
//        case NSFileProviderPage.initialPageSortedByDate:
//            listing = sortByDate(listing: listing)
//        default:
//            print("Not implemented: request for page starting at specific page")
//        }
        observer.didEnumerate(listing)
        observer.finishEnumerating(upTo: nil)
    }
    
    override func listDirectory(path: String, parent: NSFileProviderItemIdentifier) throws -> [NSFileProviderItemProtocol] {
        
        var items: [NSFileProviderItemProtocol] = []
        
        let activeUser: UserDto = ManageUsersDB.getActiveUser()
        
        let files = ManageFilesDB.getFilesByFileId(forActiveUser: Int(path)!)
        print("LOG --->  listDirectory directory enimerator files count \(files?.count)")

        
        if #available(iOSApplicationExtension 11.0, *) {
            for file in files! {
                print("LOG ---> #available(iOSApplicationExtension 11.0, *)")
                
                if !(file as! FileDto).isDirectory {
                    let item = FileProviderItem(root: true, ocFile: file as! FileDto)
                    items.append(item)
                } else {
                    let item = FolderProviderItem(directory: file as! FileDto, root: false)
                    items.append(item)
                }
                
            }
        } else {
            // Fallback on earlier versions
            print("LOG ---> System version lower than 11.0")
        }
        
        return items
    }
}
