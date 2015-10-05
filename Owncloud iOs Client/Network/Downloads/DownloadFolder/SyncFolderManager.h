//
//  SyncFolderManager.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 25/09/15.
//
//

#import <Foundation/Foundation.h>

@class FileDto;
@class CWLOrderedDictionary;
@class IndexedForest;

@interface SyncFolderManager : NSObject

@property (nonatomic, strong) CWLOrderedDictionary *dictOfFoldersToBeCheck;
@property (nonatomic, strong) IndexedForest *forestOfFilesAndFoldersToBeDownloaded;

- (void) addFolderToBeDownloaded: (FileDto *) folder;

@end
