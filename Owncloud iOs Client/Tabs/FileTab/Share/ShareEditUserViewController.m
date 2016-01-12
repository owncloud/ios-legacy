//
//  ShareEditUserViewController.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 11/1/16.
//
//

/*
 Copyright (C) 2016, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareEditUserViewController.h"
#import "ManageFilesDB.h"
#import "UtilsUrls.h"
#import "UserDto.h"
#import "OCSharedDto.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "FileNameUtils.h"
#import "UIColor+Constants.h"
#import "OCNavigationController.h"
#import "ManageUsersDB.h"
#import "EditAccountViewController.h"
#import "Customization.h"
#import "ShareSearchUserViewController.h"
#import "ManageSharesDB.h"
#import "CapabilitiesDto.h"
#import "ManageCapabilitiesDB.h"

//tools
#define standardDelay 0.2
#define animationsDelay 0.5
#define largeDelay 1.0

//Xib
#define shareMainViewNibName @"ShareEditUserViewController"

//Cells and Sections
#define shareFileCellIdentifier @"ShareFileIdentifier"
#define shareFileCellNib @"ShareFileCell"
#define shareLinkOptionIdentifer @"ShareLinkOptionIdentifier"
#define shareLinkOptionNib @"ShareLinkOptionCell"
#define shareLinkHeaderIdentifier @"ShareLinkHeaderIdentifier"
#define shareLinkHeaderNib @"ShareLinkHeaderCell"
#define shareLinkButtonIdentifier @"ShareLinkButtonIdentifier"
#define shareLinkButtonNib @"ShareLinkButtonCell"
#define shareUserCellIdentifier @"ShareUserCellIdentifier"
#define shareUserCellNib @"ShareUserCell"
#define heighOfFileDetailrow 120.0
#define heightOfShareLinkOptionRow 55.0
#define heightOfShareLinkButtonRow 40.0
#define heightOfShareLinkHeader 45.0
#define heightOfShareWithUserRow 55.0
#define shareTableViewSectionsNumber  3

//Nº of Rows
#define optionsShownWithShareLinkEnable 3
#define optionsShownWithShareLinkDisable 0

#define optionsShownIfFileIsDirectory 3
#define optionsShownIfFileIsNotDirectory 0


//Date server format
#define dateServerFormat @"YYYY-MM-dd"

//alert share password
#define password_alert_view_tag 601

@interface ShareEditUserViewController ()

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic, strong) UserDto* sharedUser;

@property (nonatomic, strong) OCSharedDto *updatedOCShare;
@property (nonatomic) NSInteger optionsShownWithCanEdit;
@property (nonatomic) BOOL canEditEnabled;
@property (nonatomic) BOOL canCreateEnabled;
@property (nonatomic) BOOL canChangeEnabled;
@property (nonatomic) BOOL canDeleteEnabled;
@property (nonatomic) BOOL canShareEnabled;

@property (nonatomic, strong) NSString* sharedToken;
@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;
@property (nonatomic, strong) MBProgressHUD* loadingView;
@property (nonatomic, strong) UIAlertView *passwordView;
@property (nonatomic, strong) UIActivityViewController *activityView;
@property (nonatomic, strong) EditAccountViewController *resolveCredentialErrorViewController;
@property (nonatomic, strong) UIPopoverController* activityPopoverController;

@end


@implementation ShareEditUserViewController


- (id) initWithFileDto:(FileDto *)fileDto andUserDto:(UserDto *)userDto{
    
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.sharedItem = fileDto;
        self.sharedUser = userDto;
        self.optionsShownWithCanEdit = 0;
        self.canEditEnabled = false;
        self.canCreateEnabled = false;
        self.canChangeEnabled = false;
        self.canDeleteEnabled = false;
        self.canShareEnabled = false;
    }
    
    return self;
}

- (void) viewDidLoad{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
    
    //[self checkSharedStatusOFile];
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}


#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = NSLocalizedString(@"share_link_long_press", nil);
    [self setBarButtonStyle];
    
}

- (void) setBarButtonStyle {
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectCloseView)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
}

- (void) reloadView {
    
    if (self.canEditEnabled == true && self.sharedItem.isDirectory){
        self.optionsShownWithCanEdit = optionsShownIfFileIsDirectory;
    }else{
        self.optionsShownWithCanEdit = optionsShownIfFileIsNotDirectory;
    }
    
    [self.shareEditUserTableView reloadData];
}

#pragma mark - Action Methods

- (void) didSelectCloseView {
    
    [self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Actions with ShareWith class

- (void) unShareWith:(OCSharedDto *) share{
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    [self.sharedFileOrFolder unshareTheFile:share];
    
}

//TODO: update with privileges
- (void) updateSharedLinkWithPassword:(NSString*) password andExpirationDate:(NSString*)expirationDate {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    OCSharedDto *ocShare = [self.sharedFileOrFolder getTheOCShareByFileDto:self.sharedItem];
    
    [self.sharedFileOrFolder updateShareLink:ocShare withPassword:password andExpirationTime:expirationDate];
    
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return shareTableViewSectionsNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }else if (section == 1){
        if (self.canEditEnabled && self.sharedItem.isDirectory) {
            return optionsShownIfFileIsDirectory;
        } else {
            return optionsShownIfFileIsNotDirectory;
        }
        
    }else {
        return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (indexPath.section == 0) {
        
        ShareFileCell* shareFileCell = (ShareFileCell*)[tableView dequeueReusableCellWithIdentifier:shareFileCellIdentifier];
        
        if (shareFileCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareFileCellNib owner:self options:nil];
            shareFileCell = (ShareFileCell *)[topLevelObjects objectAtIndex:0];
        }
        
        shareFileCell.fileName.hidden = [self.sharedUser.username stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        cell = shareFileCell;
        
    } else if (indexPath.section == 1) {
        
            
            ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];
            
            if (shareLinkOptionCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
                shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
            }
            
            switch (indexPath.row) {
                case 0:
                    shareLinkOptionCell.optionName.text = NSLocalizedString(@"user_can_create", nil);
                    
                    if (self.canEditEnabled == true) {
                        //TODO:create new type of cell with only one label
                        shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                    }else{
                        shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                    }
                    [shareLinkOptionCell.optionSwith setOn:self.canCreateEnabled animated:false];
                    
                    break;
                case 1:
                    shareLinkOptionCell.optionName.text = NSLocalizedString(@"user_can_change", nil);
                    
                    if (self.canChangeEnabled == true) {
                        shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                    } else {
                        shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                    }
                    [shareLinkOptionCell.optionSwith setOn:self.canChangeEnabled animated:false];
                    
                    break;
                case 2:
                    shareLinkOptionCell.optionName.text = NSLocalizedString(@"user_can_delete", nil);
                    
                    if (self.canDeleteEnabled == true) {
                        shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                    } else {
                        shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                    }
                    [shareLinkOptionCell.optionSwith setOn:self.canDeleteEnabled animated:false];
                    
                    break;
                    
                default:
                    //Not expected
                    DLog(@"Not expected");
                    break;
            }
            
            cell = shareLinkOptionCell;
        
    } else if (indexPath.section == 2) {
            
            ShareLinkButtonCell *shareLinkButtonCell = [tableView dequeueReusableCellWithIdentifier:shareLinkButtonIdentifier];
            
            if (shareLinkButtonCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkButtonNib owner:self options:nil];
                shareLinkButtonCell = (ShareLinkButtonCell *)[topLevelObjects objectAtIndex:0];
            }
            
            shareLinkButtonCell.backgroundColor = [UIColor colorOfLoginButtonBackground];
            shareLinkButtonCell.titleButton.textColor = [UIColor whiteColor];
            shareLinkButtonCell.titleButton.text = NSLocalizedString(@"stop_share_with_user___", nil);
            
            cell = shareLinkButtonCell;
    } else {
        ShareLinkButtonCell *shareLinkButtonCell = [tableView dequeueReusableCellWithIdentifier:shareLinkButtonIdentifier];
        
        if (shareLinkButtonCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkButtonNib owner:self options:nil];
            shareLinkButtonCell = (ShareLinkButtonCell *)[topLevelObjects objectAtIndex:0];
        }
        
        shareLinkButtonCell.backgroundColor = [UIColor colorOfLoginButtonBackground];
        shareLinkButtonCell.titleButton.textColor = [UIColor whiteColor];
        shareLinkButtonCell.titleButton.text = NSLocalizedString(@"stop_share_with_user", nil);
        
        cell = shareLinkButtonCell;
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
    CGFloat height = 10.0;
    
    if (section == 1 || section == 2) {
        height = heightOfShareLinkHeader;
    }
    
    return height;
}

-(void) canEditSwithValueChanged:(UISwitch*) sender {
    
    self.canEditEnabled = sender.on;

   [self reloadView];
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.shareEditUserTableView.frame.size.width, 1)];
    
    
    if (section == 1 || section == 2) {
        
        ShareLinkHeaderCell* shareLinkHeaderCell = [tableView dequeueReusableCellWithIdentifier:shareLinkHeaderIdentifier];
        
        if (shareLinkHeaderCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkHeaderNib owner:self options:nil];
            shareLinkHeaderCell = (ShareLinkHeaderCell *)[topLevelObjects objectAtIndex:0];
        }
        
        if (section == 1) {
            shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"title_user_can_edit", nil);
            [shareLinkHeaderCell.switchSection setOn:self.canEditEnabled animated:false];
            [shareLinkHeaderCell.switchSection addTarget:self action:@selector(canEditSwithValueChanged:) forControlEvents:UIControlEventValueChanged];

        }else{
            shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"title_user_can_share", nil);
            [shareLinkHeaderCell.switchSection setOn:self.canShareEnabled animated:false];
        }
        
        
        headerView = shareLinkHeaderCell.contentView;
        
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.section == 1) {
        
    }

}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    return false;
}


#pragma mark - ShareFileOrFolder Delegate Methods

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


- (void) presentShareOptions{
    
    if (IS_IPHONE) {
        [self presentViewController:self.activityView animated:true completion:nil];
        [self performSelector:@selector(reloadView) withObject:nil afterDelay:standardDelay];
    }else{
        [self reloadView];
        
        self.activityPopoverController = [[UIPopoverController alloc]initWithContentViewController:self.activityView];
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:2 inSection:1];
        UITableViewCell* cell = [self.shareEditUserTableView cellForRowAtIndexPath:indexPath];
        
        [self.activityPopoverController presentPopoverFromRect:cell.frame inView:self.shareEditUserTableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
    }
    
}

#pragma mark - Error Login Methods

- (void) showEditAccount {
    
#ifdef CONTAINER_APP
    
    //Edit Account
    self.resolveCredentialErrorViewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:[ManageUsersDB getActiveUser]];
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
    // test if our control subview is on-screen
//    if ([touch.view isDescendantOfView:self.pickerView]) {
//        // we touched our control surface
//        return NO;
//    }
    return YES;
}

@end

