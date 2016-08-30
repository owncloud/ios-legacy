//
//  FileDto.m
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

#import "FileDto.h"
#import "OCFileDto.h"

@implementation FileDto


///-----------------------------------
/// @name Init with OCFileDto
///-----------------------------------

/**
 * This method catch the data of OCFileDto in order to create
 * a FileDto object
 *
 * @param ocFileDto -> OCFileDto
 *
 * @return FileDto
 *
 */
- (id)initWithOCFileDto:(OCFileDto*)ocFileDto{
 
    self = [super init];
    if (self) {
        // Custom initialization
        _filePath = ocFileDto.filePath;
        _fileName = ocFileDto.fileName;
        _isDirectory = ocFileDto.isDirectory;
        _size = ocFileDto.size;
        _date = ocFileDto.date;
        _etag = ocFileDto.etag;
        _permissions = ocFileDto.permissions;
        _taskIdentifier = -1;
        _sharedFileSource = 0;
        _providingFileId = 0;
        _ocId = ocFileDto.ocId;
        
    }
    return self;
}


@end
