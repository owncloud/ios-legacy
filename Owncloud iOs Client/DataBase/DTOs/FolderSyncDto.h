//
//  FolderSyncDto.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 29/09/15.
//
//

#import "FileDto.h"

@interface FolderSyncDto : NSObject

@property NSInteger idFolderSync;
@property (nonatomic, strong) FileDto *file;
@property BOOL isRead;
@property NSInteger taskIdentifier;

@end
