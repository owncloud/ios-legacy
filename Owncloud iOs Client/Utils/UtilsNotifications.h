//
//  UtilsNotifications.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 28/06/16.
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
//FOUNDATION_EXPORT

extern NSString *const PreviewFileNotification;
extern NSString *const UploadOverwriteFileNotification;
extern NSString *const FileDeleteInAOverwriteProcess;
extern NSString *const PreviewFileNotificationUpdated;

extern NSString *const IpadFilePreviewViewControllerFileWasDeletedNotification;
extern NSString *const IpadFilePreviewViewControllerFileWasDownloadNotification;
extern NSString *const IpadFilePreviewViewControllerFileWhileDonwloadingNotification;
extern NSString *const IpadFilePreviewViewControllerFileFinishDownloadNotification;
extern NSString *const IpadSelectRowInFileListNotification;
extern NSString *const IpadCleanPreviewNotification;
extern NSString *const IpadShowNotConnectionWithServerMessageNotification;

extern NSString *const IPhoneDoneEditFileTextMessageNotification;

@interface UtilsNotifications : NSObject

@end

