 //
//  InfoFileUtils.m
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 06/03/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
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
    NSPredicate *predicateShareByLink = [NSPredicate predicateWithFormat:@"shareType == %i", shareTypeLink];
    NSArray *sharesByLink = [allShares filteredArrayUsingPredicate:predicateShareByLink];
    NSPredicate *predicateRemoteShare = [NSPredicate predicateWithFormat:@"shareType == %i", shareTypeRemote];
    NSArray *sharesByRemote = [allShares filteredArrayUsingPredicate:predicateRemoteShare];
    
    BOOL isShareAPIActive = [ManageUsersDB getActiveUser].hasCapabilitiesSupport && [ManageUsersDB getActiveUser].capabilitiesDto && [ManageUsersDB getActiveUser].capabilitiesDto.isFilesSharingAPIEnabled;
    
    
    if (fileForSetTheStatusIcon.isDirectory) {
        
            if ([fileForSetTheStatusIcon.permissions rangeOfString:k_permission_shared].location != NSNotFound) {
                fileCell.fileImageView.image=[UIImage imageNamed:@"folder-shared.png"];
                
            } else if (allShares.count > 0 && allShares !=nil) {
                
                if (sharesByLink.count > 0 && sharesByLink !=nil && isShareAPIActive) {
                    fileCell.fileImageView.image=[UIImage imageNamed:@"folder-public.png"];
                } else if((sharesByRemote.count > 0 && sharesByRemote != nil && !isShareAPIActive) || isShareAPIActive){
                    fileCell.fileImageView.image=[UIImage imageNamed:@"folder-shared.png"];
                } else{
                    fileCell.fileImageView.image=[UIImage imageNamed:@"folder_icon.png"];
                }
            } else {
                fileCell.fileImageView.image=[UIImage imageNamed:@"folder_icon.png"];
            }

#ifdef CONTAINER_APP
        if (fileForSetTheStatusIcon.isFavorite || isCurrentFolderSonOfFavoriteFolder) {
            if([[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded isFolderPendingToBeDownload:fileForSetTheStatusIcon] || [fileForSetTheStatusIcon.etag isEqualToString:k_negative_etag] || fileForSetTheStatusIcon.isNecessaryUpdate) {
                fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileFavoriteUpdatingIcon"];
            } else {
                fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileFavoriteIcon"];
            }
        } else if ([[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded isFolderPendingToBeDownload:fileForSetTheStatusIcon]) {
            fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileDownloadingIcon.png"];
        } else {
            fileCell.imageDownloaded.image=[UIImage imageNamed:@""];
        }
#else
        fileCell.imageDownloaded.image=[UIImage imageNamed:@""];
#endif   
        
    } else {
        
        fileCell.fileImageView.associatedObject = fileForSetTheStatusIcon.localFolder;
    
        
        fileCell.fileImageView.image = [self getIconOfFile:fileForSetTheStatusIcon andUser:user];
        

        if (fileForSetTheStatusIcon.isFavorite || isCurrentFolderSonOfFavoriteFolder) {
            if(fileForSetTheStatusIcon.isDownload == downloaded && !fileForSetTheStatusIcon.isNecessaryUpdate) {
                fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileFavoriteIcon"];
            } else {
                fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileFavoriteUpdatingIcon"];
            }
        } else if (!fileForSetTheStatusIcon.isFavorite) {
            if(fileForSetTheStatusIcon.isNecessaryUpdate || fileForSetTheStatusIcon.isDownload == updating) {
                //File is in updating
                fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileUpdatedIcon"];
            } else if (fileForSetTheStatusIcon.isDownload == downloaded) {
                //File is in device
                fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileDownloadedIcon"];
            } else if (fileForSetTheStatusIcon.isDownload == overwriting) {
                //File is overwritten
                fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileOverwritingIcon"];
            } else if (fileForSetTheStatusIcon.isDownload == downloading) {
                fileCell.imageDownloaded.image=[UIImage imageNamed:@"FileDownloadingIcon"];
            } else {
                fileCell.imageDownloaded.image=[UIImage imageNamed:@""];
            }
        }
    }
    
    if (allShares.count > 0 && allShares !=nil) {
        if (sharesByLink.count > 0 && sharesByLink !=nil && isShareAPIActive) {
            fileCell.sharedByLinkImage.image=[UIImage imageNamed:@"fileSharedByLink.png"];
        } else if((sharesByRemote.count > 0 && sharesByRemote != nil && !isShareAPIActive) || isShareAPIActive){
            fileCell.sharedByLinkImage.image=[UIImage imageNamed:@"fileSharedWithUs.png"];
        }
        else {
            fileCell.sharedByLinkImage.image=[UIImage imageNamed:@""];
        }
        
    } else {
        fileCell.sharedByLinkImage.image=[UIImage imageNamed:@""];
    }
    
    
    if ([fileForSetTheStatusIcon.permissions rangeOfString:k_permission_shared].location != NSNotFound){
        fileCell.sharedWithUsImage.image=[UIImage imageNamed:@"fileSharedWithUs.png"];
    } else {
        fileCell.sharedWithUsImage.image=[UIImage imageNamed:@""];
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
    
    UIImage *output;
    
    if ([[ManageThumbnails sharedManager] isStoredThumbnailWithHash:[file getHashIdentifierOfUserID:user.idUser]]) {
        
        output = [UIImage imageWithContentsOfFile:[[ManageThumbnails sharedManager] getThumbnailPathForFileHash:[file getHashIdentifierOfUserID: user.idUser]]];
            
    } else {
        NSString *imageFile = [FileNameUtils getTheNameOfTheImagePreviewOfFileName:[file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        output = [UIImage imageNamed:imageFile];
    }
    
    return output;
}

/*
 *  Method update the thumbnail of an icon after read it
 */
+ (void) updateThumbnail:(FileDto *) file andUser:(UserDto *) user andImage:(UIImageView *) imageViewToBeUpdated {
    
    if (file.isDownload == downloaded && [FileNameUtils isImageSupportedThisFile:file.fileName]) {
        
            UIImage *thumbnail;
            
            if ([[ManageThumbnails sharedManager] isStoredThumbnailWithHash:[file getHashIdentifierOfUserID: user.idUser]]){
                
                thumbnail = [UIImage imageWithContentsOfFile:[[ManageThumbnails sharedManager] getThumbnailPathForFileHash:[file getHashIdentifierOfUserID: user.idUser]]];
                
            }else{
                
                thumbnail = [[UIImage imageWithContentsOfFile: file.localFolder] getThumbnail];
                [[ManageThumbnails sharedManager] storeThumbnail:UIImagePNGRepresentation(thumbnail) withHash:[file getHashIdentifierOfUserID:user.idUser]];
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                imageViewToBeUpdated.image = thumbnail;
                [imageViewToBeUpdated.layer setMasksToBounds:YES];
                [imageViewToBeUpdated setNeedsLayout];
            });
    }
}

@end
