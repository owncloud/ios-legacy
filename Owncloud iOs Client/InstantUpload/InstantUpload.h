//
//  InstantUpload.h
//  Owncloud iOs Client
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

#import <Foundation/Foundation.h>

@protocol InstantUploadDelegate <NSObject>

@required
- (void) instantUploadPermissionLostOrDenied;
- (void) backgroundInstantUploadPermissionLostOrDenied;

@end

@interface InstantUpload : NSObject

@property (weak) id<InstantUploadDelegate> delegate;

+ (instancetype) instantUploadManager;

- (BOOL) imageInstantUploadEnabled;
- (void) setImageInstantUploadEnabled:(BOOL)enabled;

- (BOOL) videoInstantUploadEnabled;
- (void) setVideoInstantUploadEnabled:(BOOL)enabled;

- (BOOL) backgroundInstantUploadEnabled;
- (void) setBackgroundInstantUploadEnabled:(BOOL)enabled;

- (void) activate;

@end
