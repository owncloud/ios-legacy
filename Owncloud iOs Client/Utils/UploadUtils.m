//
//  UploadUtils.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 04/07/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UploadUtils.h"
#import "Customization.h"
#import "AppDelegate.h"
#import "ManageFilesDB.h"
#import "DeleteFile.h"
#import "FilePreviewViewController.h"
#import "constants.h"
#import "UtilsDtos.h"
#import "UploadsOfflineDto.h"
#import "ManageFilesDB.h"
#import "ManageUsersDB.h"
#import "UtilsUrls.h"

NSString * PreviewFileNotification=@"PreviewFileNotification";

@implementation UploadUtils

/*
 * Method tha make the lengt of the file
 */
+ (NSString *)makeLengthString:(long)estimateLength{
    //Lengh
    float lengh=estimateLength;
    lengh=lengh/1024; //KB
    
    NSString *lenghString;
    
    if (lengh>=1000) {
        //MB
        lengh=lengh/1024;
        lenghString=[NSString stringWithFormat:@"%.1f MB",lengh];
    }else {
        //KB
        lenghString=[NSString stringWithFormat:@"%.1f KB",lengh];
    }
    
    NSString *temp =[NSString stringWithFormat:@"%@", lenghString];
    
    return temp;
}


/*
 *Method that updates a downloaded file when the user overwrites this file
 */
+(void) updateOverwritenFile:(FileDto *)file FromPath:(NSString *)path{
    
    //Delete the file in the device
    DeleteFile *mDeleteFile = [[DeleteFile alloc] init];
    [mDeleteFile deleteItemFromDeviceByFileDto:file];
    
    //Update the file
    DLog(@"oldPath: %@",path);
    DLog(@"newPath: %@",file.localFolder);
    NSFileManager *filecopy=nil;
    filecopy =[NSFileManager defaultManager];
    NSError *error;
    
    if(![filecopy copyItemAtPath:path toPath:file.localFolder error:&error]){
        DLog(@"Error: %@",[error localizedDescription]);
    }
    else{
        DLog(@"All ok");
    }
    //Maintain the state as overwriting
    [ManageFilesDB setFileIsDownloadState:file.idFile andState:overwriting];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //Obtain the remotePath: https://s3.owncloud.com/owncloud/remote.php/webdav
    NSString *remoteFolder = [UtilsUrls getFullRemoteServerPathWithWebDav:app.activeUser];
    //With the filePath obtain the folder name: A/
    NSString *folderName= [UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:app.activeUser];
    //Obtain the complete path: https://s3.owncloud.com/owncloud/remote.php/webdav/A/
    remoteFolder=[NSString stringWithFormat:@"%@%@",remoteFolder, folderName];
    DLog(@"remote folder: %@",remoteFolder);
    
    //Post a notification to inform to the PreviewFileViewController class
    NSString *pathFile= [NSString stringWithFormat:@"%@%@", remoteFolder,file.fileName];
    [[NSNotificationCenter defaultCenter] postNotificationName:PreviewFileNotification object:pathFile];
}


//-----------------------------------
/// @name Get a fileDto by the UploadOffline
///-----------------------------------

/**
 * Method to get a fileDto from the DB with the information of a UploadOffline
 *
 * @param UploadsOfflineDto -> UploadsOfflineDto
 *
 * @return FileDto
 *
 *
 * @warning if the FileDto does not exist we will return a nil
 */
+ (FileDto *) getFileDtoByUploadOffline:(UploadsOfflineDto *) uploadsOfflineDto {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSString *partToRemoveOfPah = [UtilsUrls getFullRemoteServerPathWithWebDav:app.activeUser];
    
    NSString *filePath = [uploadsOfflineDto.destinyFolder substringFromIndex:partToRemoveOfPah.length];
    
    FileDto *output = [ManageFilesDB getFileDtoByFileName:uploadsOfflineDto.uploadFileName andFilePath:filePath andUser:app.activeUser];
    
    return output;
}


+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

@end



