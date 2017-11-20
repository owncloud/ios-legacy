//
//  ShareLinkViewController.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 25/04/17.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "ShareLinkViewController.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "UtilsFramework.h"
#import "ManageFilesDB.h"
#import "ManageSharesDB.h"

#define shareLinkViewNibName @"ShareLinkViewController"

//Cells and Sections
#define shareLinkOptionIdentifer @"ShareLinkOptionIdentifier"
#define shareLinkOptionNib @"ShareLinkOptionCell"
#define nOfSectionsWithAllOptionsAvailable 5

#define heightOfShareLinkOptionRow 55.0f
#define heightOfShareLinkOptionSection 25.0f
#define heightOfShareLinkOptionTitleFirstSection 55.0f
#define heightOfShareLinkOptionFooterSection 37.0f

//mail subject key
#define k_subject_key_activityView @"subject"

#define animationsDelay 0.5

#define k_permissions_when_file_listing_option_enabled 4

typedef NS_ENUM (NSInteger, LinkOption){
    LinkOptionName,
    LinkOptionPassword,
    LinkOptionExpiration,
    LinkOptionAllowUploads,
    LinkOptionShowFileListing
};

@interface ShareLinkViewController ()

@property (nonatomic) BOOL isPasswordProtectEnabled;
@property (nonatomic) BOOL isExpirationDateEnabled;

@property (nonatomic) NSInteger optionsShownWithShareLink;

@property (nonatomic) BOOL isAllowEditingEnabled;
@property (nonatomic) BOOL isShowFileListingEnabled;

@property (nonatomic, strong) UIPopoverController* activityPopoverController;


@end

@implementation ShareLinkViewController


- (id) initWithFileDto:(FileDto *)fileDto andOCSharedDto:(OCSharedDto *)sharedDto andDefaultLinkName:(NSString *)defaultLinkName andLinkOptionsViewMode:(LinkOptionsViewMode)linkOptionsViewMode {
    
    if ((self = [super initWithNibName:shareLinkViewNibName bundle:nil]))
    {
        _linkOptionsViewMode = linkOptionsViewMode;
        _fileShared = fileDto;
        _sharedDto = sharedDto;
        
        _oldPublicUploadState = (_sharedDto.permissions > 1) ? @"true" : @"false";
        // if permission is an odd value, read perimssion (last bit) is enabled
        _oldShowFileListing = (_sharedDto.permissions % 2 == 1) ? @"true" : @"false";
        
        _updatedPassword = @"";
        
        
        if (_linkOptionsViewMode == LinkOptionsViewModeCreate) {
            
            _updatedLinkName = defaultLinkName;
            _updatedExpirationDate = [ShareUtils getDefaultMaxExpirationDateInTimeInterval];
            _updatedPublicUpload = nil;
            _updatedShowFileListing = nil;

            
            if ([ShareUtils hasExpirationDefaultDateToBeShown] || ![ShareUtils hasExpirationRemoveOptionAvailable]) {
                _isExpirationDateEnabled = YES;
            } else {
                _isExpirationDateEnabled = NO;
            }

            _isPasswordProtectEnabled =  [ShareUtils hasPasswordRemoveOptionAvailable] ? NO : YES;

            _isAllowEditingEnabled = NO;
            
            _isShowFileListingEnabled = YES;    // public links are readable by default
            
        } else {
            
            _updatedLinkName = _sharedDto.name;
            _updatedExpirationDate = _sharedDto.expirationDate;
            _updatedPublicUpload = (_sharedDto.permissions > 1) ? @"true" : @"false";
            _updatedShowFileListing = (_sharedDto.permissions % 2 == 1) ? @"true" : @"false";

            
            if (![_sharedDto.shareWith isEqualToString:@""] && ![ _sharedDto.shareWith isEqualToString:@"NULL"]) {
                _isPasswordProtectEnabled = YES;
                _oldPasswordEnabledState = YES;
            }else{
                _isPasswordProtectEnabled = NO;
                _oldPasswordEnabledState = NO;
            }
            
            [self updateEnabledOptions];
        }

    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setStyleView];
}


#pragma mark - Action Methods
- (void) reloadView {

    [self.shareLinkOptionsTableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(NSInteger) getNumberOfOptionsAvailable {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    NSInteger nOfOptionsAvailable = nOfSectionsWithAllOptionsAvailable;
    
    if (![ShareUtils hasOptionLinkNameToBeShown]) {
        nOfOptionsAvailable = nOfOptionsAvailable -1;
    }
    
    if (![ShareUtils hasOptionAllowEditingToBeShownForFile:self.fileShared]) {
        nOfOptionsAvailable = nOfOptionsAvailable -1;
    }
    
    if (![ShareUtils hasOptionShowFileListingToBeShownForFile:self.fileShared]) {
        nOfOptionsAvailable = nOfOptionsAvailable -1;
    }
    
    return nOfOptionsAvailable;
}


#pragma mark - TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return [self getNumberOfOptionsAvailable];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [self getCellOptionShareLinkByTableView:tableView andIndex:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.isExpirationDateEnabled || ![ShareUtils hasExpirationRemoveOptionAvailable]) {
        if (indexPath.section == 2 || (indexPath.section == 1 && ![ShareUtils hasOptionLinkNameToBeShown]) ) {
            //the user want to change the current expiration date
            [self didSelectSetExpirationDateLink];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
             return heightOfShareLinkOptionTitleFirstSection;
            break;
        default:
             return heightOfShareLinkOptionSection;
            break;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return heightOfShareLinkOptionFooterSection;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return heightOfShareLinkOptionRow;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    NSString *title = nil;
    
    switch (section) {
        case 0:
            if ([ShareUtils hasOptionLinkNameToBeShown]) {
                title = NSLocalizedString(@"title_share_link_option_name", nil);
            } else {
                title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"title_share_link_option_password", nil), [ShareUtils hasPasswordRemoveOptionAvailable] ? @"" : @"*"];
            }
            break;
        case 1:
            if ([ShareUtils hasOptionLinkNameToBeShown]) {
                title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"title_share_link_option_password", nil), [ShareUtils hasPasswordRemoveOptionAvailable] ? @"" : @"*"];
            } else {
                title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"title_share_link_option_expiration", nil), [ShareUtils hasExpirationRemoveOptionAvailable] ? @"" : @"*"];
            }
            break;
        case 2:
            if ([ShareUtils hasOptionLinkNameToBeShown]) {
                title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"title_share_link_option_expiration", nil), [ShareUtils hasExpirationRemoveOptionAvailable] ? @"" : @"*"];
            }
            
            break;
            
        default:
            break;
    }
    
    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    
    NSString *title = nil;
    
    switch (section) {
        case 0:
            if (![ShareUtils hasOptionLinkNameToBeShown] && self.showErrorPasswordForced) {
                title = NSLocalizedString(@"show_error_password_enforced", nil);
            }
            break;
        case 1:
            if ([ShareUtils hasOptionLinkNameToBeShown]) {
                if(self.showErrorPasswordForced) {
                    title =  NSLocalizedString(@"show_error_password_enforced", nil);
                }
            } else if (![ShareUtils hasExpirationRemoveOptionAvailable]) {
                NSString *nDays = [NSString stringWithFormat:@"%d", APP_DELEGATE.activeUser.capabilitiesDto.filesSharingExpireDateDaysNumber];
                title = [NSLocalizedString(@"show_error_expiration_enforced", nil) stringByReplacingOccurrencesOfString:@"$nDays" withString:nDays];
            }
            break;
        case 2:
            if ([ShareUtils hasOptionLinkNameToBeShown] && ![ShareUtils hasExpirationRemoveOptionAvailable]) {
                NSString *nDays = [NSString stringWithFormat:@"%d", APP_DELEGATE.activeUser.capabilitiesDto.filesSharingExpireDateDaysNumber];
                title = [NSLocalizedString(@"show_error_expiration_enforced", nil) stringByReplacingOccurrencesOfString:@"$nDays" withString:nDays];
            }
            break;
            
        default:
            break;
    }
    
    return title;
    
    
}

#pragma mark - cells

- (UITableViewCell *) getCellOptionShareLinkByTableView:(UITableView *) tableView andIndex:(NSIndexPath *) indexPath {
    //TODO:update with data in other class
    ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];

    if (shareLinkOptionCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
        shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
    }

    [shareLinkOptionCell.optionSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    shareLinkOptionCell.tag = indexPath.section+1;
    
    switch (indexPath.section) {
            
        case 0:
            if ([ShareUtils hasOptionLinkNameToBeShown]) {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionName];
            } else {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionPassword];
            }
            break;

        case 1:
            if ([ShareUtils hasOptionLinkNameToBeShown]) {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionPassword];
            } else {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionExpiration];
            }
            break;

        case 2:
            if ([ShareUtils hasOptionLinkNameToBeShown]) {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionExpiration];
            } else {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionAllowUploads];
            }
            break;
            
        case 3:
            if ([ShareUtils hasOptionLinkNameToBeShown]) {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionAllowUploads];
            } else {
                [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionShowFileListing];
            }
            break;

        case 4:
            [self getUpdatedCell:shareLinkOptionCell toOption:LinkOptionShowFileListing];
            
            break;
            
        default:
            break;
    }

    return shareLinkOptionCell;
}

- (ShareLinkOptionCell *) getUpdatedCell:(ShareLinkOptionCell *)shareLinkOptionCell toOption:(LinkOption)linkOption {
    
    switch (linkOption) {
            
        case LinkOptionName:
            
            shareLinkOptionCell.optionName.hidden = YES;
            shareLinkOptionCell.optionTextField.hidden = NO;
            shareLinkOptionCell.optionTextField.placeholder = NSLocalizedString(@"placeholder_share_link_option_name", nil);
            shareLinkOptionCell.optionTextField.text = self.updatedLinkName;
            shareLinkOptionCell.optionTextField.inputAccessoryView = [self keyboardToolbarWithDoneButton];
            
            break;
        
        case LinkOptionPassword:
            
            shareLinkOptionCell.optionName.hidden = YES;
            shareLinkOptionCell.optionTextField.hidden = NO;
            shareLinkOptionCell.optionTextField.inputAccessoryView = [self keyboardToolbarWithDoneButton];
            
            if ([ShareUtils hasPasswordRemoveOptionAvailable]) {
                shareLinkOptionCell.optionSwitch.hidden = NO;
                [shareLinkOptionCell.optionSwitch setOn:self.isPasswordProtectEnabled animated:false];
                [shareLinkOptionCell.optionSwitch addTarget:self action:@selector(passwordProtectedSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            } else {
                shareLinkOptionCell.optionSwitch.hidden = YES;
            }
            
            if (self.isPasswordProtectEnabled) {
                shareLinkOptionCell.optionTextField.secureTextEntry = YES;
                if (self.oldPasswordEnabledState) {
                    shareLinkOptionCell.optionTextField.placeholder = @"**********";
                } else {
                    shareLinkOptionCell.optionTextField.placeholder = NSLocalizedString(@"placeholder_share_link_option_password", nil);
                }
                shareLinkOptionCell.optionTextField.userInteractionEnabled = YES;
            } else {
                shareLinkOptionCell.optionTextField.secureTextEntry = YES;
                shareLinkOptionCell.optionTextField.placeholder = NSLocalizedString(@"placeholder_share_link_option_password", nil);
                shareLinkOptionCell.optionTextField.userInteractionEnabled = NO;
            }
            
            shareLinkOptionCell.optionTextField.text = self.updatedPassword;
            
            break;
        
        case LinkOptionExpiration:
            
            shareLinkOptionCell.optionTextField.placeholder = NSLocalizedString(@"placeholder_share_link_option_expiration", nil);
            shareLinkOptionCell.optionTextField.inputAccessoryView = [self keyboardToolbarWithDoneButton];
            
            if ([ShareUtils hasExpirationRemoveOptionAvailable]) {
                shareLinkOptionCell.optionSwitch.hidden = NO;
                [shareLinkOptionCell.optionSwitch setOn:self.isExpirationDateEnabled animated:false];
                [shareLinkOptionCell.optionSwitch addTarget:self action:@selector(expirationTimeSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            } else {
                shareLinkOptionCell.optionSwitch.hidden = YES;
            }
            
            if (self.isExpirationDateEnabled) {
                shareLinkOptionCell.optionTextField.hidden = YES;
                shareLinkOptionCell.optionName.hidden = NO;
                shareLinkOptionCell.optionName.text = [ShareUtils stringOfDate:[NSDate dateWithTimeIntervalSince1970: self.updatedExpirationDate]];
            } else {
                shareLinkOptionCell.optionName.hidden = YES;
                shareLinkOptionCell.optionTextField.hidden = NO;
                shareLinkOptionCell.optionTextField.allowsEditingTextAttributes = NO;
                shareLinkOptionCell.optionTextField.userInteractionEnabled = NO;
            }
            
            break;
        
        case LinkOptionAllowUploads:
            
            shareLinkOptionCell.optionTextField.hidden = YES;
            shareLinkOptionCell.optionName.hidden = NO;
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_allow_editing", nil);
            shareLinkOptionCell.optionSwitch.hidden = NO;
            [shareLinkOptionCell.optionSwitch setOn:self.isAllowEditingEnabled animated:false];
            [shareLinkOptionCell.optionSwitch addTarget:self action:@selector(allowEditingSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;
            
        case LinkOptionShowFileListing:
            
            shareLinkOptionCell.optionTextField.hidden = YES;
            shareLinkOptionCell.optionName.hidden = NO;
            shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_show_file_listing", nil);
            shareLinkOptionCell.optionSwitch.hidden = NO;
            [shareLinkOptionCell.optionSwitch setEnabled:self.isAllowEditingEnabled];    // subordinate to "allow editing" option: enabled only if it is checked
            [shareLinkOptionCell.optionSwitch setOn:self.isShowFileListingEnabled animated:false];
            [shareLinkOptionCell.optionSwitch addTarget:self action:@selector(showFileListingSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            break;
            
        default:
            break;
    }
    
    return shareLinkOptionCell;
}

#pragma mark - keyboard

- (UIToolbar *) keyboardToolbarWithDoneButton {
    
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(didSelectKeyboardDoneButton)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    
    return keyboardToolbar;
}

- (void) didSelectKeyboardDoneButton {
    [self.view endEditing:YES];
}


#pragma mark - Select options

- (void) didSelectSetExpirationDateLink {
    [self.view endEditing:YES];
    [self launchDatePicker];
}

- (void) didSelectSaveShareLink {
    
    [self updateCurrentNameAndPasswordValuesByCheckingTextfields];
    
    if ([self checksBeforeSaveOK]){
        
        if (self.linkOptionsViewMode == LinkOptionsViewModeCreate) {
            
            [self createShareLink];
            
        } else {
            [self updateShareOptionsNeeded];
        }

        [self dismissViewControllerAnimated:true completion:nil];

    } else {
        [self reloadView];
    }
    
}

- (void) didSelectCloseView {
    [self dismissViewControllerAnimated:true completion:nil];
}

- (BOOL) checksBeforeSaveOK {
 
    BOOL allForcedValuesOK = YES;
    self.showErrorPasswordForced = NO;
    self.showErrorExpirationForced = NO;
    
    if ( ![ShareUtils hasPasswordRemoveOptionAvailable] && [self.updatedPassword isEqualToString:@""]  && self.linkOptionsViewMode == LinkOptionsViewModeCreate ) {
        allForcedValuesOK = NO;
        self.showErrorPasswordForced = YES;
    }
    
    if (![ShareUtils hasExpirationRemoveOptionAvailable] && !self.updatedExpirationDate) {
        allForcedValuesOK = NO;
        self.showErrorExpirationForced = YES;
    }
    
    return allForcedValuesOK;
}

#pragma mark - Network requests 
//TODO: move to other class notsharedFileOrFolder

- (void) createShareLink {
    
    NSString *updateLinkName = nil;
    NSString *updatePassword = nil;
    NSString *updateExpirationTime = nil;
    NSString *updatePublicUpload = nil;
    NSInteger permissions = 0;

    
    if (self.updatedLinkName) {
        updateLinkName = self.updatedLinkName;
    }
    
    if (self.isPasswordProtectEnabled && ![self.updatedPassword isEqualToString:@""]) {
        updatePassword = self.updatedPassword;
        self.showErrorExpirationForced = NO;
    }
    
    if (self.isExpirationDateEnabled) {
        updateExpirationTime = [ShareUtils convertDateInServerFormat:[NSDate dateWithTimeIntervalSince1970: self.updatedExpirationDate]];
        self.showErrorExpirationForced = NO;
    }
    
    if (self.isAllowEditingEnabled && self.fileShared.isDirectory) {
        
        updatePublicUpload = self.updatedPublicUpload;

        if (!self.isShowFileListingEnabled) {
            permissions = k_permissions_when_file_listing_option_enabled;
        }
    }
    
    [self.sharedFileOrFolder doRequestCreateShareLinkOfFile:self.fileShared withPassword:updatePassword expirationTime:updateExpirationTime publicUpload:updatePublicUpload linkName:updateLinkName andPermissions:permissions];
}

- (void) updateShareOptionsNeeded {

    //NAME
    if (![self.updatedLinkName isEqualToString:self.sharedDto.name] && [ShareUtils hasOptionLinkNameToBeShown]) {
        
        [self updateSharedLinkWithPassword:nil expirationDate:nil publicUpload:nil linkName:self.updatedLinkName andFileListing:nil];
    }
    
    //PASSWORD
    if (self.isPasswordProtectEnabled && ![self.updatedPassword isEqualToString:@""] ) {

        [self updateSharedLinkWithPassword:self.updatedPassword expirationDate:nil publicUpload:nil linkName:nil andFileListing:nil];
        
    } else if (_oldPasswordEnabledState && !self.isPasswordProtectEnabled){
        //Remove previous password
        [self updateSharedLinkWithPassword:@"" expirationDate:nil publicUpload:nil linkName:nil andFileListing:nil];
    }
    
    //EXPIRATION
    if (self.updatedExpirationDate != self.sharedDto.expirationDate) {
        if (self.isExpirationDateEnabled) {
            NSString *dateString = [ShareUtils convertDateInServerFormat:[NSDate dateWithTimeIntervalSince1970: self.updatedExpirationDate]];
            [self updateSharedLinkWithPassword:nil expirationDate:dateString publicUpload:nil linkName:nil andFileListing:nil];
        } else {
            [self updateSharedLinkWithPassword:nil expirationDate:@"" publicUpload:nil linkName:nil andFileListing:nil];
        }
    }
    
    //ALLOW UPLOADS
    if (self.sharedDto.isDirectory && (![self.updatedPublicUpload isEqualToString:self.oldPublicUploadState] || ![self.updatedShowFileListing isEqualToString:self.oldShowFileListing])) {
        //SHOW FILE LISTING
        [self updateSharedLinkWithPassword:nil expirationDate:nil publicUpload:self.updatedPublicUpload linkName:nil andFileListing:self.updatedShowFileListing];
    }
    
}

- (void) updateSharedLinkWithPassword:(NSString*)password expirationDate:(NSString*)expirationDate publicUpload:(NSString *)publicUpload linkName:(NSString *)linkName andFileListing:(NSString *)fileListing {
    
    NSInteger permissions = 0;
    
    if ([publicUpload isEqualToString:@"true"] && ![fileListing isEqualToString:@"true"]) {
        permissions = k_permissions_when_file_listing_option_enabled;
    }
    
    [self.sharedFileOrFolder doRequestUpdateShareLink:self.sharedDto withPassword:password expirationTime:expirationDate publicUpload:publicUpload linkName:linkName andPermissions:permissions];
    
}


#pragma mark - switch changes

- (void) passwordProtectedSwithValueChanged:(UISwitch*) sender{
    
    self.isPasswordProtectEnabled = self.isPasswordProtectEnabled ? NO : YES ;

    [self updateInterfaceWithShareOptionsLinkStatus];

}

- (void) expirationTimeSwithValueChanged:(UISwitch*) sender{
    
    if (self.isExpirationDateEnabled) {
        
        self.updatedExpirationDate = 0.0;
        [self updateInterfaceWithShareOptionsLinkStatus];
        
    } else {
        //show picker and after date selected, current exp date will be updated and the view reloaded
        [self didSelectSetExpirationDateLink];
    }
}

- (void) allowEditingSwithValueChanged:(UISwitch*) sender{
    
    if (self.isAllowEditingEnabled) {
        self.isAllowEditingEnabled = NO;
        self.updatedPublicUpload = @"false";
    
    } else {
        self.isAllowEditingEnabled = YES;
        self.updatedPublicUpload = @"true";
    }
    
    self.isShowFileListingEnabled = YES;
    self.updatedShowFileListing= @"true";
    
    [self updateInterfaceWithShareOptionsLinkStatus];  // to update 'enabled' state of subordinate switch "Show file listing" and remain rest of updated fields
}

- (void) showFileListingSwithValueChanged:(UISwitch*) sender{
    
    if (self.isShowFileListingEnabled) {
        self.isShowFileListingEnabled = NO;
        self.updatedShowFileListing = @"false";
    } else {
        self.isShowFileListingEnabled = YES;
        self.updatedShowFileListing= @"true";
    }
}


#pragma mark - update

- (void) updateEnabledOptions {
    
    if (self.updatedExpirationDate == 0.0) {
        self.isExpirationDateEnabled = NO;
    }else {
        self.isExpirationDateEnabled = YES;
    }

    self.isAllowEditingEnabled = [self.updatedPublicUpload isEqualToString:@"true"];
    self.isShowFileListingEnabled = [self.updatedShowFileListing isEqualToString:@"true"];
}

- (void) updateInterfaceWithShareOptionsLinkStatus {
    
    [self updateEnabledOptions];
    
    [self updateCurrentNameAndPasswordValuesByCheckingTextfields];
    
    [self reloadView];
}

- (void) updateCurrentNameAndPasswordValuesByCheckingTextfields {
    
    ShareLinkOptionCell *cellName = [self.shareLinkOptionsTableView viewWithTag:1];
    ShareLinkOptionCell *cellPassword = [self.shareLinkOptionsTableView viewWithTag:2];
    
    if ([ShareUtils hasOptionLinkNameToBeShown]) {
        //option name exist, we update the current value of linkName
        self.updatedLinkName = cellName.optionTextField.text;
    } else {
        //password corresponding to the first section and we not need to update linkname option
        cellPassword = [self.shareLinkOptionsTableView viewWithTag:1];
    }
    
    if (self.isPasswordProtectEnabled) {
        self.updatedPassword = cellPassword.optionTextField.text;
    } else {
        self.updatedPassword = @"";
    }
}


#pragma mark - Style Methods

- (void) setStyleView {
    
    self.navigationItem.title = (self.linkOptionsViewMode == LinkOptionsViewModeCreate) ? NSLocalizedString(@"title_view_create_link", nil) :  NSLocalizedString(@"title_view_edit_link", nil) ;
    [self setBarButtonStyle];
}

- (void) setBarButtonStyle {
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectSaveShareLink)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(didSelectCloseView)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}


#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    return YES;
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
        
        [self.datePickerView setDate:[NSDate dateWithTimeIntervalSince1970:[ShareUtils getDefaultMaxExpirationDateInTimeInterval]]];
        self.datePickerView.minimumDate = [NSDate dateWithTimeIntervalSince1970:[ShareUtils getDefaultMinExpirationDateInTimeInterval]];
        if (![ShareUtils hasExpirationRemoveOptionAvailable]) {
            self.datePickerView.maximumDate = [NSDate dateWithTimeIntervalSince1970:[ShareUtils getDefaultMaxExpirationDateInTimeInterval]];
        }
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
        
    self.updatedExpirationDate = [self.datePickerView.date timeIntervalSince1970];
    
    [self updateInterfaceWithShareOptionsLinkStatus];
}

- (void) closeDatePicker {
    [UIView animateWithDuration:animationsDelay animations:^{
        [self.pickerView setFrame:CGRectMake(self.pickerView.frame.origin.x,
                                             self.view.frame.size.height,
                                             self.pickerView.frame.size.width,
                                             self.pickerView.frame.size.height)];
    } completion:^(BOOL finished) {
        [self.datePickerContainerView removeFromSuperview];
        [self updateInterfaceWithShareOptionsLinkStatus];
    }];
    
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    [self.datePickerContainerView removeGestureRecognizer:sender];
    [self closeDatePicker];
    [self updateInterfaceWithShareOptionsLinkStatus];
}


@end
