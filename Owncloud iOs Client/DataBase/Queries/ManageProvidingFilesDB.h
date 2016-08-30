//
//  ManageProvidingFilesDB.h
//  Owncloud iOs Client
//
// This class represents the files that are using in other apps by Document Provider and
// it's can be edited by these other apps.
//
//  Created by Gonzalo Gonzalez on 2/1/15.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@class ProvidingFileDto;

@interface ManageProvidingFilesDB : NSObject

+ (ProvidingFileDto *) insertProvidingFileDtoWithPath:(NSString*)filePath byUserId:(NSInteger)userId;

+ (BOOL) removeProvidingFileDtoById:(NSInteger)idProvidingFile;

+ (NSArray*) getAllProvidingFilesDto;


+ (ProvidingFileDto *) getProvidingFileDtoByPath:(NSString *)filePath;



@end
