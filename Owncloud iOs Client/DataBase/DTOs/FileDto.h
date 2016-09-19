//
//  FileDto.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 8/6/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@class OCFileDto;

typedef enum {
    downloading = -1,
    notDownload = 0,
    downloaded = 1,
    updating = 2,
    overwriting = 3
    
} enumDownload;

@interface FileDto : NSObject {
}

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property BOOL isDirectory;
@property long size;
@property long date;
@property (nonatomic, copy) NSString *etag;
@property NSInteger idFile;
@property NSInteger userId;
@property BOOL needRefresh;
@property NSInteger isDownload;
@property NSInteger fileId;
@property (nonatomic, copy) NSString *localFolder;
@property BOOL isFavorite;
@property BOOL isRootFolder;
@property BOOL isNecessaryUpdate;
@property NSInteger sharedFileSource;
@property (nonatomic, copy) NSString *permissions;
@property NSInteger taskIdentifier;
@property (nonatomic) NSInteger providingFileId;
@property (nonatomic, copy) NSString *ocId;

///-----------------------------------
/// @name Init with OCFileDto
///-----------------------------------

/**
 * This method catch the data of OCFileDto in order to create
 * a FileDto object
 *
 * @param ocFileDto -> OCFileDto
 *
 *
 * @return FileDto
 *
 */
- (id)initWithOCFileDto:(OCFileDto*)ocFileDto;


@end
