//
//  ShareFileOrFolder.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 1/10/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
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
#import "OCSharedDto.h"
#import "Customization.h"
#import "FileNameUtils.h"
#import "CheckHasShareSupport.h"


@implementation ShareFileOrFolder

- (void) showShareActionSheetForFile:(FileDto *)file {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if ((app.activeUser.hasShareApiSupport == serverFunctionalitySupported || app
         .activeUser.hasShareApiSupport == serverFunctionalityNotChecked)) {
        _file = file;
        
        //We check if the file is shared
        if (_file.sharedFileSource > 0) {
            
            //The file is shared so we show the options to share or unshare link
            if (self.shareActionSheet) {
                self.shareActionSheet = nil;
            }
            
            self.shareActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:NSLocalizedString(@"unshare_link", nil) otherButtonTitles:NSLocalizedString(@"share_link_long_press", nil), nil];
            
            if (!IS_IPHONE){
                
                AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                if (app.detailViewController.popoverController.isPopoverVisible){
                    [app.detailViewController.popoverController dismissPopoverAnimated:YES];
                }
                
                [self.shareActionSheet showInView:_viewToShow];
            } else {
                
                [self.shareActionSheet showInView:[_viewToShow window]];
            }
        } else {
            //The file is not shared so we launch the sharing inmediatly
            [self clickOnShareLinkFromFileDto:YES];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"share_not_available_on_this_server", nil)
                                                        message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alert show];
    }
}

///-----------------------------------
/// @name Present Share Action Sheet For Token
///-----------------------------------

/**
 * This method show a Share View using a share token
 *
 * @param token -> NSString
 *
 */
- (void) presentShareActionSheetForToken:(NSString *)token{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSString *sharedLink = [NSString stringWithFormat:@"%@%@%@",app.activeUser.url,k_share_link_middle_part_url,token];
    
    UIActivityItemProvider *activityProvider = [UIActivityItemProvider new];
    NSArray *items = @[activityProvider, sharedLink];
    
    //Adding the bottom buttons on the share view
    APCopyActivityIcon *copyLink = [[APCopyActivityIcon alloc] initWithLink:sharedLink];
    APWhatsAppActivityIcon *whatsApp = [[APWhatsAppActivityIcon alloc] initWithLink:sharedLink];
    
    NSMutableArray *activities = [NSMutableArray new];
    
    if ([copyLink isAppInstalled]) {
        [activities addObject:copyLink];
    }
    
    if ([whatsApp isAppInstalled]) {
        [activities addObject:whatsApp];
    }
    
    UIActivityViewController *activityView = [[UIActivityViewController alloc]
                                              initWithActivityItems:items
                                              applicationActivities:activities];
    [activityView setExcludedActivityTypes:
     @[UIActivityTypeAssignToContact,
       UIActivityTypeCopyToPasteboard,
       UIActivityTypePrint,
       UIActivityTypeSaveToCameraRoll,
       UIActivityTypePostToWeibo]];
    
    
    if (IS_IPHONE) {
        [app.ocTabBarController presentViewController:activityView animated:YES completion:nil];
    } else {
        
        if (self.activityPopoverController) {
            [self.activityPopoverController setContentViewController:activityView];
        } else {
            self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityView];
        }
        
        if (_isTheParentViewACell) {
            //Present view from cell from file list
            [self.activityPopoverController presentPopoverFromRect:_cellFrame inView:_parentView permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
            
        } else if (_parentButton) {
            //Present view from bar button item
            [self.activityPopoverController presentPopoverFromBarButtonItem:_parentButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            
             } else {
            //Present  view from rect
            [self.activityPopoverController presentPopoverFromRect:CGRectMake(100, 100, 200, 400) inView:_parentView permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
        }
    }
    
    
    [activityView setCompletionHandler:^(NSString *act, BOOL done) {
         
         [self.activityPopoverController dismissPopoverAnimated:YES];
         
         /*NSString *serviceMsg = nil;
          if ( [act isEqualToString:UIActivityTypeMail] )                    ServiceMsg = @"Mail sended!";
          if ( [act isEqualToString:UIActivityTypePostToTwitter] )           ServiceMsg = @"Post on twitter, ok!";
          if ( [act isEqualToString:UIActivityTypePostToFacebook] )          ServiceMsg = @"Post on facebook, ok!";
          if ( [act isEqualToString:UIActivityTypeMessage] )                 ServiceMsg = @"SMS sended!";
          if ( [act isEqualToString:UIActivityTypeCopyToPasteboard] && done) {
          serviceMsg = NSLocalizedString(@"link_copied_on_pasteboard", nil);
          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:serviceMsg message:@"" delegate:nil cancelButtonTitle: NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
          [alert show];
          }*/
     }];
}



#pragma mark - UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self clickOnUnShare];
            
            break;
        case 1:
            [self clickOnShareLinkFromFileDto:YES];
            
            break;
        case 2:
            DLog(@"Cancel");
            break;
    }
}


///-----------------------------------
/// @name Click on share link from file
///-----------------------------------

/**
 * Method to share the file from file or from sharedDto
 *
 * @param isFile -> BOOL. Distinct between is fileDto or shareDto
 */
- (void) clickOnShareLinkFromFileDto:(BOOL)isFileDto {
    DLog(@"Click on Share Link");
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [_delegate initLoading];
    
    //In iPad set the global variable
    if (!IS_IPHONE) {
        //Set global loading screen global flag to YES (only for iPad)
        app.isLoadingVisible = YES;
    }
    
    NSString *filePath = @"";
    
    if (isFileDto) {
        //From fileDto
        NSString *path = [NSString stringWithFormat:@"/%@", [UtilsDtos getDbBFolderPathFromFullFolderPath:_file.filePath]];
        filePath = [NSString stringWithFormat: @"%@%@", path, _file.fileName];
        
        NSArray *sharesOfFile = [ManageSharesDB getSharesBySharedFileSource:_file.sharedFileSource forUser:app.activeUser.idUser];
        
        for (OCSharedDto *current in sharesOfFile) {
            if (current.shareType == shareTypeLink) {
                _shareDto = current;
            }
        }
        
    } else {
        //From shareDto
        filePath = _shareDto.path;
    }
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
    }
    
    __block OCSharedDto *blockShareDto = _shareDto;
    
    [[AppDelegate sharedOCCommunication] isShareFileOrFolderByServer:app.activeUser.url andIdRemoteShared:_shareDto.idRemoteShared onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer, BOOL isShared) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                [self endLoading];
                [_delegate errorLogin];
            }
        }
        
        
        if (!isSamlCredentialsError) {
        
            if (isShared) {
                
                [self endLoading];
                
                //Present
                [self presentShareActionSheetForToken:blockShareDto.token];
                
            }else{
                
                DLog(@"The file is not shared so we need to share it again");
                
                //Set the right credentials
                if (k_is_sso_active) {
                    [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
                } else if (k_is_oauth_active) {
                    [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
                } else {
                    [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
                }
                
                //Checking the Shared files and folders
                [[AppDelegate sharedOCCommunication] shareFileOrFolderByServer:app.activeUser.url andFileOrFolderPath:filePath onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *token, NSString *redirectedServer) {
                    
                    BOOL isSamlCredentialsError=NO;
                    
                    //Check the login error in shibboleth
                    if (k_is_sso_active && redirectedServer) {
                        //Check if there are fragmens of saml in url, in this case there are a credential error
                        isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                        if (isSamlCredentialsError) {
                            [self endLoading];
                            [_delegate errorLogin];
                        }
                    }
                    if (!isSamlCredentialsError) {
                        
                        //Ok we have the token but we also need all the information of the file in order to populate the database
                        [[AppDelegate sharedCheckHasShareSupport] updateSharesFromServer];
                        
                        [self endLoading];
                        
                        //Present
                        [self presentShareActionSheetForToken:token];
                    }
                    
                } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
                    
                    [self endLoading];
                    
                    DLog(@"error.code: %ld", (long)error.code);
                    DLog(@"server error: %ld", (long)response.statusCode);
                    NSInteger code = response.statusCode;
                    
                    //Select the correct msg and action for this error
                    switch (code) {
                            //Switch with response https
                        case kOCErrorServerPathNotFound:
                            [self showError:NSLocalizedString(@"file_to_share_not_exist", nil)];
                            break;
                        case kOCErrorServerUnauthorized:
                            [_delegate errorLogin];
                            break;
                        case kOCErrorServerForbidden:
                            [self showError:NSLocalizedString(@"error_not_permission", nil)];
                            break;
                        case kOCErrorServerTimeout:
                            [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                            break;
                        default:
                            //Switch with API response errors
                            switch (error.code) {
                                    //Switch with response https
                                case kOCErrorServerPathNotFound:
                                    [self showError:NSLocalizedString(@"file_to_share_not_exist", nil)];
                                    break;
                                case kOCErrorServerUnauthorized:
                                    [_delegate errorLogin];
                                    break;
                                case kOCErrorServerForbidden:
                                    [self showError:NSLocalizedString(@"error_not_permission", nil)];
                                    break;
                                case kOCErrorServerTimeout:
                                    [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                                    break;
                                default:
                                    //Switch with API response errors
                                    [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                                    break;
                            }
                            break;
                    }
                }];

                
            }
        }
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        [self endLoading];
        
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        NSInteger code = response.statusCode;
        
        //Select the correct msg and action for this error
        switch (code) {
                //Switch with response https
            case kOCErrorServerPathNotFound:
                [self showError:NSLocalizedString(@"file_to_share_not_exist", nil)];
                break;
            case kOCErrorServerUnauthorized:
                [_delegate errorLogin];
                break;
            case kOCErrorServerForbidden:
                [self showError:NSLocalizedString(@"error_not_permission", nil)];
                break;
            case kOCErrorServerTimeout:
                [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                break;
            default:
                //Switch with API response errors
                switch (error.code) {
                        //Switch with response https
                    case kOCErrorServerPathNotFound:
                        [self showError:NSLocalizedString(@"file_to_share_not_exist", nil)];
                        break;
                    case kOCErrorServerUnauthorized:
                        [_delegate errorLogin];
                        break;
                    case kOCErrorServerForbidden:
                        [self showError:NSLocalizedString(@"error_not_permission", nil)];
                        break;
                    case kOCErrorServerTimeout:
                        [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                        break;
                    default:
                        //Switch with API response errors
                        [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                        break;
                }
                break;
        }
    }];
}

///-----------------------------------
/// @name endLoading
///-----------------------------------

/**
 * Method to hide the Loading view
 *
 */
- (void) endLoading {
    
    //Set global loading screen global flag to NO
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isLoadingVisible = NO;
    
    [_delegate endLoading];
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
    
    [self unshareTheFile:sharedByLink];
}



///-----------------------------------
/// @name Unshare the file
///-----------------------------------

/**
 * This method unshares the file/folder
 *
 * @param OCSharedDto -> The shared file/folder
 */
- (void) unshareTheFile: (OCSharedDto *)sharedByLink {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [_delegate initLoading];
    
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
    
    [[AppDelegate sharedOCCommunication] unShareFileOrFolderByServer:app.activeUser.url andIdRemoteShared:sharedByLink.idRemoteShared onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active && redirectedServer) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            if (isSamlCredentialsError) {
                [self endLoading];
                [_delegate errorLogin];
            }
        }
        if (!isSamlCredentialsError) {
            [[AppDelegate sharedCheckHasShareSupport] updateSharesFromServer];
            [self endLoading];
        }

        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        [[AppDelegate sharedCheckHasShareSupport] updateSharesFromServer];
        [self endLoading];
        
        DLog(@"error.code: %ld", (long)error.code);
        DLog(@"server error: %ld", (long)response.statusCode);
        NSInteger code = response.statusCode;
        
        //Select the correct msg and action for this error
        switch (code) {
            case kOCErrorServerPathNotFound:
                [self showError:NSLocalizedString(@"file_to_unshare_not_exist", nil)];
                break;
            case kOCErrorServerUnauthorized:
                [_delegate errorLogin];
                break;
            case kOCErrorServerForbidden:
                [self showError:NSLocalizedString(@"error_not_permission", nil)];
                break;
            case kOCErrorServerTimeout:
                [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                break;
            default:
                if (error.code == kOCErrorServerPathNotFound) {
                    [self showError:NSLocalizedString(@"file_to_unshare_not_exist", nil)];
                } else {
                    [self showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                }
                
                break;
        }
    }];
}

/*
 * Show the standar message of the error connection.
 */
- (void)showError:(NSString *) message {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message
                                                    message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alert show];
}

@end
