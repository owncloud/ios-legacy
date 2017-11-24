//
//  FileProviderEnumerator.swift
//  ownCloudExtAppFileProvider
//
//  Created by Pablo Carrascal on 06/11/2017.
//

func sortByName(listing: [FileProviderItem]) -> [FileProviderItem] {
    return listing.sorted(by: {
        (itemA, itemB) in
        return itemA.filename < itemB.filename
    })
}

func sortByDate(listing: [FileProviderItem]) -> [FileProviderItem] {
    return listing.sorted(by: {
        (itemA, itemB) in
        return itemA.lastModified < itemB.lastModified
    })
}

class FileProviderEnumerator: NSObject, NSFileProviderEnumerator {
    
    var enumeratedItemIdentifier: NSFileProviderItemIdentifier
    
    init(enumeratedItemIdentifier: NSFileProviderItemIdentifier) {
        print("LOG ---> FileProviderEnumerator \(enumeratedItemIdentifier) being initialized")
        self.enumeratedItemIdentifier = enumeratedItemIdentifier
        super.init()
    }
    
    deinit {
        print("FileProviderEnumerator is being deallocated")
    }
    
    func invalidate() {
        // TODO: cancel the request with the server or something like that.
        print("LOG ---> invalidate")
    }
    
    func enumerateItems(for observer: NSFileProviderEnumerationObserver, startingAt page: NSFileProviderPage) {
        print("LOG ---> enumerateItems")
        
        print("LOG ---> observer description \(observer.description)")
        observer.finishEnumerating(upTo: nil)

        /* TODO:
         - inspect the page to determine whether this is an initial or a follow-up request
         If this is an enumerator for a directory, the root container or all directories:
         - perform a server request to fetch directory contents
         If this is an enumerator for the active set:
         - perform a server request to update your local database
         - fetch the active set from your local database
         
         - inform the observer about the items returned by the server (possibly multiple times)
         - inform the observer that you are finished with this page
         */

    }
    
    func enumerateChanges(for observer: NSFileProviderChangeObserver, from syncAnchor: NSFileProviderSyncAnchor) {
        print("LOG ---> enumerateChanges")
        /* TODO:
         - query the server for updates since the passed-in sync anchor
         
         If this is an enumerator for the active set:
         - note the changes in your local database
         
         - inform the observer about item deletions and updates (modifications + insertions)
         - inform the observer when you have finished enumerating up to a subsequent sync anchor
         */
    }
    
    func listDirectory(path: String, parent: NSFileProviderItemIdentifier) throws -> [NSFileProviderItemProtocol] {

        var items: [NSFileProviderItemProtocol] = []
        
//        let activeUser: UserDto = ManageUsersDB.getActiveUser()
//        print("LOG ---> files count \(activeUser.username)")
//        
//        let rootFolder = ManageFilesDB.getRootFileDto(byUser: activeUser)
//        print("LOG ---> files count \(rootFolder?.idFile)")
//        
//        let files = ManageFilesDB.getFilesByFileId(forActiveUser: rootFolder!.idFile)
//        
//        for file in files! {
//            if #available(iOSApplicationExtension 11.0, *) {
//                
//                if !(file as! FileDto).isDirectory {
//                    let item = FileProviderItem(root: true, ocFile: file as! FileDto)
//                    items.append(item)
//                } else {
//                    let item = FolderProviderItem(directory: file as! FileDto)
//                    items.append(item)
//                }
//
//            } else {
//                // Fallback on earlier versions
//            }
//        }
//        
        return items
    }
    
}
