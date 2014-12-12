 //
//  DPDownload.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/12/14.
//
//

#import "DPDownload.h"
#import "FFCircularProgressView.h"
#import "OCCommunication.h"
#import "DocumentPickerViewController.h"
#import "Customization.h"
#import "ManageFilesDB.h"
#import "OCErrorMsg.h"

@implementation DPDownload

- (id) init{
    
    self = [super init];
    if (self) {
        _isLIFO = YES;
    }
    return self;
}

- (void) downloadFile:(FileDto *)file withProgressView:(FFCircularProgressView *)progressView{
    
    OCCommunication *sharedCommunication = [DocumentPickerViewController sharedOCCommunication];
    self.file = file;
    NSArray *splitedUrl = [self.user.url componentsSeparatedByString:@"/"];
    NSString *serverUrl = [NSString stringWithFormat:@"%@%@%@",[NSString stringWithFormat:@"%@/%@/%@",[splitedUrl objectAtIndex:0],[splitedUrl objectAtIndex:1],[splitedUrl objectAtIndex:2]], file.filePath, file.fileName];
    
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    __block NSString *localPath = nil;
    
    if (file.isNecessaryUpdate) {
        //Change the local name for a temporal one
        self.temporalFileName = [NSString stringWithFormat:@"%@-%@", [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]], [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        localPath = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, self.temporalFileName];
    } else {
        localPath = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    self.deviceLocalPath = localPath;
    
    if (!file.isNecessaryUpdate && (file.isDownload != overwriting)) {
        //Change file status in Data Base to downloading
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:downloading];
    } else if (file.isNecessaryUpdate) {
        //Change file status in Data Base to updating
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:updating];
    }
    
    //Set the right credentials
    if (k_is_sso_active) {
        [sharedCommunication setCredentialsWithCookie:self.user.password];
    } else if (k_is_oauth_active) {
        [sharedCommunication setCredentialsOauthWithToken:self.user.password];
    } else {
        [sharedCommunication setCredentialsWithUser:self.user.username andPassword:self.user.password];
    }
    
    [progressView startSpinProgressBackgroundLayer];
    
    self.operation = [sharedCommunication downloadFile:serverUrl toDestiny:localPath withLIFOSystem:self.isLIFO onCommunication:sharedCommunication progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        [progressView stopSpinProgressBackgroundLayer];
        float percent = (float)totalBytesRead / totalBytesExpectedToRead;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView setProgress:percent];
        });
        
        
    } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        [progressView stopSpinProgressBackgroundLayer];
        [ManageFilesDB setFileIsDownloadState:file.idFile andState:downloaded];
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [progressView setHidden:YES];
            [self.delegate downloadCompleted:file];
        });
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        [progressView stopSpinProgressBackgroundLayer];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressView setProgress:0.0];
        });
        
        self.file = [ManageFilesDB getFileDtoByIdFile:self.file.idFile];
        //Set not download or downloaded in database if the file is not on an overwritten process
        if (self.file.isDownload != overwriting) {
            if (self.file.isNecessaryUpdate) {
                [ManageFilesDB setFileIsDownloadState:self.file.idFile andState:downloaded];
            } else {
                [ManageFilesDB setFileIsDownloadState:self.file.idFile andState:notDownload];
            }
        }
        
        if ([error code] == NSURLErrorCancelled) {
            [self.delegate downloadCancelled:self.file];
        }else{
            
            switch (response.statusCode) {
                case kOCErrorServerUnauthorized:
                    [self.delegate downloadFailed:NSLocalizedString(@"error_login_message", nil) andFile:self.file];
            
                    break;
                case kOCErrorServerForbidden:
                    [self.delegate downloadFailed:NSLocalizedString(@"not_establishing_connection", nil) andFile:self.file];
                    break;
                case kOCErrorProxyAuth:
                    [self.delegate downloadFailed:NSLocalizedString(@"not_establishing_connection", nil) andFile:self.file];
                    break;
                case kOCErrorServerPathNotFound:
                    [self.delegate downloadFailed:NSLocalizedString(@"download_file_exist", nil) andFile:self.file];
                    break;
                default:
                    [self.delegate downloadFailed:NSLocalizedString(@"not_possible_connect_to_server", nil) andFile:self.file];
                    break;
            }
        }
        
        //Erase cache and cookies
        [self eraseURLCache];
        
   
        
    } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
       [self.delegate downloadFailed:@"" andFile:file];
    }];

}

- (void) cancelDownload{
    
    [self.operation cancel];
}

#pragma mark File Manager

///-----------------------------------
/// @name Delete File From Local Folder
///-----------------------------------

/**
 * Method that delete a file from local folder.
 * It's called when the download fails or the user cancel an updating process
 */
- (void) deleteFileFromLocalFolder{
    //Delete file
    NSString *fileToDelete;
    if (self.file.isNecessaryUpdate) {
        fileToDelete = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, self.temporalFileName];
    } else {
        fileToDelete = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, self.file.fileName];
    }
    NSError *error;
    if([[NSFileManager defaultManager] removeItemAtPath:fileToDelete error:&error]) {
        DLog(@"All ok");
    } else {
        DLog(@"Error: %@",[error localizedDescription]);
    }
}

///-----------------------------------
/// @name Update a file with the temporal one
///-----------------------------------

/**
 * This method updates a file because there is a new version in the server
 *
 * @param file > (FileDto) the file to be updated
 * @param temporalFile > (NSString) the path of the temporal file
 */
- (void) updateFile:(FileDto *)file withTemporalFile:(NSString *)temporalFile {
    
    //If the file has been updated
    DLog(@"Temporal local path: %@", temporalFile);
    DLog(@"Old local path: %@", file.localFolder);
    
    //Delete the old file
   // DeleteFile *mDeleteFile = [[DeleteFile alloc] init];
  //  [mDeleteFile deleteItemFromDeviceByFileDto:file];
    
    //Change the name of the new updated file
    NSFileManager *filecopy=nil;
    filecopy =[NSFileManager defaultManager];
    NSError *error;
    if(![filecopy moveItemAtPath:temporalFile toPath:file.localFolder error:&error]){
        DLog(@"Error: %@",[error localizedDescription]);
    }
    else{
        DLog(@"All ok");
    }
}

- (void)eraseURLCache
{
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
}

@end
