 //
//  InfoFileUtils.m
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 06/03/14.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "InfoFileUtils.h"
#import "FileDto.h"
#import "constants.h"
#import "CustomCellFileAndDirectory.h"
#import "FileNameUtils.h"
#import "IndexedForest.h"
#import "UtilsUrls.h"
#import "SyncFolderManager.h"
#import "CWLOrderedDictionary.h"
#import "UtilsUrls.h"
#import "ManageSharesDB.h"
#import "ManageFilesDB.h"
#import "FileListDBOperations.h"
#import "UIImage+Thumbnail.h"
#import "ManageThumbnails.h"
#import "ManageUsersDB.h"
#import "NSObject+AssociatedObject.h"
#import "OCSharedDto.h"
#import "OCCommunication.h"
#import "Customization.h"

#ifdef CONTAINER_APP
#import "AppDelegate.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "DocumentPickerViewController.h"
#endif

@implementation InfoFileUtils


///-----------------------------------
/// @name getTheDifferenceBetweenDateOfUploadAndNow
///-----------------------------------

/**
 * This method obtains the difference between the upload date and the received date doing
 * a custom string like a:
 * seconds ago
 * minutes ago
 * hours ago
 * days ago
 * the date of upload (When the days > 30)
 *
 * @param NSDate -> date
 *
 * @return NSString -> The searched date
 */
+ (NSString *)getTheDifferenceBetweenDateOfUploadAndNow:(NSDate *)date {
    
    NSString *temp;
    
    NSDate *now = [NSDate date];
    NSTimeInterval timePassed = [now timeIntervalSinceDate:date];
    
    int minute = 60; //seconds one minute
    int hour = 3600; //seconds one hour
    int day = 86400; //seconds one day
    int month = 2592000; //seconds one month of 30 days
    int year = 31536000; //seconds in one year
    
    if (timePassed > 0) {
        
        if (timePassed < minute ) {
            //seconds ago
            temp=[NSString stringWithFormat:NSLocalizedString(@"recent_now", nil)];
        } else if (timePassed < hour) {
            //minutes ago
            int minutes;
            minutes = timePassed/minute;
            NSString *minutesString = [NSString stringWithFormat:@"%d", minutes];
            if (minutes == 1) {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_minute", nil) stringByReplacingOccurrencesOfString:@"$minutes" withString:minutesString]];
            } else {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_minutes", nil) stringByReplacingOccurrencesOfString:@"$minutes" withString:minutesString]];
            }
            
        } else if (timePassed < day) {
            //hours ago
            int hours;
            hours = timePassed/hour;
            NSString *hoursString = [NSString stringWithFormat:@"%d", hours];
            if (hours == 1) {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_hour", nil) stringByReplacingOccurrencesOfString:@"$hours" withString:hoursString]];
            } else {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_hours", nil) stringByReplacingOccurrencesOfString:@"$hours" withString:hoursString]];
            }
            
        } else if (timePassed < month) {
            //days ago
            int days;
            days = timePassed/day;
            NSString *daysString = [NSString stringWithFormat:@"%d", days];
            if (days == 1) {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_day", nil) stringByReplacingOccurrencesOfString:@"$days" withString:daysString]];
            } else {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_days", nil) stringByReplacingOccurrencesOfString:@"$days" withString:daysString]];
            }
            
        } else if (timePassed < year) {
            //months ago
            int months;
            months = timePassed/month;
            NSString *monthsString = [NSString stringWithFormat:@"%d", months];
            if (months == 1) {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_month", nil) stringByReplacingOccurrencesOfString:@"$months" withString:monthsString]];
            } else {
                temp = [NSString stringWithFormat:@"%@", [NSLocalizedString(@"recent_months", nil) stringByReplacingOccurrencesOfString:@"$months" withString:monthsString]];
            }
        } else {
            //years ago -> the day 13-12-12
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            //Set the date and time format as the system
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setTimeZone:[NSTimeZone systemTimeZone]];
            temp = [formatter stringFromDate:date];
        }
        
    } else {
        //If the timePassed is negative because the device date is previous to the upload date, show the date not the relative date
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        //Set the date and time format as the system
        [formatter setDateStyle:NSDateFormatterMediumStyle];
        [formatter setDateFormat:@"dd/MM/yy"];
        temp = [formatter stringFromDate:date];
    }
    return temp;
}

///-----------------------------------
/// @name setTheStatusIconOntheFile:onTheCell:
///-----------------------------------

/**
 * This method set the status icon of the files and folders
 - The general icons of the icons
 - The general icons of the folder (shared by link, shared with user)
 - The shared icon on the right of the file list
 - The status icon of the files
 *
 * @param fileForSetTheStatusIcon -> FileDto, the file for set the status
 * @param fileCell -> CustomCellFileAndDirectory, the cell where the file is located
 * @param currentFolder -> FileDto, of the folder that contain the fileForSetTheStatusIcon
 * @param isCurrentFolderSonOfFavoriteFolder -> BOOL, indicate if the current cell is from a favorit folder
 * @param user -> UserDto.
 */
+ (CustomCellFileAndDirectory *) getTheStatusIconOntheFile: (FileDto *)fileForSetTheStatusIcon onTheCell: (CustomCellFileAndDirectory *)fileCell andCurrentFolder:(FileDto *)currentFolder andIsSonOfFavoriteFolder:(BOOL)isCurrentFolderSonOfFavoriteFolder ofUser:(UserDto *)user {
    
    NSString *path = [NSString stringWithFormat:@"/%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:fileForSetTheStatusIcon.filePath andUser:user], fileForSetTheStatusIcon.fileName];
    
    NSMutableArray *allShares = [ManageSharesDB getSharesByUser:user.idUser andPath:path];
    NSInteger numberOfShares = allShares.count;
    NSPredicate *predicateShareByLink = [NSPredicate predicateWithFormat:@"shareType == %i", shareTypeLink];
    NSArray *sharesByLink = [allShares filteredArrayUsingPredicate:predicateShareByLink];
    NSInteger numberOfSharesByLink = sharesByLink.count;
    NSPredicate *predicateShareByRemote = [NSPredicate predicateWithFormat:@"shareType == %i", shareTypeRemote];
    NSArray *sharesByRemote = [allShares filteredArrayUsingPredicate:predicateShareByRemote];
    NSInteger numberOfSharesByRemote = sharesByRemote.count;
    
    BOOL isShareAPIActive = (user.hasCapabilitiesSupport != serverFunctionalitySupported) || (user.hasCapabilitiesSupport == serverFunctionalitySupported && user.capabilitiesDto && user.capabilitiesDto.isFilesSharingAPIEnabled);

    if (fileForSetTheStatusIcon.isDirectory) {
        
            if ([fileForSetTheStatusIcon.permissions rangeOfString:k_permission_shared].location != NSNotFound) {
                fileCell.fileImageView.image=[UIImage imageNamed:@"folder-shared.png"];
                
            } else if (numberOfShares > 0 && allShares != nil) {
                
                if (numberOfSharesByLink > 0 && sharesByLink !=nil && isShareAPIActive) {
                    fileCell.fileImageView.image=[UIImage imageNamed:@"folder-public.png"];
                } else if ((numberOfSharesByRemote > 0 && sharesByRemote != nil && !isShareAPIActive) || isShareAPIActive) {
                    fileCell.fileImageView.image=[UIImage imageNamed:@"folder-shared.png"];
                } else {
                    fileCell.fileImageView.image=[UIImage imageNamed:@"folder_icon.png"];
                }
            } else {
                fileCell.fileImageView.image=[UIImage imageNamed:@"folder_icon.png"];
            }

#ifdef CONTAINER_APP
        BOOL isFolderPendingToBeDownload = [[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded isFolderPendingToBeDownload:fileForSetTheStatusIcon];

        if (fileForSetTheStatusIcon.isFavorite || isCurrentFolderSonOfFavoriteFolder) {
            fileCell.imageAvailableOffline.image=[UIImage imageNamed:@"file_available_offline_icon"];
        } else {
            fileCell.imageAvailableOffline.image= nil;
        }

        if (isFolderPendingToBeDownload) {
            fileCell.imageDownloaded.image=[UIImage imageNamed:@"file_synchronizing_icon"];
        } else {
            fileCell.imageDownloaded.image= nil;
        }
#else
        fileCell.imageDownloaded.image= nil;
#endif   
        
    } else {
        
        fileCell.fileImageView.associatedObject = fileForSetTheStatusIcon.localFolder;
    
        
        fileCell.fileImageView.image = [self getIconOfFile:fileForSetTheStatusIcon andUser:user];
        

        if (fileForSetTheStatusIcon.isFavorite || isCurrentFolderSonOfFavoriteFolder) {
            fileCell.imageAvailableOffline.image=[UIImage imageNamed:@"file_available_offline_icon"];
        } else {
            fileCell.imageAvailableOffline.image= nil;
        }
        
        if(fileForSetTheStatusIcon.isNecessaryUpdate || fileForSetTheStatusIcon.isDownload == updating) {
            //File is in updating
            fileCell.imageDownloaded.image=[UIImage imageNamed:@"file_new_server_version_available_icon"];
        } else if (fileForSetTheStatusIcon.isDownload == downloaded) {
            //File is in device
            fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileDownloadedIcon"];
        } else if (fileForSetTheStatusIcon.isDownload == overwriting || fileForSetTheStatusIcon.isDownload == downloading || (fileForSetTheStatusIcon.isDownload == notDownload && (fileForSetTheStatusIcon.isFavorite || isCurrentFolderSonOfFavoriteFolder))) {
            //File is overwritten, downloading or pending to download in available offline folder
            fileCell.imageDownloaded.image=[UIImage imageNamed:@"file_synchronizing_icon"];
        } else {
            fileCell.imageDownloaded.image= nil;
        }
        
    }
    
    if (numberOfShares > 0 && allShares !=nil) {
        if (numberOfSharesByLink > 0 && sharesByLink !=nil && isShareAPIActive) {
            fileCell.sharedByLinkImage.image=[UIImage imageNamed:@"fileSharedByLink.png"];
        } else if((numberOfSharesByRemote > 0 && sharesByRemote != nil && !isShareAPIActive) || isShareAPIActive){
            fileCell.sharedByLinkImage.image=[UIImage imageNamed:@"fileSharedWithUs.png"];
        }
        else {
            fileCell.sharedByLinkImage.image= nil;
        }
        
    } else {
        fileCell.sharedByLinkImage.image= nil;
    }
    
    
    if ([fileForSetTheStatusIcon.permissions rangeOfString:k_permission_shared].location != NSNotFound){
        fileCell.sharedWithUsImage.image=[UIImage imageNamed:@"fileSharedWithUs.png"];
    } else {
        fileCell.sharedWithUsImage.image= nil;
    }
    
    return fileCell;
}


+(void)createAllFoldersInFileSystemByFileDto:(FileDto *)file andUserDto:(UserDto *)user {
    
    NSMutableArray *listOfRemoteFilesAndFolders = [ManageFilesDB getFilesByFileIdForActiveUser:file.idFile];
    
    NSString *path = [UtilsUrls getLocalFolderByFilePath:file.filePath andFileName:file.fileName andUserDto:user];
    
    [FileListDBOperations createAllFoldersByArrayOfFilesDto:listOfRemoteFilesAndFolders andLocalFolder:path];
}

/*
 *  Method to set the icon or the thumbnail when we create the cell
 */
+ (UIImage *) getIconOfFile:(FileDto *) file andUser:(UserDto *) user {
    
    UIImage *imageForCell;
    
    if ([[ManageThumbnails sharedManager] isStoredThumbnailForFile:file]) {
        
        imageForCell = [UIImage imageWithContentsOfFile:[[ManageThumbnails sharedManager] getThumbnailPathForFile:file]];
        
    } else {
        NSString *imageFile = [FileNameUtils getTheNameOfTheImagePreviewOfFileName:[file.fileName stringByRemovingPercentEncoding]];
        imageForCell = [UIImage imageNamed:imageFile];
    }
    
    return imageForCell;
}

/*
 *  Method update the thumbnail of an icon after read it
 */
+ (NSURLSessionTask *) updateThumbnail:(FileDto *) file andUser:(UserDto *) user tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSURLSessionTask *thumbnailSessionTask;
    
    if (![[ManageThumbnails sharedManager] isStoredThumbnailForFile:file]) {
        
        if ([FileNameUtils isRemoteThumbnailSupportThiFile:file.fileName]) {
            OCCommunication *sharedCommunication;
            
#ifdef CONTAINER_APP
            sharedCommunication = [AppDelegate sharedOCCommunication];
#elif SHARE_IN
            sharedCommunication = Managers.sharedOCCommunication;
#else
            sharedCommunication = [DocumentPickerViewController sharedOCCommunication];
#endif
            
            //Set the right credentials
            if (k_is_sso_active) {
                [sharedCommunication setCredentialsWithCookie:user.password];
            } else if (k_is_oauth_active) {
                [sharedCommunication setCredentialsOauthWithToken:user.password];
            } else {
                [sharedCommunication setCredentialsWithUser:user.username andPassword:user.password];
            }
            
            [sharedCommunication setUserAgent:[UtilsUrls getUserAgent]];
            
            NSString *path = [UtilsUrls getFilePathOnDBWithFileName:file.fileName ByFilePathOnFileDto:file.filePath andUser:user];
            path = [path stringByRemovingPercentEncoding];
            
            thumbnailSessionTask = [sharedCommunication getRemoteThumbnailByServer:user.url ofFilePath:path withWidth:k_thumbnails_width andHeight:k_thumbnails_height onCommunication:sharedCommunication successRequest:^(NSHTTPURLResponse *response, NSData *thumbnail, NSString *redirectedServer) {
                
                UIImage *thumbnailImage = [UIImage imageWithData:thumbnail];
                
                if (thumbnailImage && [[ManageThumbnails sharedManager] storeThumbnail:UIImagePNGRepresentation(thumbnailImage) forFile:file]) {
                    
                    thumbnailImage = [UIImage imageWithContentsOfFile:[[ManageThumbnails sharedManager] getThumbnailPathForFile:file]];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CustomCellFileAndDirectory *updateCell = (id)[tableView cellForRowAtIndexPath:indexPath];
                        
                        updateCell.fileImageView.image = thumbnailImage;
                        [updateCell.fileImageView.layer setMasksToBounds:YES];
                        [updateCell.fileImageView setNeedsLayout];
                    });
                }
                
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                DLog(@"Error: %@",error);
            }];
            

            
        } else if (file.isDownload == downloaded && [FileNameUtils isImageSupportedThisFile:file.fileName]){
            
            UIImage *thumbnailImage;
            thumbnailImage = [[UIImage imageWithContentsOfFile: file.localFolder] getThumbnailFromDownloadedImage];
            [[ManageThumbnails sharedManager] storeThumbnail:UIImagePNGRepresentation(thumbnailImage) forFile:file];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                CustomCellFileAndDirectory *updateCell = (id)[tableView cellForRowAtIndexPath:indexPath];
                
                updateCell.fileImageView.image = thumbnailImage;
                [updateCell.fileImageView.layer setMasksToBounds:YES];
                [updateCell.fileImageView setNeedsLayout];
            });
        }
     }
    
    return thumbnailSessionTask;
}


+ (NSString *) getFileIdFromOcId:(NSString *)ocId {

    NSString *fileIdString = [ocId substringToIndex:8];
    
    return [NSString stringWithFormat:@"%d", [fileIdString intValue]];
    
}

@end
