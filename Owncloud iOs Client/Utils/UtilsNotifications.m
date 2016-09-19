//
//  UtilsNotifications.m
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

#import "UtilsNotifications.h"

@implementation UtilsNotifications

NSString *const PreviewFileNotification = @"PreviewFileNotification";
NSString *const UploadOverwriteFileNotification = @"UploadOverwriteFileNotification";
NSString *const FileDeleteInAOverwriteProcess = @"FileDeleteInAOverwriteProcess";
NSString *const PreviewFileNotificationUpdated = @"PreviewFileNotificationUpdated";

NSString *const IpadFilePreviewViewControllerFileWasDeletedNotification = @"IpadFilePreviewViewControllerFileWasDeletedNotification";
NSString *const IpadFilePreviewViewControllerFileWasDownloadNotification = @"IpadFilePreviewViewControllerFileWasDownloadNotification";
NSString *const IpadFilePreviewViewControllerFileWhileDonwloadingNotification = @"IpadFilePreviewViewControllerFileWhileDonwloadingNotification";
NSString *const IpadFilePreviewViewControllerFileFinishDownloadNotification = @"IpadFilePreviewViewControllerFileFinishDownloadNotification";
NSString *const IpadSelectRowInFileListNotification = @"IpadSelectRowInFileListNotification";
NSString *const IpadCleanPreviewNotification = @"IpadCleanPreviewNotification";
NSString *const IpadShowNotConnectionWithServerMessageNotification = @"IpadShowNotConnectionWithServerMessageNotification";

NSString *const IPhoneDoneEditFileTextMessageNotification = @"IPhoneDoneEditFileTextMessageNotification";

@end

