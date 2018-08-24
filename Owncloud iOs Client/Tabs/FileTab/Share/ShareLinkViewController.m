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

#define heightOfShareLinkOptionRow 55.0f
#define heightOfShareLinkOptionSection 25.0f
#define heightOfShareLinkOptionTitleFirstSection 55.0f
#define heightOfNameOptionFooterSection 10.0f
#define heightOfShareLinkOptionFooterSection 37.0f

//mail subject key
#define k_subject_key_activityView @"subject"

#define animationsDelay 0.5

#define k_permissions_when_file_listing_option_enabled 4

//Sections
typedef NS_ENUM (NSInteger, Sections){
	LinkNameSection,
	LinkPermissionsSection,
	LinkPasswordSection,
	LinkExpirationDateSection
};

//Rows by section
typedef NS_ENUM (NSInteger, LinkNameSectionEnum){
	LinkOptionName
};

typedef NS_ENUM (NSInteger, LinkPermissionsSectionEnum){
	LinkOptionAllowDownload,
	LinkOptionAllowUploads,
	LinkOptionShowFileListing
};

typedef NS_ENUM (NSInteger, LinkPasswordSectionEnum){
	LinkOptionPassword,
};

typedef NS_ENUM (NSInteger, LinkExpirationDateSectionEnum){
	LinkOptionExpiration,
};

@interface ShareLinkViewController ()

@property (nonatomic) BOOL isPasswordProtectEnabled;
@property (nonatomic) BOOL isExpirationDateEnabled;

@property (nonatomic) NSInteger optionsShownWithShareLink;

@property (nonatomic) BOOL isDownloadViewPermission;
@property (nonatomic) BOOL isDownloadViewUploadPermission;
@property (nonatomic) BOOL isUploadOnlyPermission;

@property (nonatomic) UITextField *nameTextField;
@property (nonatomic) UITextField *passwordTextField;

@end

@implementation ShareLinkViewController


- (id) initWithFileDto:(FileDto *)fileDto andOCSharedDto:(OCSharedDto *)sharedDto andDefaultLinkName:(NSString *)defaultLinkName andLinkOptionsViewMode:(LinkOptionsViewMode)linkOptionsViewMode {
    
    if ((self = [super initWithNibName:shareLinkViewNibName bundle:nil]))
    {
        _linkOptionsViewMode = linkOptionsViewMode;
        _fileShared = fileDto;
        _sharedDto = sharedDto;

        _updatedPassword = @"";

        if (_linkOptionsViewMode == LinkOptionsViewModeCreate) {
            
            _updatedLinkName = defaultLinkName;
            _updatedExpirationDate = [ShareUtils getDefaultMaxExpirationDateInTimeInterval];
            
            if ([ShareUtils hasExpirationDefaultDateToBeShown] || ![ShareUtils hasExpirationRemoveOptionAvailable]) {
                _isExpirationDateEnabled = YES;
            } else {
                _isExpirationDateEnabled = NO;
            }

            _isPasswordProtectEnabled =  [ShareUtils hasPasswordRemoveOptionAvailable] ? NO : YES;

			self.isDownloadViewPermission = YES;
			self.isDownloadViewUploadPermission = NO;
			self.isUploadOnlyPermission = NO;

        } else {
            
            _updatedLinkName = _sharedDto.name;
            _updatedExpirationDate = _sharedDto.expirationDate;

			//Permissions
			self.isDownloadViewPermission = [UtilsFramework isPermissionToRead:self.sharedDto.permissions];
			self.isDownloadViewUploadPermission = [UtilsFramework isPermissionToReadCreateUpdate:self.sharedDto.permissions];
			self.isUploadOnlyPermission = [UtilsFramework isPermissionToCanCreate:self.sharedDto.permissions];

			//Set the higher permission
			if (self.isDownloadViewUploadPermission) {
				self.isDownloadViewPermission = false;
				self.isUploadOnlyPermission = false;
			}

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


-(NSInteger) getNumberOfSectionsAvailable {

    NSInteger nOfOptionsAvailable = 4;
    
    if (![ShareUtils hasOptionLinkNameToBeShown]) {
        nOfOptionsAvailable = nOfOptionsAvailable -2;
    }

    return nOfOptionsAvailable;
}

-(NSInteger) getNumberOfRowsAvailableBySection:(Sections) section {

	//Update the section value in case that the first is not available
	if (![ShareUtils hasOptionLinkNameToBeShown]) {
		section = section + 2;
	}

	NSInteger numberOfRows = 0;

	switch (section) {
		case LinkNameSection:
			numberOfRows = 1;
			break;

		case LinkPermissionsSection:
			numberOfRows = 3;

			if (![ShareUtils hasOptionAllowEditingToBeShownForFile:self.fileShared]) {
				numberOfRows--;
			}

			if (![ShareUtils hasOptionShowFileListingToBeShownForFile:self.fileShared]) {
				numberOfRows--;
			}

			break;

		case LinkPasswordSection:
			numberOfRows = 1;
			break;

		case LinkExpirationDateSection:
			numberOfRows = 1;
			break;

		default:
			break;
	}

	return numberOfRows;
}


#pragma mark - TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [self getNumberOfSectionsAvailable];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self getNumberOfRowsAvailableBySection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	ShareLinkOptionCell *shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];

	if (shareLinkOptionCell == nil) {
		NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
		shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
	}

	[shareLinkOptionCell.optionSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
	shareLinkOptionCell.tag = indexPath.section + 1;

	NSInteger section = indexPath.section;

	//Update the section value in case that the first is not available
	if (![ShareUtils hasOptionLinkNameToBeShown]) {
		section = section + 2;
	}

	switch (section) {
		case LinkNameSection:
			switch (indexPath.row) {
				case LinkOptionName:
					[self getLinkNameCell:shareLinkOptionCell];
					break;

				default:
					break;
			}
			break;

		case LinkPermissionsSection:
			switch (indexPath.row) {
				case LinkOptionAllowDownload:
					[self getOptionAllowsViewCell:shareLinkOptionCell];
					break;
				case LinkOptionAllowUploads:
					[self getOptionAllowsUploadAndViewCell:shareLinkOptionCell];
					break;
				case LinkOptionShowFileListing:
					[self getOptionAllowsOnlyUploadCell:shareLinkOptionCell];
					break;

				default:
					break;
			}
			break;

		case LinkPasswordSection:
			[self getPasswordLinkCell:shareLinkOptionCell];
			break;

		case LinkExpirationDateSection:
			[self getExpirationDateLinkCell:shareLinkOptionCell];
			break;

		default:
			break;
	}

	return shareLinkOptionCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	//Permissions
	if (indexPath.section == LinkPermissionsSection) {

		switch (indexPath.row) {
			case LinkOptionAllowDownload:
				self.isDownloadViewPermission = true;
				self.isDownloadViewUploadPermission = false;
				self.isUploadOnlyPermission = false;
				break;
			case LinkOptionAllowUploads:
				self.isDownloadViewPermission = false;
				self.isDownloadViewUploadPermission = true;
				self.isUploadOnlyPermission = false;
				break;
			case LinkOptionShowFileListing:
				self.isDownloadViewPermission = false;
				self.isDownloadViewUploadPermission = false;
				self.isUploadOnlyPermission = true;
				break;
		}

		[self updateInterfaceWithShareOptionsLinkStatus];
	}

	//Expiration date
    if (self.isExpirationDateEnabled || ![ShareUtils hasExpirationRemoveOptionAvailable]) {

		NSInteger section = indexPath.section;

		//Update the section value in case that the first is not available
		if (![ShareUtils hasOptionLinkNameToBeShown]) {
			section = section - 2;
		}

        if (indexPath.section == LinkExpirationDateSection) {
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
	if ([ShareUtils hasOptionLinkNameToBeShown] && section == 0) {
		return heightOfNameOptionFooterSection;
	} else {
		return heightOfShareLinkOptionFooterSection;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return heightOfShareLinkOptionRow;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    NSString *title = nil;

	//Update the section value in case that the first is not available
	if (![ShareUtils hasOptionLinkNameToBeShown]) {
		section = section + 2;
	}
    
    switch (section) {
        case LinkNameSection:
			title = NSLocalizedString(@"title_share_link_option_name", nil);
            break;
        case LinkPasswordSection:
			title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"title_share_link_option_password", nil), [ShareUtils hasPasswordRemoveOptionAvailable] ? @"" : @"*"];
            break;
        case LinkExpirationDateSection:
                title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"title_share_link_option_expiration", nil), [ShareUtils hasExpirationRemoveOptionAvailable] ? @"" : @"*"];
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
				NSString *nDays = [NSString stringWithFormat:@"%ld", (long)APP_DELEGATE.activeUser.capabilitiesDto.filesSharingExpireDateDaysNumber];
                title = [NSLocalizedString(@"show_error_expiration_enforced", nil) stringByReplacingOccurrencesOfString:@"$nDays" withString:nDays];
            }
            break;
        case 2:
            if ([ShareUtils hasOptionLinkNameToBeShown] && ![ShareUtils hasExpirationRemoveOptionAvailable]) {
				NSString *nDays = [NSString stringWithFormat:@"%ld", (long)APP_DELEGATE.activeUser.capabilitiesDto.filesSharingExpireDateDaysNumber];
                title = [NSLocalizedString(@"show_error_expiration_enforced", nil) stringByReplacingOccurrencesOfString:@"$nDays" withString:nDays];
            }
            break;
            
        default:
            break;
    }
    
    return title;
    
    
}

#pragma mark - cells

- (ShareLinkOptionCell *) getLinkNameCell:(ShareLinkOptionCell *)shareLinkOptionCell {
	shareLinkOptionCell.optionName.hidden = YES;
	shareLinkOptionCell.optionTextField.hidden = NO;
	shareLinkOptionCell.optionTextField.placeholder = NSLocalizedString(@"placeholder_share_link_option_name", nil);
	shareLinkOptionCell.optionTextField.text = self.updatedLinkName;
	shareLinkOptionCell.optionTextField.inputAccessoryView = [self keyboardToolbarWithDoneButton];
	self.nameTextField = shareLinkOptionCell.optionTextField;

	return shareLinkOptionCell;
}

- (ShareLinkOptionCell *) getPasswordLinkCell:(ShareLinkOptionCell *)shareLinkOptionCell {
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
	self.passwordTextField = shareLinkOptionCell.optionTextField;

	return shareLinkOptionCell;
}

- (ShareLinkOptionCell *) getExpirationDateLinkCell:(ShareLinkOptionCell *)shareLinkOptionCell {
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

	return shareLinkOptionCell;
}

- (ShareLinkOptionCell *) getOptionAllowsViewCell:(ShareLinkOptionCell *)shareLinkOptionCell {

	if (self.isDownloadViewPermission) {
		shareLinkOptionCell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		shareLinkOptionCell.accessoryType = UITableViewCellAccessoryNone;
	}

	shareLinkOptionCell.optionTextField.hidden = YES;
	shareLinkOptionCell.optionName.hidden = NO;
	shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_allow_dowload_view", nil);

	return shareLinkOptionCell;
}

- (ShareLinkOptionCell *) getOptionAllowsUploadAndViewCell:(ShareLinkOptionCell *)shareLinkOptionCell {

	if (self.isDownloadViewUploadPermission) {
		shareLinkOptionCell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		shareLinkOptionCell.accessoryType = UITableViewCellAccessoryNone;
	}

	shareLinkOptionCell.optionTextField.hidden = YES;
	shareLinkOptionCell.optionName.hidden = NO;
	shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_allow_dowload_view_upload", nil);

	return shareLinkOptionCell;
}

- (ShareLinkOptionCell *) getOptionAllowsOnlyUploadCell:(ShareLinkOptionCell *)shareLinkOptionCell {

	if (self.isUploadOnlyPermission) {
		shareLinkOptionCell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		shareLinkOptionCell.accessoryType = UITableViewCellAccessoryNone;
	}

	shareLinkOptionCell.optionTextField.hidden = YES;
	shareLinkOptionCell.optionName.hidden = NO;
	shareLinkOptionCell.optionName.text = NSLocalizedString(@"title_share_link_option_allow_upload_only", nil);

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

- (void) createShareLink {
    
    NSString *updateLinkName = nil;
    NSString *updatePassword = nil;
    NSString *updateExpirationTime = nil;
    NSString *updatePublicUpload = nil;

    
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

    [self.sharedFileOrFolder doRequestCreateShareLinkOfFile:self.fileShared withPassword:updatePassword expirationTime:updateExpirationTime publicUpload:updatePublicUpload linkName:updateLinkName andPermissions:[self getPermissions]];
}

- (void) updateShareOptionsNeeded {

    //NAME
    if (![self.updatedLinkName isEqualToString:self.sharedDto.name] && [ShareUtils hasOptionLinkNameToBeShown]) {
		[self updateSharedLinkWithPassword:nil expirationDate:nil linkName:self.updatedLinkName andPermissions:0];
    }
    
    //PASSWORD
    if (self.isPasswordProtectEnabled && ![self.updatedPassword isEqualToString:@""] ) {
        [self updateSharedLinkWithPassword:self.updatedPassword expirationDate:nil linkName:nil andPermissions:0];
    } else if (_oldPasswordEnabledState && !self.isPasswordProtectEnabled){
        //Remove previous password
        [self updateSharedLinkWithPassword:@"" expirationDate:nil linkName:nil andPermissions:0];
    }
    
    //EXPIRATION
    if (self.updatedExpirationDate != self.sharedDto.expirationDate) {
        if (self.isExpirationDateEnabled) {
            NSString *dateString = [ShareUtils convertDateInServerFormat:[NSDate dateWithTimeIntervalSince1970: self.updatedExpirationDate]];
            [self updateSharedLinkWithPassword:nil expirationDate:dateString linkName:nil andPermissions:0];
        } else {
            [self updateSharedLinkWithPassword:nil expirationDate:@"" linkName:nil andPermissions:0];
        }
    }

	//PERMISSIONS
	if (self.sharedDto.permissions != [self getPermissions]) {
		[self updateSharedLinkWithPassword:nil expirationDate:nil linkName:nil andPermissions:[self getPermissions]];
	}
}

- (void) updateSharedLinkWithPassword:(NSString*)password expirationDate:(NSString*)expirationDate linkName:(NSString *)linkName andPermissions:(NSInteger) permissions {
    [self.sharedFileOrFolder doRequestUpdateShareLink:self.sharedDto withPassword:password expirationTime:expirationDate publicUpload:nil linkName:linkName andPermissions:permissions];
}

- (NSInteger) getPermissions {

	NSInteger permissions = 0;

	if (self.isDownloadViewPermission) {
		permissions = [UtilsFramework getPermissionsValueByCanRead: YES andCanEdit:NO andCanCreate:NO andCanChange:NO andCanDelete:NO andCanShare:NO andIsFolder:self.fileShared.isDirectory];
	} else if (self.isDownloadViewUploadPermission) {
		permissions = [UtilsFramework getPermissionsValueByCanRead: YES andCanEdit:YES andCanCreate:YES andCanChange:YES andCanDelete:YES andCanShare:NO andIsFolder:self.fileShared.isDirectory];
	} else if (self.isUploadOnlyPermission) {
		permissions = [UtilsFramework getPermissionsValueByCanRead: NO andCanEdit:NO andCanCreate:YES andCanChange:NO andCanDelete:NO andCanShare:NO andIsFolder:self.fileShared.isDirectory];
	}

	return permissions;
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

#pragma mark - update

- (void) updateEnabledOptions {
    
    if (self.updatedExpirationDate == 0.0) {
        self.isExpirationDateEnabled = NO;
    }else {
        self.isExpirationDateEnabled = YES;
    }
}

- (void) updateInterfaceWithShareOptionsLinkStatus {
    
    [self updateEnabledOptions];
    [self updateCurrentNameAndPasswordValuesByCheckingTextfields];
    
    [self reloadView];
}

- (void) updateCurrentNameAndPasswordValuesByCheckingTextfields {

    if ([ShareUtils hasOptionLinkNameToBeShown]) {
        //option name exist, we update the current value of linkName
        self.updatedLinkName = self.nameTextField.text;
    }
    
    if (self.isPasswordProtectEnabled) {
        self.updatedPassword = self.passwordTextField.text;
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

- (void) launchDatePicker {

    static CGFloat controlToolBarHeight = 44.0;
    static CGFloat datePickerViewHeight = 300.0;

    // Setup the background view.
    if (_datePickerFullScreenBackgroundView == nil) {

        _datePickerFullScreenBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        [_datePickerFullScreenBackgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_datePickerFullScreenBackgroundView setBackgroundColor:[UIColor clearColor]];

        // Setup the gesture recognizer for the background View.
        // When the user taps in this view, the date picker should dismiss.
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
        recognizer.delegate = self;
        recognizer.cancelsTouchesInView = YES;
        [_datePickerFullScreenBackgroundView addGestureRecognizer:recognizer];

        [self.view addSubview: _datePickerFullScreenBackgroundView];

        if (@available(iOS 11.0, *)) {
            UILayoutGuide *safeArea = [self.view safeAreaLayoutGuide];
            [[_datePickerFullScreenBackgroundView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor] setActive:YES];
            [[_datePickerFullScreenBackgroundView.topAnchor constraintEqualToAnchor:safeArea.topAnchor] setActive:YES];
            [[_datePickerFullScreenBackgroundView.leftAnchor constraintEqualToAnchor:safeArea.leftAnchor] setActive:YES];
            [[_datePickerFullScreenBackgroundView.rightAnchor constraintEqualToAnchor:safeArea.rightAnchor] setActive:YES];
        } else {
            [[_datePickerFullScreenBackgroundView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
            [[_datePickerFullScreenBackgroundView.topAnchor constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
            [[_datePickerFullScreenBackgroundView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor] setActive:YES];
            [[_datePickerFullScreenBackgroundView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor] setActive:YES];
        }
    } else {
        [self.view addSubview: _datePickerFullScreenBackgroundView];
    }

    if (_pickerContainerView == nil) {
        _pickerContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        [_pickerContainerView setTranslatesAutoresizingMaskIntoConstraints:NO];

        [_datePickerFullScreenBackgroundView addSubview:_pickerContainerView];

        [[_pickerContainerView.bottomAnchor constraintEqualToAnchor: _datePickerFullScreenBackgroundView.bottomAnchor] setActive:YES];
        [[_pickerContainerView.leftAnchor constraintEqualToAnchor:_datePickerFullScreenBackgroundView.leftAnchor] setActive:YES];
        [[_pickerContainerView.rightAnchor constraintEqualToAnchor:_datePickerFullScreenBackgroundView.rightAnchor] setActive:YES];
        [[_pickerContainerView.heightAnchor constraintEqualToConstant:datePickerViewHeight] setActive:YES];
        [_pickerContainerView setBackgroundColor:[UIColor whiteColor]];

    } else {
        [_datePickerFullScreenBackgroundView addSubview:_pickerContainerView];
        [_pickerContainerView setHidden:NO];
    }

    // Setup the above the picker Toolbar.
    UIToolbar *controlToolbar = [[UIToolbar alloc] initWithFrame: CGRectZero];
    [controlToolbar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_pickerContainerView addSubview:controlToolbar];
    [[controlToolbar.topAnchor constraintEqualToAnchor:_pickerContainerView.topAnchor] setActive:YES];
    [[controlToolbar.leftAnchor constraintEqualToAnchor:_pickerContainerView.leftAnchor] setActive:YES];
    [[controlToolbar.rightAnchor constraintEqualToAnchor:_pickerContainerView.rightAnchor] setActive:YES];
    [[controlToolbar.heightAnchor constraintEqualToConstant:controlToolBarHeight] setActive:YES];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dateSelected:)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeDatePicker)];

    UIBarButtonItem *toolbarSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    [controlToolbar setItems:@[cancelButton, toolbarSpacer, doneButton]];


    // Setup the date picker
    if (_datePicker == nil) {
        _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
        [_datePicker setTranslatesAutoresizingMaskIntoConstraints:NO];
        _datePicker.datePickerMode = UIDatePickerModeDate;
        [_datePicker setBackgroundColor:[UIColor whiteColor]];

        [_datePicker setDate:[NSDate dateWithTimeIntervalSince1970:[ShareUtils getDefaultMaxExpirationDateInTimeInterval]]];
        [_datePicker setMinimumDate:[NSDate dateWithTimeIntervalSince1970:[ShareUtils getDefaultMinExpirationDateInTimeInterval]]];

        if (![ShareUtils hasExpirationRemoveOptionAvailable]) {
            [_datePicker setMaximumDate:[NSDate dateWithTimeIntervalSince1970:[ShareUtils getDefaultMaxExpirationDateInTimeInterval]]];
        }

        [_pickerContainerView addSubview:_datePicker];

        [[_datePicker.bottomAnchor constraintEqualToAnchor:_pickerContainerView.bottomAnchor] setActive:YES];
        [[_datePicker.topAnchor constraintEqualToAnchor:_pickerContainerView.topAnchor constant:controlToolBarHeight] setActive:YES];
        [[_datePicker.leftAnchor constraintEqualToAnchor:_pickerContainerView.leftAnchor] setActive:YES];
        [[_datePicker.rightAnchor constraintEqualToAnchor:_pickerContainerView.rightAnchor] setActive:YES];

    } else {
        [_pickerContainerView addSubview:_datePicker];
    }

}

- (void) dateSelected:(UIBarButtonItem *)sender{
    
    [self closeDatePicker];
        
    self.updatedExpirationDate = [_datePicker.date timeIntervalSince1970];
    
    [self updateInterfaceWithShareOptionsLinkStatus];
}

- (void) closeDatePicker {
    [UIView animateWithDuration:animationsDelay animations:^{
        [self.pickerContainerView setFrame:CGRectMake(self.pickerContainerView.frame.origin.x,
                                             self.view.frame.size.height,
                                             self.pickerContainerView.frame.size.width,
                                             self.pickerContainerView.frame.size.height)];
    } completion:^(BOOL finished) {
        [_datePickerFullScreenBackgroundView removeFromSuperview];
        _datePickerFullScreenBackgroundView = nil;
        _pickerContainerView = nil;
        _datePicker = nil;
        [self updateInterfaceWithShareOptionsLinkStatus];
    }];
    
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender {
    [_datePickerFullScreenBackgroundView removeGestureRecognizer:sender];
    [self closeDatePicker];
    [self updateInterfaceWithShareOptionsLinkStatus];
}

@end
