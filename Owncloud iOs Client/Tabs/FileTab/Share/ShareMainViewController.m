//
//  ShareMainViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/8/15.
//

/*
 Copyright (C) 2015, ownCloud, Inc.
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

//tools
#define standardDelay 0.2
#define animationsDelay 0.5

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
#define heighOfFileDetailrow 120.0
#define heightOfShareLinkOptionRow 55.0
#define heightOfShareLinkHeader 40.0
#define shareTableViewSectionsNumber  2

//Nº of Rows
#define optionsShownWithShareLinkEnable 3
#define optionsShownWithShareLinkDisable 0

//Date
#define expirationDateFormat @"YYYY-MM-dd"

@interface ShareMainViewController ()

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic, strong) OCSharedDto *updatedOCShare;
@property (nonatomic) NSInteger optionsShownWithShareLink;
@property (nonatomic) BOOL isShareLinkEnabled;
@property (nonatomic) BOOL isPasswordProtectEnabled;
@property (nonatomic) BOOL isExpirationDateEnabled;
@property (nonatomic, strong) NSString* sharedToken;
@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;
@property (nonatomic, strong) MBProgressHUD* loadingView;
@property(nonatomic, strong) UIAlertView *passwordView;



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
        
    }
    
    return self;
}

- (void) viewDidLoad{
    [super viewDidLoad];
    
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self setStyleView];
    [self updateInterfaceWithShareLinkStatus];
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

#pragma mark - Accessory alert views

- (void) showPasswordView {
    
    if (self.passwordView != nil) {
        self.passwordView = nil;
    }
    
    self.passwordView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"shared_link_protected_title", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
    
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
        self.datePickerView.minimumDate = [NSDate date];
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
    
    NSString *dateString = [self converDateInCorrectFormat:self.datePickerView.date];
    
    [self updateSharedLinkWithPassword:nil andExpirationDate:dateString];
    
    
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
    [dateFormatter setDateFormat:expirationDateFormat];
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
    
    if (self.isShareLinkEnabled == true){
        self.optionsShownWithShareLink = optionsShownWithShareLinkEnable;
    }else{
        self.optionsShownWithShareLink = optionsShownWithShareLinkDisable;
    }
    
    [self.shareTableView reloadData];
}

#pragma mark - Action Methods

- (void) updateInterfaceWithShareLinkStatus {
    
       self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
    
    if (self.sharedItem.sharedFileSource > 0) {
        
        self.isShareLinkEnabled = true;
        
        self.sharedItem = [ManageFilesDB getFileDtoByFileName:self.sharedItem.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser] andUser:APP_DELEGATE.activeUser];
        
        if (self.sharedFileOrFolder == nil) {
            self.sharedFileOrFolder = [ShareFileOrFolder new];
            self.sharedFileOrFolder.delegate = self;
        }
        
        self.updatedOCShare = [self.sharedFileOrFolder getTheOCShareByFileDto:self.sharedItem];
        
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
        
        
    }else{
        self.isShareLinkEnabled = false;
    }
    
    [self reloadView];
    
}

- (void) didSelectCloseView {
    
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) sharedLinkSwithValueChanged: (UISwitch*)sender {
    
    self.isShareLinkEnabled = sender.on;
    
    if (self.isShareLinkEnabled == true) {
        [self getShareLinkView];
    } else{
        [self unShareByLink];
    }
}

- (void) passwordProtectedSwithValueChanged:(UISwitch*) sender{
    
    
    if (self.isPasswordProtectEnabled == false) {
        //Update with password protected
        [self showPasswordView];
    } else{
        //Remove password Protected
        [self updateSharedLinkWithPassword:@"" andExpirationDate:nil];
    }
}


- (void) expirationTimeSwithValueChanged:(UISwitch*) sender{
    
    if (self.isExpirationDateEnabled == false) {
        [self launchDatePicker];
    }else{
        //Remove exipration time
        [self updateSharedLinkWithPassword:nil andExpirationDate:@""];
    }
    

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
    
    OCSharedDto *ocShare = [self.sharedFileOrFolder getTheOCShareByFileDto:self.sharedItem];
    
    if (ocShare != nil) {
        [self.sharedFileOrFolder unshareTheFile:ocShare];
    }
    
}

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
        [self updateSharedLinkWithPassword:password andExpirationDate:nil];
        
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
    
    NSString *stringNow = [alertView textFieldAtIndex:0].text;
    
    
    //Active button of folderview only when the textfield has something.
    NSString *rawString = stringNow;
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
    
    if ([trimmed length] == 0) {
        // Text was empty or only whitespace.
        output = NO;
    }
    
    //Button save disable when the textfield is empty
    if ([stringNow isEqualToString:@""]) {
        output = NO;
    }
    
    return output;
}


#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return shareTableViewSectionsNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return 1;
    }else{
        return self.optionsShownWithShareLink;
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
        
        if (self.sharedItem.isDirectory == true) {
            shareFileCell.fileImage.image = [UIImage imageNamed:@"folder_icon"];
            shareFileCell.fileSize.text = @"";
        }else{
            shareFileCell.fileImage.image = [UIImage imageNamed:[FileNameUtils getTheNameOfTheImagePreviewOfFileName:[self.sharedItem.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            shareFileCell.fileSize.text = [NSByteCountFormatter stringFromByteCount:[NSNumber numberWithLong:self.sharedItem.size].longLongValue countStyle:NSByteCountFormatterCountStyleMemory];
        }
        
        shareFileCell.fileName.text = [self.sharedItem.fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        cell = shareFileCell;
        
    } else {
        
        if (indexPath.row == 2) {
            
            ShareLinkButtonCell *shareLinkButtonCell = [tableView dequeueReusableCellWithIdentifier:shareLinkButtonIdentifier];
            
            if (shareLinkButtonCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkButtonNib owner:self options:nil];
                shareLinkButtonCell = (ShareLinkButtonCell *)[topLevelObjects objectAtIndex:0];
            }
            
            shareLinkButtonCell.titleButton.text = NSLocalizedString(@"get_share_link", nil);
            
            cell = shareLinkButtonCell;
            
            
        } else {
            
            ShareLinkOptionCell* shareLinkOptionCell = [tableView dequeueReusableCellWithIdentifier:shareLinkOptionIdentifer];
            
            if (shareLinkOptionCell == nil) {
                NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkOptionNib owner:self options:nil];
                shareLinkOptionCell = (ShareLinkOptionCell *)[topLevelObjects objectAtIndex:0];
            }
            
            switch (indexPath.row) {
                case 0:
                    shareLinkOptionCell.optionName.text = NSLocalizedString(@"set_expiration_time", nil);
                    
                    if (self.isExpirationDateEnabled == true) {
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
                    
                    if (self.isPasswordProtectEnabled == true) {
                        shareLinkOptionCell.optionName.textColor = [UIColor blackColor];
                        shareLinkOptionCell.optionDetail.textColor = [UIColor blackColor];
                        shareLinkOptionCell.optionDetail.text = @"Secured";
                    } else {
                        shareLinkOptionCell.optionName.textColor = [UIColor grayColor];
                        shareLinkOptionCell.optionDetail.textColor = [UIColor grayColor];
                        shareLinkOptionCell.optionDetail.text = @"";
                    }
                    [shareLinkOptionCell.optionSwith setOn:self.isPasswordProtectEnabled animated:false];
                    
                    [shareLinkOptionCell.optionSwith addTarget:self action:@selector(passwordProtectedSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
                    
                    break;
                    
                default:
                    //Not expected
                    DLog(@"Not expected");
                    break;
            }
            
            cell = shareLinkOptionCell;
            
        }
        
    }
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return heighOfFileDetailrow;
    }else{
        return heightOfShareLinkOptionRow;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 10.0;
    
    if (section == 1) {
        height = heightOfShareLinkHeader;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [UIView new];
    
    if (section == 1) {
        
        ShareLinkHeaderCell* shareLinkHeaderCell = [tableView dequeueReusableCellWithIdentifier:shareLinkHeaderIdentifier];
        
        if (shareLinkHeaderCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLinkHeaderNib owner:self options:nil];
            shareLinkHeaderCell = (ShareLinkHeaderCell *)[topLevelObjects objectAtIndex:0];
        }
        
         shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_link_long_press", nil);
        [shareLinkHeaderCell.switchSection setOn:self.isShareLinkEnabled animated:false];
        [shareLinkHeaderCell.switchSection addTarget:self action:@selector(sharedLinkSwithValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        headerView = shareLinkHeaderCell;
        
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.section == 1 && indexPath.row == 2) {
        [self getShareLinkView];
    }
}

#pragma mark - ShareFileOrFolder Delegate Methods

- (void) initLoading {
    
    if (self.loadingView != nil) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
    }
    
    self.loadingView = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
    self.loadingView.delegate = self;
    
    if (IS_IPHONE) {
        [self.view.window addSubview:self.loadingView];
    }else{
        [APP_DELEGATE.splitViewController.view.window addSubview:self.loadingView];
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
    
    
}

- (void) finishUnShare {
    
    [self performSelector:@selector(reloadView) withObject:nil afterDelay:standardDelay];
    
}

- (void) finishUpdateShare {
    
    [self performSelector:@selector(updateInterfaceWithShareLinkStatus) withObject:nil afterDelay:standardDelay];
    
}

- (void) presentShareOptions:(UIActivityViewController*) activityView{
    
    if (IS_IPHONE) {
        [self presentViewController:activityView animated:true completion:nil];
        [self performSelector:@selector(reloadView) withObject:nil afterDelay:standardDelay];
    }else{
        [self reloadView];
        
        UIPopoverController* activityPopoverController = [[UIPopoverController alloc]initWithContentViewController:activityView];
        
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:2 inSection:1];
        UITableViewCell* cell = [self.shareTableView cellForRowAtIndexPath:indexPath];
        
        [activityPopoverController presentPopoverFromRect:cell.frame inView:self.shareTableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
    }
    
}



@end
