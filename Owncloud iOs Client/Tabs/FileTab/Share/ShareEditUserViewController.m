//
//  ShareEditUserViewController.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 11/1/16.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareEditUserViewController.h"
#import "ManageFilesDB.h"
#import "UtilsUrls.h"
#import "OCSharedDto.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "FileNameUtils.h"
#import "UIColor+Constants.h"
#import "OCNavigationController.h"
#import "ManageUsersDB.h"
#import "EditAccountViewController.h"
#import "Customization.h"
#import "ManageSharesDB.h"
#import "UtilsFramework.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "OCErrorMsg.h"
#import "constants.h"

//tools
#define standardDelay 0.2
#define animationsDelay 0.5
#define largeDelay 1.0

//Xib
#define shareMainViewNibName @"ShareEditUserViewController"

//Cells and Sections
#define shareUserPrivilegeIdentifier @"ShareUserPrivilegeIdentifier"
#define shareUserPrivilegeNib @"ShareUserPrivilegeCell"
#define shareLinkHeaderIdentifier @"ShareLinkHeaderIdentifier"
#define shareLinkHeaderNib @"ShareLinkHeaderCell"
#define sharePrivilegeIdentifier @"SharePrivilegeIdentifier"
#define sharePrivilegeNib @"SharePrivilegeCell"
#define shareLinkButtonIdentifier @"ShareLinkButtonIdentifier"
#define shareLinkButtonNib @"ShareLinkButtonCell"
#define heighOfFileDetailrow 120.0
#define heightOfShareLinkOptionRow 55.0
#define heightOfShareLinkHeader 45.0
#define heightOfHeader 10.0

#define shareTableViewSectionsNumber  3
#define shareTableViewSectionsNumberRemote  2

//Nº of Rows
#define fullOptionsForCanEditOption 3
#define minOptionsForCanEditOption 0


@interface ShareEditUserViewController ()

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic, strong) OCSharedDto *updatedOCShare;
@property (nonatomic) BOOL canEditEnabled;
@property (nonatomic) BOOL canCreateEnabled;
@property (nonatomic) BOOL canChangeEnabled;
@property (nonatomic) BOOL canDeleteEnabled;
@property (nonatomic) BOOL canShareEnabled;
@property (nonatomic) BOOL canCreateOldValue;
@property (nonatomic) BOOL canChangeOldValue;
@property (nonatomic) BOOL canDeleteOldValue;

@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;
@property (nonatomic, strong) MBProgressHUD* loadingView;
@property (nonatomic, strong) UIActivityViewController *activityView;
@property (nonatomic, strong) EditAccountViewController *resolveCredentialErrorViewController;
@property (nonatomic, strong) UIPopoverController* activityPopoverController;

//Enum to restore the option after get an error
typedef NS_ENUM (NSInteger, enumUpload){
    optionPermissionNothingYet=0,
    optionPermissionCanEdit=1,
    optionPermissionCanCreate=2,
    optionPermissionCanChange=3,
    optionPermissionCanDelete=4,
    optionPermissionCanShare=5
};
@property (nonatomic) NSInteger optionTryingToEnabling;

@end


@implementation ShareEditUserViewController


- (id) initWithFileDto:(FileDto *)fileDto andOCSharedDto:(OCSharedDto *)sharedDto{
    
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.sharedItem = fileDto;
        self.updatedOCShare = sharedDto;
        self.canEditEnabled = [UtilsFramework isAnyPermissionToEdit:self.updatedOCShare.permissions];
        self.canCreateEnabled = [UtilsFramework isPermissionToCanCreate:self.updatedOCShare.permissions];
        self.canChangeEnabled = [UtilsFramework isPermissionToCanChange:self.updatedOCShare.permissions];
        self.canDeleteEnabled = [UtilsFramework isPermissionToCanDelete:self.updatedOCShare.permissions];
        self.canShareEnabled = [UtilsFramework isPermissionToCanShare:self.updatedOCShare.permissions];
        self.optionTryingToEnabling = optionPermissionNothingYet;
        
        self.manageNetworkErrors = [ManageNetworkErrors new];
        self.manageNetworkErrors.delegate = self;
    }
    
    return self;
}

- (void) viewDidLoad{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
    
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}


#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = NSLocalizedString(@"title_view_edit_user_privileges", nil);
    [self setBarButtonStyle];
    
}

- (void) setBarButtonStyle {
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectCloseView)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
}


#pragma mark - Action Methods

- (void) didSelectCloseView {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) reloadView {
    [self.shareEditUserTableView reloadData];
}


- (void) updatePermissionOnServer {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    NSInteger permissionValue = [UtilsFramework getPermissionsValueByCanEdit:self.canEditEnabled andCanCreate:self.canCreateEnabled andCanChange:self.canChangeEnabled andCanDelete:self.canDeleteEnabled andCanShare:self.canShareEnabled andIsFolder:self.sharedItem.isDirectory];
    
    //We update the permission only if the permissions are differents than the current ones
    if (permissionValue != self.updatedOCShare.permissions) {
        
        [self initLoading];
        
        //Set the right credentials
        if (k_is_sso_active) {
            [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:APP_DELEGATE.activeUser.password];
        } else if (k_is_oauth_active) {
            [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:APP_DELEGATE.activeUser.password];
        } else {
            [[AppDelegate sharedOCCommunication] setCredentialsWithUser:APP_DELEGATE.activeUser.username andPassword:APP_DELEGATE.activeUser.password];
        }
        
        [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
        
        [[AppDelegate sharedOCCommunication] updateShare:self.updatedOCShare.idRemoteShared ofServerPath:app.activeUser.url withPasswordProtect:nil andExpirationTime:nil andPermissions:permissionValue onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
                if (isSamlCredentialsError) {
                    [self endLoading];
                    [self errorLogin];
                }
            }
            if (!isSamlCredentialsError) {
                self.updatedOCShare.permissions = permissionValue;
                [ManageSharesDB updateTheRemoteShared:self.updatedOCShare.idRemoteShared forUser:APP_DELEGATE.activeUser.idUser withPermissions:permissionValue];
                [self endLoading];
                [self reloadView];
            }
            
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
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
            //If it is not SAML
            if (!isSamlCredentialsError) {
                
                DLog(@"error.code: %ld", (long)error.code);
                DLog(@"server error http: %ld", (long)response.statusCode);
                
                [self.manageNetworkErrors manageErrorHttp:response.statusCode andErrorConnection:error andUser:app.activeUser];

                switch (self.optionTryingToEnabling) {
                    case optionPermissionCanEdit:
                        self.canEditEnabled = !self.canEditEnabled;
                        if(self.canEditEnabled){
                            [self restoreEditOptionValues];
                        }
                        break;
                    case optionPermissionCanCreate:
                        self.canCreateEnabled = !self.canCreateEnabled;
                        break;
                    case optionPermissionCanChange:
                        self.canChangeEnabled = !self.canChangeEnabled;
                        break;
                    case optionPermissionCanDelete:
                        self.canDeleteEnabled = !self.canDeleteEnabled;
                        break;
                    case optionPermissionCanShare:
                        self.canShareEnabled = !self.canShareEnabled;
                        break;
                    default:
                        break;
                }
                
                //Reset the last permission option
                self.optionTryingToEnabling = optionPermissionNothingYet;
                [self reloadView];
                
            }
        }];
    } else {
        [self reloadView];
    }
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    if (self.updatedOCShare.shareType == shareTypeRemote) {
        if (!(APP_DELEGATE.activeUser.hasFedSharesOptionShareSupport == serverFunctionalitySupported)) {
            return shareTableViewSectionsNumberRemote;
        }
    }
    return shareTableViewSectionsNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }else if (section == 1){
        if (self.canEditEnabled && self.sharedItem.isDirectory && self.updatedOCShare.shareType != shareTypeRemote) {
            return fullOptionsForCanEditOption;
        } else {
            return minOptionsForCanEditOption;
        }
        
    }else if (section == 2) {
        return 0;
    }else {
        return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (indexPath.section == 0) {
        
        ShareUserPrivilegeCell *shareUserPrivilegeCell = (ShareUserPrivilegeCell *)[tableView dequeueReusableCellWithIdentifier:shareUserPrivilegeIdentifier];
        
        if (shareUserPrivilegeCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserPrivilegeNib owner:self options:nil];
            shareUserPrivilegeCell = (ShareUserPrivilegeCell *)[topLevelObjects objectAtIndex:0];
        }
        
        shareUserPrivilegeCell.fileName.text = [self.updatedOCShare.shareWithDisplayName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        cell = shareUserPrivilegeCell;
        
    } else if (indexPath.section == 1) {
            
            SharePrivilegeCell* sharePrivilegeCell = [tableView dequeueReusableCellWithIdentifier:sharePrivilegeIdentifier];
            
            if (sharePrivilegeCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:sharePrivilegeNib owner:self options:nil];
                sharePrivilegeCell = (SharePrivilegeCell *)[topLevelObjects objectAtIndex:0];
            }
            
            switch (indexPath.row) {
                case 0:
                    sharePrivilegeCell.optionName.text = NSLocalizedString(@"user_can_create", nil);
                    
                    if (self.canCreateEnabled) {
                        sharePrivilegeCell.optionName.textColor = [UIColor blackColor];
                    }else{
                        sharePrivilegeCell.optionName.textColor = [UIColor grayColor];
                    }
                    [sharePrivilegeCell.optionSwitch setOn:self.canCreateEnabled animated:false];
                    [sharePrivilegeCell.optionSwitch addTarget:self action:@selector(canCreateSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
                    
                    break;
                case 1:
                    sharePrivilegeCell.optionName.text = NSLocalizedString(@"user_can_change", nil);
                    
                    if (self.canChangeEnabled) {
                        sharePrivilegeCell.optionName.textColor = [UIColor blackColor];
                    } else {
                        sharePrivilegeCell.optionName.textColor = [UIColor grayColor];
                    }
                    [sharePrivilegeCell.optionSwitch setOn:self.canChangeEnabled animated:false];
                    [sharePrivilegeCell.optionSwitch addTarget:self action:@selector(canChangeSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];

                    break;
                case 2:
                    sharePrivilegeCell.optionName.text = NSLocalizedString(@"user_can_delete", nil);
                    
                    if (self.canDeleteEnabled) {
                        sharePrivilegeCell.optionName.textColor = [UIColor blackColor];
                    } else {
                        sharePrivilegeCell.optionName.textColor = [UIColor grayColor];
                    }
                    [sharePrivilegeCell.optionSwitch setOn:self.canDeleteEnabled animated:false];
                    [sharePrivilegeCell.optionSwitch addTarget:self action:@selector(canDeleteSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];

                    
                    break;
                    
                default:
                    //Not expected
                    DLog(@"Not expected");
                    break;
            }
            
            cell = sharePrivilegeCell;
        
    }
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0.0;
    
    if (indexPath.section == 0) {
        
        height = heighOfFileDetailrow;
        
    }else {
        
        height = heightOfShareLinkOptionRow;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = heightOfHeader;
    
    if (section == 1 || section == 2) {
        height = heightOfShareLinkHeader;
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.shareEditUserTableView.frame.size.width, 1)];
    
    
    if (section == 1 || section == 2) {
        
        ShareLinkHeaderCell* shareLinkHeaderCell = [tableView dequeueReusableCellWithIdentifier:shareLinkHeaderIdentifier];
        shareLinkHeaderCell.addButtonSection.hidden = YES;
        
        if (shareLinkHeaderCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkHeaderNib owner:self options:nil];
            shareLinkHeaderCell = (ShareLinkHeaderCell *)[topLevelObjects objectAtIndex:0];
        }
        
        if (section == 1) {
            shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"title_user_can_edit", nil);
            [shareLinkHeaderCell.switchSection setOn:self.canEditEnabled animated:false];
            [shareLinkHeaderCell.switchSection addTarget:self action:@selector(canEditSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];

        } else {
            shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"title_user_can_share", nil);
            [shareLinkHeaderCell.switchSection setOn:self.canShareEnabled animated:false];
            [shareLinkHeaderCell.switchSection addTarget:self action:@selector(canShareSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        shareLinkHeaderCell.addButtonSection.hidden = YES;
        
        headerView = shareLinkHeaderCell.contentView;
        
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
  //  [tableView deselectRowAtIndexPath:indexPath animated:true];

}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return false;
}


#pragma mark - Handle switch values

-(void) setOptionsCanEditTo:(BOOL)value {
    [self saveEditOptionValues];
    self.canCreateEnabled = value;
    self.canChangeEnabled = value;
    self.canDeleteEnabled = value;
}

-(void) saveEditOptionValues{
    self.canCreateOldValue  = self.canCreateEnabled;
    self.canChangeOldValue  = self.canChangeEnabled;
    self.canDeleteOldValue  = self.canDeleteEnabled;
}

-(void) restoreEditOptionValues{
    self.canCreateEnabled = self.canCreateOldValue;
    self.canChangeEnabled = self.canChangeOldValue;
    self.canDeleteEnabled = self.canDeleteOldValue;
}

-(void) canEditSwitchValueChanged:(UISwitch*) sender {
    
    self.canEditEnabled = sender.on;
    
    if (sender.on && ([self.sharedItem.permissions rangeOfString:k_permission_shared].location == NSNotFound)) {
        [self setOptionsCanEditTo:true];
    } else {
        [self setOptionsCanEditTo:false];
    }
    
    self.optionTryingToEnabling = optionPermissionCanEdit;
    [self updatePermissionOnServer];
}

-(void) canShareSwitchValueChanged:(UISwitch*) sender {
    
    self.canShareEnabled = sender.on;
    
    self.optionTryingToEnabling = optionPermissionCanShare;
    [self updatePermissionOnServer];
}

-(void) canCreateSwitchValueChanged:(UISwitch*) sender {
    
    self.canCreateEnabled = sender.on;
    
    if (self.sharedItem.isDirectory) {
        if (!self.canChangeEnabled && !self.canCreateEnabled && !self.canDeleteEnabled) {
            self.canEditEnabled = false;
            [self reloadView];
        }
    } else {
        if (!self.canChangeEnabled && !self.canDeleteEnabled) {
            self.canEditEnabled = false;
            [self reloadView];
        }
    }
    
    self.optionTryingToEnabling = optionPermissionCanCreate;
    [self updatePermissionOnServer];
}

-(void) canChangeSwitchValueChanged:(UISwitch*) sender {
    
    self.canChangeEnabled = sender.on;
    
    if (self.sharedItem.isDirectory) {
        if (!self.canChangeEnabled && !self.canCreateEnabled && !self.canDeleteEnabled) {
            self.canEditEnabled = false;
            [self reloadView];
        }
    } else {
        if (!self.canCreateEnabled && !self.canDeleteEnabled) {
            self.canEditEnabled = false;
            [self reloadView];
        }
    }
    
    self.optionTryingToEnabling = optionPermissionCanChange;
    [self updatePermissionOnServer];
}

-(void) canDeleteSwitchValueChanged:(UISwitch*) sender {
    
    self.canDeleteEnabled = sender.on;
    
    if (self.sharedItem.isDirectory) {
        if (!self.canChangeEnabled && !self.canCreateEnabled && !self.canDeleteEnabled) {
            self.canEditEnabled = false;
            [self reloadView];
        }
    } else {
        if (!self.canCreateEnabled && !self.canChangeEnabled) {
            self.canEditEnabled = false;
            [self reloadView];
        }
    }
    
    self.optionTryingToEnabling = optionPermissionCanDelete;
    [self updatePermissionOnServer];
}


#pragma mark - Loading Methods

- (void) initLoading {
    
    if (self.loadingView == nil) {
        self.loadingView = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
        self.loadingView.delegate = self;
    }
    
    [self.view addSubview:self.loadingView];
    
    self.loadingView.labelText = NSLocalizedString(@"loading", nil);
    self.loadingView.dimBackground = false;
    
    [self.loadingView show:true];
    
    self.view.userInteractionEnabled = false;
    self.navigationController.navigationBar.userInteractionEnabled = false;
    self.view.window.userInteractionEnabled = false;
    
}

- (void) endLoading {
    
    if (APP_DELEGATE.isLoadingVisible == false) {
        [self.loadingView removeFromSuperview];
        
        self.view.userInteractionEnabled = true;
        self.navigationController.navigationBar.userInteractionEnabled = true;
        self.view.window.userInteractionEnabled = true;
        
    }
}

- (void) errorLogin {
    
    [self endLoading];
    
    [self performSelector:@selector(showEditAccount) withObject:nil afterDelay:animationsDelay];
    
    [self performSelector:@selector(showErrorAccount) withObject:nil afterDelay:largeDelay];
    
}


#pragma mark - Error Login Methods

- (void) showEditAccount {
    
#ifdef CONTAINER_APP
    
    //Edit Account
    self.resolveCredentialErrorViewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:[ManageUsersDB getActiveUser] andModeUpdateToPredefinedUrl:NO];
    [self.resolveCredentialErrorViewController setBarForCancelForLoadingFromModal];
    
    if (IS_IPHONE) {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:self.resolveCredentialErrorViewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
        
    } else {
        
        OCNavigationController *navController = nil;
        navController = [[OCNavigationController alloc] initWithRootViewController:self.resolveCredentialErrorViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    }
    
#endif
    
}

- (void) showErrorAccount {
    
    if (k_is_sso_active) {
        [self showErrorWithTitle:NSLocalizedString(@"session_expired", nil)];
    }else{
        [self showErrorWithTitle:NSLocalizedString(@"error_login_message", nil)];
    }
    
}

- (void)showErrorWithTitle: (NSString *)title {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
    
    
}

#pragma mark - UIGestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

    return YES;
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

