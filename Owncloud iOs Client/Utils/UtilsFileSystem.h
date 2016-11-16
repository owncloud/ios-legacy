//
//  UtilsFileSystem.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 09/05/16.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@interface UtilsFileSystem : NSObject


+ (NSString *) temporalFileNameByName:(NSString *)fileName;
+ (BOOL) createFileOnTheFileSystemByPath:(NSString *)tempPath andData:(NSData *)fileData;
+ (BOOL) moveFileOnTheFileSystemFrom:(NSString *)origin toDestiny:(NSString *)destiny;
+ (BOOL) existFileOnFileSystemByPath:(NSString *)filePath;
+ (void) initBundleVersionDefaults;
+ (BOOL) isOpenAfterUpgrade;

@end
