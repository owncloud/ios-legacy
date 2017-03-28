//
//  EditAccountViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/5/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "EditAccountViewController.h"
#import "UserDto.h"

#import "constants.h"
#import "AppDelegate.h"
#import "UIColor+Constants.h"
#import "Customization.h"
#import "ManageUsersDB.h"
#import "ManageUploadsDB.h"
#import "UtilsCookies.h"
#import "UtilsFramework.h"
#import "ManageCookiesStorageDB.h"
#import "CheckFeaturesSupported.h"
#import "CheckCapabilities.h"
#import "FilesViewController.h"
#import "UtilsUrls.h"
#import "OCKeychain.h"


//Initialization the notification
NSString *relaunchErrorCredentialFilesNotification = @"relaunchErrorCredentialFilesNotification";


@interface EditAccountViewController ()

@end

@implementation EditAccountViewController
@synthesize selectedUser = _selectedUser;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andUser:(UserDto *) selectedUser andLoginMode:(LoginMode)loginMode {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil andLoginMode:loginMode];
    if (self) {
        self.selectedUser = selectedUser;
        
        if(self.loginMode == LoginModeMigrate){
            self.auxUrlForReloadTable = k_default_url_server;
        } else {
            self.auxUrlForReloadTable = self.selectedUser.url;
        }
        self.auxUsernameForReloadTable = self.selectedUser.username;
        self.auxPasswordForReloadTable = self.selectedUser.password;
        
        urlEditable = NO;
        userNameEditable = NO;
        
        DLog(@"self.auxUrlForReloadTable: %@", self.auxUrlForReloadTable);
        
        isSSLAccepted = YES;
        isCheckingTheServerRightNow = YES;
        isConnectionToServer = NO;
        isNeedToCheckAgain = YES;
        
        
        // Custom initialization
        if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
            UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelClicked:)];
            
            self.navigationItem.leftBarButtonItem = cancelButton;
        }
    }
    return self;
}

- (void)setTableBackGroundColor {
    [self.tableView setBackgroundView: nil];
    [self.tableView setBackgroundColor:[UIColor colorOfLoginBackground]];
}

- (void)setBarForCancelForLoadingFromModal {
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeViewController)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
}

- (void)setBrandingNavigationBarWithCancelButton{
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self.navigationController.navigationBar setTintColor:[UIColor colorOfNavigationBar]];
    }else{
        [self.navigationController.navigationBar setTintColor:[UIColor colorOfNavigationBar]];
    }
    //If the client want his custom bar
    if(k_have_image_background_navigation_bar) {
        UIImage *imageBack = [UIImage imageNamed:@"topBar.png"];
        [self.navigationController.navigationBar setBackgroundImage:imageBack forBarMetrics:UIBarMetricsDefault];
    }
    
    [self setBarForCancelForLoadingFromModal];
}

- (void) closeViewController {
    
    
    [self dismissViewControllerAnimated:YES completion:nil];
    //[self dismissModalViewControllerAnimated:NO];
}

- (void)viewDidLoad
{    

    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void) viewDidAppear:(BOOL)animated {

   [self textFieldDidEndEditing:self.urlTextField];
    
    //Hide the show password button until the user write something
    showPasswordCharacterButton.hidden = YES;
    self.auxPasswordForShowPasswordOnEdit = self.selectedUser.password;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self restoreTheCookiesOfActiveUser];

    ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).delegate = nil;
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void) viewWillAppear:(BOOL)animated {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Clear the cookies before to try to do login
    //1- Storage the new cookies on the Database
    [UtilsCookies setOnDBStorageCookiesByUser:app.activeUser];
    //2- Clean the cookies storage
    [UtilsFramework deleteAllCookies];
    
    [super viewWillAppear:animated];
    
}


-(void)internazionaliceTheInitialInterface {
    self.loginButtonString = NSLocalizedString(@"save_changes", nil);
}

-(void)potraitViewiPad{
    
    DLog(@"Potrait iPad");
    
    [self addEditAccountsViewiPad];
}

-(void)landscapeViewiPad{
    
    DLog(@"Landscape iPad");
    
    [self addEditAccountsViewiPad];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up {
    
    if (textField==self.usernameTextField) {
        isUserTextUp=YES;
    }
    
    if (textField==self.passwordTextField) {
        isPasswordTextUp=YES;
    }
    
    
    NSIndexPath *scrollIndexPath = nil;
    
    if(k_hide_url_server) {
        
        if(textField == self.usernameTextField) {
            scrollIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        } else if(textField == self.passwordTextField) {
            scrollIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        }
    } else {
        
        if(textField == self.usernameTextField) {
            scrollIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
        } else if(textField == self.passwordTextField) {
            scrollIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
        }
    }
    
    DLog(@"Before the scroll To Row At IndexPath Medhod");
    
    
    [[self tableView] scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];

    
}


/*
 * Overwrite method of LoginViewController to check the username after continue the login process
 */
- (void)setCookieForSSO:(NSString *) cookieString andSamlUserName:(NSString*)samlUserName {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    NSString *connectURL =[NSString stringWithFormat:@"%@%@",app.activeUser.url,k_url_webdav_server];
    
    [ManageCookiesStorageDB deleteCookiesByUser:[ManageUsersDB getActiveUser]];
    [UtilsCookies eraseCredentialsWithURL:connectURL];
    [UtilsCookies eraseURLCache];
    
    //We check if the user that we are editing is the same that we are using
    if ([_selectedUser.username isEqualToString:samlUserName]) {
        
        _usernameTextField = [UITextField new];
        _usernameTextField.text = samlUserName;
        
        _passwordTextField = [UITextField new];
        _passwordTextField.text = cookieString;
        [self goTryToDoLogin];
    } else {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"credentials_different_user", nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alertView show];
    }
}

///-----------------------------------
/// @name Create data with server data
///-----------------------------------

/**
 * This method is called when the app receive the data of the login proffind
 *
 * @param items -> Items of the proffind
 * @param requestCode -> webdav server response
 *
 * @warning This method is overwrite of the parent class (LoginViewController) and it's present also in AddAcountViewController
 */
-(void)createUserAndDataInTheSystemWithRequest:(NSArray *)items andCode:(int) requestCode {
    
    //DLog(@"Request Did Fetch Directory Listing And Test Authetification");
    
    if(requestCode >= 400) {
        isError500 = YES;
        [self hideTryingToLogin];
        
        [self.tableView reloadData];
    } else {
        
        UserDto *userDtoEdited =[ManageUsersDB getUserByIdUser:self.selectedUser.idUser];
        
        //We check if start with http or https to concat it
        if([self.urlTextField.text hasPrefix:@"http://"] || [self.urlTextField.text hasPrefix:@"https://"]) {
            userDtoEdited.url = [self getUrlChecked: self.urlTextField.text];
            
        } else {
            if(isHttps) {
                userDtoEdited.url = [NSString stringWithFormat:@"%@%@",@"https://", [self getUrlChecked: self.urlTextField.text]];
            } else {
                userDtoEdited.url = [NSString stringWithFormat:@"%@%@",@"http://", [self getUrlChecked: self.urlTextField.text]];
            }
        }

        [self hideTryingToLogin];
        
        //TODO normalize username and password fields
        NSString *passwordUTF8=self.passwordTextField.text;
        
        //userDto.username = userNameUTF8;
        userDtoEdited.password = passwordUTF8;
        
        //Update parameters after a force url and credentials have not been renewed
        if (self.loginMode == LoginModeMigrate) {
            
            if (k_is_sso_active) {
                userDtoEdited.username = self.usernameTextField.text;
            }
            userDtoEdited.ssl = isHttps;
            userDtoEdited.urlRedirected = APP_DELEGATE.urlServerRedirected;
            userDtoEdited.predefinedUrl = k_default_url_server;
            
            [ManageUsersDB overrideAllUploadsWithNewURL:[UtilsUrls getFullRemoteServerPath:userDtoEdited]];
            
            [ManageUsersDB updateUserByUserDto:userDtoEdited];
        }
        
        //update keychain user
        if(![OCKeychain updateCredentialsById:[NSString stringWithFormat:@"%ld", (long)userDtoEdited.idUser] withUsername:userDtoEdited.username andPassword:userDtoEdited.password]) {
            DLog(@"Error updating credentials of userId:%ld on keychain",(long)userDtoEdited.idUser);
        }
        
        if (userDtoEdited.activeaccount) {
        
            //update current active DTO user
            APP_DELEGATE.activeUser = userDtoEdited;
            DLog(@"user predefined url:%@", APP_DELEGATE.activeUser.predefinedUrl);
            
            [UtilsCookies eraseCredentialsAndUrlCacheOfActiveUser];
            
            [CheckFeaturesSupported updateServerFeaturesAndCapabilitiesOfActiveUser];
        }
        
        //Change the state of user uploads with credential error
        [ManageUploadsDB updateErrorCredentialFiles:userDtoEdited.idUser];
        
        [self performSelector:@selector(restoreDownloadsAndUploads) withObject:nil afterDelay:5.0];
            
        [[NSNotificationCenter defaultCenter] postNotificationName:relaunchErrorCredentialFilesNotification object:_selectedUser];
        
        [[self navigationController] popViewControllerAnimated:YES];
       
        [self performSelector:@selector(closeViewController) withObject:nil afterDelay:0.5];
    }
}


- (void) restoreDownloadsAndUploads {
    //Cancel current uploads with the same user
    [APP_DELEGATE cancelTheCurrentUploadsOfTheUser:_selectedUser.idUser];
    [APP_DELEGATE.downloadManager cancelDownloadsAndRefreshInterface];
    [APP_DELEGATE launchProcessToSyncAllFavorites];
}

/*- (void)sendErrorCredentialFilesNotification{
    
    //Notification to indicate that shouled be relaunch the uploads with Credentials Error
    [[NSNotificationCenter defaultCenter] postNotificationName:relaunchErrorCredentialFilesNotification object:_selectedUser];
}*/



#pragma mark - Buttons
/*
 * This method close the view
 */
- (IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
