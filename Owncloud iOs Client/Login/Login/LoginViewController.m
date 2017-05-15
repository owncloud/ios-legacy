//
//  LoginViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/8/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "UserDto.h"
#import "MBProgressHUD.h"
#import "FilesViewController.h"
#import "SettingsViewController.h"
#import "RecentViewController.h"
#import "CheckAccessToServer.h"
#import "constants.h"
#import "AccountCell.h"
#import "constants.h"
#import "UIColor+Constants.h"
#import "Customization.h"
#import "ManageUsersDB.h"
#import "ManageFilesDB.h"
#import "FileNameUtils.h"
#import "OCNavigationController.h"
#import "OCTabBarController.h"
#import "UtilsDtos.h"
#import "UtilsUrls.h"
#import "OCCommunication.h"
#import "OCErrorMsg.h"
#import "UtilsFramework.h"
#import "UtilsCookies.h"
#import "ManageCookiesStorageDB.h"

#define k_http_prefix @"http://"
#define k_https_prefix @"https://"

#define k_remove_to_suffix @"/index.php"
#define k_remove_to_contains_path @"/index.php/apps/"

NSString *loginViewControllerRotate = @"loginViewControllerRotate";

@interface LoginViewController ()

@end


@implementation LoginViewController

- (id)initWithLoginMode:(LoginMode)loginMode {
    
    NSString *nibName = nil;
    NSBundle *bundle = nil;
    
    if (IS_IPHONE) {
        nibName = @"LoginViewController_iPhone";
    } else {
         nibName = @"LoginViewController_iPad";
    }
    
    self = [self initWithNibName:nibName bundle:bundle andLoginMode:(LoginMode)loginMode];
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andLoginMode:(LoginMode)loginMode {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _loginMode = loginMode;
        self.auxUrlForReloadTable = k_default_url_server;
        self.auxUsernameForReloadTable = @"";
        self.auxPasswordForReloadTable = @"";
        
        if (_loginMode==LoginModeExpire){
            isErrorOnCredentials = YES;
        } else {
            isErrorOnCredentials = NO;
        }
        
        if (_loginMode == LoginModeCreate || _loginMode == LoginModeMigrate) {
            urlEditable = YES;
        } else {
            urlEditable = NO;
        }
        
        if (loginMode == LoginModeCreate || loginMode == LoginModeMigrate) {
            userNameEditable = YES;
        } else {
            userNameEditable = NO;
        }
        
        isSSLAccepted = YES;
        isError500 = NO;
        isCheckingTheServerRightNow = NO;
        isConnectionToServer = NO;
        isNeedToCheckAgain = YES;
        hasInvalidAuth = NO;
        isHttpsSecure = NO;
        self.alreadyHaveValidSAMLCredentials = NO;
        
        showPasswordCharacterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [showPasswordCharacterButton setHidden:YES];
        
        //We init the ManageNetworkErrors
        if (!self.manageNetworkErrors) {
            self.manageNetworkErrors = [ManageNetworkErrors new];
            self.manageNetworkErrors.delegate = self;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTableBackGroundColor];
    
    //Set background company color like a comanyImageColor
    [_backCompanyView setBackgroundColor:[UIColor colorOfLoginTopBackground]];
    
    //Set background color of company image v
    [logoImageView setBackgroundColor:[UIColor colorOfLoginTopBackground]];
    
    //Configure view for interface position
    [self configureViewForInterfacePosition];
    
    isLoginButtonEnabled = NO;
    
    //Keyboard hidding after write url, name and password
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:
     UIKeyboardWillShowNotification object:nil];
    
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:
     UIKeyboardWillHideNotification object:nil];
    
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAnywhere:)];
    
    isUserTextUp = NO;
    isPasswordTextUp = NO;

}

-(void) viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if(![self.auxUrlForReloadTable isEqualToString:@""] && !self.alreadyHaveValidSAMLCredentials) {
        DLog(@"1- self.auxUrlForReloadTable: %@",self.auxUrlForReloadTable);
        [self checkUrlManually];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).delegate = self;
    
    
    if (self.urlTextField.text.length > 0 && (!isConnectionToServer) && !self.alreadyHaveValidSAMLCredentials) {
        DLog(@"_login view appear and no connection to server and no valid SAML credentials auto recheck server manually_");
        [self checkUrlManually];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    //Cleaning boolean for next connections
    self.alreadyHaveValidSAMLCredentials = NO;
}

- (void)setTableBackGroundColor {
    [self.tableView setBackgroundView: nil];
    [self.tableView setBackgroundColor:[UIColor colorOfLoginBackground]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    //return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
    return YES;
}

//Only for ios 6
- (BOOL)shouldAutorotate {
    
    return YES;
}

//For one of the next user story
-(UIStatusBarStyle)preferredStatusBarStyle {
    
    if (k_is_text_login_status_bar_white) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Draw Position

///-----------------------------------
/// @name Configure View for Interface Position
///-----------------------------------

/**
 * This method get the current interface position and call the
 * specific method to configure the view for the current position
 *
 * There are direrents configurations depends of the device:
 * iPhone 3.5"
 * iPhone 4"
 * iPad
 *
 * @discussion In this method we could use the toInterfaceOrientation object of the 
 *  willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration method, but
 * the "toInterfaceOrientation" gets in iPad in iOS 7 is wrong.
 *
 */
-(void)configureViewForInterfacePosition{
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            if (IS_IPHONE) {
                [self potraitViewiPhone];
            } else {
                [self potraitViewiPad];
            }
            
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            if (IS_IPHONE) {
                if ([UIScreen mainScreen].bounds.size.height<=480.0) {
                    //3.5" screen
                    [self landscapeViewiPhone];
                } else {
                    //4" screen
                    [self landscapeViewiPhone5];
                }
            } else {
                //iPad landscape
                [self landscapeViewiPad];
            }
            
            break;
            
        default:
            if (IS_IPHONE) {
                [self potraitViewiPhone];
            } else {
                [self potraitViewiPad];
            }
            
            break;
    }
}

-(void) potraitViewiPhone {
    
    DLog(@"Vertical iPhone");
    
    //to set the scroll
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 260, 0);
    
//FIRST SECTION
    
    //Frame for url field
     _urlFrame = CGRectMake(60,14,200,20);
    
    //Server image - User image - Password image
    _imageTextFieldLeftFrame = CGRectMake(20.0, 10.0, 25.0, 25.0);
    
    //Refresh button
    refreshButtonFrame = CGRectMake(260.0, 10.0, 25.0, 25.0);
    
    
    
//FOOTER FOR FIRST SECTION
    
    //Frame used for Loading icon, secure or not secure connection
    lockImageFrame = CGRectMake(20.0, 5.0, 25.0, 25.0);
    
    //Frame used for information message under the url field
    textFooterFrame1 = CGRectMake((lockImageFrame.origin.x + lockImageFrame.size.width + 15), 7.0, (self.view.frame.size.width - ((lockImageFrame.origin.x + lockImageFrame.size.width) * 2)), 25.0);
    
    
//SECOND SECTION
    
    //user and password text fields frame
    _userAndPasswordFrame = CGRectMake(60,14,200,20);
    
    //image about show/hide the password
    showPasswordButtonFrame = CGRectMake(260.0, 10.0, 25.0, 25.0);
    

//FOOTER FOR SECOND SECTION
    
    //Frame for uiview that contains image and text
    footerSection1Frame = CGRectMake(0, 0, 320, 40);
    
    //Error image for bad credentials
    okNokImageFrameFooter = CGRectMake(20.0, 7.5, 25.0, 25.0);
    
    //Test with information about the problem
    textFooterFrame2 = CGRectMake((okNokImageFrameFooter.origin.x + okNokImageFrameFooter.size.width + 15), 0, (self.view.frame.size.width - ((okNokImageFrameFooter.origin.x + okNokImageFrameFooter.size.width) * 2)), 40.0);
    

    
//HEADER OF THE TABLE WHEN THE ARE NOT URL FRAME
    
    //Frame used for add the information under the url field
    _txtWithLogoWhenNoURLFrame = CGRectMake(0,0,320,90);
    
    //Frame used for reconection icon
    syncImageFrameForNoURL = CGRectMake(280.0, 5.0, 25.0, 25.0);


    
}

-(void) addEditAccountsViewiPad {
    
    DLog(@"Vertical iPhone");
    
    //to set the scroll
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 260, 0);
    
    //FIRST SECTION
    
    //Frame for url field
    _urlFrame = CGRectMake(60,14,420,20);
    
    //Server image - User image - Password image
    _imageTextFieldLeftFrame = CGRectMake(20.0, 10.0, 25.0, 25.0);
    
    //Refresh button
    refreshButtonFrame = CGRectMake(480.0, 10.0, 25.0, 25.0);
    
    
    
    //FOOTER FOR FIRST SECTION
    
    //Frame used for Loading icon, secure or not secure connection
    lockImageFrame = CGRectMake(20.0, 5.0, 25.0, 25.0);
    
    //Frame used for information message under the url field
    textFooterFrame1 = CGRectMake((lockImageFrame.origin.x + lockImageFrame.size.width + 15), 7.0, (self.view.frame.size.width - ((lockImageFrame.origin.x + lockImageFrame.size.width) * 2)), 25.0);
    
    
    //SECOND SECTION
    
    //user and password text fields frame
    _userAndPasswordFrame = CGRectMake(60 ,14,420,20);
    
    //image about show/hide the password
    showPasswordButtonFrame = CGRectMake(480.0, 10.0, 25.0, 25.0);
    
    
    //FOOTER FOR SECOND SECTION
    
    //Frame for uiview that contains image and text
    footerSection1Frame = CGRectMake(0, 0, 320, 40);
    
    //Error image for bad credentials
    okNokImageFrameFooter = CGRectMake(20.0, 7.5, 25.0, 25.0);
    
    //Test with information about the problem
    textFooterFrame2 = CGRectMake((okNokImageFrameFooter.origin.x + okNokImageFrameFooter.size.width + 15), 0, (self.view.frame.size.width - ((okNokImageFrameFooter.origin.x + okNokImageFrameFooter.size.width) * 2)), 40.0);
    
    
    
    //HEADER OF THE TABLE WHEN THE ARE NOT URL FRAME
    
    //Frame used for add the information under the url field
    _txtWithLogoWhenNoURLFrame = CGRectMake(0,0,320,90);
    
    //Frame used for reconection icon
    syncImageFrameForNoURL = CGRectMake(280.0, 5.0, 25.0, 25.0);
    
    
    
}

-(void)landscapeViewiPhone{
    
    DLog(@"Horizontal iPhone");

    //to set the scroll
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 170, 0);
    
    
//FIRST SECTION
    
    //Frame for url field
    _urlFrame = CGRectMake(60,14,340,20);
    
    //Server image - User image - Password image
     _imageTextFieldLeftFrame = CGRectMake(20.0, 10.0, 25.0, 25.0);
    
    //Refresh button
    refreshButtonFrame = CGRectMake(420.0, 10.0, 25.0, 25.0);
    
    
//FOOTER FOR FIRST SECTION
    
    //Frame used for Loading icon, secure or not secure connection
    lockImageFrame = CGRectMake(20.0, 5.0, 25.0, 25.0);
    
    //Frame used for information message under the url field
    textFooterFrame1 = CGRectMake((lockImageFrame.origin.x + lockImageFrame.size.width + 15), 5.0, (self.view.frame.size.width - (lockImageFrame.origin.x + lockImageFrame.size.width + 10)), 25.0);
    
    
//SECOND SECTION
    
    //user and password text fields frame
    _userAndPasswordFrame = CGRectMake(60,14,340,20);
    
    //image about show/hide the password
    showPasswordButtonFrame = CGRectMake(420.0, 10.0, 25.0, 25.0);
    

//FOOTER FOR SECOND SECTION
    
    //Frame for uiview that contains image and text
    footerSection1Frame = CGRectMake(0, 0, 480, 40);
    
    //Error image for bad credentials
    okNokImageFrameFooter = CGRectMake(20.0, 7.5, 25.0, 25.0);
    
    //Test with information about the problem
    textFooterFrame2 = CGRectMake((okNokImageFrameFooter.origin.x + okNokImageFrameFooter.size.width + 15), 0.0, 280.0, 40.0);
    
    
//HEADER OF THE TABLE WHEN THE ARE NOT URL FRAME
    
    //Frame used for add the information under the url field
    _txtWithLogoWhenNoURLFrame = CGRectMake(0,0,480,90);
    
    //Frame used for reconection icon
    syncImageFrameForNoURL = CGRectMake(420.0, 5.0, 25.0, 25.0);

   
}

-(void)landscapeViewiPhone5{
    
    DLog(@"Horizontal iPhone 5");
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 170, 0);
    
    
//FIRST SECTION
    
    //Frame for url field
    _urlFrame = CGRectMake(60,14,430,20);
    
    //Server image - User image - Password image
    _imageTextFieldLeftFrame = CGRectMake(20.0, 10.0, 25.0, 25.0);
    
    //Refresh button
    refreshButtonFrame = CGRectMake(510.0, 10.0, 25.0, 25.0);
    

//FOOTER FOR FIRST SECTION
    
    //Frame used for Loading icon, secure or not secure connection
    lockImageFrame = CGRectMake(20.0, 5.0, 25.0, 25.0);
    
    //Frame used for information message under the url field
    textFooterFrame1 = CGRectMake((lockImageFrame.origin.x + lockImageFrame.size.width + 15), 5.0, (self.view.frame.size.width - (lockImageFrame.origin.x + lockImageFrame.size.width + 10)), 25.0);
    
    
    
//SECOND SECTION
    
    //user and password text fields frame
    _userAndPasswordFrame = CGRectMake(60,14,430,20);
    
    //image about show/hide the password
    showPasswordButtonFrame = CGRectMake(510.0, 10.0, 25.0, 25.0);
    

//FOOTER FOR SECOND SECTION
    
    //Frame for uiview that contains image and text
    footerSection1Frame = CGRectMake(0, 0, 568, 40);
    
    //Error image for bad credentials
    okNokImageFrameFooter = CGRectMake(20.0, 7.5, 25.0, 25.0);
    
    //Test with information about the problem
    textFooterFrame2 = CGRectMake((okNokImageFrameFooter.origin.x + okNokImageFrameFooter.size.width + 15), 0.0, 280.0, 40.0);
    
    
    
//HEADER OF THE TABLE WHEN THE ARE NOT URL FRAME
    
    //Frame used for add the information under the url field
    _txtWithLogoWhenNoURLFrame = CGRectMake(0,0,568,90);
    
    //Frame used for reconection icon
    syncImageFrameForNoURL = CGRectMake(510.0, 5.0, 25.0, 25.0);
    
    
}

-(void)potraitViewiPad{
    
    DLog(@"Vertical iPad");

    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundView:[[UIView alloc] init]];
    
    
//FIRST SECTION
    
    //Frame for url field
    _urlFrame = CGRectMake(280,14,420,20);
    
    //Server image - User image - Password image
    _imageTextFieldLeftFrame = CGRectMake(235.0, 10.0, 25.0, 25.0);
    
    //Refresh button
    refreshButtonFrame = CGRectMake(680.0, 10.0, 25.0, 25.0);
    
    
//FOOTER FOR FIRST SECTION
    
    //Frame used for Loading icon, secure or not secure connection
    lockImageFrame = CGRectMake(235.0, 5.0, 25.0, 25.0);
    
    //Frame used for information message under the url field
    textFooterFrame1 = CGRectMake(280.0, 7.0, 300.0, 25.0);
    
    
//SECOND SECTION
    
    //user and password text fields frame
    _userAndPasswordFrame = CGRectMake(280,14,220,20);
    
    //image about show/hide the password
    showPasswordButtonFrame = CGRectMake(500.0, 10.0, 25.0, 25.0);
    
    
//FOOTER FOR SECOND SECTION
    
    //Frame for uiview that contains image and text
    footerSection1Frame = CGRectMake(0, 0, 685, 40);
    
    //Error image for bad credentials
    okNokImageFrameFooter = CGRectMake(235.0, 7.5, 25.0, 25.0);
    
    //Test with information about the problem
    textFooterFrame2 = CGRectMake(280, 0.0, 300.0, 40.0);
    
    
//HEADER OF THE TABLE WHEN THE ARE NOT URL FRAME
    
    //Frame used for add the information under the url field
     _txtWithLogoWhenNoURLFrame = CGRectMake(0,0,768,195);
    
    //Frame used for reconection icon when there are not url frame
    syncImageFrameForNoURL = CGRectMake(500.0, 5.0, 25.0, 25.0);

    
    
}

-(void)landscapeViewiPad{
    
    DLog(@"Horizontal iPad");
    
    //to set the scroll
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 500, 0);
    
    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundView:[[UIView alloc] init]];
    
    
//FIRST SECTION
    
    //Frame for url field
    _urlFrame = CGRectMake(408.0,14,420,20);
    
    //Server image - User image - Password image
    _imageTextFieldLeftFrame = CGRectMake(368.0, 10.0, 25.0, 25.0);
    
    //Refresh button
    refreshButtonFrame = CGRectMake(828.0 , 10.0, 25.0, 25.0);
    
    
//FOOTER FOR FIRST SECTION
    
    //Frame used for Loading icon, secure or not secure connection
    lockImageFrame = CGRectMake(368.0, 5.0, 25.0, 25.0);
    
    //Frame used for information message under the url field
    textFooterFrame1 = CGRectMake(408.0, 7.0, 300.0, 25.0);
    
    
    
//SECOND SECTION
    
    //user and password text fields frame
    _userAndPasswordFrame = CGRectMake(408,14,220,20);
    
    
    //image about show/hide the password
    showPasswordButtonFrame = CGRectMake(628.0, 10.0, 25.0, 25.0);
    
    
//FOOTER FOR SECOND SECTION
    
    //Frame for uiview that contains image and text
    footerSection1Frame = CGRectMake(0, 0, 785, 40);
    
    //Error image for bad credentials
    okNokImageFrameFooter = CGRectMake(368.0, 7.5, 25.0, 25.0);
    
    
    //Test with information about the problem
    textFooterFrame2 = CGRectMake(408, 0.0, 300.0, 40.0);
    
    
    
//HEADER OF THE TABLE WHEN THE ARE NOT URL FRAME
    
    //Frame used for add the information under the url field
    _txtWithLogoWhenNoURLFrame = CGRectMake(0,0,1024,195);
    
    //Frame used for reconection icon when there are not url frame
    syncImageFrameForNoURL = CGRectMake(628.0, 5.0, 25.0, 25.0);
    

    
}

//Only for ios 6
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    //Configure View For interface position
    [self configureViewForInterfacePosition];
    [self.tableView reloadData];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    //Send a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: loginViewControllerRotate object: nil];
}

//Only for ios6
- (NSUInteger)supportedInterfaceOrientations {
    if (IS_IPHONE) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }else{
        return UIInterfaceOrientationMaskAll;
    }
}

#pragma mark - UITableView datasource

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(k_hide_url_server) {
        return 2;
    } else {
        return 3;
    }
    
    
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger n = 0;
    
    if(k_hide_url_server) {
        if(k_is_oauth_active || k_is_sso_active) {
            if (section==0) {
                n=0;
            } else if (section==1) {
                if (k_is_shown_help_link_on_login) {
                    n=2;
                } else {
                    n=1;
                }
            }
        } else {
            if (section==0) {
                n=2;
            } else if (section==1) {
                if (k_is_shown_help_link_on_login) {
                    n=2;
                } else {
                    n=1;
                }
            }
        }
    } else {
        if(k_is_oauth_active || k_is_sso_active) {
            if (section==0) {
                n=1;
            } else if (section==1) {
                if (k_is_shown_help_link_on_login) {
                    n=2;
                } else {
                    n=1;
                }
            } else if (section==2) {
                n=0;
            }
        } else {
            if (section==0) {
                n=1;
            } else if (section==1) {
                n=2;
            } else if (section==2) {
                if (k_is_shown_help_link_on_login) {
                    n=2;
                } else {
                    n=1;
                }
            }
        }
    }
    return n;
}


// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"AccountCell";
    
    AccountCell *cell = (AccountCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		
		NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"AccountCell" owner:self options:nil];
		
		for (id currentObject in topLevelObjects){
			if ([currentObject isKindOfClass:[UITableViewCell class]]){
				cell =  (AccountCell *) currentObject;
				break;
			}
		}
	}
    
    UIFont *cellBoldFont = [UIFont boldSystemFontOfSize:16.0];
    cell.textLabel.font=cellBoldFont;
    
    if (indexPath.section==0) {
        
        if(k_hide_url_server) {
            if(k_is_oauth_active || k_is_sso_active) {
                switch (indexPath.row) {
                    case 0:
                        cell = [self configureCellToLoginByAccountCell:cell];
                        
                        //we configure too the server url
                        self.urlTextField = [[UITextField alloc]initWithFrame:_urlFrame];
                        self.urlTextField.delegate = self;
                        DLog(@"5- self.auxUrlForReloadTable: %@", self.auxUrlForReloadTable);
                        self.urlTextField.text = self.auxUrlForReloadTable;
                        
                        break;
                    case  1:
                        cell =  [self configureCellToShowLinkByAccountCell:cell];
                        
                        break;
                        
                    default:
                        break;
                }
            } else {
                switch (indexPath.row) {
                    case 0:
                        cell = [self configureCellToUsernameByAccountCell:cell];
                        
                        break;
                    case 1:
                        cell = [self configureCellToPasswordByAccountCell:cell];
                        
                        break;
                        
                    default:
                        break;
                }
            }
        } else {
            switch (indexPath.row) {
                case 0:
                    cell = [self configureCellToURLServerByAccountCell:cell];
                    break;
                    
                default:
                    break;
            }
        }
        
    }else if (indexPath.section==1) {
        
        if(k_hide_url_server) {
                switch (indexPath.row) {
                    case 0:
                        cell = [self configureCellToLoginByAccountCell:cell];
                        
                        //we configure too the server url
                        self.urlTextField = [[UITextField alloc]initWithFrame:_urlFrame];
                        self.urlTextField.delegate = self;
                        DLog(@"4- self.auxUrlForReloadTable: %@", self.auxUrlForReloadTable);
                        self.urlTextField.text = self.auxUrlForReloadTable;
                        
                        break;
                        
                    case  1:
                        cell =  [self configureCellToShowLinkByAccountCell:cell];
                        
                        break;
                        
                    default:
                        break;
                }
        } else {
            if(k_is_oauth_active || k_is_sso_active) {
                switch (indexPath.row) {
                    case 0:
                        cell = [self configureCellToLoginByAccountCell:cell];
                        
                        break;
                        
                    case  1:
                        cell =  [self configureCellToShowLinkByAccountCell:cell];
                        
                        break;
                        
                    default:
                        break;
                }
            } else {
                switch (indexPath.row) {
                    case 0:
                        cell = [self configureCellToUsernameByAccountCell:cell];
                        
                        break;
                    case 1:
                        cell = [self configureCellToPasswordByAccountCell:cell];
                        
                        break;
                        
                    default:
                        break;
                }
            }
        }
    } else if (indexPath.section==2) {
        
        switch (indexPath.row) {
            case 0:
                cell = [self configureCellToLoginByAccountCell:cell];
                
                break;
                
            case  1:
                cell =  [self configureCellToShowLinkByAccountCell:cell];
                
                break;
            default:
                break;
        }
    }
    return cell;
}

#pragma mark - Configure cells

-(AccountCell *) configureCellToURLServerByAccountCell:(AccountCell *) cell {

    cell.textLabel.textColor = [UIColor colorWithRed:0/256.0f green:0/256.0f blue:0/256.0f alpha:1];
    
    UIImageView *iconLeftImage= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"server.png"]];
    [iconLeftImage setFrame:_imageTextFieldLeftFrame];
    
    self.urlTextField = [[UITextField alloc]initWithFrame:_urlFrame];
    self.urlTextField.delegate = self;
    [self.urlTextField setKeyboardType:UIKeyboardTypeURL];
    [self.urlTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    
    [self.urlTextField setClearButtonMode:UITextFieldViewModeNever];
    //searchField.borderStyle= UITextBorderStyleRoundedRect;
    self.urlTextField.borderStyle= UITextBorderStyleNone;
    //searchField.background=img;
    [self.urlTextField setReturnKeyType:UIReturnKeyDone];
    [self.urlTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    self.urlTextField.textAlignment = NSTextAlignmentLeft;
    self.urlTextField.font = [UIFont boldSystemFontOfSize:14.0];
    self.urlTextField.textColor = [UIColor colorOfURLUserPassword];
    self.urlTextField.placeholder = NSLocalizedString(@"url_sample", nil);
    
    if(!urlEditable) {
        [self.urlTextField setEnabled:NO];
    }
    
    DLog(@"2- self.auxUrlForReloadTable: %@", self.auxUrlForReloadTable);
    
    self.urlTextField.text = self.auxUrlForReloadTable;
    
    refreshTestServerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [refreshTestServerButton addTarget:self action:@selector(checkUrlManually) forControlEvents:UIControlEventTouchUpInside];
    [refreshTestServerButton setFrame:refreshButtonFrame];
    [refreshTestServerButton setBackgroundImage:[UIImage imageNamed:@"ReconnectIcon.png"] forState:UIControlStateNormal];
    
    if(([self.urlTextField.text length] > 0) && !isConnectionToServer && !isCheckingTheServerRightNow) {
        [refreshTestServerButton setHidden:NO];
    } else {
        [refreshTestServerButton setHidden:YES];
    }
    
    [cell.contentView addSubview:iconLeftImage];
    [cell.contentView addSubview:self.urlTextField];
    [cell.contentView addSubview:refreshTestServerButton];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

-(AccountCell *) configureCellToUsernameByAccountCell:(AccountCell *) cell {
    
    cell.textLabel.textColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:1];
    
    UIImageView *iconLeftImage= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"user.png"]];
    [iconLeftImage setFrame:_imageTextFieldLeftFrame];
    
    self.usernameTextField = [[UITextField alloc]initWithFrame:_userAndPasswordFrame];
    self.usernameTextField.delegate = self;
    
    
    [self.usernameTextField setClearButtonMode:UITextFieldViewModeNever];
    //searchField.borderStyle= UITextBorderStyleRoundedRect;
    self.usernameTextField.borderStyle= UITextBorderStyleNone;
    //searchField.background=img;
    [self.usernameTextField setReturnKeyType:UIReturnKeyDone];
    [self.usernameTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.usernameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    
    self.usernameTextField.textAlignment = NSTextAlignmentLeft;
    self.usernameTextField.font = [UIFont boldSystemFontOfSize:14.0];
    self.usernameTextField.textColor = [UIColor colorOfURLUserPassword];
    self.usernameTextField.placeholder = NSLocalizedString(@"username", nil);
    self.usernameTextField.text = self.auxUsernameForReloadTable;
    
    [self.usernameTextField addTarget:self action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
    
    if(!userNameEditable) {
        [self.usernameTextField setEnabled:NO];
    }
    
    [cell.contentView addSubview:iconLeftImage];
    [cell.contentView addSubview:self.usernameTextField];
    
    //Separator (Not works in iOS 7 in iPad)
    if (IS_IPHONE) {
        UIView *separator = [UIView new];
        separator.backgroundColor = [UIColor lightGrayColor];
        separator.frame = CGRectMake(0, cell.contentView.frame.size.height - 0.5, cell.contentView.frame.size.width, 0.5);
        separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [cell.contentView addSubview:separator];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

-(AccountCell *) configureCellToPasswordByAccountCell:(AccountCell *) cell {
    
    cell.textLabel.textColor = [UIColor colorWithRed:0/256.0f green:0/256.0f blue:0/256.0f alpha:1];
    
    UIImageView *iconLeftImage= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"password.png"]];
    [iconLeftImage setFrame:_imageTextFieldLeftFrame];
    
    self.passwordTextField = [[UITextField alloc]initWithFrame:_userAndPasswordFrame];
    self.passwordTextField.textColor = [UIColor colorOfURLUserPassword];
    self.passwordTextField.delegate = self;
    [self.passwordTextField setSecureTextEntry:YES];
    
    [self.passwordTextField setClearButtonMode:UITextFieldViewModeNever];
    //searchField.borderStyle= UITextBorderStyleRoundedRect;
    self.passwordTextField.borderStyle= UITextBorderStyleNone;
    //searchField.background=img;
    [self.passwordTextField setReturnKeyType:UIReturnKeyDone];
    [self.passwordTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.passwordTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    
    self.passwordTextField.textAlignment = NSTextAlignmentLeft;
    self.passwordTextField.font = [UIFont boldSystemFontOfSize:14.0];
    self.passwordTextField.placeholder = NSLocalizedString(@"password", nil);
    self.passwordTextField.text = self.auxPasswordForReloadTable;
    
    [showPasswordCharacterButton addTarget:self action:@selector(hideOrShowPassword) forControlEvents:UIControlEventTouchUpInside];
    [showPasswordCharacterButton setFrame:showPasswordButtonFrame];
    
    [showPasswordCharacterButton setBackgroundImage:[UIImage imageNamed:@"RevealPasswordIcon.png"] forState:UIControlStateNormal];
    
    [cell.contentView addSubview:iconLeftImage];
    [cell.contentView addSubview:self.passwordTextField];
    [cell.contentView addSubview:showPasswordCharacterButton];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    return cell;
}

-(AccountCell *) configureCellToLoginByAccountCell:(AccountCell *) cell {
    
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text= NSLocalizedString(@"login", nil);
    cell.textLabel.textColor = [UIColor colorOfLoginButtonTextColor];
  //  cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradImage.png"]];
    cell.backgroundColor = [UIColor colorOfLoginButtonBackground];
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    if(!isLoginButtonEnabled) {
        // Mac's native DigitalColor Meter reads exactly {R:143, G:143, B:143}.
        cell.textLabel.alpha = 0.439216f; // (1 - alpha) * 255 = 143
        
        cell.userInteractionEnabled = NO;
    }
    return cell;
}

-(AccountCell *) configureCellToShowLinkByAccountCell:(AccountCell *) cell {
    
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    cell.textLabel.text = [NSLocalizedString(@"help_link_login", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName];
    cell.textLabel.textColor = [UIColor colorOfLoginText];
    cell.backgroundColor = [UIColor clearColor];
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;

    return cell;
}

-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
    if (section==0) {
        if(k_hide_url_server) {
            return 40.0;
        } else {
            return 35.0;
        }
    }else if (section==1){
        return 40;
    } else {
        return 0;
    }
    
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0) {
        if(k_hide_url_server) {
            return 35.0;
        } else {
            return 15.0;
        }
    } else {
        return 1;
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    if(section == 0) {
        if(k_hide_url_server) {
            UIView *textView = [self configureViewForFooterURLServer];
            [textView setFrame:_txtWithLogoWhenNoURLFrame];
            
            UIView *headerView = [[UIView alloc] init];
            
            //[headerView addSubview:logoImageView];
            [headerView addSubview:textView];
            
            return headerView;
        } else {
          //  UIView *headerView = [[UIView alloc] init];
           // [headerView addSubview:logoImageView];
            
            return nil;
        }
    } else {
        return nil;
    }
}


#pragma mark - UITableView delegate


// Tells the delegate that the specified row is now selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DLog(@"cell tapped number: %ld, in section:%ld", (long)indexPath.row, (long)indexPath.section);
    
    //check if the constant k_hide_url_server is Yes or Not, depend of the branding
    if(k_hide_url_server) {
        //hide url
        if (indexPath.section==1) {
            
            switch (indexPath.row) {
                case 0:
                    //in oaut or saml is the login button
                    if(k_is_oauth_active) {
                        [self oAuthScreen];
                    } else if (k_is_sso_active) {
                        [self checkURLServerForSSO];
                    } else {
                        //login button
                        [self goTryToDoLogin];
                    }
                    break;
                  
                case 1:
                    //login button
                    [self showHelpURLInSafari];
                    break;
                    
                default:
                    break;
            }
        }
    } else {
        //show url
        switch (indexPath.section) {
            case 0:
                //Nothing, is the url field
                break;
                
            case 1:
                switch (indexPath.row) {
                    case 0:
                        //in oauth or saml is the login button
                        if(k_is_oauth_active) {
                            [self oAuthScreen];
                        } else if (k_is_sso_active) {
                            [self checkURLServerForSSO];
                        }
                        break;
                    case 1:
                        break;
                        
                    default:
                        break;
                }
                break;
            
            case 2:
                switch (indexPath.row) {
                    case 0:
                        //login button
                        [self goTryToDoLogin];
                        break;
                    case 1:
                        //login button
                        [self showHelpURLInSafari];
                        break;
                        
                    default:
                        break;
                }
                break;
                
            default:
                break;
        }
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if(k_hide_url_server) {
            return [self generateFooterForUsernameAndPassword];
        } else {
            return [self configureViewForFooterURLServer];
        }
    } else if (section == 1) {
          if(!k_hide_url_server) {
             return [self generateFooterForUsernameAndPassword];
          } else {
              return nil;
          }
    } else {
        return nil;
    }
}

-(UIView *) configureViewForFooterURLServer {
    UIView *view = [[UIView alloc] initWithFrame:textFooterFrame1];
    
    if (!([self.auxUrlForReloadTable isEqualToString:@""] || ((CheckAccessToServer *)[CheckAccessToServer sharedManager]).delegate == nil)) {
        
        UILabel *label = [self setTheDefaultStyleOfTheServerFooterLabel];
        UIImageView *errorImage;
        
        if (isCheckingTheServerRightNow) {
            UIActivityIndicatorView *activity = [self setTheActivityIndicatorWhileTheConnectionIsBeenEstablished];
            [view addSubview:activity];
            label.text = NSLocalizedString(@"testing_connection",nil);
        } else if (isConnectionToServer) {
            if (hasInvalidAuth) {
                errorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CredentialsError.png"]];
                label.text = NSLocalizedString(@"authentification_not_valid",nil);
                label.numberOfLines = 1;
                [label setAdjustsFontSizeToFitWidth:YES];
            } else if (isHttps) {
                if (isHttpsSecure) {
                    errorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"SecureConnectionIcon.png"]];
                    label.text = NSLocalizedString(@"secure_connection_established",nil);
                } else {
                    errorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NonSecureConnectionIcon.png"]];
                    label.text = NSLocalizedString(@"https_non_secure_connection_established",nil);
                }
            } else {
                errorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NonSecureConnectionIcon.png"]];
                label.text = NSLocalizedString(@"connection_established",nil);
            }
        } else {
            if(isSSLAccepted) {
                errorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CredentialsError.png"]];
                NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                label.text = [NSLocalizedString(@"server_instance_not_found",nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName];
                if(k_hide_url_server) {
                    UIButton *button = [self setTheButtonForReconnectWithTheCurrentServer];
                    [view addSubview:button];
                }
            } else if(self.loginMode == LoginModeMigrate){
                errorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CredentialsError.png"]];
                label.text = NSLocalizedString(@"error_updating_predefined_url",nil);
            } else {
                errorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CredentialsError.png"]];
                label.text = NSLocalizedString(@"connection_declined",nil);
            }
        }
        [errorImage setFrame:lockImageFrame];
        [view addSubview:errorImage];
        [view addSubview:label];
    }
    return view;
}


///-----------------------------------
/// @name setTheDefaultStyleOfTheServerFooterLabel
///-----------------------------------

/**
 * This method set the default parameters of the label located on the server footer
 */
- (UILabel *) setTheDefaultStyleOfTheServerFooterLabel {
    UILabel* label = [[UILabel alloc] initWithFrame:textFooterFrame1];
    label.backgroundColor       = [UIColor clearColor];
    label.baselineAdjustment    = UIBaselineAdjustmentAlignCenters;
    label.lineBreakMode         = NSLineBreakByWordWrapping;
    label.textAlignment         = NSTextAlignmentLeft;
    label.textColor             = [UIColor colorOfLoginText];
    label.numberOfLines         = 0;
    label.font                  = [UIFont fontWithName:@"Arial" size:12.5];
    
    return label;
}


///-----------------------------------
/// @name setTheActivityIndicatorWhileTheConnectionIsBeenEstablished
///-----------------------------------

/**
 * This method set the activity indicator in the label located on the server footer
 */
- (UIActivityIndicatorView *) setTheActivityIndicatorWhileTheConnectionIsBeenEstablished {
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activity setFrame:lockImageFrame];
    [activity startAnimating];
    
    return activity;
}


///-----------------------------------
/// @name setTheButtonForReconnectWithTheCurrentServer
///-----------------------------------

/**
 * This method set the button located on the server field for reconnect the server
 */
- (UIButton *) setTheButtonForReconnectWithTheCurrentServer {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:syncImageFrameForNoURL];
    [button setBackgroundImage:[UIImage imageNamed:@"ReconnectIcon.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(checkUrlManually) forControlEvents:UIControlEventTouchDown];
    
    return button;
}

-(UIView *) generateFooterForUsernameAndPassword {
    
    NSString *errorMessage = @"";
    
    if(isError500) {

        errorMessage = @"unknow_response_server";
        
    } else if (isErrorOnCredentials){
        
        //In SAML the error message is about the session expired
        if (k_is_sso_active) {
            errorMessage = @"session_expired";
        }
        else{
            errorMessage = @"error_login_message";
        }

    } else if (self.loginMode == LoginModeMigrate){
        
        errorMessage = @"error_updating_predefined_url";
        
    } else {
        
        return nil;
    }
    
    UIImageView *errorImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"CredentialsError.png"]];
    [errorImage setFrame:okNokImageFrameFooter];
    
    UILabel* label = [[UILabel alloc] initWithFrame:textFooterFrame2];
    label.backgroundColor = [UIColor clearColor];
    
    label.baselineAdjustment= UIBaselineAdjustmentAlignCenters;
    label.lineBreakMode     =  NSLineBreakByWordWrapping;
    label.textAlignment     = NSTextAlignmentLeft;
    label.font          = [UIFont fontWithName:@"Arial" size:13];
    label.textColor     = [UIColor colorOfLoginErrorText];
    label.numberOfLines = 0;
    
    label.text = NSLocalizedString(errorMessage,nil);

    UIView *view = [[UIView alloc] initWithFrame:footerSection1Frame];
    
    [view addSubview:errorImage];
    [view addSubview:label];
    
    return view;
    
}

#pragma mark - Keyboard

-(void) keyboardWillShow:(NSNotification *) note {
    [self.view addGestureRecognizer:tapRecognizer];
}

-(void) keyboardWillHide:(NSNotification *) note
{
    [self.view removeGestureRecognizer:tapRecognizer];
}

-(void)didTapAnywhere: (UITapGestureRecognizer*) recognizer {
    [self.urlTextField resignFirstResponder];
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    if (isUserTextUp==YES || isPasswordTextUp==YES) {
        [self undoAnimate];
    }
    
    //Hide password
    [self hidePassword];
}

// Asks the delegate if the text field should process the pressing of the return button.
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    if (textField == self.urlTextField) {
        //[self.usernameTextField becomeFirstResponder];
        [textField resignFirstResponder];
    }
    else if (textField == self.usernameTextField) {
        if([self.passwordTextField.text isEqualToString:@""]) {
            [self.passwordTextField becomeFirstResponder];
        } else {
            [textField resignFirstResponder];
        }
    } else if (textField == self.passwordTextField) {
        [[NSUserDefaults standardUserDefaults] synchronize];
        [textField resignFirstResponder];
        
        //if the scrroll is not a the start of the tableview we move the scroll
       /* if(self.tableView.contentOffset.y > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }*/
    }
    
    return YES;
}

#pragma mark - Animation write

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    if (IS_IPHONE) {
        [self animateTextField:textField up:YES];
        
        if (textField == self.passwordTextField){
            [showPasswordCharacterButton setHidden:YES];
        } else if (textField == self.urlTextField) {
            [refreshTestServerButton setHidden:YES];
            
            [self.urlTextField setFrame:_urlFrame];
        }
        
        //Show or not show password
        if (textField==self.passwordTextField) {
            
        }else{
            [self hidePassword];
        }
    }
}

- (void)animateTextField: (UITextField*) textField up: (BOOL) up {
    DLog(@"Animate text field");
    
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
        } else if(textField == self.urlTextField) {
            scrollIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        }
    }
    
    DLog(@"Before the scroll To Row At IndexPath Medhod");
    if (textField == _usernameTextField || textField == _passwordTextField) {
        [[self tableView] scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    /*
     if(textField == self.passwordTextField || textField == self.usernameTextField) {
     const int movementDistancePortTrait = 100; // tweak as needed
     const int movementDistanceLandscape = 150; // tweak as needed
     const float movementDuration = 0.3f; // tweak as needed
     
     [UIView beginAnimations: @"anim" context: nil];
     [UIView setAnimationBeginsFromCurrentState: YES];
     [UIView setAnimationDuration: movementDuration];
     
     UIInterfaceOrientation currentOrientation;
     currentOrientation=[[UIApplication sharedApplication] statusBarOrientation];
     BOOL isPotrait = UIDeviceOrientationIsPortrait(currentOrientation);
     
     if(isPotrait) {
     self.view.frame = CGRectOffset(self.view.frame, 0, -movementDistancePortTrait);
     } else {
     self.view.frame = CGRectOffset(self.view.frame, -movementDistanceLandscape, 0);
     }
     //[UIView commitAnimations];
     
     NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
     [[self tableView] scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
     }*/
}

- (void) undoAnimate {
    
    if (isUserTextUp==YES) {
        isUserTextUp=NO;
    }
    
    if (isPasswordTextUp==YES) {
        isPasswordTextUp=NO;
    }
    
   //[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [_tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    
    
    
    
    // DLog(@"undoAnimateTextField");
    
    /*const int movementDistancePortTrait = 100; // tweak as needed
     const int movementDistanceLandscape = 150; // tweak as needed
     const float movementDuration = 0.3f; // tweak as needed
     
     //int movement = (up ? -movementDistance : movementDistance);
     
     [UIView beginAnimations: @"anim" context: nil];
     [UIView setAnimationBeginsFromCurrentState: YES];
     [UIView setAnimationDuration: movementDuration];
     
     UIInterfaceOrientation currentOrientation;
     currentOrientation=[[UIApplication sharedApplication] statusBarOrientation];
     BOOL isPotrait = UIDeviceOrientationIsPortrait(currentOrientation);
     
     if(isPotrait) {
     self.view.frame = CGRectOffset(self.view.frame, 0, movementDistancePortTrait);
     } else {
     self.view.frame = CGRectOffset(self.view.frame, movementDistanceLandscape, 0);
     }
     
     
     //self.view.frame=CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height+20.0);
     //[UIView commitAnimations];
     */
}

#pragma mark - Loading

-(void) showTryingToLogin {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        //hud.mode=MBProgressHUDModeDeterminate;
        hud.labelText = NSLocalizedString(@"loading", nil);
        hud.dimBackground = NO;
        
        self.view.userInteractionEnabled = NO;
        self.navigationController.navigationBar.userInteractionEnabled = NO;
        self.tabBarController.tabBar.userInteractionEnabled = NO;
    });
}

-(void) hideTryingToLogin {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.view.userInteractionEnabled = YES;
        self.navigationController.navigationBar.userInteractionEnabled = YES;
        self.tabBarController.tabBar.userInteractionEnabled = YES;
    });
}

#pragma mark - TextField delegates

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    DLog(@"6- self.auxUrlForReloadTable %@", self.auxUrlForReloadTable);
    DLog(@"6- self.urlTextField.text %@", self.urlTextField.text);
    DLog(@"6- textFieldDidEndEditing:textField %@", textField);
    DLog(@"6- is in main thread? %d", [NSThread isMainThread]);
    
    if(self.urlTextField != nil) {
        NSString *urlWithoutUserPassword = [self stripUsernameAndPassword:self.urlTextField.text];
        self.auxUrlForReloadTable = [self stripIndexPhpOrAppsFilesFromUrl:urlWithoutUserPassword];
    } else {
        //This is when we deleted the last account and go to the login screen and when edit credentials in settings view
        self.urlTextField = [[UITextField alloc]initWithFrame:self.urlFrame];
        self.urlTextField.text = self.auxUrlForReloadTable;
        textField = self.urlTextField;
    }
    
    if(self.usernameTextField.text == nil) {
        self.usernameTextField = [[UITextField alloc]initWithFrame:self.userAndPasswordFrame];
        self.usernameTextField.text = self.auxUsernameForReloadTable;
    }
    
    self.auxUsernameForReloadTable = self.usernameTextField.text;
    self.auxPasswordForReloadTable = self.passwordTextField.text;
    
    //if it is nil the screen is not here
    if(((CheckAccessToServer *)[CheckAccessToServer sharedManager]).delegate != nil) {
        DLog(@"CheckAccessToServer nil");
        //[self undoAnimateTextField:textField up:YES];
        
        if(isUserTextUp==YES || isPasswordTextUp==YES){
           // [self undoAnimate];
        }
        
        if(textField == self.urlTextField) {
            isError500 = NO;
        }
        
        if(textField == self.urlTextField && self.urlTextField.text.length > 0) {
            [self animateTextField: textField up: NO];
            
            
            if(textField == self.urlTextField) {
                
                if(threadToCheckUrl.isExecuting) {
                    [threadToCheckUrl cancel];
                }
                
                //[self.tableView reloadData];                
                [self isConnectionToTheServerByUrlInOtherThread];
                
                //[self performSelectorInBackground:@selector(isConnectionToTheServerByUrlInOtherThread) withObject:nil];
            }
        }
        
        if(textField == self.passwordTextField && ![textField.text isEqualToString:self.auxPasswordForShowPasswordOnEdit]) {
            self.auxPasswordForShowPasswordOnEdit = @"";
            [showPasswordCharacterButton setHidden:NO];
        } else if (textField == self.urlTextField) {
            [refreshTestServerButton setHidden:NO];
        }
        
        if ((self.urlTextField.text.length > 0 && self.passwordTextField.text.length > 0 && self.passwordTextField.text.length > 0 && isConnectionToServer && !hasInvalidAuth) || (isConnectionToServer && (k_is_oauth_active || k_is_sso_active))) {
            //[loginButton setEnabled:YES];
            isLoginButtonEnabled = YES;
            [self.tableView reloadData];
        }else {
            isLoginButtonEnabled = NO;
        }
        
        if(textField == self.urlTextField) {
            [self.urlTextField setFrame:_urlFrame];
        }
        
        if (textField == _passwordTextField) {
            //if the scrroll is not a the start of the tableview we move the scroll
            if(_tableView.contentOffset.y > 0) {
                //[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                [_tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
            }
        }
    }
}

-(void) textFieldDidChange {
    
    if(k_is_autocomplete_username_necessary) {
        DLog(@"textFieldDidChange: %@", self.usernameTextField.text);
        
        if([self.usernameTextField.text hasSuffix:k_letter_to_begin_autocomplete]) {
            self.usernameTextField.text = [NSString stringWithFormat:@"%@%@",self.usernameTextField.text,k_text_to_autocomplete];
        }
    }
}

-(void) isConnectionToTheServerByUrlInOtherThread {
    DLog(@"_isConnectionToTheServerByUrlInOtherThread_");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    isCheckingTheServerRightNow = YES;
    isConnectionToServer = NO;
    
    //Reset the url of redirected server at this point
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    app.urlServerRedirected = nil;
    
    [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:[self getUrlToCheck]];
}

-(NSString *)stripIndexPhpOrAppsFilesFromUrl:(NSString *)url {
    
    NSRange range = [url rangeOfString:k_remove_to_contains_path];
    
    if ([url hasSuffix:k_remove_to_suffix]) {
        url = [url substringToIndex:[url length] - [(NSString *)k_remove_to_suffix length]];
        self.urlTextField.text = url;
    } else if (range.length > 0) {
        url = [url substringToIndex:range.location];
        self.urlTextField.text = url;
    }
    
    return url;
}

- (NSString *)stripUsernameAndPassword:(NSString *)url {
    
    NSString *fakeUrl = url;
    
    //fake url to compose full url propertly without use getUrlToCheck to compose components propertly
    if (!([url hasPrefix:k_https_prefix] || [url hasPrefix:k_http_prefix])) {
        fakeUrl = [NSString stringWithFormat:@"%@%@",k_https_prefix ,url];
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:fakeUrl];
    
    // if user component was set on the server URL, move it to the user field
    if(components.user.length > 0) {
        [self.usernameTextField setText:components.user];
    }
    
    // if password component was set on the server URL, move it to the password field
    if(components.password.length > 0) {
        [self.passwordTextField setText:components.password];
    }
    
    if (components.user.length > 0 || components.password.length >0) {
        
        components.user = nil;
        components.password = nil;
        
        NSString *fullURLWithoutUsernamePassword = [self.urlTextField.text substringFromIndex:[self.urlTextField.text rangeOfString: @"@"].location+1];
        
        url = fullURLWithoutUsernamePassword;
        
        [self.urlTextField setText:url];
    }
    
    return url;
}

-(NSString *)getUrlToCheck {
    
    DLog(@"getUrlToCheck");
    
    NSString *url = [self getUrlChecked:self.urlTextField.text];
    
    if ([url hasPrefix:k_https_prefix]) {
        isNeedToCheckAgain = NO;
        isHttps=YES;
        url = [NSString stringWithFormat:@"%@", [self getUrlChecked: self.urlTextField.text]];
    } else if ([url hasPrefix:k_http_prefix]) {
        isNeedToCheckAgain = NO;
        isHttps = NO;
        url = [NSString stringWithFormat:@"%@", [self getUrlChecked: self.urlTextField.text]];
    } else if (isNeedToCheckAgain) {
        isNeedToCheckAgain = YES;
        isHttps = YES;
        url = [NSString stringWithFormat:@"%@%@",k_https_prefix,[self getUrlChecked: self.urlTextField.text]];
    } else {
        isNeedToCheckAgain = NO;
        isHttps = NO;
        url = [NSString stringWithFormat:@"%@%@",k_http_prefix,[self getUrlChecked: self.urlTextField.text]];
    }
    return url;
}

-(NSString *)getUrlChecked:(NSString *)byUrl {
    
    //We remove the accidentally last spaces " "
    while([byUrl hasSuffix:@" "]) {
        byUrl = [byUrl substringToIndex:[byUrl length] - 1];
    }
    
    DLog(@"byURL: |%@|",byUrl);
    
    //We check if the last char is a / if it is not we set it
    char urlLastChar =[byUrl characterAtIndex:([byUrl length]-1)];
    if(urlLastChar != '/') {
        byUrl = [byUrl stringByAppendingString:@"/"];
    }
    
    DLog(@"URL with /: %@", byUrl);
    
    //We remove the accidentally first spaces " "
    while([byUrl hasPrefix:@" "]) {
        byUrl = [byUrl substringFromIndex:1];
        
        DLog(@"byURL: |%@|",byUrl);
    }
    
    return byUrl;
}

-(void)repeatTheCheckToTheServer {
    [self isConnectionToTheServerByUrlInOtherThread];
}


///-----------------------------------
/// @name Update Interface With Connection to the server
///-----------------------------------

/**
 * This method update the login view depends of the server is 
 * conected or not.
 *
 * Is called from "connectionToTheServer" and "checkIfServerAutentificationIsNormalFromURL"
 *
 * @param isConnection -> BOOL
 */
-(void)updateInterfaceWithConnectionToTheServer:(BOOL)isConnection{
 dispatch_async(dispatch_get_main_queue(), ^{
    if(isConnection) {
        isConnectionToServer = YES;
        if (self.urlTextField.text.length > 0 && self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0 && !hasInvalidAuth) {
            //[loginButton setEnabled:YES];
            isLoginButtonEnabled = YES;
        }
        
    } else {
        isConnectionToServer = NO;
        //[loginButton setEnabled:NO];
        isLoginButtonEnabled = NO;
    }
    
    
    if (isNeedToCheckAgain && !isConnectionToServer) {
        isNeedToCheckAgain = NO;
        //[loginButton setEnabled:NO];
        isLoginButtonEnabled = NO;
        
        if (isConnection) {
            isConnectionToServer = YES;
            //[loginButton setEnabled:YES];
            isLoginButtonEnabled = YES;
            
            if (self.urlTextField.text.length > 0 && self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0) {
                //[loginButton setEnabled:YES];
                isLoginButtonEnabled = YES;
            }
            
        } else {
            isConnectionToServer = NO;
            //[loginButton setEnabled:NO];
            isLoginButtonEnabled = NO;
        }
    }
    
    if (isConnectionToServer) {
        if (isHttps) {
            UIImage *currentImage = [UIImage imageNamed: @"SecureConnectionIcon.png"];
            [checkConnectionToTheServerImage setImage:currentImage];
            [checkConnectionToTheServerImage setHidden:NO];
        } else {
            UIImage *currentImage = [UIImage imageNamed: @"NonSecureConnectionIcon.png"];
            [checkConnectionToTheServerImage setImage:currentImage];
            [checkConnectionToTheServerImage setHidden:NO];
        }
        
    } else {
        
        if (isHttps && ![self.urlTextField.text hasPrefix:k_https_prefix]) {
            DLog(@"es HTTPS no hay conexión");
            [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:[self getUrlToCheck]];
            
        } else {
            UIImage *currentImage = [UIImage imageNamed: @"CredentialsError.png"];
            [checkConnectionToTheServerImage setImage:currentImage];
            [checkConnectionToTheServerImage setHidden:NO];
        }
    }
    
    isCheckingTheServerRightNow = NO;
    [self.tableView reloadData];
    
    isNeedToCheckAgain = YES;
 });
}

///-----------------------------------
/// @name Connection to the server
///-----------------------------------

/**
 * It's a delegate method of CheckAccessToServer class that
 * it's called when the app know if the server is connected or not
 *
 * @param isConnection -> BOOL
 *
 */
-(void)connectionToTheServer:(BOOL)isConnection {
    //Set to NO, before the checking
    hasInvalidAuth = NO;
    
    if (isConnection) {
        [self checkIfServerAutentificationIsNormalFromURL];
    }else{
        //Update the interface
        [self updateInterfaceWithConnectionToTheServer:isConnection];
    }
}

#pragma mark - Checklogin

///-----------------------------------
/// @name Update Connect String
///-----------------------------------

/**
 * This method update the global variable _connectString, 
 * it's called sometimes in the code in order to get a correct 
 * full url dependes of the protocol
 *
 */
- (void) updateConnectString{
    
    NSString *httpOrHttps = @"";
    
    if(isHttps) {
        if([_urlTextField.text hasPrefix:k_https_prefix]) {
            httpOrHttps = @"";
        } else {
            httpOrHttps = k_https_prefix;
            
        }
    } else {
        if([_urlTextField.text hasPrefix:k_http_prefix]) {
            httpOrHttps = @"";
        } else {
            httpOrHttps = k_http_prefix;
        }
    }
    
    NSString *connectURL =[NSString stringWithFormat:@"%@%@%@",httpOrHttps,[self getUrlChecked: _urlTextField.text], k_url_webdav_server];
    _connectString=connectURL;
}



-(void) checkLogin {
    DLog(@"_checkLogin_");
    
    [self updateConnectString];
    
    [UtilsFramework deleteAllCookies];
    [UtilsCookies eraseURLCache];
    [UtilsCookies eraseCredentialsWithURL:self.connectString];
    
    [self performSelector:@selector(connectToServer) withObject:nil afterDelay:0.5];
}


///-----------------------------------
/// @name Check if server autentification is normal
///-----------------------------------

/**
 * This method is called in a normal autentification to check if the autentification
 * server is normal.
 *
 */
- (void) checkIfServerAutentificationIsNormalFromURL {
    
    //Update connect string
    [self updateConnectString];
    
    [UtilsFramework deleteAllCookies];
    [UtilsCookies eraseURLCache];
    [UtilsCookies eraseCredentialsWithURL:self.connectString];
    
    //Empty username and password to get a fail response to the server
    NSString *userName=@"";
    NSString *password=@"";
    
    DLog(@"connect string: %@", _connectString);
    
    [[AppDelegate sharedOCCommunication] setCredentialsWithUser:userName andPassword:password];
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    [[AppDelegate sharedOCCommunication] checkServer:_connectString onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        //Update the interface depend of if isInvalid or not
        
        isLoginButtonEnabled = k_is_sso_active;
        hasInvalidAuth = !k_is_sso_active;
        
        DLog(@"_Check server success_  InvalidAuth=%d",hasInvalidAuth);
        
        [self checkTheSecurityOfTheRedirectedURL:response.URL.absoluteString];
        
         dispatch_async(dispatch_get_main_queue(), ^{
             [_tableView reloadData];
             [self updateInterfaceWithConnectionToTheServer:YES];
         });
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        BOOL isInvalid = YES;
        
        NSString *authenticationHeader = @"Www-Authenticate";
        NSString *outhAuthentication = @"bearer";
        NSString *basicAuthentication = @"basic";
        
        if (!k_is_sso_active) {
            if (response.statusCode == kOCErrorServerUnauthorized) {
                //Get header related with autentication type
                NSString *autenticationType = [[response allHeaderFields] valueForKey:authenticationHeader];

                if ((autenticationType) && ([autenticationType.lowercaseString hasPrefix:outhAuthentication])) {
                    //Autentication type oauth
                    if (k_is_oauth_active) {
                        //Check if is activate oauth
                        isInvalid = NO;
                    } else {
                        isInvalid = YES;
                    }
                } else if ((autenticationType) && ([autenticationType.lowercaseString hasPrefix:basicAuthentication])) {
                    isInvalid = NO;
                } else {
                    //For the moment we have to mantain this value as valid because when we work with
                    //some Redirected Server our library lost the Wwww-Authenticate header
                    isInvalid = NO;
                }
            }else if (response != nil) {
                [self.manageNetworkErrors returnErrorMessageWithHttpStatusCode:response.statusCode andError:error];
            }
            
        } else {
            //If sso_active the check does not fail
            //As we are receiving a SAML error from SAML server, we forced the flag to accept this connection
            isInvalid = NO;
            isLoginButtonEnabled = YES;
        }
        
        
        //Update the interface depend of if isInvalid or not
        if (isInvalid) {
            hasInvalidAuth = YES;
        } else {
            hasInvalidAuth = NO;
        }
        
        DLog(@"_Check server failure_  InvalidAuth=%d",hasInvalidAuth);
        
        if (response == nil) {
             [self checkTheSecurityOfTheRedirectedURL:redirectedServer];
        }else{
            [self checkTheSecurityOfTheRedirectedURL:response.URL.absoluteString];
        }
        
       
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView reloadData];
            [self updateInterfaceWithConnectionToTheServer:YES];
        });
    }];
}


///-----------------------------------
/// @name checkTheSecurityOfTheRedirectedURL
///-----------------------------------

/**
 * This method checks if the redirected URL has a downgrade of the security
    So, if the first URL has https but the redirected one has http, we show a message to the user
 *
 * @param repsonse -> NSHTTPURLResponse, the response of the server
 */
- (void) checkTheSecurityOfTheRedirectedURL: (NSString *)redirectionURLString {
    
    if (isHttps) {
        if ([redirectionURLString hasPrefix:k_https_prefix]) {
            isHttpsSecure = YES;
        } else {
            isHttpsSecure = NO;
        }
    }
    
    DLog(@"_Check the security of the redirectedURL_: %@ isHttps=%d", redirectionURLString, isHttps);
}


///-----------------------------------
/// @name Connect to Server
///-----------------------------------

/**
 * This method do the proffind request to the webdav server in order
 * to do the login and get the root folder
 *
 * If the request "success" call the method "createUserAndDataInTheSystemWithRequest"
 *
 */
- (void) connectToServer{
    DLog(@"_connectToServer_");
    
    NSString *userName=self.usernameTextField.text;
    NSString *password=self.passwordTextField.text;
    
    //Set the right credentials

    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:userName andPassword:password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
     [[AppDelegate sharedOCCommunication] readFolder:_connectString withUserSessionToken:nil onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer, NSString *token){
        
        DLog(@"Operation success response code: %ld", (long)response.statusCode);
        
        BOOL isSamlCredentialsError = NO;

        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [self errorLogin];
            }
            
        } else if (redirectedServer){
            //Manage the redirectedServer. This case will only happen if is a permanent redirection 301
            DLog(@"Set the redirectedServer as default URL for the new user");
            
            redirectedServer = [redirectedServer substringToIndex:[redirectedServer length] - k_url_webdav_server.length];
            
            self.urlTextField.text = redirectedServer;
        }
        
        if (!isSamlCredentialsError) {
            //Pass the items with OCFileDto to FileDto Array
            NSMutableArray *directoryList = [UtilsDtos passToFileDtoArrayThisOCFileDtoArray:items];
            [self createUserAndDataInTheSystemWithRequest:directoryList andCode:response.statusCode];
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *token, NSString *redirectedServer) {
        
        DLog(@"error: %@", error);
        DLog(@"Operation error: %ld", (long)response.statusCode);
        
        [self.manageNetworkErrors returnErrorMessageWithHttpStatusCode:response.statusCode andError:error];
    }];
    
}


- (void)showError:(NSString *) message {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideTryingToLogin];
        _alert = nil;
        _alert = [[UIAlertView alloc] initWithTitle:message
                                            message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [_alert show];
    });
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
 * @warning This method it's present also in AddAcountViewController and EditViewController
 */
-(void)createUserAndDataInTheSystemWithRequest:(NSArray *)items andCode:(NSInteger) requestCode {
    DLog(@"_createUserAndDataInTheSystemWithRequest:andCode:_ %ld",(long)requestCode);
   // DLog(@"Request Did Fetch Directory Listing And Test Authetification");
    
    if(requestCode >= 400) {
        isError500 = YES;
        [self hideTryingToLogin];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } else {
        
        UserDto *userDto = [[UserDto alloc] init];
        
        //We check if start with http or https to concat it
        if([self.urlTextField.text hasPrefix:k_http_prefix] || [self.urlTextField.text hasPrefix:k_https_prefix]) {
            userDto.url = [self getUrlChecked: self.urlTextField.text];
            
        } else {
            if(isHttps) {
                userDto.url = [NSString stringWithFormat:@"%@%@",k_https_prefix, [self getUrlChecked: self.urlTextField.text]];
            } else {
                userDto.url = [NSString stringWithFormat:@"%@%@",k_http_prefix, [self getUrlChecked: self.urlTextField.text]];
            }
        }
        
        DLog(@"Request code >=400 and userDtoUrl: %@", userDto.url);
        
        AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        
        NSString *userNameUTF8=self.usernameTextField.text;
        NSString *passwordUTF8=self.passwordTextField.text;
        
        userDto.username = userNameUTF8;
        userDto.password = passwordUTF8;
        userDto.ssl = isHttps;
        userDto.activeaccount = YES;
        //Take into account that this global property can be stored bab value
        //For that we reset this property when the system check the server in LoginViewController class
        userDto.urlRedirected = app.urlServerRedirected;
        userDto.predefinedUrl = k_default_url_server;
        
        [ManageUsersDB insertUser:userDto];
        
        app.activeUser=[ManageUsersDB getActiveUser];
        
        NSMutableArray *directoryList = [NSMutableArray arrayWithArray:items];
        
        //Change the filePath from the library to our db format
        for (FileDto *currentFile in directoryList) {
            currentFile.filePath = [UtilsUrls getFilePathOnDBByFilePathOnFileDto:currentFile.filePath andUser:app.activeUser];
        }
        
        DLog(@"The directory List have: %ld elements", (unsigned long)directoryList.count);
        
        DLog(@"Directoy list: %@", directoryList);
    
        [ManageFilesDB insertManyFiles:directoryList andFileId:0];
        
        [self hideTryingToLogin];
        
        //Generate the app interface
        [app generateAppInterfaceFromLoginScreen:YES];
        
    }
    
}

-(void) errorLogin {
    
    DLog(@"Error login");
    
    [self hideTryingToLogin];
    
    isErrorOnCredentials = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Cookies support
//-----------------------------------
/// @name restoreTheCookiesOfActiveUserByNewUser
///-----------------------------------

/**
 * Method to restore the cookies of the active after add a new user
 *
 * @param UserDto -> user
 *
 */
- (void) restoreTheCookiesOfActiveUser {
    DLog(@"_restoreTheCookiesOfActiveUser_");
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //1- Clean the cookies storage
    [UtilsFramework deleteAllCookies];
    //2- We restore the previous cookies of the active user on the System cookies storage
    [UtilsCookies setOnSystemStorageCookiesByUser:app.activeUser];
    //3- We delete the cookies of the active user on the databse because it could change and it is not necessary keep them there
    [ManageCookiesStorageDB deleteCookiesByUser:app.activeUser];
}

#pragma marK - Action Buttons

-(void)checkUrlManually {
    DLog(@"_checkUrlManually_");
    [self textFieldDidEndEditing:self.urlTextField];
}

-(void)hideOrShowPassword {
    if ([self.passwordTextField isSecureTextEntry]) {
        [self.passwordTextField setSecureTextEntry:NO];
        [showPasswordCharacterButton setBackgroundImage:[UIImage imageNamed:@"NonRevealPasswordIcon.png"] forState:UIControlStateNormal];
    } else {
        [self.passwordTextField setSecureTextEntry:YES];
        [showPasswordCharacterButton setBackgroundImage:[UIImage imageNamed:@"RevealPasswordIcon.png"] forState:UIControlStateNormal];
    }
}

- (void)hidePassword{
    [self.passwordTextField setSecureTextEntry:YES];
    [showPasswordCharacterButton setBackgroundImage:[UIImage imageNamed:@"RevealPasswordIcon.png"] forState:UIControlStateNormal];
}

-(void)goTryToDoLogin {
    DLog(@"_goTryToDoLogin_ with user: %@ | pass: %@", self.usernameTextField.text, self.passwordTextField.text);
    
    isError500 = NO;
    
    DLog(@"_goTryToDoLogin_ log2 urlTextField: %@ username:%@  isConnectionToServer%d : hasInvalidAuth: %d", self.urlTextField.text, self.usernameTextField.text, isConnectionToServer, hasInvalidAuth);
    if (self.urlTextField.text.length > 0 && self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0 && isConnectionToServer && !hasInvalidAuth) {
        DLog(@"_goTryToDoLogin_ logIf_ Connection with server OK, go to showTryingToLogin");

        [self showTryingToLogin];
        DLog(@"Connection with server, try to login");
        [self checkLogin];
        
    }else {
        isLoginButtonEnabled = NO;
        DLog(@"_goTryToDoLogin_ logElse urlTextField: %@ username:%@  isConnectionToServer%d : hasInvalidAuth: %d", self.urlTextField.text, self.usernameTextField.text, isConnectionToServer, hasInvalidAuth);
    }
}

- (void) showHelpURLInSafari {
    DLog(@"_showHelpURLInSafari_");
    
    NSURL *url = [NSURL URLWithString:k_url_link_on_login];
    
    if (![[UIApplication sharedApplication] openURL:url]) {
        DLog(@"Failed to open url: %@", [url description]);
    }
}

#pragma mark - SSL Certificates

-(void)badCertificateNoAcceptedByUser {
    
    isCheckingTheServerRightNow = NO;
    isSSLAccepted = NO;
    //[loginButton setEnabled:NO];
    isLoginButtonEnabled = NO;
    
    UIImage *currentImage = [UIImage imageNamed: @"CredentialsError.png"];
    [checkConnectionToTheServerImage setImage:currentImage];
    [checkConnectionToTheServerImage setHidden:NO];
    
    isNeedToCheckAgain = YES;
    
    [self.tableView reloadData];
}


#pragma mark - OAuth

-(void)oAuthScreen {
    
    NSURL *url = [NSURL URLWithString:k_oauth_login];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - SSO

///-----------------------------------
/// @name Check URL Server For SSO
///-----------------------------------

/**
 * This method checks the URL in URLTextField in order to know if
 * is a valid SSO server.
 *
 */

-(void) checkURLServerForSSO {
    
    //Get the URL string
    NSString *urlString = [self getUrlToCheck];
    DLog(@"_checkURLServerForSSO_ %@",urlString);
    
    //Check SSO Server
    CheckSSOServer *checkSSOServer = [CheckSSOServer new];
    checkSSOServer.delegate = self;
    [checkSSOServer checkURLServerForSSOForThisPath:urlString];
    
    //Show Loading screen
    [self showTryingToLogin];
}



#pragma mark - CheckSSOServer Delegate methods

///-----------------------------------
/// @name Show Shibboleth Login Screen
///-----------------------------------

/**
 * Method called from CheckSSOServer that show the Shibboleth login Screen
 *
 */
- (void) showSSOLoginScreen{

    //Server url
    NSString * urlString = [self getUrlToCheck];
    
    DLog(@"_showSSOLoginScreen_ url: %@", urlString);
    
    //In main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //Hide the loading icon
        [self hideTryingToLogin];
        
        //WebView controller
        SSOViewController *ssoViewController = [[SSOViewController alloc] initWithNibName:@"SSOViewController" bundle:nil];
        ssoViewController.delegate = self;
        ssoViewController.urlString = urlString;
        
        //Branding navigation bar
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:ssoViewController];
        
        //Check if is iPhone or iPad
        if (!IS_IPHONE) {
            //iPad
            navController.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        
        [self presentViewController:navController animated:YES completion:nil];
    });
    
}


///-----------------------------------
/// @name Show SSO Error Server
///-----------------------------------

/**
 * Method called from CheckSSOServer that shows an alert view when the URLTextField isn't a valid SSO server
 *
 */
- (void) showSSOErrorServer {
    
    //In main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideTryingToLogin];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"auth_unsupported_auth_method", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alertView show];
    });
}


///-----------------------------------
/// @name Show Error Connection
///-----------------------------------

/**
 * Method called from CheckSSOServer that show an alert view with error connection
 *
 */
- (void)showErrorConnection{
    
    //In main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideTryingToLogin];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_possible_connect_to_server", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
        [alertView show];
    });
}


#pragma mark - SSODelegate methods

///-----------------------------------
/// @name Set Cookie For SSO
///-----------------------------------

/**
 * This delegate method is called from SSOViewController when the user
 * sets a correct credencials
 *
 * @param cookieString -> NSString
 * @param samUserName -> NSString
 *
 */
- (void)setCookieForSSO:(NSString *) cookieString andSamlUserName:(NSString*)samlUserName {
    DLog(@"_setCookieForSSO:andSamlUserName:_ %@", samlUserName);
    
    //We should be change this behaviour when in the server side update the cookies.
    if (samlUserName) {
        _usernameTextField = [UITextField new];
        _usernameTextField.text = samlUserName;
        
        _passwordTextField = [UITextField new];
        _passwordTextField.text = cookieString;
        self.alreadyHaveValidSAMLCredentials = YES;
        
        [self goTryToDoLogin];
        
    }else if ([samlUserName isEqual: @""]){
    
        //Show message in main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"saml_server_does_not_give_user_id", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alertView show];
        });
    }else {
        //It's nil
        //nothing to do
        DLog(@"saml user name is nil");
    }

}


- (void)setBarForCancelForLoadingFromModal {
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeViewController)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
}

- (void) closeViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
