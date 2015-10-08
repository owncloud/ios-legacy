//
//  DownloadFileSyncFolder.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 07/10/15.
//
//

#import "DownloadFileSyncFolder.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "ManageFilesDB.h"
#import "Customization.h"
#import "UtilsUrls.h"
#import "DownloadUtils.h"
#import "SyncFolderManager.h"
#import "IndexedForest.h"

#define k_task_identifier_invalid -1

@implementation DownloadFileSyncFolder


- (void) addFileToDownload:(FileDto *) file {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSString *serverUrl = [UtilsUrls getFullRemoteServerFilePathByFile:file andUser:app.activeUser];
    serverUrl = [serverUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunicationDownloadFolder] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunicationDownloadFolder] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunicationDownloadFolder] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    DLog(@"serverUrl: %@", serverUrl);
    
    //get local path of server
    __block NSString *localPath = file.localFolder;
    
    if (file.isNecessaryUpdate) {
        //Change the local name for a temporal one
        NSString *tmpUpdateFileName = [NSString stringWithFormat:@"%@-%@", [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]], [file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        localPath = [localPath substringToIndex:[localPath length] - file.fileName.length];
        localPath = [localPath stringByAppendingString: tmpUpdateFileName];
        
        self.tmpUpdatePath = localPath;
    }
    
    __weak typeof(self) weakSelf = self;
    
    if (k_is_sso_active || !k_is_background_active) {
        
        //Create the block of NSOperation to download.
        self.operation = [[AppDelegate sharedOCCommunication] downloadFile:serverUrl toDestiny:localPath withLIFOSystem:NO onCommunication:[AppDelegate sharedOCCommunication]
                                                      progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                                                          
                                                      } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                                                          
                                                          DLog(@"file: %@", file.localFolder);
                                                          DLog(@"File downloaded");
                                                          
                                                          //Finalized the download
                                                          [weakSelf updateDataDownload:file];
                                                          [[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded removeFileFromTheForest:file];
                                                          
                                                      } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
                                                          DLog(@"Error: %@", error);
                                                          DLog(@"error.code: %ld", (long)error.code);
                                                          
                                                      } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
                                                          //Cancel download
                                                          [weakSelf cancelDownload];
                                                      }];
        
    } else {
        self.downloadTask = [[AppDelegate sharedOCCommunicationDownloadFolder] downloadFileSession:serverUrl  toDestiny:localPath defaultPriority:NO onCommunication:[AppDelegate sharedOCCommunicationDownloadFolder] withProgress:nil successRequest:^(NSURLResponse *response, NSURL *filePath) {
            
            DLog(@"file: %@", file.localFolder);
            DLog(@"File downloaded");
            
            //Finalized the download
            [weakSelf updateDataDownload:file];
            [ManageFilesDB updateFile:file.idFile withTaskIdentifier:k_task_identifier_invalid];
            [[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded removeFileFromTheForest:file];
            
        } failureRequest:^(NSURLResponse *response, NSError *error) {
            
            DLog(@"Error: %@", error);
            DLog(@"error.code: %ld", (long)error.code);
            [ManageFilesDB updateFile:file.idFile withTaskIdentifier:k_task_identifier_invalid];
            
        }];
        
        [self.downloadTask resume];
        [ManageFilesDB updateFile:file.idFile withTaskIdentifier:self.downloadTask.taskIdentifier];
    }
}

- (void) updateDataDownload:(FileDto *) file {
    
    if (file.isNecessaryUpdate) {
        [DownloadUtils updateFile:file withTemporalFile:self.tmpUpdatePath];
    }
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Update the datas of the new file
    file = [ManageFilesDB getFileDtoByFileName:file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    //Set file status like downloaded in Data Base
    [ManageFilesDB setFileIsDownloadState:file.idFile andState:downloaded];
    
    [ManageFilesDB updateEtagOfFileDtoByid:file.idFile andNewEtag:self.currentFileEtag];
}

- (void) cancelDownload {
    
    if (self.operation) {
        [self.operation cancel];
    }
    
    if (self.downloadTask) {
        [self.downloadTask cancel];
    }
}

@end
