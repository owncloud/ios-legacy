//
//  ManageThumbnails.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 23/12/15.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@interface ManageThumbnails : NSObject

+ (id) sharedManager;

- (BOOL) isStoredThumbnailForFile:(FileDto *)file;
- (BOOL) storeThumbnail:(NSData *)thumbnail forFile:(FileDto *)file;
- (BOOL) removeStoredThumbnailForFile:(FileDto *)file;
- (NSString *) getThumbnailPathForFile:(FileDto *)file;
- (void) deleteThumbnailsInFolder:(NSInteger)idFile;
- (void) deleteThumbnailCacheFolderOfUserId:(NSInteger) userId ;
@end
