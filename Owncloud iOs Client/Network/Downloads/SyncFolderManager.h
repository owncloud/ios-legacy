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

@interface SyncFolderManager : NSObject

@property (nonatomic, strong) CWLOrderedDictionary *dictOfFilesAndFoldersToBeDownloaded;
@property NSInteger indexDict; //TODO: set indexDict to 0 when we finish the loop

- (void) addFolderToBeDownloaded: (FileDto *) folder;

@end
