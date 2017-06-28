//
//  ShareFileOrFolder.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 1/10/14.
//  Edited by Noelia Alvarez

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareFileOrFolder.h"
#import "AppDelegate.h"
#import "FileDto.h"
#import "OCCommunication.h"
#import "UtilsDtos.h"
#import "ManageFilesDB.h"
#import "constants.h"
#import "AppsActivityProvider.h"
#import "OCErrorMsg.h"
#import "ManageSharesDB.h"
#import "Customization.h"
#import "FileNameUtils.h"
#import "UtilsUrls.h"
#import "OCSharedDto.h"
#import "OCConstants.h"


@implementation ShareFileOrFolder

- (void) initManageErrors {
    //We init the ManageNetworkErrors
    if (!_manageNetworkErrors) {
        _manageNetworkErrors = [ManageNetworkErrors new];
        _manageNetworkErrors.delegate = self;
    }
}

#pragma mark - Share Requests (create, update, unshare)

- (void) doRequestCreateShareLinkOfFile:(FileDto *)file withPassword:(NSString *)password expirationTime:(NSString*)expirationTime publicUpload:(NSString *)publicUpload linkName:(NSString *)linkName andPermissions:(NSInteger)permissions{
    
    [self initManageErrors];
    
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
    
    
    NSString *filePath = [UtilsUrls getFilePathOnDBwithRootSlashAndWithFileName:file.fileName ByFilePathOnFileDto:file.filePath andUser:app.activeUser];

    
    [[AppDelegate sharedOCCommunication] shareFileOrFolderByServerPath:[UtilsUrls getFullRemoteServerPath:app.activeUser] withFileOrFolderPath:filePath password:password expirationTime:expirationTime publicUpload:publicUpload linkName:linkName permissions:permissions onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *token, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
        }
        
        if (isSamlCredentialsError) {
            [self errorLogin];
        } else {
            [self.delegate sharelinkOptionsUpdated];
        }

    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
        }
        
        if (isSamlCredentialsError) {
            [self errorLogin];
            
        } else {
            
            DLog(@"error.code: %ld", (long)error.code);
            DLog(@"server error: %ld", (long)response.statusCode);
            
            [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }

    }];
}


- (void) doRequestUpdateShareLink:(OCSharedDto *)ocShare withPassword:(NSString*)password expirationTime:(NSString*)expirationTime publicUpload:(NSString *)publicUpload linkName:(NSString *)linkName andPermissions:(NSInteger)permissions {
    
    [self initManageErrors];
    
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
    
    [[AppDelegate sharedOCCommunication] updateShare:ocShare.idRemoteShared ofServerPath:[UtilsUrls getFullRemoteServerPath:app.activeUser] withPasswordProtect:password andExpirationTime:expirationTime andPublicUpload:publicUpload andLinkName:linkName andPermissions:permissions onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSData *responseData, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
        }
        
        if (isSamlCredentialsError) {
            [self errorLogin];
        } else {
            [self.delegate sharelinkOptionsUpdated]; //TODO:return ocsharedDto instead of responsese data and not call sharelinkoptionsupdated
        }
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
        }
        
        if (isSamlCredentialsError) {
            [self errorLogin];
        } else {
            [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }

    }];
}


///-----------------------------------
/// @name Unshare the file
///-----------------------------------

/**
 * This method unshares the file/folder
 *
 * @param OCSharedDto -> The shared file/folder
 */
- (void)unshareTheFileByIdRemoteShared:(NSInteger)idRemoteShared {
    
    [self initManageErrors];

    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [self initLoading];
    
    //In iPad set the global variable
    if (!IS_IPHONE) {
        //Set global loading screen global flag to YES (only for iPad)
        app.isLoadingVisible = YES;
    }
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    [[AppDelegate sharedOCCommunication] unShareFileOrFolderByServer:[UtilsUrls getFullRemoteServerPath:app.activeUser] andIdRemoteShared:idRemoteShared onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        [self endLoading];
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        
        if (!isSamlCredentialsError) {
            [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];

        }

        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        
        [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];
        [self endLoading];
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
                
            }
        }
        if (!isSamlCredentialsError) {
           
            [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }
        
    }];
}

- (void) checkSharedStatusOfFile:(FileDto *) file {
    
    [self initManageErrors];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [self initLoading];
    
    //In iPad set the global variable
    if (!IS_IPHONE) {
        //Set global loading screen global flag to YES (only for iPad)
        app.isLoadingVisible = YES;
    }

    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:APP_DELEGATE.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:APP_DELEGATE.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:APP_DELEGATE.activeUser.username andPassword:APP_DELEGATE.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    FileDto *parentFolder = [ManageFilesDB getFileDtoByIdFile:file.fileId];
    
    NSString *path = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:parentFolder.filePath andUser:APP_DELEGATE.activeUser];
    path = [path stringByAppendingString:parentFolder.fileName];
    path = [path stringByRemovingPercentEncoding];
    
    [[AppDelegate sharedOCCommunication] readSharedByServer:APP_DELEGATE.activeUser.url andPath:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *listOfShared, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self endLoading];
                [self errorLogin];
            }
        }
        
        if (!isSamlCredentialsError) {
            
            NSArray *itemsToDelete = [ManageSharesDB getSharesByFolderPath:[NSString stringWithFormat:@"/%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:parentFolder.filePath andUser:APP_DELEGATE.activeUser], parentFolder.fileName]];
            
            //1. We remove the removed shared from the Files table of the current folder
            [ManageFilesDB setUnShareFilesOfFolder:parentFolder];
            //2. Delete all shared to not repeat them
            [ManageSharesDB deleteLSharedByList:itemsToDelete];
            //3. Delete all the items that we want to insert to not insert them twice
            [ManageSharesDB deleteLSharedByList:listOfShared];
            //4. We add the new shared on the share list
            [ManageSharesDB insertSharedList:listOfShared];
            //5. Update the files with shared info of this folder
            [ManageFilesDB updateFilesAndSetSharedOfUser:APP_DELEGATE.activeUser.idUser];
            
            [self endLoading];
            
            [self.delegate finishCheckSharesAndReloadShareView];
        }

        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        
        [self endLoading];
        
        BOOL isSamlCredentialsError = NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
        }
        
        if (!isSamlCredentialsError) {
            
            [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }
    }];
}



///-----------------------------------
/// @name clickOnUnShare
///-----------------------------------

/**
 * Method to obtain the share the file or folder
 *
 */
- (void) clickOnUnShare {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSArray *sharesOfFile = [ManageSharesDB getSharesBySharedFileSource:_file.sharedFileSource forUser:app.activeUser.idUser];
    OCSharedDto *sharedByLink;
    
    for (OCSharedDto *current in sharesOfFile) {
        if (current.shareType == shareTypeLink) {
            sharedByLink = current;
        }
    }
    
    [self unshareTheFileByIdRemoteShared:sharedByLink.idRemoteShared];
}


#pragma mark - Utils

- (void) refreshSharedItemInDataBase:(OCSharedDto *) item {
    
    NSArray* items = [NSArray arrayWithObject:item];
    
    [ManageSharesDB deleteLSharedByList:items];
    
    [ManageSharesDB insertSharedList:items];
    
    [ManageFilesDB updateFilesAndSetSharedOfUser:APP_DELEGATE.activeUser.idUser];
}


#pragma mark - Loading Methods

///-----------------------------------
/// @name endLoading
///-----------------------------------


- (void) initLoading{
    
    if([self.delegate respondsToSelector:@selector(initLoading)]) {
        [self.delegate initLoading];
    }
}

/**
 * Method to hide the Loading view
 *
 */
- (void) endLoading {
    
    //Set global loading screen global flag to NO
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isLoadingVisible = NO;
    
    if([self.delegate respondsToSelector:@selector(endLoading)]) {
        [self.delegate endLoading];
    }
}

- (void) errorLogin {
    
    if([self.delegate respondsToSelector:@selector(errorLogin)]) {
        [self.delegate errorLogin];
    }
    
}


/*
 * Show the standar message of the error connection.
 */
- (void)showError:(NSString *) message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message
                                                        message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    });
}


@end
