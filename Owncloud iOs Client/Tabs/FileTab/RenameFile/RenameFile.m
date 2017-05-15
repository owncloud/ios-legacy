//
//  RenameFile.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/9/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "RenameFile.h"
#import "FileDto.h"
#import "MBProgressHUD.h"
#import "NSString+Encoding.h"
#import "UtilsDtos.h"
#import "AppDelegate.h"
#import "FileNameUtils.h"
#import "constants.h"
#import "Customization.h"
#import "OCErrorMsg.h"
#import "ManageFilesDB.h"
#import "FileNameUtils.h"
#import "DetailViewController.h"
#import "OCCommunication.h"
#import "UtilsNetworkRequest.h"
#import "UtilsUrls.h"
#import "ManageUsersDB.h"
#import "ManageThumbnails.h"

@interface RenameFile ()

@property (nonatomic, strong) FileDto *oldFile;

@end


@implementation RenameFile


#pragma mark - Rename file

/*
 * This method show an pop up view to create folder
 */
- (void)showRenameFile: (FileDto *) file {
    
    _oldFile = file;
    
    //We init the ManageNetworkErrors
    if (!_manageNetworkErrors) {
        _manageNetworkErrors = [ManageNetworkErrors new];
        _manageNetworkErrors.delegate = self;
    }
    
    self.selectedFileDto = file;
    
    _renameAlertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"rename_file_title", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"save", nil), nil];
    _renameAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_renameAlertView textFieldAtIndex:0].delegate = self;
    [[_renameAlertView textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeNo];
    [[_renameAlertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeNone];

    if(self.selectedFileDto.isDirectory) {
        if ( [self.selectedFileDto.fileName length] > 0) {
            [_renameAlertView textFieldAtIndex:0].text = [[self.selectedFileDto.fileName substringToIndex:[self.selectedFileDto.fileName length] - 1]stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    } else {
        [_renameAlertView textFieldAtIndex:0].text = [self.selectedFileDto.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    [_renameAlertView show];
    //This delay is included because on iPad iOS6 the app crashs if do long press and rename
    [self performSelector:@selector(markFileName) withObject:nil afterDelay:0.5];
}


/*
 * Method that marked the name in the pop up, from the begin until the extensión of the file name
 */
- (void)markFileName {
    
    //Check if the filename is not a directory
    //if (!_selectedFileDto.isDirectory) { //I comment this if in oder to show the select balls on the folders too not only on the files
        [FileNameUtils markFileNameOnAlertView:[_renameAlertView textFieldAtIndex:0]];
    //}
}


#pragma mark - UIalertViewDelegate

- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex
{
    // cancel
    if( buttonIndex == 1 ){
        
          BOOL serverHasForbiddenCharactersSupport = [ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport];
        
        if ([FileNameUtils isForbiddenCharactersInFileName:[_renameAlertView textFieldAtIndex:0].text withForbiddenCharactersSupported:serverHasForbiddenCharactersSupport]) {
            
            NSString *msg = nil;
            msg = NSLocalizedString(@"forbidden_characters_from_server", nil);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: msg message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alert show];
        } else {
            DLog(@"We change %@ for %@", self.selectedFileDto.fileName, [_renameAlertView textFieldAtIndex:0].text);
            //Clear the spaces of the left and the right of the sentence
            NSString* result = [[_renameAlertView textFieldAtIndex:0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            //Init loading
            if ([(NSObject*)_delegate respondsToSelector:@selector(initLoading)]) {
                [_delegate initLoading];
            }
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            //In iPad set the global variable
            if (!IS_IPHONE) {
                //Set global loading screen global flag to YES (only for iPad)
                app.isLoadingVisible = YES;
            }
            
            [self performSelector:@selector(renameFileClicked:) withObject:result];
        }
    }  else {
        //We call the endLoading to set nil the rename
        [self endLoading];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL output = YES;
    
    NSString *stringNow = [alertView textFieldAtIndex:0].text;
    
    //Active button of folderview only when the textfield has something.
    NSString *rawString = stringNow;
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
    
    if ([trimmed length] == 0) {
        // Text was empty or only whitespace.
        output = NO;
    }
    
    //Button save disable when the textfield is empty
    if ([stringNow isEqualToString:@""]) {
        output = NO;
    }
    
    return output;
}


/*
 * The user has pressed the "save button" in the popup
 * This method launch the check method to know if there are the item
 * with the same name in the path of the server.
 *
 * @name -> Name of the new item
 */
-(void) renameFileClicked:(NSString*)name {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (!_utilsNetworkRequest) {
        _utilsNetworkRequest = [UtilsNetworkRequest new];
        _utilsNetworkRequest.delegate = self;
    }
    
    _mNewName = name;
    
    NSString *fileDBPathToCheck;
    NSString *fileDBPathToDestination;
    
    //Get the file database path of the item without utf8
    fileDBPathToDestination  = [UtilsUrls getFilePathOnDBByFullPath:self.currentRemoteFolder andUser:app.activeUser];
    
    if ([_selectedFileDto isDirectory]) {
        //If is directory quit the "/"
        //Get the file database path of the item for the check with the server
        fileDBPathToCheck  = [UtilsUrls getFilePathOnDBByFullPath:[NSString stringWithFormat:@"%@", self.currentRemoteFolder] andUser:app.activeUser];
    } else {
        //Get the file database path of the item for the check with the server
        fileDBPathToCheck  = [UtilsUrls getFilePathOnDBByFullPath:[NSString stringWithFormat:@"%@%@", self.currentRemoteFolder,self.selectedFileDto.fileName] andUser:app.activeUser];
    }
    
    DLog(@"FilePath: %@", fileDBPathToCheck);
    DLog(@"FilePath: %@", fileDBPathToDestination);
    DLog(@"Destination file: %@%@", self.currentRemoteFolder, self.selectedFileDto.fileName);
    
    //Create the path of the destination
    _destinationFile = [NSString stringWithFormat:@"%@%@",fileDBPathToDestination,[name encodeString:NSUTF8StringEncoding]];
    
    //Create path to check with the server
    NSString *pathToCheck=[NSString stringWithFormat:@"%@%@",self.currentRemoteFolder,[name encodeString:NSUTF8StringEncoding]];
    
    //If is directory we need the "/"
    if ([_selectedFileDto isDirectory]) {
        pathToCheck = [NSString stringWithFormat:@"%@/", pathToCheck];
    }
    
    //Check if the item already exists in the path
    [_utilsNetworkRequest checkIfTheFileExistsWithThisPath:pathToCheck andUser:app.activeUser];
}

#pragma mark - UtilsNetworkRequestDelegate

/*
 * Method that is use with the information of the server to know if the
 * file is in the path of server or not.
 * @isExist --> YES/NO information of the server
 */
- (void) theFileIsInThePathResponse:(NSInteger) response {
    
    if(response == isInThePath) {
        if(self.selectedFileDto.isDirectory) {
            DLog(@"Exist a folder with the same name");
            [self showError:NSLocalizedString(@"folder_exist", nil)];
        } else {
            DLog(@"Exist a file with the same name");
            [self showError:NSLocalizedString(@"file_exist", nil)];
        }
    } else {
        [self renameFile];
    }
}

/*
 * Method that check the name of the if the new name has forbiden characters
 * and then send the request to the webdav server to rename the item.
 */
 
-(void) renameFile {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    NSString *newURLString = [NSString stringWithFormat:@"%@%@", [UtilsUrls getFullRemoteServerPathWithWebDav:app.activeUser], self.destinationFile];
    NSString *originalURLString = [UtilsUrls getFullRemoteServerFilePathByFile:self.selectedFileDto andUser:app.activeUser];
    
    originalURLString = [originalURLString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    newURLString = [newURLString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if ([originalURLString hasSuffix:@"/"]) {
        originalURLString = [originalURLString substringToIndex:[originalURLString length] - 1];
    }
    
    DLog(@"originalURLString: %@", originalURLString);
    DLog(@"newURLString: %@", newURLString);
    
    DLog(@"After checking the original and destiny path Move request");
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    [[AppDelegate sharedOCCommunication] moveFileOrFolder:originalURLString toDestiny:newURLString onCommunication:[AppDelegate sharedOCCommunication] withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        DLog(@"Great, the item is renamed");
        
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
            [self endLoading];
            [self moveTheFileOrFolderOnTheDBAndFileSystem];
        }
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        [self endLoading];
        
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        
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
            [_manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];
        }
        
    } errorBeforeRequest:^(NSError *error) {
        
        NSString *msg = nil;

        switch (error.code) {
            case OCErrorMovingTheDestinyAndOriginAreTheSame:
                [self endLoading];
                break;
                
            case OCErrorMovingFolderInsideItself:
                [self showError:NSLocalizedString(@"error_folder_destiny_is_the_same", nil)];
                break;
                
            case OCErrorMovingDestinyNameHaveForbiddenCharacters:
            
                msg = NSLocalizedString(@"forbidden_characters_from_server", nil);

                [self showError:msg];
                break;
                
            default:
                [self showError:NSLocalizedString(@"unknow_response_server", nil)];
                break;
        }
    }];
    
}

/*
 * Show the standar message of the error connection.
 *
 */
- (void)showError:(NSString *) message{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self endLoading];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    });
}

- (void)errorLogin {
    [self endLoading];
    
    [self.delegate errorLogin];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    return YES;
    
}

#pragma mark - Rename Folder

- (void)renameFolderChildsWithFilePath:(NSString*)filePath ofFileId:(NSInteger)idFile{
    
    DLog(@"filePath: %@", filePath);
    
    //Rename local url and server url of files
    NSArray *files = [ManageFilesDB getFilesByFileIdForActiveUser:idFile];
    
    if ([files count]>0) {
        FileDto *oneFile;
        //Change for each file the local url and server url
        for (int i=0;i<[files count]; i++) {
            
            oneFile=[files objectAtIndex:i];
            
            if (oneFile.isDirectory==NO) {
                //New server url
                //NSString *newServerUrl = [NSString stringWithFormat:@"%@%@", filePath, oneFile.fileName];
                NSString *newServerUrl = filePath;
                [ManageFilesDB setFilePath:newServerUrl byIdFile:oneFile.idFile];
                
            }else{
                //Si es un directorio.
                //Actulizar el newserverurl del directorio
                NSString *newServerUrl = [NSString stringWithFormat:@"%@%@", filePath, oneFile.fileName];
                //NSString *newServerUrl = filePath;
                [ManageFilesDB setFilePath:filePath byIdFile:oneFile.idFile];
                //Obtener objeto
                oneFile=[ManageFilesDB getFileDtoByIdFile:oneFile.idFile];
                //Llamar a este metodo para comenzar a renombrar -recursividad
                [self renameFolderChildsWithFilePath:newServerUrl ofFileId:oneFile.idFile];
            }
        }
    }
}


-(void) moveTheFileOrFolderOnTheDBAndFileSystem {
    
    if (self.selectedFileDto.isDirectory) {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        DLog(@"Change folder name");
        
        DLog(@"OldFilePath: %@", self.selectedFileDto.filePath);
        
        self.mNewName= [self.mNewName encodeString:NSUTF8StringEncoding];
        NSString *originalName = [self.selectedFileDto.fileName substringToIndex:[self.selectedFileDto.fileName length]-1];
        [ManageFilesDB renameFolderByFileDto:self.selectedFileDto andNewName:self.mNewName];
        
        //Rename paths of the childs (items and folders)
        
        self.selectedFileDto=[ManageFilesDB getFileDtoByIdFile:self.selectedFileDto.idFile];
        
        NSString *newFilePathOnDB = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.selectedFileDto.filePath andUser:app.activeUser];
        
        [self renameFolderChildsWithFilePath:[NSString stringWithFormat:@"%@%@",newFilePathOnDB, self.selectedFileDto.fileName] ofFileId:self.selectedFileDto.idFile];
        
        
        //self.mNewName=[NSString stringWithFormat:@"%@/", self.mNewName];
        
        
        // Create file manager
        NSFileManager *fileMgr = [[NSFileManager alloc] init];
        
        NSError *error;
        
        NSString *localUrl = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, [originalName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSString *newFile = [NSString stringWithFormat:@"%@%@", self.currentLocalFolder, [self.mNewName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSString *documentPath= [UtilsUrls getOwnCloudFilePath];
        
        NSString *tempUrl = [NSString stringWithFormat:@"%@/tempfolder", documentPath];
        
        DLog(@"Local URL %@", localUrl);
        DLog(@"New File %@", newFile );
        DLog(@"Temp File: %@", tempUrl);
        
        //Move the original folder to tempfolder
        //Delete original folder
        //Move tempfolder to newfolder
        
        BOOL isError=NO;
        
        [fileMgr removeItemAtPath:tempUrl error:nil];
        
        if ([fileMgr moveItemAtPath:localUrl toPath:tempUrl error:&error] != YES) {
            DLog(@"Unable to move file: %@", [error localizedDescription]);
            isError=YES;
        }
        
        if (!isError) {
            if ([fileMgr moveItemAtPath:tempUrl toPath:newFile error:&error] != YES) {
                DLog(@"Unable to move file: %@", [error localizedDescription]);
            }
        }else{
            
            //Error
        }
    } else {
                
        [ManageFilesDB renameFileByFileDto:self.selectedFileDto andNewName:[self.mNewName encodeString:NSUTF8StringEncoding]];
        
        if(self.selectedFileDto.isDownload) {
            // Create file manager
            NSFileManager *fileMgr = [[NSFileManager alloc] init];
            
            NSString *fileNameWithoutPercents = [self.selectedFileDto.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            DLog(@"FileName: %@", fileNameWithoutPercents);
            DLog(@"Delete: %@", self.selectedFileDto.localFolder);
            
            NSError *error;
            
            NSString *localUrl = [self.selectedFileDto.localFolder substringToIndex:self.selectedFileDto.localFolder.length - fileNameWithoutPercents.length];
            
            DLog(@"%@", localUrl);
            
            NSString *newFile = [NSString stringWithFormat:@"%@%@", localUrl, self.mNewName];
            
            // Attempt to delete the file at filePath2
            
            DLog(@"self.selectedFileDto.localFolder: %@",self.selectedFileDto.localFolder);
            DLog(@"newFile: %@", newFile);
            
            
            // Attempt the move
            if ([fileMgr moveItemAtPath:self.selectedFileDto.localFolder toPath:newFile error:&error] != YES) {
                DLog(@"Unable to rename file: %@", [error localizedDescription]);
            }
        }
    }
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //If is IPAD we update the fileDto in case that the current file is the same on preview
    if (!IS_IPHONE) {
        if (app.detailViewController.file.idFile == _selectedFileDto.idFile) {
            app.detailViewController.file = [ManageFilesDB getFileDtoByFileName:[_mNewName encodeString:NSUTF8StringEncoding] andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_selectedFileDto.filePath andUser:app.activeUser] andUser:app.activeUser];
            app.detailViewController.titleLabel.text = [app.detailViewController.file.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
        }
    }
    
    //To update the audio player
    NSString *oldPath = [NSString stringWithFormat:@"%@%@",_currentLocalFolder, [self.selectedFileDto.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    if ([app isMediaPlayerRunningWithThisFilePath: oldPath]) {
        NSString *pathOfNewFile = [NSString stringWithFormat:@"%@%@",_currentLocalFolder, _mNewName];
        app.avMoviePlayer.urlString = pathOfNewFile;
    }
    
    if ([(NSObject*)self.delegate respondsToSelector:@selector(reloadTableFromDataBase)]) {
        [_delegate reloadTableFromDataBase];
    }
}

#pragma mark - Loading

///-----------------------------------
/// @name End Loading
///-----------------------------------

/**
 * Method that remove the loading icon in parent view
 * in Case on iPhone by delegate
 * and in case of iPad by notification
 */
- (void)endLoading{
    
    if (IS_IPHONE) {
        if ([(NSObject*)_delegate respondsToSelector:@selector(endLoading)]) {
            [_delegate endLoading];
        }
    } else {
        [self performSelectorOnMainThread:@selector(endLoadingInOtherThread) withObject:nil waitUntilDone:YES];
    }
}


/*
 * This method close the loading view in main screen by local notification
 */
- (void)endLoadingInOtherThread {
    
    //Set global loading screen global flag to NO
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isLoadingVisible = NO;
    //Send notification to indicate to close the loading view
    [[NSNotificationCenter defaultCenter] postNotificationName:EndLoadingFileListNotification object: nil];
}

@end
