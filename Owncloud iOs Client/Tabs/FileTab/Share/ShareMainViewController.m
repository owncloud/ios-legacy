//
//  ShareMainViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/8/15.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareMainViewController.h"
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
#import "ManageCapabilitiesDB.h"
#import "ShareEditUserViewController.h"
#import "OCShareUser.h"
#import "ShareUtils.h"
#import "UtilsFramework.h"

//tools
#define standardDelay 0.2
#define animationsDelay 0.5
#define largeDelay 1.0

//Xib
#define shareMainViewNibName @"ShareViewController"

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
#define optionsShownWithShareLinkEnableAndAllowEditing 4
#define optionsShownWithShareLinkEnableWithoutAllowEditing 3
#define optionsShownWithShareLinkDisable 0

//Date server format
#define dateServerFormat @"YYYY-MM-dd"

//alert share password
#define password_alert_view_tag 601

//mail subject key
#define k_subject_key_activityView @"subject"

//permissions value to not update them
#define k_permissions_do_not_update 0

@interface ShareMainViewController ()

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic, strong) OCSharedDto *updatedOCShare;
@property (nonatomic) NSInteger optionsShownWithShareLink;
@property (nonatomic) BOOL isShareLinkEnabled;
@property (nonatomic) BOOL isPasswordProtectEnabled;
@property (nonatomic) BOOL isExpirationDateEnabled;
@property (nonatomic) BOOL isAllowEditingEnabled;
@property (nonatomic) BOOL isAllowEditingShown;
@property (nonatomic, strong) NSString* sharedToken;
@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;
@property (nonatomic, strong) MBProgressHUD* loadingView;
@property (nonatomic, strong) UIAlertView *passwordView;
@property (nonatomic, strong) UIActivityViewController *activityView;
@property (nonatomic, strong) EditAccountViewController *resolveCredentialErrorViewController;
@property (nonatomic, strong) UIPopoverController* activityPopoverController;
@property (nonatomic, strong) NSMutableArray *sharedUsersOrGroups;
@property (nonatomic, strong) NSMutableArray *sharesOfFile;
@property (nonatomic) NSInteger permissions;

@end


@implementation ShareMainViewController


- (id) initWithFileDto:(FileDto *)fileDto {
    
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.sharedItem = fileDto;
        self.optionsShownWithShareLink = 0;
        self.isShareLinkEnabled = false;
        self.isPasswordProtectEnabled = false;
        self.isExpirationDateEnabled = false;
        self.isAllowEditingEnabled = false;
        self.isAllowEditingShown = false;
        self.sharedUsersOrGroups = [NSMutableArray new];
        self.sharesOfFile = [NSMutableArray new];


    }
    
    return self;
}

- (void) viewDidLoad{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
    
    [self checkSharedStatusOFile];
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

- (BOOL) hasAllowEditingToBeShown {

    if (((APP_DELEGATE.activeUser.hasCapabilitiesSupport != serverFunctionalitySupported) ||
        (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAllowPublicUploadsEnabled))
        && self.sharedItem.isDirectory){
        return YES;
        
    } else {
        
        return NO;
    }
}

#pragma mark - Accessory alert views

- (void) showPasswordView {
    
    if (self.passwordView != nil) {
        self.passwordView = nil;
    }
    
    self.passwordView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"shared_link_protected_title", nil)
                                                  message:nil delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                        otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
    
    self.passwordView.tag = password_alert_view_tag;
    self.passwordView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [self.passwordView textFieldAtIndex:0].delegate = self;
    [[self.passwordView textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeNo];
    [[self.passwordView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [[self.passwordView textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeDefault];
    [[self.passwordView textFieldAtIndex:0] setKeyboardAppearance:UIKeyboardAppearanceLight];
    [[self.passwordView textFieldAtIndex:0] setSecureTextEntry:true];
    
    [self.passwordView show];
}

#pragma mark - Date Picker methods

- (void) launchDatePicker{
    
    static CGFloat controlToolBarHeight = 44.0;
    static CGFloat datePickerViewYPosition = 40.0;
    static CGFloat datePickerViewHeight = 300.0;
    static CGFloat pickerViewHeight = 250.0;
    static CGFloat deltaSpacerWidthiPad = 150.0;
 
    
    self.datePickerContainerView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.datePickerContainerView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.datePickerContainerView];
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.delegate = self;
    recognizer.cancelsTouchesInView = true;
    [self.datePickerContainerView addGestureRecognizer:recognizer];

    UIToolbar *controlToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, controlToolBarHeight)];
    [controlToolbar sizeToFit];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dateSelected:)];
    
    UIBarButtonItem *spacer;
    
    if (IS_IPHONE) {
         spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }else{
         spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
         CGFloat width = self.view.frame.size.width - deltaSpacerWidthiPad;
         spacer.width = width;
    }
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeDatePicker)];
    

    [controlToolbar setItems:[NSArray arrayWithObjects:cancelButton, spacer, doneButton, nil] animated:NO];
    
    if (self.datePickerView == nil) {
        self.datePickerView = [[UIDatePicker alloc] init];
        self.datePickerView.datePickerMode = UIDatePickerModeDate;
        
        NSDateComponents *deltaComps = [NSDateComponents new];
        [deltaComps setDay:1];
        NSDate *tomorrow = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:[NSDate date] options:0];
        
        self.datePickerView.minimumDate = tomorrow;
    }
    
    [self.datePickerView setFrame:CGRectMake(0, datePickerViewYPosition, self.view.frame.size.width, datePickerViewHeight)];
    
    if (!self.pickerView) {
        self.pickerView = [[UIView alloc] initWithFrame:self.datePickerView.frame];
    } else {
        [self.pickerView setHidden:NO];
    }
    
    
    [self.pickerView setFrame:CGRectMake(0,
                                         self.view.frame.size.height,
                                         self.view.frame.size.width,
                                         pickerViewHeight)];
    
    [self.pickerView setBackgroundColor: [UIColor whiteColor]];
    [self.pickerView addSubview: controlToolbar];
    [self.pickerView addSubview: self.datePickerView];
    [self.datePickerView setHidden: false];
    
    [self.datePickerContainerView addSubview:self.pickerView];
    
    [UIView animateWithDuration:animationsDelay
                     animations:^{
                         [self.pickerView setFrame:CGRectMake(0,
                                                              self.view.frame.size.height - self.pickerView.frame.size.height,
                                                              self.view.frame.size.width,
                                                              pickerViewHeight)];
                     }
                     completion:nil];
    
}


- (void) dateSelected:(UIBarButtonItem *)sender{
    
    [self closeDatePicker];
    
    NSString *dateString = [self convertDateInServerFormat:self.datePickerView.date];
    
    [self updateSharedLinkWithPassword:nil expirationDate:dateString permissions:k_permissions_do_not_update];
    
}

- (void) closeDatePicker {
    [UIView animateWithDuration:animationsDelay animations:^{
        [self.pickerView setFrame:CGRectMake(self.pickerView.frame.origin.x,
                                         self.view.frame.size.height,
                                         self.pickerView.frame.size.width,
                                         self.pickerView.frame.size.height)];
    } completion:^(BOOL finished) {
        [self.datePickerContainerView removeFromSuperview];
    }];
    
    [self updateInterfaceWithShareLinkStatus];
    
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    [self.datePickerContainerView removeGestureRecognizer:sender];
    [self closeDatePicker];
}

- (NSString *) converDateInCorrectFormat:(NSDate *) date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];

    return [dateFormatter stringFromDate:date];
}

- (NSString *) convertDateInServerFormat:(NSDate *)date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateFormat:dateServerFormat];
    
    return [dateFormatter stringFromDate:date];
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
    
    if (self.isShareLinkEnabled){
        
        if (self.isAllowEditingShown){
            self.optionsShownWithShareLink = optionsShownWithShareLinkEnableAndAllowEditing;
        }else{
            self.optionsShownWithShareLink = optionsShownWithShareLinkEnableWithoutAllowEditing;
        }
        
    }else{
        self.optionsShownWithShareLink = optionsShownWithShareLinkDisable;
        self.isPasswordProtectEnabled = false;
        self.isExpirationDateEnabled = false;
        self.isShareLinkEnabled = false;
        self.isAllowEditingShown = false;
        self.isAllowEditingEnabled =false;
    }
    
    [self.shareTableView reloadData];
}

#pragma mark - Action Methods

- (void) updateInterfaceWithShareLinkStatus {
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    if ([ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser]) {
        
        self.isShareLinkEnabled = true;
        
        self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
        
        if (self.sharedFileOrFolder == nil) {
            self.sharedFileOrFolder = [ShareFileOrFolder new];
            self.sharedFileOrFolder.delegate = self;
        }
        
        self.updatedOCShare = [ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser];
        
        if (![ self.updatedOCShare.shareWith isEqualToString:@""] && ![ self.updatedOCShare.shareWith isEqualToString:@"NULL"]  &&  self.updatedOCShare.shareType == shareTypeLink) {
            self.isPasswordProtectEnabled = true;
        }else{
            self.isPasswordProtectEnabled = false;
        }
        
        if (self.updatedOCShare.expirationDate == 0.0) {
            self.isExpirationDateEnabled = false;
        }else {
            self.isExpirationDateEnabled = true;
        }
        
        self.isAllowEditingShown = [self hasAllowEditingToBeShown];
        self.isAllowEditingEnabled = [UtilsFramework isPermissionToReadCreateUpdate:self.updatedOCShare.permissions];
        
    }else{
        self.isShareLinkEnabled = false;
    }
    
    [self checkForShareWithUsersOrGroups];
    
    [self reloadView];
    
}

- (void) checkForShareWithUsersOrGroups {
    
    NSString *path = [NSString stringWithFormat:@"/%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser], self.sharedItem.fileName];
    
    NSArray *sharesWith = [ManageSharesDB getSharesByUser:APP_DELEGATE.activeUser.idUser andPath:path];
    
    DLog(@"SharesWith: %@", sharesWith);
    
    [self.sharedUsersOrGroups removeAllObjects];
    [self.sharesOfFile removeAllObjects];
    
    for (OCSharedDto *shareWith in sharesWith) {
        if (shareWith.shareType == shareTypeUser || shareWith.shareType == shareTypeGroup || shareWith.shareType == shareTypeRemote) {
            
            OCShareUser *shareUser = [OCShareUser new];
            shareUser.name = shareWith.shareWith;
            shareUser.displayName = shareWith.shareWithDisplayName;
            shareUser.sharedDto = shareWith;
            shareUser.shareeType = shareWith.shareType;
            
            [self.sharedUsersOrGroups addObject:shareUser];
            [self.sharesOfFile addObject:shareWith];
        }
    }
    
    self.sharedUsersOrGroups = [ShareUtils manageTheDuplicatedUsers:self.sharedUsersOrGroups]; 
 
}



- (void) didSelectCloseView {
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) sharedLinkSwithValueChanged: (UISwitch*)sender {
    
    if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto) {
        OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
        
        if (!cap.isFilesSharingShareLinkEnabled) {
            sender.on = false;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not_share_link_enabled_capabilities", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alertView show];
            return;
        }
    }
    
    self.isShareLinkEnabled = sender.on;
    
    if (self.isShareLinkEnabled) {
        [self getShareLinkView];
    } else {
        [self unShareByLink];
    }
}


- (void) passwordProtectedSwithValueChanged:(UISwitch*) sender{
    
     if (self.isPasswordProtectEnabled){

        if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported) {
            OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
            
            if (cap.isFilesSharingPasswordEnforcedEnabled) {
                //not remove, is enforced password
                sender.on = true;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"shared_link_cannot_remove_password", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
        }
        
        //Remove password Protected
        [self updateSharedLinkWithPassword:@"" expirationDate:nil permissions:k_permissions_do_not_update];
         
     } else {
         //Update with password protected
         [self showPasswordView];
     }
}

- (void) expirationTimeSwithValueChanged:(UISwitch*) sender{
    
    if (self.isExpirationDateEnabled) {
        if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported) {
            OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
            
            if (cap.isFilesSharingExpireDateEnforceEnabled) {
                //not remove, is enforced expiration date
                sender.on = true;
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"shared_link_cannot_remove_expiration_date", nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
        }
        
        //Remove expiration date
        [self updateSharedLinkWithPassword:nil expirationDate:@"" permissions:k_permissions_do_not_update];
        
    } else {
        //Update with expiration date
        [self launchDatePicker];
    }
    
}

- (void) allowEditingSwithValueChanged:(UISwitch*) sender{
    
    if (self.isAllowEditingEnabled) {
        self.permissions = [UtilsFramework getPermissionsValueByCanEdit:NO andCanCreate:NO andCanChange:NO andCanDelete:NO andCanShare:NO andIsFolder:YES];        
    } else {
        self.permissions = [UtilsFramework getPermissionsValueByCanEdit:YES andCanCreate:YES andCanChange:YES andCanDelete:NO andCanShare:NO andIsFolder:YES];
    }
    
    //update permissions
    [self updateSharedLinkWithPassword:nil expirationDate:nil permissions:self.permissions];
}

#pragma mark - Actions with ShareFileOrFolder class

- (void) getShareLinkView {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    if (IS_IPHONE) {
        self.sharedFileOrFolder.viewToShow = self.view;
        self.sharedFileOrFolder.parentViewController = self;
    }else{
        self.sharedFileOrFolder.viewToShow = self.view;
        self.sharedFileOrFolder.parentViewController = self;
        self.sharedFileOrFolder.parentView = self.view;
    }
    
    if (self.sharedItem.sharedFileSource > 0){
        self.sharedFileOrFolder.file = self.sharedItem;
        [self.sharedFileOrFolder clickOnShareLinkFromFileDto:true];
    }else{
        [self.sharedFileOrFolder showShareActionSheetForFile:self.sharedItem];
    }
}

- (void) unShareByLink {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    OCSharedDto *ocShare = [ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser];
    
    if (ocShare != nil) {
        [self.sharedFileOrFolder unshareTheFile:ocShare];
    }
    
}

- (void) unShareWith:(OCSharedDto *) share{
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    [self.sharedFileOrFolder unshareTheFile:share];
    
}

- (void) updateSharedLinkWithPassword:(NSString*) password expirationDate:(NSString*)expirationDate permissions:(NSInteger)permissions{
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    OCSharedDto *ocShare = [ManageSharesDB getTheOCShareByFileDto:self.sharedItem andShareType:shareTypeLink andUser:APP_DELEGATE.activeUser];

    [self.sharedFileOrFolder updateShareLink:ocShare withPassword:password expirationTime:expirationDate permissions:permissions];
    
}

- (void) checkSharedStatusOFile {
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    [self.sharedFileOrFolder checkSharedStatusOfFile:self.sharedItem];
    
}

#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    return YES;
}

#pragma mark - UIAlertView delegate methods


- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex
{
    
    if( buttonIndex == 1 ){
        //Update share item with password
        
        NSString* password = [alertView textFieldAtIndex:0].text;
        [self initLoading];
        [self updateSharedLinkWithPassword:password expirationDate:nil permissions:k_permissions_do_not_update];
        
    }else if (buttonIndex == 0) {
        //Cancel
        [self reloadView];
        
    }else {
        //Nothing
    }

}


- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    BOOL output = YES;
    if (alertView.tag == password_alert_view_tag) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0){
            output = NO;
        }
    }

    return output;
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    NSInteger numberOfSections = shareTableViewSectionsNumber;
    
    if (!k_is_share_with_users_available) {
        numberOfSections--;
    }
    
    if (!k_is_share_by_link_available) {
        numberOfSections--;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }else if (section == 1 && k_is_share_with_users_available){
        if (self.sharedUsersOrGroups.count == 0) {
           return self.sharedUsersOrGroups.count + 1;
        }else{
           return self.sharedUsersOrGroups.count;
        }
    } else if ((section == 1 || section == 2) && k_is_share_by_link_available){
        return self.optionsShownWithShareLink;
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    switch (indexPath.section) {
        case 0:
            
            cell = [self getCellOfFileOrFolderInformationByTableView:tableView];
            
            break;
        case 1:
            
            //All available
            if (k_is_share_with_users_available) {
                
                if (indexPath.row == 0 && self.sharedUsersOrGroups.count == 0) {
                    
                    cell = [self getCellShareUserByTableView:tableView];
                    
                } else {
                    
                    cell = [self getCellOfUserOrGroupNameSharedByTableView:tableView andIndexPath:indexPath];
                    
                }
              
            } else if (!k_is_share_with_users_available && k_is_share_by_link_available) {
                if ((indexPath.row == 2 && !self.isAllowEditingShown) || (indexPath.row == 3 && self.isAllowEditingShown)) {
                    
                    cell = [self getCellShareLinkButtonByTableView:tableView];
                    
                } else {
                    
                    cell = [self getCellOptionShareLinkByTableView:tableView andIndex:indexPath];
                    
                }
                
            }
            break;
        case 2:

            if ((indexPath.row == 2 && !self.isAllowEditingShown) || (indexPath.row == 3 && self.isAllowEditingShown)) {
                
                cell = [self getCellShareLinkButtonByTableView:tableView];

            } else {
                
                cell = [self getCellOptionShareLinkByTableView:tableView andIndex:indexPath];
                
            }
            break;
        default:
            break;
    }
    
    return cell;
    
}

#pragma mark - Cells

- (UITableViewCell *) getCellOfFileOrFolderInformationByTableView:(UITableView *) tableView {
    
    ShareFileCell* shareFileCell = (ShareFileCell*)[tableView dequeueReusableCellWithIdentifier:shareFileCellIdentifier];
    
    if (shareFileCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareFileCellNib owner:self options:nil];
        shareFileCell = (ShareFileCell *)[topLevelObjects objectAtIndex:0];
    }
    
    NSString *itemName = [self.sharedItem.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    shareFileCell.fileName.hidden = self.sharedItem.isDirectory;
    shareFileCell.fileSize.hidden = self.sharedItem.isDirectory;
    shareFileCell.folderName.hidden = !self.sharedItem.isDirectory;
    
    if (self.sharedItem.isDirectory) {
        shareFileCell.fileImage.image = [UIImage imageNamed:@"folder_icon"];
        shareFileCell.folderName.text = @"";
        //Remove the last character (folderName/ -> folderName)
        shareFileCell.folderName.text = [itemName substringToIndex:[itemName length]-1];
        
    }else{
        shareFileCell.fileImage.image = [UIImage imageNamed:[FileNameUtils getTheNameOfTheImagePreviewOfFileName:[self.sharedItem.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        shareFileCell.fileSize.text = [NSByteCountFormatter stringFromByteCount:[NSNumber numberWithLong:self.sharedItem.size].longLongValue countStyle:NSByteCountFormatterCountStyleMemory];
        shareFileCell.fileName.text = itemName;
    }
    
    return shareFileCell;
    
}

- (UITableViewCell *) getCellShareUserByTableView:(UITableView *) tableView {
    
    ShareUserCell* shareUserCell = (ShareUserCell*)[tableView dequeueReusableCellWithIdentifier:shareUserCellIdentifier];
    
    if (shareUserCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
        shareUserCell = (ShareUserCell *)[topLevelObjects objectAtIndex:0];
    }
    
    NSString *name = NSLocalizedString(@"not_share_with_users_yet", nil);
    
    shareUserCell.itemName.text = name;
    shareUserCell.itemName.textColor = [UIColor grayColor];
    
    shareUserCell.selectionStyle = UITableViewCellEditingStyleNone;
    
    return shareUserCell;
    
}

- (UITableViewCell *) getCellOfUserOrGroupNameSharedByTableView:(UITableView *) tableView andIndexPath:(NSIndexPath *) indexPath {
    
    ShareUserCell* shareUserCell = (ShareUserCell*)[tableView dequeueReusableCellWithIdentifier:shareUserCellIdentifier];
    
    if (shareUserCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
        shareUserCell = (ShareUserCell *)[topLevelObjects objectAtIndex:0];
    }
    
    
    OCShareUser *shareUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
    
    NSString *name;
    
    if (shareUser.shareeType == shareTypeGroup) {
        name = [NSString stringWithFormat:@"%@ (%@)",shareUser.name, NSLocalizedString(@"share_user_group_indicator", nil)];
    } else {
        
        if (shareUser.isDisplayNameDuplicated) {
            name = [NSString stringWithFormat:@"%@ (%@)", shareUser.displayName, shareUser.name];
        }else{
            name = shareUser.displayName;
        }
    }
    
    shareUserCell.itemName.text = name;
    
    shareUserCell.selectionStyle = UITableViewCellEditingStyleNone;
    
    shareUserCell.accessoryType = UITableViewCellAccessoryDetailButton;
    
    return shareUserCell;
    
}

- (UITableViewCell *) getCellShareLinkButtonByTableView:(UITableView *) tableView {
    ShareLinkButtonCell *shareLinkButtonCell = [tableView dequeueReusableCellWithIdentifier:shareLinkButtonIdentifier];
    
    if (shareLinkButtonCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkButtonNib owner:self options:nil];
        shareLinkButtonCell = (ShareLinkButtonCell *)[topLevelObjects objectAtIndex:0];
    }
    
    shareLinkButtonCell.shareLinkButton.layer.cornerRadius = 10;
    shareLinkButtonCell.shareLinkButton.clipsToBounds = YES;
    shareLinkButtonCell.shareLinkButton.backgroundColor = [UIColor colorOfLoginButtonBackground];
    [shareLinkButtonCell.shareLinkButton setTitleColor:[UIColor colorOfLoginButtonTextColor] forState:UIControlStateNormal];
    [shareLinkButtonCell.shareLinkButton setTitle:NSLocalizedString(@"get_share_link", nil) forState:UIControlStateNormal];
    
    shareLinkButtonCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [shareLinkButtonCell.shareLinkButton addTarget:self action:@selector(didSelectGetShareLink) forControlEvents:UIControlEventTouchUpInside];
    
    return shareLinkButtonCell;
}

- (UITableViewCell *) getCellOptionShareLinkByTableView:(UITableView *) tableView andIndex:(NSIndexPath *) indexPath {
    
    ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];
    
    if (shareLinkOptionCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
        shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
    }

    [shareLinkOptionCell.optionSwith removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    
    switch (indexPath.row) {
        case 0:
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"set_expiration_time", nil);
            
            if (self.isExpirationDateEnabled) {
                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.text = [self converDateInCorrectFormat:[NSDate dateWithTimeIntervalSince1970: self.updatedOCShare.expirationDate]];
            }else{
                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.text = @"";
            }
            [shareLinkOptionCell.optionSwith setOn:self.isExpirationDateEnabled animated:false];
            
            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(expirationTimeSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;
            
        case 1:
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"password_protect", nil);
            
            if (self.isPasswordProtectEnabled) {
                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.text = NSLocalizedString(@"secured_link", nil);
            } else {
                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.text = @"";
            }
            [shareLinkOptionCell.optionSwith setOn:self.isPasswordProtectEnabled animated:false];
            
            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(passwordProtectedSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;
            
        case 2:
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"allow_editing", nil);
            
            if (self.isAllowEditingEnabled) {
                shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
            } else {
                shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
            }
            shareLinkOptionCell.optionDetail.text = @"";
            [shareLinkOptionCell.optionSwith setOn:self.isAllowEditingEnabled animated:false];
            
            [shareLinkOptionCell.optionSwith addTarget:self action:@selector(allowEditingSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;
            
        default:
            //Not expected
            DLog(@"Not expected");
            break;
    }
    
    return shareLinkOptionCell;
    
}






- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0.0;
    
    switch (indexPath.section) {
        case 0:
            height = heighOfFileDetailrow;
            break;
        case 1:
            if (k_is_share_with_users_available) {
                
                if (indexPath.row == 0 && self.sharedUsersOrGroups.count == 0){
                    height = heightOfShareWithUserRow;
                }else if ((indexPath.row == 1 && self.sharedUsersOrGroups.count == 0) || (indexPath.row == self.sharedUsersOrGroups.count)){
                    height = heightOfShareLinkButtonRow;
                }else{
                    height = heightOfShareWithUserRow;
                }
                
            } else {
                if ((indexPath.row == 2 && !self.isAllowEditingShown) || (indexPath.row == 3 && self.isAllowEditingShown)) {
                    height = heightOfShareLinkButtonRow;
                }else{
                    height = heightOfShareLinkOptionRow;
                }
            }
            break;
        case 2:
            if ((indexPath.row == 2 && !self.isAllowEditingShown) || (indexPath.row == 3 && self.isAllowEditingShown)) {
                height = heightOfShareLinkButtonRow;
            }else{
                height = heightOfShareLinkOptionRow;
            }
            break;
            
        default:
            break;
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.shareTableView.frame.size.width, 1)];
    
    
    if (section == 1 || section == 2) {
        
        ShareLinkHeaderCell* shareLinkHeaderCell = [tableView dequeueReusableCellWithIdentifier:shareLinkHeaderIdentifier];
        
        if (shareLinkHeaderCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkHeaderNib owner:self options:nil];
            shareLinkHeaderCell = (ShareLinkHeaderCell *)[topLevelObjects objectAtIndex:0];
        }
        
        switch (section) {
            case 1:
                if (k_is_share_with_users_available) {
                    shareLinkHeaderCell = [self getHeaderCellForShareWithUsersOrGroups:shareLinkHeaderCell];
                } else if (!k_is_share_with_users_available && k_is_share_by_link_available){
                    shareLinkHeaderCell = [self getHeaderCellForShareByLink:shareLinkHeaderCell];
                }
                break;
            case 2:
                if (k_is_share_by_link_available){
                    shareLinkHeaderCell = [self getHeaderCellForShareByLink:shareLinkHeaderCell];
                }
                break;
                
            default:
                break;
        }
        
        headerView = shareLinkHeaderCell.contentView;
        
    }
    
    return headerView;
}

/*
 * Method to get the header for the first section: Share with user or groups
 */
- (ShareLinkHeaderCell *) getHeaderCellForShareWithUsersOrGroups:(ShareLinkHeaderCell *) shareLinkHeaderCell {
    
    shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_with_users_or_groups", nil);
    shareLinkHeaderCell.switchSection.hidden = true;
    shareLinkHeaderCell.addButtonSection.hidden = false;
    
    [shareLinkHeaderCell.addButtonSection addTarget:self action:@selector(didSelectAddUserOrGroup) forControlEvents:UIControlEventTouchUpInside];
    
    return shareLinkHeaderCell;
}

/*
 * Method to get the header for the second section: Share by link
 */
- (ShareLinkHeaderCell *) getHeaderCellForShareByLink:(ShareLinkHeaderCell *) shareLinkHeaderCell {
    
    shareLinkHeaderCell.switchSection.hidden = false;
    shareLinkHeaderCell.addButtonSection.hidden = true;
    
    shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_link_title", nil);
    [shareLinkHeaderCell.switchSection setOn:self.isShareLinkEnabled animated:false];
    [shareLinkHeaderCell.switchSection addTarget:self action:@selector(sharedLinkSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    return shareLinkHeaderCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    switch (indexPath.section) {
        case 1:
            if (k_is_share_with_users_available && (self.sharedUsersOrGroups.count == 0 && indexPath.row == self.sharedUsersOrGroups.count + 1) || (self.sharedUsersOrGroups.count > 0 && indexPath.row == self.sharedUsersOrGroups.count)) {
                [self didSelectAddUserOrGroup];
            } else if(!k_is_share_with_users_available && k_is_share_by_link_available) {
                [self didSelectShareLinkOptionSection:indexPath.row];
            }
            
            break;
        case 2:
            [self didSelectShareLinkOptionSection:indexPath.row];
            break;
        default:
            break;
    }
}

- (void) didSelectShareLinkOptionSection:(NSInteger) row {
    switch (row) {
        case 0:
            if (self.isExpirationDateEnabled) {
                [self didSelectSetExpirationDateLink];
            }
            break;
        case 1:
            if (self.isPasswordProtectEnabled) {
                [self didSelectSetPasswordLink];
            }
            break;
        default:
            break;
    }
}

- (void) didSelectAddUserOrGroup {
    //Check if the server has Sharee support
    if (APP_DELEGATE.activeUser.hasShareeApiSupport == serverFunctionalitySupported) {
        ShareSearchUserViewController *ssuvc = [[ShareSearchUserViewController alloc] initWithNibName:@"ShareSearchUserViewController" bundle:nil];
        ssuvc.shareFileDto = self.sharedItem;
        [ssuvc setAndAddSelectedItems:self.sharedUsersOrGroups];
        self.activityView = nil;
        [self.navigationController pushViewController:ssuvc animated:NO];
    }else{
        [self showErrorWithTitle:NSLocalizedString(@"not_sharee_api_supported", nil)];
        
    }
}

- (void) didSelectSetExpirationDateLink {
    [self launchDatePicker];
}

- (void) didSelectSetPasswordLink {
    [self showPasswordView];
}

- (void) didSelectGetShareLink {
    [self getShareLinkView];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (indexPath.section) {
        case 0:
            return NO;
            break;
        case 1:
            if (k_is_share_with_users_available && self.sharedUsersOrGroups.count > 0) {
                return YES;
            } else {
                return NO;
            }
            break;
        case 2:
            return NO;
            break;
        default:
            return NO;
            break;
    }
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        OCShareUser *shareUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
        
        for (OCSharedDto *shareWith in self.sharesOfFile) {
            if ([shareUser.name isEqualToString:shareWith.shareWith]) {
                [self unShareWith:shareWith];
                break;
            }
        }
        
    }
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
    //Edit share with user Privileges
    
    OCShareUser *shareUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
    OCSharedDto *sharedDto = shareUser.sharedDto;

    
    ShareEditUserViewController *viewController = [[ShareEditUserViewController alloc] initWithFileDto:self.sharedItem andOCSharedDto:sharedDto];
    OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
    
    if (IS_IPHONE)
    {
        viewController.hidesBottomBarWhenPushed = YES;
        [self presentViewController:navController animated:YES completion:nil];
    } else {
        OCNavigationController *navController = nil;
        navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navController animated:YES completion:nil];
    }

    
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
    
    if (!APP_DELEGATE.isLoadingVisible) {
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

- (void) finishShareWithStatus:(BOOL)successful andWithOptions:(UIActivityViewController*) activityView{
    
    if (successful) {
         self.activityView = activityView;
         [self checkSharedStatusOFile];
        
    }else{
       [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];

    }
}

- (void) finishUnShareWithStatus:(BOOL)successful {
    
    if (successful) {
        self.activityView = nil;
        [self checkSharedStatusOFile];
    }else{
        [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    }
    
}

- (void) finishUpdateShareWithStatus:(BOOL)successful {
    
    [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    
}

- (void) finishCheckSharedStatusOfFile:(BOOL)successful {
    
    if (successful && self.activityView != nil) {
        [self updateInterfaceWithShareLinkStatus];
        [self performSelector:@selector(presentShareOptions) withObject:nil afterDelay:standardDelay];
    }else{
        [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    }

}


- (void) presentShareOptions{
    
    
    NSString *fileOrFolderName = self.sharedItem.fileName;
    if(self.sharedItem.isDirectory){
        //Remove the last character (folderName/ -> folderName)
        fileOrFolderName = [fileOrFolderName substringToIndex:fileOrFolderName.length -1];
    }
    
    NSString *subject = [[NSLocalizedString(@"shared_link_mail_subject", nil)stringByReplacingOccurrencesOfString:@"$userName" withString:[ManageUsersDB getActiveUser].username]stringByReplacingOccurrencesOfString:@"$fileOrFolderName"  withString:[fileOrFolderName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [self.activityView setValue:subject forKey:k_subject_key_activityView];
    
    if (IS_IPHONE) {
        [self presentViewController:self.activityView animated:true completion:nil];
        [self performSelector:@selector(reloadView) withObject:nil afterDelay:standardDelay];
    }else{
        [self reloadView];
        
        self.activityPopoverController = [[UIPopoverController alloc]initWithContentViewController:self.activityView];
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:2 inSection:1];
        UITableViewCell* cell = [self.shareTableView cellForRowAtIndexPath:indexPath];
        
        [self.activityPopoverController presentPopoverFromRect:cell.frame inView:self.shareTableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
    }
}

#pragma mark - Error Login Methods

- (void) showEditAccount {
    
#ifdef CONTAINER_APP
    
    //Edit Account
    self.resolveCredentialErrorViewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:[ManageUsersDB getActiveUser] andLoginMode:LoginModeExpire];
    
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

- (void)showErrorWithTitle: (NSString *)title {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
    [alertView show];
    
    
}

#pragma mark - UIGestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // test if our control subview is on-screen
    if ([touch.view isDescendantOfView:self.pickerView]) {
        // we touched our control surface
        return NO;
    }
    return YES;
}

@end
