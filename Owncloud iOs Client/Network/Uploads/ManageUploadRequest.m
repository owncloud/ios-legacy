//
//  ManageUploadRequest.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 11/11/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "ManageUploadRequest.h"
#import "AppDelegate.h"
#import "Customization.h"
#import "ManageUsersDB.h"
#import "ManageUploadsDB.h"
#import "ManageFilesDB.h"
#import "UtilsNetworkRequest.h"
#import "UtilsDtos.h"
#import "UtilsUrls.h"
#import "DetailViewController.h"
#import "FileNameUtils.h"
#import "UploadUtils.h"
#import "OCErrorMsg.h"
#import "OCCommunication.h"
#import "constants.h"
#import "UtilsDtos.h"
#import "OCURLSessionManager.h"
#import "ManageAppSettingsDB.h"
#import "UtilsCookies.h"

NSString *fileDeleteInAOverwriteProcess=@"fileDeleteInAOverwriteProcess";
NSString *uploadOverwriteFileNotification=@"uploadOverwriteFileNotification";


@implementation ManageUploadRequest

/*
 * Method that begin upload files
 */
- (void)addFileToUpload:(UploadsOfflineDto*) currentUpload {
    
    self.currentUpload = currentUpload;
    _transferProgress = 0.0;
    
    [self dismissTransferProgress:self];
    
    //Store the upload objet to appdelegate
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //If we have the same file on the recentView we remove the old upload
    NSArray *uploadArrayCopy = [NSArray arrayWithArray:appDelegate.uploadArray];
    
    [uploadArrayCopy enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ManageUploadRequest *currentArrayUpload = (ManageUploadRequest*)obj;
        if (currentArrayUpload.currentUpload.idUploadsOffline == _currentUpload.idUploadsOffline) {
            [appDelegate.uploadArray removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    
    [appDelegate.uploadArray addObject:self];
    
    [self updateRecentsTab];
    
    self.userUploading = [ManageUsersDB getUserByIdUser:_currentUpload.userId];
    
    [self checkIfExistOnserverAndBeginUpload];
}

-(void) checkIfExistOnserverAndBeginUpload {
    
    _userUploading = [ManageUsersDB getUserByIdUser:_currentUpload.userId];
    
    if (_currentUpload.isNotNecessaryCheckIfExist) {
        [self performSelectorInBackground:@selector(startUploadFile) withObject:nil];
    } else {
        _utilsNetworkRequest = [UtilsNetworkRequest new];
        _utilsNetworkRequest.delegate = self;
        
        NSString *serverUrl = [NSString stringWithFormat:@"%@%@",self.currentUpload.destinyFolder,self.currentUpload.uploadFileName];
        
        [_utilsNetworkRequest checkIfTheFileExistsWithThisPath:serverUrl andUser:_userUploading];
        
        //Upload ready, continue with next
        [ManageUploadsDB setStatus:waitingForUpload andKindOfError:notAnError byUploadOffline:self.currentUpload];
        _currentUpload.status=waitingForUpload;
        [_delegate uploadAddedContinueWithNext];
    }
}

//Get the file dto related with the upload ofline if exist
- (FileDto *) getFileDtoOfTheUploadOffline{
    
    NSString *folderName = [UtilsUrls getFilePathOnDBByFullPath:self.currentUpload.destinyFolder andUser:self.userUploading];
    FileDto *uploadFile = [ManageFilesDB getFileDtoByFileName:self.currentUpload.uploadFileName andFilePath:folderName andUser:self.userUploading];
    
    return uploadFile;
}

#pragma mark - UtilsNetworkRequestDelegate

-(void) theFileIsInThePathResponse:(NSInteger)response {
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    switch (response) {
        case isInThePath:
        {
            //Get the file of the Upload.
            FileDto *uploadFile = [self getFileDtoOfTheUploadOffline];
            
            if (uploadFile.isDownload == overwriting) {
                //Read the file of the server to check if the etag has changed
                [self checkTheEtagInTheServerOfTheFile:uploadFile];
            }else{
                [self changeTheStatusToErrorFileExist];
            }
        }
            break;
            
        case isNotInThePath:
        {
            NSString *folderInstantUpload = [self.currentUpload.destinyFolder lastPathComponent];
            
            if ([ManageAppSettingsDB isInstantUpload] && [folderInstantUpload isEqualToString:k_path_instant_upload]) {
                //create folder instant upload
                [self newFolder:_currentUpload.destinyFolder];
            } else {
                [self performSelectorInBackground:@selector(startUploadFile) withObject:nil];
            }
            
        }
            break;
            
        case errorSSL:
            [ManageUploadsDB setStatus:errorUploading andKindOfError:notAnError byUploadOffline:_currentUpload];
            break;
            
        case credentialsError:
        {
            _currentUpload.status = errorUploading;
            _currentUpload.kindOfError = errorCredentials;
            [ManageUploadsDB setStatus:_currentUpload.status andKindOfError:_currentUpload.kindOfError byUploadOffline:_currentUpload];
            [appDelegate cancelTheCurrentUploadsWithTheSameUserId:_currentUpload.userId];
            [appDelegate updateRecents];
        }
            break;
            
        case serverConnectionError:
            [ManageUploadsDB setStatus:errorUploading andKindOfError:notAnError byUploadOffline:_currentUpload];
            break;
            
        default:
            break;
    }
}

#pragma mark - Create folder on server

-(void) newFolder:(NSString*) pathRemoteFolder {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    
    [[AppDelegate sharedOCCommunication] createFolder:pathRemoteFolder onCommunication:[AppDelegate sharedOCCommunication] withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport]
     successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
         
        DLog(@"Folder created");
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
        }
        if (!isSamlCredentialsError) {
            
            //Upload ready, continue
            [self performSelectorInBackground:@selector(startUploadFile) withObject:nil];
            
        }
        
        
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        //Web Dav Error Code
        switch (response.statusCode) {
            case kOCErrorServerMethodNotPermitted:
                //405 Method not permitted "not_possible_create_folder"
                [self performSelectorInBackground:@selector(startUploadFile) withObject:nil];
                break;
            default:
                //"not_possible_connect_to_server"
                break;
        }
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
    } errorBeforeRequest:^(NSError *error) {
        if (error.code == OCErrorForbidenCharacters) {
            DLog(@"The folder have problematic characters");
        } else {
            DLog(@"The folder have problems under controlled");
        }
        
    }
     ];
    
}


- (void) startUploadFile {
    _isFromBackground = NO;
    
    DLog(@"self.currentUpload: %@", _currentUpload.uploadFileName);
    
    if (_currentUpload.isNotNecessaryCheckIfExist) {
        //Upload ready, continue with next
        [ManageUploadsDB setStatus:waitingForUpload andKindOfError:notAnError byUploadOffline:self.currentUpload];
        _currentUpload.status=waitingForUpload;
    }
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:_userUploading.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:_userUploading.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:_userUploading.username andPassword:_userUploading.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    NSString *urlClean = [NSString stringWithFormat:@"%@%@", _currentUpload.destinyFolder, _currentUpload.uploadFileName];
    urlClean = [urlClean stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    __block BOOL firstTime = YES;
    __weak typeof(self) weakSelf = self;
    
    if (k_is_sso_active || !k_is_background_active) {
        
        //Create the block of NSOperation to upload.
        _operation = [[AppDelegate sharedOCCommunication] uploadFile:_currentUpload.originPath toDestiny:urlClean onCommunication:[AppDelegate sharedOCCommunication] progressUpload:^(NSUInteger bytesWrote, long long totalBytesWrote, long long totalBytesExpectedToWrote) {
            
            DLog(@"Sent %lld of %lld bytes", totalBytesWrote, totalBytesExpectedToWrote);
            
            /*  DLog(@"----------------------------");
             DLog(@"bytesWrote: %d", bytesWrote);
             DLog(@"totalBytesWrote: %lld", totalBytesWrote);
             DLog(@"totalBytesExpectedToWrote: %lld", totalBytesExpectedToWrote);*/
            
            if(totalBytesExpectedToWrote/1024 != 0) {
                if (bytesWrote>0) {
                    float percent;
                    
                    percent=totalBytesWrote*100/totalBytesExpectedToWrote;
                    percent = percent / 100;
                    
                    DLog(@"percent: %f", percent);
                    
                    [weakSelf updateProgressWithPercent:percent];
                }
            }
            
            if (firstTime) {
                
                //Check if the first time the file is waiting for upload (the previous state of uploading)
                if (weakSelf.currentUpload.status == waitingForUpload) {
                    [ManageUploadsDB setStatus:uploading andKindOfError:notAnError byUploadOffline:weakSelf.currentUpload];
                    weakSelf.currentUpload.status=uploading;
                    [weakSelf updateRecentsTab];
                    firstTime=NO;
                }
            }
        } successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            
            DLog(@"File uploaded");
            DLog(@"self.currentUpload: %@", weakSelf.currentUpload.uploadFileName);
            DLog(@"setCompletionBlockWithSuccess");
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active && redirectedServer) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                if (isSamlCredentialsError) {
                    weakSelf.currentUpload.status = errorUploading;
                    weakSelf.currentUpload.kindOfError = errorCredentials;
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                    [appDelegate cancelTheCurrentUploadsWithTheSameUserId:weakSelf.currentUpload.userId];
                    [weakSelf updateRecentsTab];
                }
            }
            
            
            if (!isSamlCredentialsError) {
                
                [ManageUploadsDB setStatus:uploaded andKindOfError:notAnError byUploadOffline:weakSelf.currentUpload];
                
                DLog(@"Transfer complete, next file if exists");
                
                [weakSelf storeDateOfUpload];
                weakSelf.pathOfUpload = [UtilsUrls getPathWithAppNameByDestinyPath:weakSelf.currentUpload.destinyFolder andUser:weakSelf.userUploading];
                
                [ManageUploadsDB setDatebyUploadOffline:weakSelf.currentUpload];
                
                weakSelf.currentUpload.status = uploaded;
                
                [weakSelf updateRecentsTab];
                [weakSelf dismissTransferProgress:weakSelf];
                [weakSelf removeTheFileOnFileSystem];
                
                if(weakSelf.currentUpload.isLastUploadFileOfThisArray) {
                    DLog(@"self.currentUpload: %@", weakSelf.currentUpload.uploadFileName);
                    [weakSelf.delegate uploadCompleted:weakSelf.currentUpload.destinyFolder];
                }
                
                //The destinyfolder: https://s3.owncloud.com/owncloud/remote.php/webdav/A/
                //The folder Name: A/
                FileDto *uploadFile = [self getFileDtoOfTheUploadOffline];
                
                if (uploadFile.isDownload == overwriting) {
                    //Update the etag
                    [self updateTheEtagOfTheFile:uploadFile];
                }
                
                [_operation finalize];
                _operation = nil;
            }
            
        } failureRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer, NSError *error) {
            
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            
            DLog(@"response.statusCode: %ld", (long)response.statusCode);
            DLog(@"Error: %@", error);
            DLog(@"error.code: %ld", (long)error.code);
            
            BOOL isSamlCredentialsError = NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active && redirectedServer) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                if (isSamlCredentialsError) {
                    weakSelf.currentUpload.status = errorUploading;
                    weakSelf.currentUpload.kindOfError = errorCredentials;
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                    [appDelegate cancelTheCurrentUploadsWithTheSameUserId:weakSelf.currentUpload.userId];
                    [weakSelf updateRecentsTab];
                }
            }
            
            if (!isSamlCredentialsError) {
                
                if ([error code] != NSURLErrorCancelled) {
                    
                    if(appDelegate.isOverwriteProcess == YES){
                        [self finishOverwriteProcess];
                    }
                    
                    if (error.code == OCServerErrorForbiddenCharacters) {
                        weakSelf.currentUpload.status = errorUploading;
                        weakSelf.currentUpload.kindOfError = errorInvalidPath;
                        [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                        
                    }else{
                        
                        //We set the kindOfError in case that we have a credential or if the file where we want upload not exist
                        switch (response.statusCode) {
                            case kOCErrorServerUnauthorized:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = errorCredentials;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                [appDelegate cancelTheCurrentUploadsWithTheSameUserId:weakSelf.currentUpload.userId];
                                break;
                            case kOCErrorServerForbidden:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = errorNotPermission;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                break;
                            case kOCErrorProxyAuth:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = errorCredentials;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                [appDelegate cancelTheCurrentUploadsWithTheSameUserId:weakSelf.currentUpload.userId];
                                break;
                            case kOCErrorServerPathNotFound:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = errorDestinyNotExist;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                break;
                            default:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = notAnError;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                
                                appDelegate.userUploadWithError=weakSelf.userUploading;
                                break;
                        }
                        
                    }

                    [weakSelf updateRecentsTab];
                }
                
            }
            
        } failureBeforeRequest:^(NSError *error) {
            switch (error.code) {
                case OCErrorFileToUploadDoesNotExist: {
                    //TODO: create a state to control if the file does not exist
                    
                    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    
                    weakSelf.currentUpload.status = errorUploading;
                    weakSelf.currentUpload.kindOfError = errorUploadFileDoesNotExist;
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                    
                    appDelegate.userUploadWithError=weakSelf.userUploading;
                    break;
                }
                    
                    
                default: {
                    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    
                    weakSelf.currentUpload.status = errorUploading;
                    weakSelf.currentUpload.kindOfError = errorUploadFileDoesNotExist;
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                    
                    appDelegate.userUploadWithError=weakSelf.userUploading;
                    break;
                }
            }
            [weakSelf updateRecentsTab];
            
        } shouldExecuteAsBackgroundTaskWithExpirationHandler:^{
            
            
            AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            app.isExpirationTimeInUpload = YES;
            
            //Get the status
            /* weakSelf.currentUpload =  [ManageUploadsDB getUploadOfflineById:weakSelf.currentUpload.idUploadsOffline];
             
             DLog(@"current upload status: %d", weakSelf.currentUpload.status);
             //Check if the current Upload is not uploaded
             if ( weakSelf.currentUpload.status != uploaded) {
             weakSelf.currentUpload.status = errorUploading;
             weakSelf.currentUpload.kindOfError = notAnError;
             [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
             
             AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
             appDelegate.userUploadWithError=weakSelf.userUploading;
             }*/
        }];
        
    } else {
        
        NSProgress *progressValue;
        
        [[AppDelegate sharedOCCommunication].uploadSessionManager.operationQueue cancelAllOperations];
        
        
        _uploadTask = [[AppDelegate sharedOCCommunication] uploadFileSession:_currentUpload.originPath toDestiny:urlClean onCommunication:[AppDelegate sharedOCCommunication] withProgress:&progressValue successRequest:^(NSURLResponse *response, NSString *redirectedServer) {
            
            [self.progressValueGlobal removeObserver:self forKeyPath:@"fractionCompleted"];
            
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            
            DLog(@"File uploaded");
            
            DLog(@"self.currentUpload: %@", weakSelf.currentUpload.uploadFileName);
            
            DLog(@"setCompletionBlockWithSuccess");
            
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active && redirectedServer) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                if (isSamlCredentialsError) {
                    weakSelf.currentUpload.status = errorUploading;
                    weakSelf.currentUpload.kindOfError = errorCredentials;
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                    [appDelegate cancelTheCurrentUploadsWithTheSameUserId:weakSelf.currentUpload.userId];
                    [weakSelf updateRecentsTab];
                }
            }
            
            
            if (!isSamlCredentialsError) {
                
                [ManageUploadsDB setStatus:uploaded andKindOfError:notAnError byUploadOffline:weakSelf.currentUpload];
                
                DLog(@"Transfer complete, next file if exists");
                
                [weakSelf storeDateOfUpload];
                weakSelf.pathOfUpload = [UtilsUrls getPathWithAppNameByDestinyPath:weakSelf.currentUpload.destinyFolder andUser:weakSelf.userUploading];
                
                [ManageUploadsDB setDatebyUploadOffline:weakSelf.currentUpload];
                
                weakSelf.currentUpload.status = uploaded;
                
                [weakSelf updateRecentsTab];
                [weakSelf dismissTransferProgress:weakSelf];
                [weakSelf removeTheFileOnFileSystem];
                
                if(weakSelf.currentUpload.isLastUploadFileOfThisArray) {
                    DLog(@"self.currentUpload: %@", weakSelf.currentUpload.uploadFileName);
                    [weakSelf.delegate uploadCompleted:weakSelf.currentUpload.destinyFolder];
                }
                
                //The destinyfolder: https://s3.owncloud.com/owncloud/remote.php/webdav/A/
                //The folder Name: A/
                
                FileDto *uploadFile = [self getFileDtoOfTheUploadOffline];
                
                if (uploadFile.isDownload == overwriting) {
                    //Update the etag
                    [self updateTheEtagOfTheFile:uploadFile];
                }
                
                
            }
            
            
        } failureRequest:^(NSURLResponse *response, NSString *redirectedServer, NSError *error) {
            
            [self.progressValueGlobal removeObserver:self forKeyPath:@"fractionCompleted"];
            
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            
            AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            
            DLog(@"response.statusCode: %ld", (long)httpResponse.statusCode);
            DLog(@"Error: %@", error);
            DLog(@"error.code: %ld", (long)error.code);
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active && redirectedServer) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                if (isSamlCredentialsError) {
                    weakSelf.currentUpload.status = errorUploading;
                    weakSelf.currentUpload.kindOfError = errorCredentials;
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                    [appDelegate cancelTheCurrentUploadsWithTheSameUserId:weakSelf.currentUpload.userId];
                    [weakSelf updateRecentsTab];
                }
            }
            
            if (!isSamlCredentialsError) {
                
                if ([error code] != NSURLErrorCancelled) {
                    
                    if(appDelegate.isOverwriteProcess == YES){
                        [self finishOverwriteProcess];
                    }
                    
                    if (error.code == OCServerErrorForbiddenCharacters) {
                        weakSelf.currentUpload.status = errorUploading;
                        weakSelf.currentUpload.kindOfError = errorInvalidPath;
                        [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                        
                    }else{
                        //We set the kindOfError in case that we have a credential or if the file where we want upload not exist
                        switch (httpResponse.statusCode) {
                            case kOCErrorServerUnauthorized:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = errorCredentials;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                [appDelegate cancelTheCurrentUploadsWithTheSameUserId:weakSelf.currentUpload.userId];
                                break;
                            case kOCErrorServerForbidden:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = errorNotPermission;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                break;
                            case kOCErrorProxyAuth:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = errorCredentials;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                [appDelegate cancelTheCurrentUploadsWithTheSameUserId:weakSelf.currentUpload.userId];
                                break;
                            case kOCErrorServerPathNotFound:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = errorDestinyNotExist;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                break;
                            default:
                                weakSelf.currentUpload.status = errorUploading;
                                weakSelf.currentUpload.kindOfError = notAnError;
                                [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                                
                                appDelegate.userUploadWithError=weakSelf.userUploading;
                                break;
                        }

                    }
                    
                    [weakSelf updateRecentsTab];
                }
                
            }
        } failureBeforeRequest:^(NSError *error) {
            
            [self.progressValueGlobal removeObserver:self forKeyPath:@"fractionCompleted"];
            
            switch (error.code) {
                case OCErrorFileToUploadDoesNotExist: {
                    //TODO: create a state to control if the file does not exist
                    
                    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    
                    weakSelf.currentUpload.status = errorUploading;
                    weakSelf.currentUpload.kindOfError = errorUploadFileDoesNotExist;
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                    
                    appDelegate.userUploadWithError=weakSelf.userUploading;
                    break;
                }
                    
                    
                default: {
                    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                    
                    weakSelf.currentUpload.status = errorUploading;
                    weakSelf.currentUpload.kindOfError = errorUploadFileDoesNotExist;
                    [ManageUploadsDB setStatus:errorUploading andKindOfError:weakSelf.currentUpload.kindOfError byUploadOffline:weakSelf.currentUpload];
                    
                    appDelegate.userUploadWithError=weakSelf.userUploading;
                    break;
                }
            }
            [weakSelf updateRecentsTab];
            
        }];
        
        self.progressValueGlobal = progressValue;
        progressValue = nil;
        
        // Observe fractionCompleted using KVO
        [self.progressValueGlobal addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:NULL];
        
    }
    
    if (_isCanceled) {
        [_operation cancel];
    }
    
    if (_currentUpload.isNotNecessaryCheckIfExist) {
        [self.delegate uploadAddedContinueWithNext];
    }
    
    DLog(@"taskIdentifier: %lu", (unsigned long)_uploadTask.taskIdentifier);
    
    if (_uploadTask) {
        [self setTaskIdentifier];
    }
    
}

//Method to set the task identifier
- (void) setTaskIdentifier{
    
    [ManageUploadsDB setTaskIdentifier:_uploadTask.taskIdentifier forUploadOffline:_currentUpload];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"fractionCompleted"] && [object isKindOfClass:[NSProgress class]]) {
        NSProgress *progress = (NSProgress *)object;
        //DLog(@"Progress is %f", progress.fractionCompleted);
        
        float percent = roundf (progress.fractionCompleted * 100) / 100.0;
        
        DLog(@"Progress is %f", percent);
        
        //We make it on the main thread because we came from a delegate
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateProgressWithPercent:percent];
        });
        
        if (progress.fractionCompleted > 0.000000 && !_isUploadBegan) {
            _isUploadBegan = YES;
            //Check if the first time the file is waiting for upload (the previous state of uploading)
            if (self.currentUpload.status == waitingForUpload) {
                [ManageUploadsDB setStatus:uploading andKindOfError:notAnError byUploadOffline:self.currentUpload];
                self.currentUpload.status=uploading;
                [self updateRecentsTab];
            }
        }
    }
    
}

- (void)finishOverwriteProcess{
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    DLog(@"Overwriten process active: Cancel a file");
    NSString *localFolder=[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.currentUpload.destinyFolder andUser:self.userUploading];
    DLog(@"Local folder:%@",localFolder);
    
    FileDto *deleteOverwriteFile = [ManageFilesDB getFileDtoByFileName:self.currentUpload.uploadFileName andFilePath:localFolder andUser:self.userUploading];
    DLog(@"id file: %ld",(long)deleteOverwriteFile.idFile);
    
    //In iPad clean the view
    if (!IS_IPHONE){
        [app.detailViewController presentWhiteView];
        //Launch a notification for update the previewed file
        [[NSNotificationCenter defaultCenter] postNotificationName:fileDeleteInAOverwriteProcess object:self.currentUpload.destinyFolder];
    }
    
    [ManageFilesDB setFileIsDownloadState:deleteOverwriteFile.idFile andState:notDownload];
    
}

- (void) cancelUpload {
    DLog(@"CANCEL UPLOAD");
    _isCanceled = YES;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //The user cancel a file which had been chosen for be overwritten
    if(app.isOverwriteProcess == YES){
        [self finishOverwriteProcess];
    }
    
    [ManageUploadsDB deleteUploadOfflineByUploadOfflineDto:self.currentUpload];
    
    //Quit the upload from the uploadArray
    [app.uploadArray removeObjectIdenticalTo:self];
    
    //Quit the operation from the operation queue
    if (self.operation) {
        [[AppDelegate sharedOCCommunication].uploadOperationQueueArray removeObjectIdenticalTo:self.operation];
    }
    
    //Send this percent to remove the progressview of the array
    //[self updateProgressWithPercent:1.0];
    
    //Check if the operation exist (If possible that the upload stated in wainting state)
    if (self.operation == nil && self.uploadTask == nil) {
        //Check if the operation exist (If possible that the upload stated in wainting state)
        DLog(@"THE OPERATION DOES NOT EXIST!!!!");
        [self removeTheFileOnFileSystem];
        [_delegate uploadCanceled:self];
    } else {
        //Current upload
        if (self.operation) {
            [self.operation cancel];
            self.operation = nil;
        }
        
        if (self.uploadTask) {
            
            [self.uploadTask cancel];
            
        }
        
        [self removeTheFileOnFileSystem];
        
        if (_isFinishTransferLostServer==NO) {
            [_delegate uploadCompleted:_currentUpload.destinyFolder];
        }
    }
    
    //update Recents view
    [self updateRecentsTab];
    
    //Clear cache and cookies
    [UtilsCookies eraseURLCache];
}


/*
 * This method change the status of this upload to fail for credentials
 * It's used when the user resolved the credentials fails and there are still
 * uploads in progress.
 */
- (void)changeTheStatusToFailForCredentials{
    
    DLog(@"The Status is Fail for credentials");
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [_operation cancel];
    _operation=nil;
    
    //Like credential error
    _currentUpload.status = errorUploading;
    _currentUpload.kindOfError = errorCredentials;
    [ManageUploadsDB setStatus:errorUploading andKindOfError:errorCredentials byUploadOffline:self.currentUpload];
    
}


- (void) changeTheStatusToWaitingToServerConnection{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (self.operation) {
        [self.operation cancel];
        self.operation=nil;
    }
    
    if (self.uploadTask) {
        [self.uploadTask cancel];
        self.uploadTask = nil;
    }
    
    
    self.currentUpload.status = errorUploading;
    self.currentUpload.kindOfError = notAnError;
    [ManageUploadsDB setStatus:errorUploading andKindOfError:self.currentUpload.kindOfError byUploadOffline:self.currentUpload];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.userUploadWithError=self.userUploading;
    
    
}

/*
 * This method change the satuso fo this upload to fail for file exist in the server
 * It's used in the overwrite process when we detect that exist a diferent version of the file
 * on the server side.
 */
- (void) changeTheStatusToErrorFileExist {
    
    _currentUpload.status = errorUploading;
    _currentUpload.kindOfError = errorFileExist;
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //If we have the same file on the recentView we remove the old upload
    NSArray *uploadArrayCopy = [NSArray arrayWithArray:appDelegate.uploadArray];
    
    [uploadArrayCopy enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ManageUploadRequest *currentArrayUpload = (ManageUploadRequest*)obj;
        if (currentArrayUpload.currentUpload.idUploadsOffline == _currentUpload.idUploadsOffline) {
            [appDelegate.uploadArray removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
    
    [ManageUploadsDB setStatus:errorUploading andKindOfError:errorFileExist byUploadOffline:_currentUpload];
    
    [appDelegate.uploadArray addObject:self];
    
    [self updateRecentsTab];
    
}


#pragma mark - Utils

/*
 * Update only the progress view
 */
- (void)updateProgressWithPercent:(float)per{
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate updateProgressView:_progressTag withPercent:per];
}

/*
 * Remove the file
 */
- (void) removeTheFileOnFileSystem {
    
    if (self.currentUpload.originPath) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:self.currentUpload.originPath error:&error];
    }
}


/*
 * Method that store the date of upload is completed
 */
- (void)storeDateOfUpload{
    
    _date = [NSDate date];
    
    _currentUpload.uploadedDate = [_date timeIntervalSince1970];
    
}


#pragma mark - Transfer methods

/*
 * Dismiss transfer progress
 */
- (void)dismissTransferProgress:(id)sender {
    _operation = nil;
}

/*
 * Update recents view
 */
- (void)updateRecentsTab{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate updateRecents];
}




#pragma mark - Etag support

//Check etag in overwrite file to update with the new one.

- (void) updateTheEtagOfTheFile: (FileDto *) overwrittenFile {
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:self.userUploading.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:self.userUploading.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:self.userUploading.username andPassword:self.userUploading.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    //FileName full path
    NSString *serverPath = [UtilsUrls getFullRemoteServerPathWithWebDav:self.userUploading];
    NSString *path = [NSString stringWithFormat:@"%@%@%@",serverPath, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:overwrittenFile.filePath andUser:self.userUploading], overwrittenFile.fileName];
    
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    __weak typeof(self) weakSelf = self;
    
    [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        DLog(@"Operation response code: %ld", (long)response.statusCode);
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                DLog(@"error login updating the etag");
            }
        }
        if(response.statusCode < kOCErrorServerUnauthorized && !isSamlCredentialsError) {
            
            //Change the filePath from the library to our format
            for (FileDto *currentFile in items) {
                //Remove part of the item file path
                NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:self.userUploading];
                if([currentFile.filePath length] >= [partToRemove length]){
                    currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
                }
            }
            
            DLog(@"The directory List have: %lu elements", (unsigned long)items.count);
            
            
            //Check if there are almost one item in the array
            if (items.count >= 1) {
                DLog(@"Directoy list: %@", items);
                FileDto *currentFileDto = [items objectAtIndex:0];
                DLog(@"currentFileDto: %@", currentFileDto.etag);
                //Update the etag
                NSString *folderName=[UtilsUrls getFilePathOnDBByFilePathOnFileDto:overwrittenFile.filePath andUser:self.userUploading];
                [ManageFilesDB updateEtagOfFileDtoByFileName:overwrittenFile.fileName andFilePath:folderName andActiveUser:self.userUploading withNewEtag:currentFileDto.etag];
                //Set file status like downloaded in Data Base
                [ManageFilesDB updateDownloadStateOfFileDtoByFileName:overwrittenFile.fileName andFilePath:folderName andActiveUser:self.userUploading withState:downloaded];
                
                //Launch a notification for update the file previewed
                [[NSNotificationCenter defaultCenter] postNotificationName:uploadOverwriteFileNotification object:nil];
                
                
                [self.delegate overwriteCompleted];
            }
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
    }];
    //Erase cache and cookies
    [UtilsCookies eraseURLCache];
}

// Check the etag in the case that in the server has changed

- (void) checkTheEtagInTheServerOfTheFile:(FileDto *) overwrittenFile {
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:self.userUploading.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:self.userUploading.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:self.userUploading.username andPassword:self.userUploading.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    //FileName full path
    NSString *serverPath = [UtilsUrls getFullRemoteServerPathWithWebDav:self.userUploading];
    NSString *path = [NSString stringWithFormat:@"%@%@%@",serverPath, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:overwrittenFile.filePath andUser:self.userUploading], overwrittenFile.fileName];
    
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    __weak typeof(self) weakSelf = self;
    
    [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        DLog(@"Operation response code: %ld", (long)response.statusCode);
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                DLog(@"error login checking the etag");
                [ManageUploadsDB setStatus:errorUploading andKindOfError:notAnError byUploadOffline:_currentUpload];
            }
        }
        if(response.statusCode < kOCErrorServerUnauthorized && !isSamlCredentialsError) {
            
            //Change the filePath from the library to our format
            for (FileDto *currentFile in items) {
                //Remove part of the item file path
                NSString *partToRemove = [UtilsUrls getRemovedPartOfFilePathAnd:self.userUploading];
                if([currentFile.filePath length] >= [partToRemove length]){
                    currentFile.filePath = [currentFile.filePath substringFromIndex:[partToRemove length]];
                }
            }
            
            DLog(@"The directory List have: %lu elements", (unsigned long)items.count);
            
            //Check if there are almost one item in the array
            if (items.count >= 1) {
                DLog(@"Directoy list: %@", items);
                FileDto *currentFileDto = [items objectAtIndex:0];
                DLog(@"currentFileDto: %@", currentFileDto.etag);
                
                //Check the etag
                if (![overwrittenFile.etag isEqualToString:currentFileDto.etag]) {
                    [self changeTheStatusToErrorFileExist];
                    [ManageFilesDB setFileIsDownloadState:overwrittenFile.idFile andState:downloaded];
                    //Only for refresh file list
                    [self.delegate overwriteCompleted];
                    
                } else{
                    [self performSelectorInBackground:@selector(startUploadFile) withObject:nil];
                }
                
            }else{
                [ManageUploadsDB setStatus:errorUploading andKindOfError:notAnError byUploadOffline:_currentUpload];
            }
        }else{
            [ManageUploadsDB setStatus:errorUploading andKindOfError:notAnError byUploadOffline:_currentUpload];
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        [ManageUploadsDB setStatus:errorUploading andKindOfError:notAnError byUploadOffline:_currentUpload];
        
    }];
    //Erase cache and cookies
    [UtilsCookies eraseURLCache];
}

@end
