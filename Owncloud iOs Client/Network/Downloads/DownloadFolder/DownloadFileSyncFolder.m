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
#import "FilesViewController.h"

#define k_task_identifier_invalid -1

@implementation DownloadFileSyncFolder


- (void) addFileToDownload:(FileDto *) file {
    
    self.file = file;
    
    if (!self.file.isNecessaryUpdate && (self.file.isDownload != overwriting)) {
        //Change file status in Data Base to downloading
        [ManageFilesDB setFileIsDownloadState:self.file.idFile andState:downloading];
    } else if (self.file.isNecessaryUpdate) {
        //Change file status in Data Base to updating
        [ManageFilesDB setFileIsDownloadState:self.file.idFile andState:updating];
    }
    
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
    
    [[AppDelegate sharedOCCommunicationDownloadFolder] setUserAgent:[UtilsUrls getUserAgent]];
    
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
        self.operation = [[AppDelegate sharedOCCommunicationDownloadFolder] downloadFile:serverUrl toDestiny:localPath withLIFOSystem:NO onCommunication:[AppDelegate sharedOCCommunication]
                                                      progressDownload:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                                                          
                                                      } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                                                          
                                                          DLog(@"file: %@", file.localFolder);
                                                          DLog(@"File downloaded");
                                                          
                                                           if (k_is_sso_active && redirectedServer) {
                                                               [weakSelf failureDownloadProcess];
                                                           } else {
                                                               //Finalized the download
                                                               if ([[NSFileManager defaultManager] fileExistsAtPath:self.file.localFolder]) {
                                                                   [weakSelf updateDataDownloadSuccess];
                                                               } else {
                                                                   [weakSelf failureDownloadProcess];
                                                               }
                                                           }
                                                          
                                                      } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
                                                          DLog(@"Error: %@", error);
                                                          DLog(@"error.code: %ld", (long)error.code);
                                                          [weakSelf failureDownloadProcess];
                                                          
                                                      } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
                                                          //Cancel download
                                                          [weakSelf cancelDownload];
                                                      }];
        
    } else {
        self.downloadTask = [[AppDelegate sharedOCCommunicationDownloadFolder] downloadFileSession:serverUrl  toDestiny:localPath defaultPriority:NO onCommunication:[AppDelegate sharedOCCommunicationDownloadFolder] withProgress:nil successRequest:^(NSURLResponse *response, NSURL *filePath) {
            
            DLog(@"file: %@", file.localFolder);
            DLog(@"File downloaded");
            
            //Finalized the download
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.file.localFolder]) {
                [weakSelf updateDataDownloadSuccess];
            } else {
                [weakSelf failureDownloadProcess];
            }
            
        } failureRequest:^(NSURLResponse *response, NSError *error) {
            
            DLog(@"Error: %@", error);
            DLog(@"error.code: %ld", (long)error.code);
            
            if (error.code != kCFURLErrorCancelled) {
                [weakSelf failureDownloadProcess];
            }
        }];
        
        [self.downloadTask resume];
        [ManageFilesDB updateFile:file.idFile withTaskIdentifier:self.downloadTask.taskIdentifier];
    }
}

#pragma mark - Success/Failure/Cancel

- (void) updateDataDownloadSuccess {
    
    if (self.file.isNecessaryUpdate) {
        [DownloadUtils updateFile:self.file withTemporalFile:self.tmpUpdatePath];
    }
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Update the datas of the new file
    self.file = [ManageFilesDB getFileDtoByFileName:self.file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.file.filePath andUser:app.activeUser] andUser:app.activeUser];
    
    //Set file status like downloaded in Data Base
    [ManageFilesDB setFileIsDownloadState:self.file.idFile andState:downloaded];
    
    [ManageFilesDB updateEtagOfFileDtoByid:self.file.idFile andNewEtag:self.currentFileEtag];
    [ManageFilesDB updateFile:self.file.idFile withTaskIdentifier:k_task_identifier_invalid];
    [[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded removeFileFromTheForest:self.file];
    
    [self reloadCellFromDataBase];
    [[AppDelegate sharedSyncFolderManager].listOfFilesToBeDownloaded removeObjectIdenticalTo:self];
}

- (void) failureDownloadProcess {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (!self.user) {
        self.user = app.activeUser;
    }
    
    self.file = [ManageFilesDB getFileDtoByFileName:self.file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.file.filePath andUser:self.user] andUser:self.user];
    
    [ManageFilesDB updateFile:self.file.idFile withTaskIdentifier:k_task_identifier_invalid];
    [[AppDelegate sharedSyncFolderManager].forestOfFilesAndFoldersToBeDownloaded removeFileFromTheForest:self.file];
    
    if (self.file.isDownload == downloading) {
        [ManageFilesDB setFileIsDownloadState:self.file.idFile andState:notDownload];
    } else if (self.file.isDownload == updating) {
        [ManageFilesDB setFileIsDownloadState:self.file.idFile andState:downloaded];
    }
    
    //For sons of favorites to force again to be checked and downloaded again
    if ([DownloadUtils isSonOfFavoriteFolder:self.file]) {
        [DownloadUtils setEtagNegativeToAllTheFoldersThatContainsFile:self.file];
    }
    
    [self reloadCellFromDataBase];
    [[AppDelegate sharedSyncFolderManager].listOfFilesToBeDownloaded removeObjectIdenticalTo:self];
}

- (void) cancelDownload {
    
    if (self.operation) {
        [self.operation cancel];
    }
    
    if (self.downloadTask) {
        [self.downloadTask cancel];
    }
    
    [self failureDownloadProcess];
}

- (void)reloadCellFromDataBase{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [app reloadCellByFile:self.file];
}

@end
