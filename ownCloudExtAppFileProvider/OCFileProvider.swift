//
//  OCFileProvider.swift
//  ownCloudExtAppFileProvider
//
//  Created by Pablo Carrascal on 03/11/2017.
//

import UIKit

@available(iOSApplicationExtension 11.0, *)
class OCFileProvider: NSFileProviderExtension {
    
    // This is our file provider manager, it handles things like placeholders on disk
    var fileProviderManager: NSFileProviderManager!
    var fileManager: FileManager!
    
    
    override init() {
        print("FileProviderExtension is being created")
        super.init()
        
        let activeUser: UserDto = ManageUsersDB.getActiveUser()
        print("LOG ---> files count \(activeUser.username)")

        let userLocalPath: String = UtilsUrls.getOwnCloudFilePath().appendingFormat("%ld", activeUser.idUser)
        
        let currentUserDomain: NSFileProviderDomain = NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier(String(activeUser.idUser)) , displayName: activeUser.credDto.userDisplayName, pathRelativeToDocumentStorage: userLocalPath)
        
        self.fileProviderManager = NSFileProviderManager.default

        self.fileManager = FileManager()
    }
    
    deinit {
        print("FileProviderExtension is being deallocated")
    }
    
    override func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        
        //return the unique id if exists a file with the url getted as parameter.
        
        return NSFileProviderItemIdentifier.init("elePitele")
        
//        ManageFilesDB.getFileDto(
//
    }
    
    override func urlForItem(withPersistentIdentifier identifier: NSFileProviderItemIdentifier) -> URL? {
       
        print("LOG ---> urlForItem")
        
        return URL(fileURLWithPath: "pepe")
    }
    
    override func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        
        if identifier == .rootContainer {
            let activeUser: UserDto = ManageUsersDB.getActiveUser()
            print("LOG ---> files count \(activeUser.username)")
            
            let rootFolder = ManageFilesDB.getRootFileDto(byUser: activeUser)
            print("LOG ---> files count \(rootFolder?.idFile)")

            return FileProviderItem(parent: .rootContainer, type: .directory, ocFile: rootFolder!)
        }
        
        return FileProviderItem(dummy: "dummy")
    }
    
    override func itemChanged(at url: URL) {
        print("LOG ---> itemchanged")
    }
    
    override func providePlaceholder(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        
        guard let identifier = persistentIdentifierForItem(at: url) else {

            completionHandler(NSFileProviderError(.noSuchItem))
            return
        }

        do {
            let fileProviderItem = try item(for: identifier)
            let fileName:String = url.lastPathComponent
            
            let placeholderURL: URL = NSFileProviderManager.placeholderURL(for: self.fileProviderManager.documentStorageURL.appendingPathComponent(fileName))
            
            try NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: FileProviderItem(dummy: "du"))

            completionHandler(nil)
        }
        catch let error {
            completionHandler(error)
        }
    }
    
    func fileCoordinator() -> NSFileCoordinator {
        let fileCoordinator = NSFileCoordinator()
        fileCoordinator.purposeIdentifier = self.providerIdentifier
        return fileCoordinator
    }
    
    override func startProvidingItem(at url: URL, completionHandler: @escaping (Error?) -> Void) {
        print("LOG --->startproviding")

    }
    
    override func stopProvidingItem(at url: URL) {
        print("LOG --->stopproviding")
    }
    
    override func createDirectory(withName directoryName: String, inParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG --->createdirectory")
        completionHandler(nil, nil)
    }
    
    override func deleteItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (Error?) -> Void) {
        print("LOG --->delete")
        completionHandler(nil)
    }
    
    override func importDocument(at fileURL: URL, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG --->import")
        completionHandler(nil, nil)

    }
    
    override func renameItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toName itemName: String, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG ---> rename")
        completionHandler(nil, nil)
    }
    
    override func setFavoriteRank(_ favoriteRank: NSNumber?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG --->setfavourite")
        completionHandler(nil, nil)
    }
    
    override func setLastUsedDate(_ lastUsedDate: Date?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG --->setLastUsedDate")
        completionHandler(nil, nil)
    }
    
    override func setTagData(_ tagData: Data?, forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG ---> setTagData")
        completionHandler(nil, nil)
    }
    
    override func trashItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG ---> trashitem")
        completionHandler(nil, nil)
    }
    
    override func untrashItem(withIdentifier itemIdentifier: NSFileProviderItemIdentifier, toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier?, completionHandler: @escaping (NSFileProviderItem?, Error?) -> Void) {
        print("LOG ---> untrashitem")
        completionHandler(nil, nil)
    }
    
    override func fetchThumbnails(for itemIdentifiers: [NSFileProviderItemIdentifier], requestedSize size: CGSize, perThumbnailCompletionHandler: @escaping (NSFileProviderItemIdentifier, Data?, Error?) -> Void, completionHandler: @escaping (Error?) -> Void) -> Progress {
    
        let progress = Progress(totalUnitCount: Int64(itemIdentifiers.count))
        
        let image = UIImage(named: "doc_icon")
        let imagePNG = UIImagePNGRepresentation(image!) as! Data
        
        for item in itemIdentifiers {
            perThumbnailCompletionHandler(item, imagePNG, nil)
        }
        
        return progress

    }
    
    override func enumerator(for containerItemIdentifier: NSFileProviderItemIdentifier) throws -> NSFileProviderEnumerator {
        print("LOG ---> enumerator")
        var maybeEnumerator: NSFileProviderEnumerator? = nil
        
        print("LOG ---> containerItemIdentifier \(containerItemIdentifier)")
        switch containerItemIdentifier {
                case .rootContainer:
                // TODO: instantiate an enumerator for the container root
                maybeEnumerator = DirectoryEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
                case .workingSet:
                // TODO: instantiate an enumerator for the working set
                maybeEnumerator = DirectoryEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
                default:
                // TODO: determine if the item is a directory or a file
                // - for a directory, instantiate an enumerator of its subitems
                // - for a file, instantiate an enumerator that observes changes to the file
                maybeEnumerator = DirectoryEnumerator(enumeratedItemIdentifier: containerItemIdentifier)
            }
            
            guard let enumerator = maybeEnumerator else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo:[:])
            }
            return enumerator
    }
}

