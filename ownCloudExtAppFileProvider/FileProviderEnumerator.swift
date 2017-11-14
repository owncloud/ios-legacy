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
        
        print("LOG ---> \(observer.description)")
        
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
        // TODO: enumerate changes.
        print("LOG ---> enumerateChanges")

    }
    
    func listDirectory(path: String, parent: NSFileProviderItemIdentifier) throws -> [NSFileProviderItemProtocol] {

        var items: [NSFileProviderItemProtocol] = []
        
        let activeUser: UserDto = ManageUsersDB.getActiveUser()
        print("LOG ---> files count \(activeUser.username)")
        
        let rootFolder = ManageFilesDB.getRootFileDto(byUser: activeUser)
        print("LOG ---> files count \(rootFolder?.idFile)")
        
        let files = ManageFilesDB.getFilesByFileId(forActiveUser: rootFolder!.idFile)
        
        for file in files! {
            if #available(iOSApplicationExtension 11.0, *) {
                
                if !(file as! FileDto).isDirectory {
                    let item = FileProviderItem(parent: NSFileProviderItemIdentifier.rootContainer, type: .directory, ocFile: file as! FileDto)
                    items.append(item)
                } else {
                    let item = FolderProviderItem(folder: file as! FileDto)
                    items.append(item)
                }

            } else {
                // Fallback on earlier versions
            }
        }
        
        return items
    }
    
}
