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
//        observer.finishEnumerating(upTo: NSFileProviderPage(myIntData))
    }
}
