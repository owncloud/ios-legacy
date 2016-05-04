//
//  EditFileViewController.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 04/05/16.
//
//

#import "EditFileViewController.h"
#import "FileNameUtils.h"
#import "ManageUsersDB.h"
#import "ManageFilesDB.h"
#import "constants.h"
#import "Customization.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "UtilsUrls.h"
#import "NSString+Encoding.h"
#import "ManageNetworkErrors.h"


@interface EditFileViewController ()

@end

@implementation EditFileViewController

- (id)initWithFileDto:(FileDto *)fileDto {
   
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.currentFileDto = fileDto;
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
}

#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = NSLocalizedString(@"title_view_edit_file", nil);
    [self setBarButtonStyle];
    
}

- (void) setBarButtonStyle {
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectDoneView)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
}


#pragma mark - Action Methods

- (void) didSelectDoneView {
    [self storeTextFile];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (BOOL) checkForSameName:(NSString*)name {
    
    BOOL existSameName = NO;
    
    self.currentDirectoryArray = [ManageFilesDB getFilesByFileIdForActiveUser:self.currentFileDto.idFile];

    NSPredicate *predicateSameName = [NSPredicate predicateWithFormat:@"fileName == %@", name];
    NSArray *filesSameName = [self.currentDirectoryArray filteredArrayUsingPredicate:predicateSameName];

    if (filesSameName !=nil && filesSameName.count > 0) {
        existSameName = YES;
    }
    
    return existSameName;
}

- (void) storeTextFile {
    
    
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    NSString *name = self.titleTextField.text;
    
    if (![FileNameUtils isForbiddenCharactersInFileName:name withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport]]) {
        
        //Check if exist a file with the same name
        if (![self checkForSameName:name]) {
            
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
            
            NSString *remoteServerPath = [UtilsUrls getFullRemoteServerPath:app.activeUser];
            
            NSString *newURL = [NSString stringWithFormat:@"%@%@",remoteServerPath,[name encodeString:NSUTF8StringEncoding]];
            NSString *rootPath = [UtilsUrls getFilePathOnDBByFullPath:newURL andUser:app.activeUser];
            
            NSString *pathOfNewFolder = [NSString stringWithFormat:@"%@%@",[remoteServerPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], name ];

            [[AppDelegate sharedOCCommunication] createFolder:pathOfNewFolder onCommunication:[AppDelegate sharedOCCommunication] withForbiddenCharactersSupported:[ManageUsersDB hasTheServerOfTheActiveUserForbiddenCharactersSupport] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
                DLog(@"Folder created");
                BOOL isSamlCredentialsError = NO;
                
//                //Check the login error in shibboleth
//                if (k_is_sso_active && redirectedServer) {
//                    //Check if there are fragmens of saml in url, in this case there are a credential error
//                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
//                    if (isSamlCredentialsError) {
//                        [self errorLogin];
//                    }
//                }
//                if (!isSamlCredentialsError) {
//                    [self refreshTableFromWebDav];
//                }
            } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                DLog(@"error: %@", error);
                DLog(@"Operation error: %ld", (long)response.statusCode);
                
                BOOL isSamlCredentialsError = NO;
                
                //Check the login error in shibboleth
                if (k_is_sso_active && redirectedServer) {
                    //Check if there are fragmens of saml in url, in this case there are a credential error
                    isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
                    if (isSamlCredentialsError) {
                        [self errorLogin];
                    }
                }
                if (!isSamlCredentialsError) {
                    [self manageServerErrors:response.statusCode and:error];
                }
                
            } errorBeforeRequest:^(NSError *error) {
                if (error.code == OCErrorForbidenCharacters) {
                    [self endLoading];
                    DLog(@"The folder have problematic characters");
                    
                    NSString *msg = nil;
                    msg = NSLocalizedString(@"forbidden_characters_from_server", nil);
                    
                    _alert = [[UIAlertView alloc] initWithTitle:msg message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                    [_alert show];
                } else {
                    [self endLoading];
                    DLog(@"The folder have problems under controlled");
                    _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"unknow_response_server", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                    [_alert show];
                }
            }];
        }else {
            [self endLoading];
            DLog(@"Exist a folder with the same name");
            _alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"folder_exist", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [_alert show];
        }
        
    }else{
        [self endLoading];
        //Forbidden characters found after the request.
        NSString *msg = nil;
        msg = NSLocalizedString(@"forbidden_characters_from_server", nil);
        
        _alert = [[UIAlertView alloc] initWithTitle:msg message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [_alert show];
        
    }

}

-(void) errorLogin {

}

#pragma mark - Server connect methods

/*
 * Method called when receive a fail from server side
 * @errorCodeFromServer -> WebDav Server Error of NSURLResponse
 * @error -> NSError of NSURLConnection
 */

- (void)manageServerErrors: (NSInteger)errorCodeFromServer and:(NSError *)error {
    
//    [self stopPullRefresh];
//    [self endLoading];
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [_manageNetworkErrors manageErrorHttp:errorCodeFromServer andErrorConnection:error andUser:app.activeUser];
}

/*
 * Method that quit the loading screen and unblock the view
 */
- (void)endLoading {
    
//    if (!_isLoadingForNavigate) {
//        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//        //Check if the loading should be visible
//        if (app.isLoadingVisible==NO) {
//            // [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
//            [_HUD removeFromSuperview];
//            self.view.userInteractionEnabled = YES;
//            self.navigationController.navigationBar.userInteractionEnabled = YES;
//            self.tabBarController.tabBar.userInteractionEnabled = YES;
//            [self.view.window setUserInteractionEnabled:YES];
//        }
//        
//        //Check if the app is wainting to show the upload from other app view
//        if (app.isFileFromOtherAppWaitting && app.isPasscodeVisible == NO) {
//            [app performSelector:@selector(presentUploadFromOtherApp) withObject:nil afterDelay:0.3];
//        }
//        
//        if (!_rename.renameAlertView.isVisible) {
//            _rename = nil;
//        }
//    }
}

@end
