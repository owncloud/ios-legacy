//
//  AddAccountViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/2/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "AddAccountViewController.h"
#import "UserDto.h"

#import "UIColor+Constants.h"
#import "constants.h"
#import "Customization.h"
#import "ManageUsersDB.h"
#import "UtilsCookies.h"
#import "UtilsFramework.h"
#import "AppDelegate.h"
#import "ManageCookiesStorageDB.h"
#import "ManageAppSettingsDB.h"

@interface AddAccountViewController ()

@end

@implementation AddAccountViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil andLoginMode:LoginModeCreate];
    if (self) {
        // Custom initialization
       if (!IS_IPHONE) {
            UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelClicked:)];
            self.navigationItem.leftBarButtonItem = cancelButton;
        }
        
    }
    return self;
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


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self restoreTheCookiesOfActiveUser];
    
    ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).delegate = nil;
}


-(void)potraitViewiPad{
    
    DLog(@"Vertical iPad");

    [self addEditAccountsViewiPad];
}

-(void)landscapeViewiPad{
    
    DLog(@"Horizontal iPad");

    [self addEditAccountsViewiPad];
}


///-----------------------------------
/// @name Create data with server data
///-----------------------------------

/**
 * This method is called when the app receive the data of the login proffind
 *
 * @param items -> items of the proffind
 * @param requestCode -> webdav server response
 *
 * @warning This method is overwrite of the parent class (LoginViewController) and it's present also in EditViewController
 */
-(void)createUserAndDataInTheSystemWithRequest:(NSArray *)items andCode:(int) requestCode{
    
    //DLog(@"Request Did Fetch Directory Listing And Test Authetification");
    
    if(requestCode >= 400) {
        isError500 = YES;
        [self hideTryingToLogin];
        
        [self.tableView reloadData];
    } else {
        
        UserDto *userDto = [[UserDto alloc] init];
        
        //We check if start with http or https to concat it
        if([self.urlTextField.text hasPrefix:@"http://"] || [self.urlTextField.text hasPrefix:@"https://"]) {
            userDto.url = [self getUrlChecked: self.urlTextField.text];
            
        } else {
            if(isHttps) {
                userDto.url = [NSString stringWithFormat:@"%@%@",@"https://", [self getUrlChecked: self.urlTextField.text]];
            } else {
                userDto.url = [NSString stringWithFormat:@"%@%@",@"http://", [self getUrlChecked: self.urlTextField.text]];
            }
        }
        
        //DLog(@"URL FINAL: %@", userDto.url);
        
        NSString *userNameUTF8=self.usernameTextField.text;
        NSString *passwordUTF8=self.passwordTextField.text;
        //TODO with UTF8 the % crash on password...
        //userNameUTF8 = [userNameUTF8 stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
        //passwordUTF8 = [passwordUTF8 stringByReplacingPercentEscapesUsingEncoding:(NSStringEncoding)NSUTF8StringEncoding];
        
        userDto.username = userNameUTF8;
        userDto.password = passwordUTF8;
        userDto.ssl = isHttps;
        userDto.activeaccount = NO;
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        userDto.urlRedirected = app.urlServerRedirected;
        userDto.predefinedUrl = k_default_url_server;
        
        [self hideTryingToLogin];
        
        if([ManageUsersDB isExistUser:userDto]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"user_exist", nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alertView show];
            
            //1- Clean the cookies after login or not before go with the active user
            [UtilsFramework deleteAllCookies];

            //2- Storage the active account cookies on the Cookies System Storage
            [UtilsCookies setOnSystemStorageCookiesByUser:app.activeUser];
            //3- We delete the cookies of the active user on the databse because it could change and it is not necessary keep them there
            [ManageCookiesStorageDB deleteCookiesByUser:app.activeUser];
            
        } else {
            [ManageUsersDB insertUser:userDto];
            
            [ManageAppSettingsDB updateInstantUploadAllUser];
            
            //Return the cookies to the previous user
            userDto = [ManageUsersDB getLastUserInserted];
            
            //Storage the new cookies on the Database
            [UtilsCookies setOnDBStorageCookiesByUser:userDto];
            [self restoreTheCookiesOfActiveUser];
            
            if (!IS_IPHONE) {
                [_delegate refreshTable];
                [self cancelClicked:nil];
            } else {
                [[self navigationController] popViewControllerAnimated:YES];
            }
        }
    }
}



#pragma mark - Buttons
/*
 * This method close the view
 */
- (IBAction)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
