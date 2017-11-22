//
//  SettingsViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/11/12.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "SettingsViewController.h"

#import "AppDelegate.h"
#import "UserDto.h"
#import "FilesViewController.h"
#import "WebViewController.h"
#import "UIColor+Constants.h"
#import "constants.h"
#import "AppDelegate.h"
#import "constants.h"
#import "ImpressumViewController.h"
#import "Customization.h"
#import "ManageAppSettingsDB.h"
#import "ManageUsersDB.h"
#import "OCNavigationController.h"
#import "OCPortraitNavigationViewController.h"
#import "ImageUtils.h"
#import "UtilsFramework.h"
#import "UtilsUrls.h"
#import "PrepareFilesToUpload.h"
#import "UploadUtils.h"
#import "UtilsCookies.h"
#import "ManageCookiesStorageDB.h"
#import "Accessibility.h"
#import "SyncFolderManager.h"
#import "ManageThumbnails.h"
#import "ManageTouchID.h"
#import "DeleteUtils.h"
#import "OCLoadingSpinner.h"
#import "InstantUpload.h"
#import "CheckFeaturesSupported.h"
#import "UtilsFileSystem.h"

//Settings table view size separator
#define k_padding_normal_section 20.0
#define k_padding_last_section 40.0
#define k_padding_under_section 5.0

//Settings custom font
#define k_settings_normal_font [UIFont fontWithName:@"HelveticaNeue" size:17]
#define k_settings_bold_font [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];

//ActionSheet tags
#define k_tag_actionSheet_menu_account 101
#define k_tag_actionSheet_recommend 102


///-----------------------------------
/// @name MFMailComposeViewController Category for iOS 7 Status Style
///-----------------------------------

/**
 * Category for MFMailComposer in order to change two things:
 * The custom tint color of buttons in nav bar
 * The status bar to white (by default is black)
 *
 */
@implementation MFMailComposeViewController (IOS7_StatusBarStyle)

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [self.navigationBar setTintColor:[UIColor colorOfNavigationItems]];
}


-(UIStatusBarStyle)preferredStatusBarStyle {
    
    if (k_is_text_status_bar_white) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

-(UIViewController *)childViewControllerForStatusBarStyle
{
    return nil;
}

@end

@interface SettingsViewController () <InstantUploadDelegate>

@property (nonatomic, strong) NSMutableArray *listUsers;

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isMailComposeVisible = NO;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"settings", nil);
    
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];

    [InstantUpload instantUploadManager].delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = true;
    self.automaticallyAdjustsScrollViewInsets = true;

    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Relaunch the uploads that failed before
    [app performSelector:@selector(relaunchUploadsFailedNoForced) withObject:nil afterDelay:5.0];

    self.user = app.activeUser;
    
    self.listUsers = [ManageUsersDB getAllUsers];
    [self.settingsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatesWhenEnteringForegroundMode) name:UIApplicationDidBecomeActiveNotification object:nil];

}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

-(void)viewDidLayoutSubviews
{
    
    if (IS_IOS8 || IS_IOS9) {
        
        if ([self.settingsTableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.settingsTableView setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 0)];
        }
        
        if ([self.settingsTableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.settingsTableView setLayoutMargins:UIEdgeInsetsZero];
        }
        
        
        CGRect rect = self.navigationController.navigationBar.frame;
        float y = rect.size.height + rect.origin.y;
        self.settingsTableView.contentInset = UIEdgeInsetsMake(y,0,0,0);
        
    }
    
}

-(void)viewWillLayoutSubviews
{
    [self.settingsTableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPHONE) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void) updatesWhenEnteringForegroundMode {
    [self.settingsTableView reloadData];
}

#pragma mark - Setting Actions


///-----------------------------------
/// @name Change Switch Passcode
///-----------------------------------

/**
 * This method is calle que the pass code switch change
 *
 * @param id -> UISwitch sender
 
 * @return IBAction
 *
 */
-(IBAction)changeSwitchPasscode:(id)sender {
    
    //Create pass code view controller
    self.vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
    self.vc.delegate = self;
    
    //Create the navigation bar of portrait
    OCPortraitNavigationViewController *oc = [[OCPortraitNavigationViewController alloc]initWithRootViewController:_vc];

    //Indicate the pass code view mode
    if([ManageAppSettingsDB isPasscode]) {
        self.vc.mode = KKPasscodeModeDisabled;
    } else {
        self.vc.mode = KKPasscodeModeSet;
    }
    
    if (IS_IPHONE) {
        //is iphone
        [self presentViewController:oc animated:YES completion:nil];
    } else {
        //is ipad
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        oc.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:oc animated:YES completion:nil];
    }
    
    [self.settingsTableView reloadData];

}

/**
 * This method is called when the touch ID swicth changes
 *
 * @param id -> UISwitch sender
 
 * @return IBAction
 *
 */
-(IBAction)changeSwitchTouchID:(UISwitch*)touchIDSwitch {
    [self setPropertiesTouchIDToState:touchIDSwitch.on];
}


-(void)disconnectUser {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    [[ManageThumbnails sharedManager] deleteThumbnailCacheFolderOfUserId: APP_DELEGATE.activeUser.userId];
    
    [ManageUsersDB removeUserAndDataByUser:APP_DELEGATE.activeUser];
    
    [UtilsFramework deleteAllCookies];
    
    DLog(@"ID to delete user: %ld", (long)app.activeUser.userId);
    
    //Delete files os user in the system
    NSString *userFolder = [NSString stringWithFormat:@"/%ld", (long)app.activeUser.userId];
    NSString *path= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:userFolder];
    
    NSError *error;     
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    [self performSelectorInBackground:@selector(cancelAllDownloads) withObject:nil];
    app.uploadArray=[[NSMutableArray alloc]init];
    [app updateRecents];
    [app restartAppAfterDeleteAllAccounts];
}


-(void)goImprint {
   
    if(k_impressum_is_file) {
        ImpressumViewController *viewController = [[ImpressumViewController alloc]initWithNibName:@"ImpressumViewController" bundle:nil];
        
        OCNavigationController *navBar=[[OCNavigationController alloc]initWithRootViewController:viewController];
        
        // only for iPad
        if (!IS_IPHONE) {
            navBar.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
            navBar.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        [self presentViewController:navBar animated:YES completion:nil];
    } else {
        if (IS_IPHONE) {
            WebViewController *webView=[[WebViewController alloc]initWithNibName:@"WebViewController" bundle:nil];
            
            webView.urlString = k_impressum_url;
            webView.navigationTitleString = NSLocalizedString(@"imprint_button", nil);
            
            [self.navigationController pushViewController:webView animated:NO];

        } else {
            if(!_detailViewController) {
                AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                _detailViewController = app.detailViewController;
            }
            [_detailViewController openLink:k_impressum_url];
            _detailViewController.linkTitle=NSLocalizedString(@"imprint_button", nil);
        }
    }
}

#pragma mark - UITableView datasource

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 5;
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger n = 0;
    
    switch (section) {
        case 0:
            
            if (k_multiaccount_available) {
                n = self.listUsers.count;
            }else{
                n = 1;
            }
            break;
            
        case 1:
            if (k_multiaccount_available) {
                n = 1;
            }else{
                n = 0;
            }
            break;
            
        case 2:
            if ((self.switchPasscode.on || k_is_passcode_forced) && [self isTouchIDAvailable]) {
                n = 2;
            }else{
                n = 1;
            }
            break;
            
        case 3:
            if ([[InstantUpload instantUploadManager] imageInstantUploadEnabled] || [[InstantUpload instantUploadManager] videoInstantUploadEnabled]) {
                n = 3;
            } else {
                n = 2;
            }
            break;
        case 4:
            if (k_show_help_option_on_settings) {
                n = n + 1;
            }
            if (k_show_recommend_option_on_settings) {
                n = n + 1;
            }
            if (k_show_feedback_option_on_settings) {
                n = n + 1;
            }
            if (k_show_imprint_option_on_settings) {
                n = n + 1;
            }
            break;
            
        default:
            break;
    }
    
    return n;
}


// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingsCell";
    
    UITableViewCell *cell;
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    switch (indexPath.section) {
        case 0:
            cell = [self getSectionManageAccountBlock:cell byRow:indexPath.row];
            break;

        case 1:
            if (k_multiaccount_available) {
                cell = [self getSectionAddAccountButton:cell byRow:indexPath.row];
            }
            break;

        case 2:
            [self getSectionAppPinBlock:cell byRow:indexPath.row];
            break;

        case 3:
            [self getSectionAppInstantUpload:cell byRow:indexPath.row];
            break;
        case 4:
            [self getSectionInfoBlock:cell byRow:indexPath.row];
            break;
            
        default:
            break;
    }
    
    
    return cell;
}


-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    //Set the text of the footer section
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.settingsTableView.frame.size.width, k_padding_last_section + self.tabBarController.tabBar.frame.size.height)];
    container.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.settingsTableView.frame.size.width, k_padding_last_section)];
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:13];
    
    NSInteger sectionToShowFooter = 4;

    if (section == sectionToShowFooter) {
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        NSString *lastGitCommit = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"LastGitCommit"];
        label.text = [NSString stringWithFormat:@"%@ %d    iOS %@ (%@)", appName, k_year, appVersion, lastGitCommit];
        label.font = appFont;
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
    } else {
        label.backgroundColor = [UIColor clearColor];
        label.text = @"";
    }
    
    [container addSubview:label];
    
    return container;
}


-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    CGFloat height = 0;
    
    switch (section) {
        case 0:
            height = k_padding_normal_section * 2;
            break;
            
        case 1:
            if (k_multiaccount_available) {
                height = k_padding_under_section;
            }else{
                height = 0;
            }
            break;
            
        default:
            height = k_padding_normal_section;
            break;
    }
    
    return height;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    CGFloat height = 0;
    
    switch (section) {
        case 0:
            if (k_multiaccount_available) {
                height = k_padding_under_section;
            }else{
                height = k_padding_normal_section;
            }
            break;
            
        case 1:
            if (k_multiaccount_available) {
                height = k_padding_normal_section;
            } else {
                height = 0;
            }
            break;
            
        case 4:
            height = k_padding_last_section + self.tabBarController.tabBar.frame.size.height;
            break;
            
        default:
            height = k_padding_normal_section;
            break;
    }
    
    return height;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    
    NSString *title = nil;
    
    switch (section) {
        case 0:
            title = NSLocalizedString(@"accounts_section", nil);
            break;
            
        case 2:
            title = NSLocalizedString(@"security_section", nil);
            break;
        case 3:
            title = NSLocalizedString(@"instant_updloads_section", nil);
            break;
        case 4:
            title = NSLocalizedString(@"more_section", nil);
            break;

        default:
            break;
    }
    
    return title;
}

#pragma mark - Sections of TableView

-(UITableViewCell *) getSectionInfoBlock:(UITableViewCell *) cell byRow:(NSInteger) row {
    switch (row) {
        case 0:
            if (k_show_help_option_on_settings) {
                [self setTitleOfRow:help inCell:cell];
            } else if (k_show_recommend_option_on_settings) {
                [self setTitleOfRow:recommend inCell:cell];
            } else if (k_show_feedback_option_on_settings) {
                [self setTitleOfRow:feedback inCell:cell];
            } else if (k_show_imprint_option_on_settings) {
                [self setTitleOfRow:impress inCell:cell];
            }
            break;
            
        case 1:
            if (k_show_help_option_on_settings && k_show_recommend_option_on_settings) {
                 [self setTitleOfRow:recommend inCell:cell];
            } else if ((k_show_help_option_on_settings && !k_show_recommend_option_on_settings) ||
                        (!k_show_help_option_on_settings && k_show_recommend_option_on_settings)){
                if (k_show_feedback_option_on_settings) {
                    [self setTitleOfRow:feedback inCell:cell];
                } else if (k_show_imprint_option_on_settings){
                    [self setTitleOfRow:impress inCell:cell];
                }
            } else if (!k_show_help_option_on_settings && !k_show_recommend_option_on_settings) {
                 [self setTitleOfRow:impress inCell:cell];
            }
            break;
            
        case 2:
            if (k_show_help_option_on_settings && k_show_recommend_option_on_settings && k_show_feedback_option_on_settings) {
                [self setTitleOfRow:feedback inCell:cell];
            } else if (!k_show_help_option_on_settings || !k_show_recommend_option_on_settings || !k_show_feedback_option_on_settings) {
                [self setTitleOfRow:impress inCell:cell];
            }
            break;
            
        case 3:
            [self setTitleOfRow:impress inCell:cell];
            break;
            
        default:
            break;
    }
    return cell;
}


///-----------------------------------
/// @name Set title of the row
///-----------------------------------

/**
 * This method set the title of the row in order to the branding options
 *
 * @param row -> (int) the number of the row to set the title
 * @param cell -> (UITableViewCell) the cell to set the options
 *
 */
- (void) setTitleOfRow: (NSInteger)row inCell: (UITableViewCell *)cell{
    
    cell.textLabel.font = k_settings_normal_font;
    
    switch (row) {
            
        case help:
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"help", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            
            //Add accesibility label for Automation
            cell.accessibilityLabel = ACS_SETTINGS_HELP_CELL;
            break;
            
        case recommend:
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"recommend_to_friend", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            //Add accesibility label for Automation
            cell.accessibilityLabel = ACS_SETTINGS_RECOMMEND_CELL;
            break;
            
        case feedback:
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"send_feedback", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            //Add accesibility label for Automation
            cell.accessibilityLabel = ACS_SETTINGS_SEND_FEEDBACK_CELL;
            break;
            
        case impress:
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"imprint_button", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            //Add accesibility label for Automation
            cell.accessibilityLabel = ACS_SETTINGS_IMPRESS_CELL;
            break;
            
        default:
            break;
    }
}


- (UITableViewCell *) getSectionStorageBlock:(UITableViewCell *) cell byRow:(int) row {
    
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    
    switch (row) {
        case 0:
            
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"Storage", nil);
            
            NSInteger percent = 0;
            if(self.user.storage > 0) {
                percent = (self.user.storageOccupied * 100)/self.user.storage;
            }
                        
            cell.detailTextLabel.text=[NSString stringWithFormat:@"%ld%% %@ %ldMB %@", (long)percent, NSLocalizedString(@"of_storage", nil), self.user.storage, NSLocalizedString(@"occupied_storage", nil)];
            
            [cell.detailTextLabel setFont:appFont];
            [cell.detailTextLabel setTextColor:[UIColor colorOfDetailTextSettings]];
            
            break;
        case 1:
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.textLabel.text = NSLocalizedString(@"storage_upgrade", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (UITableViewCell *) getSectionAppPinBlock:(UITableViewCell *) cell byRow:(NSInteger) row {
   
    cell.textLabel.font = k_settings_normal_font;
    
    switch (row) {
        case 0:
            
            if (k_is_passcode_forced) {

                cell.textLabel.text = NSLocalizedString(@"title_app_pin_forced", nil);
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.textLabel.font = k_settings_bold_font;
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.editing = NO;
                cell.backgroundColor = [UIColor colorOfBackgroundButtonOnList];
                cell.textLabel.textColor = [UIColor colorOfTextButtonOnList];
                cell.accessibilityLabel = ACS_SETTINGS_PASSCODE_CHANGE_CELL;

            } else {
                if([self isTouchIDAvailable] && !self.switchPasscode.on) {
                    cell.textLabel.text = NSLocalizedString(@"title_app_pin_and_touchID", nil);
                    
                } else {
                    cell.textLabel.text = NSLocalizedString(@"title_app_pin", nil);
                }
                self.switchPasscode = [[UISwitch alloc] initWithFrame:CGRectZero];
                cell.accessoryView = self.switchPasscode;
                [self.switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:YES];
                [self.switchPasscode addTarget:self action:@selector(changeSwitchPasscode:) forControlEvents:UIControlEventValueChanged];
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                //Add accesibility label for Automation
                self.switchPasscode.accessibilityLabel = ACS_SETTINGS_PASSCODE_SWITCH;
            }
            

            
            break;
            
        case 1:
            cell.textLabel.text = NSLocalizedString(@"title_app_touchID", nil);
            self.switchTouchID = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = self.switchTouchID;
            [self.switchTouchID setOn:[ManageAppSettingsDB isTouchID] animated:YES];
            [self.switchTouchID addTarget:self action:@selector(changeSwitchTouchID:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            //Add accesibility label for Automation
            self.switchTouchID.accessibilityLabel = ACS_SETTINGS_TOUCH_ID_SWITCH;
            
            break;
            
        default:
            break;
    }
    
    return cell;
}

-(UITableViewCell *) getSectionAppInstantUpload:(UITableViewCell *) cell byRow:(NSInteger) row {
    
    cell.textLabel.font = k_settings_normal_font;
    
    switch (row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"title_instant_upload_photos", nil);
            self.switchInstantUploadPhotos = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = self.switchInstantUploadPhotos;
            [self.switchInstantUploadPhotos setOn:[[InstantUpload instantUploadManager] imageInstantUploadEnabled] animated:YES];
            [self.switchInstantUploadPhotos addTarget:self action:@selector(changeSwitchImageInstantUpload:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            self.switchInstantUploadPhotos.accessibilityLabel = ACS_SETTINGS_INSTANT_UPLOAD_PHOTOS_SWITCH;
            
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"title_instant_upload_videos", nil);
            self.switchInstantUploadVideos = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = self.switchInstantUploadVideos;
            [self.switchInstantUploadVideos setOn:[[InstantUpload instantUploadManager] videoInstantUploadEnabled] animated:YES];
            [self.switchInstantUploadVideos addTarget:self action:@selector(changeSwitchVideoInstantUpload:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            self.switchInstantUploadVideos.accessibilityLabel = ACS_SETTINGS_INSTANT_UPLOAD_VIDEOS_SWITCH;
            
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"title_background_instant_upload", nil);
            
            self.switchBackgroundInstantUpload = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = self.switchBackgroundInstantUpload;
            
            [self.switchBackgroundInstantUpload setOn:[[InstantUpload instantUploadManager] backgroundInstantUploadEnabled] animated:YES];
            
            [self.switchBackgroundInstantUpload addTarget:self action:@selector(changeSwitchBackgroundInstantUpload:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            self.switchBackgroundInstantUpload.accessibilityLabel = ACS_SETTINGS_BACKGROUND_INSTANT_UPLOADS_SWITCH;
            break;
        default:
            break;
    }
    
    return cell;
}


- (AccountCell *) getSectionManageAccountBlock:(UITableViewCell *) cell byRow:(NSInteger) row {
    
    static NSString *CellIdentifier = @"AccountCell";
    
    AccountCell *accountCell = (AccountCell *) [self.settingsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UserDto *userAccount = [UserDto new];
    userAccount = [self.listUsers objectAtIndex:row];
    
    if (accountCell == nil) {
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"AccountCell" owner:self options:nil];
        
        for (id currentObject in topLevelObjects){
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                accountCell =  (AccountCell *) currentObject;
                break;
            }
        }
    }
    
    [accountCell.activeButton setTag:row];
    
    accountCell.selectionStyle = UITableViewCellSelectionStyleNone;
    accountCell.userName.text = [userAccount nameToDisplay];
    
    //If saml needs change the name to utf8
    if (k_is_sso_active) {
        accountCell.userName.text = [accountCell.userName.text stringByRemovingPercentEncoding];
    }
    
    if ([UtilsUrls isNecessaryUpdateToPredefinedUrlByPreviousUrl:userAccount.predefinedUrl]) {
        accountCell.urlServer.text = NSLocalizedString(@"pending_migration_to_new_url", nil);
        accountCell.urlServer.textColor = [UIColor colorOfLoginErrorText];
    } else {
        accountCell.urlServer.text = userAccount.url;
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [accountCell.menuButton setTag:row];
    [accountCell.menuButton setImage:[UIImage imageNamed:@"more-filledBlack.png"] forState:UIControlStateNormal];
    [accountCell.menuButton addTarget:self action:@selector(showMenuAccountOptions:) forControlEvents:UIControlEventTouchUpInside];

    
    if(((UserDto *) [self.listUsers objectAtIndex:row]).activeaccount){
        [accountCell.activeButton setImage:[UIImage imageNamed:@"radio_checked.png"] forState:UIControlStateNormal];
        
    }else {
        [accountCell.activeButton setImage:[UIImage imageNamed:@"radio_unchecked.png"] forState:UIControlStateNormal];
    }
    
    //Accesibility support for Automation
    NSString *accesibilityCellString = ACS_SETTINGS_USER_ACCOUNT_CELL;
    accesibilityCellString = [accesibilityCellString stringByReplacingOccurrencesOfString:@"$user" withString:accountCell.userName.text];
    accesibilityCellString = [accesibilityCellString stringByReplacingOccurrencesOfString:@"$server" withString:accountCell.urlServer.text];

    [accountCell setAccessibilityLabel:accesibilityCellString];
    
    return accountCell;
    
}


- (UITableViewCell *) getSectionAddAccountButton:(UITableViewCell *) cell byRow:(NSInteger) row {
    
    static NSString *CellIdentifier = @"AddAccountCell";
    
    UITableViewCell *addAccountCell;
    
    addAccountCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    addAccountCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    addAccountCell.textLabel.font = k_settings_bold_font;
    addAccountCell.textLabel.textAlignment = NSTextAlignmentCenter;
    addAccountCell.editing = NO;
    addAccountCell.textLabel.text = NSLocalizedString(@"add_new_account", nil);
    addAccountCell.backgroundColor = [UIColor colorOfBackgroundButtonOnList];
    addAccountCell.textLabel.textColor = [UIColor colorOfTextButtonOnList];
    
    //Accesibility support for Automation
    addAccountCell.accessibilityLabel = ACS_SETTINGS_ADD_ACCOUNT_CELL;
    
    return addAccountCell;
}


#pragma mark - UITableView delegate

// Tells the delegate that the specified row is now selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0:
            if (k_multiaccount_available) {
                [self didPressOnAccountIndexPath:indexPath];
            }
            break;
            
        case 1:
            if (k_multiaccount_available) {
                [self didPressOnAddAccountButton];
            }
            break;
            
        case 2:
            if (k_is_passcode_forced) {
                [self didPressOnChangePasscodeButton];
            }
            break;
            
        case 4:
            [self didPressOnInfoBlock:indexPath.row];
            break;
            
        default:
            break;
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if(indexPath.section > 0) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
         UserDto *selectedUser = (UserDto *)[self.listUsers objectAtIndex:indexPath.row];
        [self didSelectLogOutAccount:selectedUser];
    }
}


#pragma mark - DidSelectRow Sections

-(void) didPressOnInfoBlock:(NSInteger) row {

    switch (row) {
        case 0:
            if (k_show_help_option_on_settings) {
                [self setContentOfRow:help];
            } else if (k_show_recommend_option_on_settings) {
                [self setContentOfRow:recommend];
            } else if (k_show_feedback_option_on_settings) {
                [self setContentOfRow:feedback];
            } else if (k_show_imprint_option_on_settings) {
                [self setContentOfRow:impress];
            }
            break;
        case 1:
            if (k_show_help_option_on_settings && k_show_recommend_option_on_settings) {
                [self setContentOfRow:recommend];
            } else if ((k_show_help_option_on_settings && !k_show_recommend_option_on_settings) ||
                       (!k_show_help_option_on_settings && k_show_recommend_option_on_settings)){
                if (k_show_feedback_option_on_settings) {
                    [self setContentOfRow:feedback];
                } else if (k_show_imprint_option_on_settings){
                   [self setContentOfRow:impress];
                }
            } else if (!k_show_help_option_on_settings && !k_show_recommend_option_on_settings) {
                [self setContentOfRow:impress];
            }
            break;
        case 2:
            if (k_show_help_option_on_settings && k_show_recommend_option_on_settings && k_show_feedback_option_on_settings) {
                [self setContentOfRow:feedback];
            } else if (!k_show_help_option_on_settings || !k_show_recommend_option_on_settings || !k_show_feedback_option_on_settings) {
                [self setContentOfRow:impress];
            }
            break;
        case 3:
            [self setContentOfRow:impress];
            break;
        default:
            break;
    }
}


///-----------------------------------
/// @name Set the content of the row
///-----------------------------------

/**
 * This method set the content of the row in order to the branding options
 *
 * @param row -> (int) the number of the row to set the content
 *
 */
-(void) setContentOfRow: (int)row {
    switch (row) {
        case help:
            DLog(@"1-Press Help");
            if (IS_IPHONE) {
                DLog(@"2.1-Press Help");
                WebViewController *webView = [[WebViewController alloc]initWithNibName:@"WebViewController" bundle:nil];
                
                webView.urlString = k_help_url;
                webView.navigationTitleString = NSLocalizedString(@"help", nil);
                
                [self.navigationController pushViewController:webView animated:NO];

            } else {
                DLog(@"2.2-Press Help");
                if(!_detailViewController) {
                    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                    self.detailViewController = app.detailViewController;
                }
                [self.detailViewController openLink:k_help_url];
                self.detailViewController.linkTitle=NSLocalizedString(@"help", nil);
            }
            break;
            
        case recommend:
        {
            
            if (IS_IPHONE && (!IS_PORTRAIT)) {
                
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil
                                                                   message:NSLocalizedString(@"not_show_potrait", nil)
                                                                  delegate:nil
                                                         cancelButtonTitle:nil
                                                         otherButtonTitles:NSLocalizedString(@"ok",nil), nil];
                [alertView show];
                
            } else {
                
                if (self.popupQuery) {
                    self.popupQuery = nil;
                }
                self.popupQuery = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:@"Facebook", @"Twitter", @"E-Mail", nil];
                
                self.popupQuery.actionSheetStyle = UIActionSheetStyleDefault;
                self.popupQuery.tag = k_tag_actionSheet_recommend;
                
                if (IS_IPHONE) {
                    [self.popupQuery showInView:[self.view window]];
                }else {
                    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                    [self.popupQuery showInView:app.splitViewController.view];
                }
            }
        }
            break;
            
        case feedback:
            [self sendFeedbackByMail];
            break;
        case impress:
            [self goImprint];
            break;
        default:
            break;
    }
}

- (void) didPressOnAddAccountButton{
   
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    UniversalLoginViewController *loginViewController = [UtilsLogin getLoginVCWithMode:LoginModeCreate andUser:nil];
    
    if (IS_IPHONE)
    {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:loginViewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
    } else {
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:loginViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
    }

}

- (void) didPressOnChangePasscodeButton{
    
    //Create pass code view controller
    self.vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
    self.vc.delegate = self;
    
    //Create the navigation bar of portrait
    OCPortraitNavigationViewController *oc = [[OCPortraitNavigationViewController alloc]initWithRootViewController:_vc];
    
    self.vc.mode = KKPasscodeModeChange;
    
    if (IS_IPHONE) {
        //is iphone
        [self presentViewController:oc animated:YES completion:nil];
    } else {
        //is ipad
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        oc.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:oc animated:YES completion:nil];
    }
    
    [self.settingsTableView reloadData];

}

- (void) didPressOnAccountIndexPath:(NSIndexPath*)indexPath {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    UserDto *selectedUser = (UserDto *)[self.listUsers objectAtIndex:indexPath.row];

    //We check the connection here because we need to accept the certificate on the self signed server before go to the files tab
    [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:[UtilsUrls getFullRemoteServerPath:selectedUser]];

    
    //Method to change the account
    [[OCLoadingSpinner sharedOCLoadingSpinner] initLoadingForViewController: self];
    [app switchActiveUserTo:selectedUser isNewAccount:NO withCompletionHandler:^{
        DLog(@"refreshing list of accounts after user was switched");
        
        [[OCLoadingSpinner sharedOCLoadingSpinner] endLoading];
        
        //If ipad, clean the detail view
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            [app presentWithView];
        }
                
        [self refreshTable];
        
    } ];
    
}

#pragma mark - AddAccountDelegate

- (void) refreshTable {
    self.listUsers = [ManageUsersDB getAllUsers];
    [self.settingsTableView reloadData];
}


#pragma mark - Manage Accounts Methods

//-----------------------------------
/// @name setCookiesOfActiveAccount
///-----------------------------------

/**
 * Method to delete the current cookies and add the cookies of the active account
 *
 * @warning we have to take in account that the cookies of the active account must to be in the database
 */
- (void) setCookiesOfActiveAccount {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //1- Delete the current cookies because we delete the current active user
    [UtilsFramework deleteAllCookies];
    //2- We restore the previous cookies of the active user on the System cookies storage
    [UtilsCookies setOnSystemStorageCookiesByUser:app.activeUser];
    //3- We delete the cookies of the active user on the databse because it could change and it is not necessary keep them there
    [ManageCookiesStorageDB deleteCookiesByUser:app.activeUser];
}

///-----------------------------------
/// @name cancelAndRemoveFromTabRecentsAllInfoByUser
///-----------------------------------

/**
 * This method cancel the uploads of a deleted user and after that remove all the other files from Recents Tab
 *
 * @param UserDto
 *
 */

- (void) cancelAndRemoveFromTabRecentsAllInfoByUser:(UserDto *) selectedUser {
    
    //1- - We cancell all the downloads
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    //Create an array with the data of all uploads
    __block NSArray *uploadsArray = [NSArray arrayWithArray:appDelegate.uploadArray];
    
    //Var to use the current ManageUploadRequest
    __block ManageUploadRequest *currentManageUploadRequest = nil;
    
    
    //Make a loop for all objects of uploadsArray.
    [uploadsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        currentManageUploadRequest = obj;
        
        if (currentManageUploadRequest.userUploading.userId == selectedUser.userId) {
            [currentManageUploadRequest cancelUpload];
        }
        
        //2- Clean the recent view
        if ([uploadsArray count] == idx) {
            
            DLog(@"All canceled. Now we clean the view");
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            //Remove from Recents tab all the info of this user
            [app removeFromTabRecentsAllInfoByUser:selectedUser];
        }
    }];
    
}


#pragma mark - Utils

- (void) cancelAllDownloads {
    //Cancel downloads in ipad
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate.downloadManager cancelDownloads];
    
    [[AppDelegate sharedSyncFolderManager] cancelAllDownloads];
}

- (NSMutableArray *) getUsersWithoutActiveUser {
    NSMutableArray *listOfUsersWithouActive = [NSMutableArray new];
    
    for (UserDto *current in self.listUsers) {
        if (!current.activeaccount) {
            [listOfUsersWithouActive addObject:current];
        }
    }
    
    return listOfUsersWithouActive;
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {

    if (actionSheet.tag == k_tag_actionSheet_recommend) {
        
        switch (buttonIndex) {
            case 0:
                DLog(@"Facebook");
                [self publishFacebook];
                break;
            case 1:
                DLog(@"Twitter");
                [self publishTwitter];
                break;
            case 2:
                DLog(@"Mail");
                [self sendRecommendacionByMail];
                break;
            case 3:
                DLog(@"Cancel Button Clicked");
                break;
        }
    } else if (actionSheet.tag == k_tag_actionSheet_menu_account) {
        switch (buttonIndex) {
            case 0:
                [self didSelectEditAccount:self.selectedUserAccount];
                break;
            case 1:
                [self didSelectClearCacheAccount:self.selectedUserAccount];
                break;
            case 2:
                [self didSelectLogOutAccount:self.selectedUserAccount];
                break;
            default:
                break;
        }
    }
}

#pragma mark - Social Publish Methods

-(void) publishTwitter {
    // Singleton instance
    self.twitter = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    // Check that twitter is available
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        // Block to handle the result
        SLComposeViewControllerCompletionHandler completionHandler = ^(SLComposeViewControllerResult result)
        {
            switch (result) {
                case SLComposeViewControllerResultCancelled:
                    DLog(@"canceled");
                    break;
                case SLComposeViewControllerResultDone:
                    DLog(@"published");
                    break;
                default:
                    break;
            }
            self.isMailComposeVisible = NO;
            [self dismissViewControllerAnimated:YES completion:nil];
        };
        
        //Custom message
        if (k_is_custom_twitter) {
            // Add the text to the publish
            NSString *message = k_custom_twitter_message;
            [self.twitter setInitialText:message];
            
        } else {
            // Add the text to the publish with the URL
            [self.twitter setInitialText:[NSString stringWithFormat:@"%@%@",[NSLocalizedString(@"twitter_message", nil) stringByReplacingOccurrencesOfString:@"$twitteruser" withString:k_twitter_user],k_download_url_short]];
        }
        
        // Add an image to the publish
        [self.twitter addImage:[UIImage imageNamed:@"CompanyLogo.png"]];
        
        [self.twitter setCompletionHandler:completionHandler];
        
        if (!IS_IPHONE)
        {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            [app.detailViewController presentViewController:self.twitter animated:YES completion:^{
                self.isMailComposeVisible = YES;
            }];
            
            
        } else{
            
            [self presentViewController:self.twitter animated:YES completion:^{
                self.isMailComposeVisible = YES;
            }];
        }
    }  else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:NSLocalizedString(@"account_not_configure", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil];
        [alertView show];
    }
}


-(void) publishFacebook {
    
    self.facebook = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewControllerCompletionHandler completionHandler = ^(SLComposeViewControllerResult result)
        {
            switch (result) {
                case SLComposeViewControllerResultCancelled:
                    DLog(@"canceled");
                    break;
                case SLComposeViewControllerResultDone:
                    DLog(@"published");
                    break;
                default:
                    break;
            }
             self.isMailComposeVisible = NO;
            [self dismissViewControllerAnimated:YES completion:nil];
        };
        
        if(k_is_custom_facebook) {
            [self.facebook setInitialText:k_custom_facebook_message];
        } else {
            NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
            [self.facebook setInitialText:[NSString stringWithFormat: @"%@%@",[NSLocalizedString(@"facebook_message", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName],k_download_url_long]];
        }
        
        [self.facebook addImage:[UIImage imageNamed:@"CompanyLogo.png"]];
        [self.facebook setCompletionHandler:completionHandler];
        
        if (!IS_IPHONE)
        {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            [app.detailViewController presentViewController:self.facebook animated:YES completion:^{
                self.isMailComposeVisible = YES;
            }];
            
            
        } else{
            [self presentViewController:self.facebook animated:YES completion:^{
                self.isMailComposeVisible = YES;
            }];
        }
        
    } else {
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:NSLocalizedString(@"account_not_configure", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

-(void) sendRecommendacionByMail {
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if ([MFMailComposeViewController canSendMail]) {
        
        if (self.mailer) {
            self.mailer = nil;
        }
        
        self.mailer = [[MFMailComposeViewController alloc] init];
        
        self.mailer.mailComposeDelegate = self;
        
        [self.mailer.navigationBar setTintColor:[UIColor colorOfNavigationItems]];
        
        if(k_is_custom_recommend_mail) {
            if (k_is_username_recommend_mail) {
                NSString *subject= k_subject_recommend_mail;
                @try {
                    if(_user) {
                        [self.mailer setSubject:[subject stringByReplacingOccurrencesOfString:@"$username" withString:[self.user nameToDisplay]]];
                    } else {
                        [self.mailer setSubject:[subject stringByReplacingOccurrencesOfString:@"$username" withString:@""]];
                    }
                }
                @catch (NSException *exception) {
                    DLog(@"Exception stringByReplacingOccurrencesOfString username: %@", exception);
                    [self.mailer setSubject:[subject stringByReplacingOccurrencesOfString:@"$username" withString:@""]];
                }
                @finally {
                }
            }else {
                [self.mailer setSubject:k_subject_recommend_mail];
            }
            
        } else {
            [self.mailer setSubject:[NSLocalizedString(@"mail_recommendation_subject", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName]];
        }
        
        UIImage *myImage = [UIImage imageNamed:@"CompanyLogo.png"];
        NSData *imageData = UIImagePNGRepresentation(myImage);
        [self.mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"logo"];
        
        if(k_is_custom_recommend_mail) {
            if(k_is_sign_custom_usign_username) {
                [self.mailer setMessageBody:[NSString stringWithFormat:@"%@%@",k_text_recommend_mail,[self.user nameToDisplay]] isHTML:NO];
            } else {
                [self.mailer setMessageBody:k_text_recommend_mail isHTML:NO];
            }
        } else {
            
            NSString *emailBody = [NSString stringWithFormat: @"%@\r\n%@",[NSLocalizedString(@"mail_recommendation_body", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName],k_download_url_long];
            [self.mailer setMessageBody:emailBody isHTML:NO];
        }
        
        if (!IS_IPHONE)
        {
            self.mailer.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
            self.mailer.modalPresentationStyle = UIModalPresentationFormSheet;
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            [app.detailViewController presentViewController:self.mailer animated:YES completion:^{
                self.isMailComposeVisible = YES;
            }];
            
    
        } else{
            [self presentViewController:self.mailer animated:YES completion:^{
                self.isMailComposeVisible = YES;
            }];
        }

        
    } else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", nil)
                                                        message:NSLocalizedString(@"device_not_support_mail", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                              otherButtonTitles: nil];
        [alert show];
    }
}

-(void) sendFeedbackByMail {
    
    if ([MFMailComposeViewController canSendMail]){
        
        if (self.mailer) {
            self.mailer = nil;
        }
        
        self.mailer = [[MFMailComposeViewController alloc] init];
        
        self.mailer.mailComposeDelegate = self;
        
        [self.mailer.navigationBar setTintColor:[UIColor colorOfNavigationItems]];
        
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

        NSString *subject = [NSString stringWithFormat:@"%@ - iOS v%@", NSLocalizedString(@"mail_feedback_subject", nil), version];
        subject = [subject stringByReplacingOccurrencesOfString:@"$appname" withString:appName];

        [self.mailer setSubject:subject];
        
        NSArray *toRecipients = [NSArray arrayWithObjects:k_mail_feedback,nil];
        [self.mailer setToRecipients:toRecipients];
        
        NSString *emailBody = @"";
        [self.mailer setMessageBody:emailBody isHTML:NO];
        
        if (!IS_IPHONE)
        {
            self.mailer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            self.mailer.modalPresentationStyle = UIModalPresentationFormSheet;
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            [app.detailViewController presentViewController:self.mailer animated:YES completion:^{
                self.isMailComposeVisible = YES;
            }];
            
            
        }else{
            
            [self presentViewController:self.mailer animated:YES completion:^{
                self.isMailComposeVisible = YES;
            }];

        }
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", nil)
                                                        message:NSLocalizedString(@"device_not_support_mail", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                              otherButtonTitles: nil];
        [alert show];
    }
}


#pragma mark - MFMailComposeController delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	switch (result)
	{
		case MFMailComposeResultCancelled:
			DLog(@"Mail cancelled: you cancelled the operation and no email message was queued");
			break;
		case MFMailComposeResultSaved:
			DLog(@"Mail saved: you saved the email message in the Drafts folder");
			break;
		case MFMailComposeResultSent:
			DLog(@"Mail send: the email message is queued in the outbox. It is ready to send the next time the user connects to email");
			break;
		case MFMailComposeResultFailed:
			DLog(@"Mail failed: the email message was nog saved or queued, possibly due to an error");
			break;
		default:
			DLog(@"Mail not sent");
			break;
	}
    
    if (IS_IPHONE) {
        
         [self dismissViewControllerAnimated:YES completion:^{
              self.isMailComposeVisible = NO;
         }];
        
    }else{
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [app.detailViewController dismissViewControllerAnimated:YES completion:^{
             self.isMailComposeVisible = NO;
        }];
    }
   
}


#pragma mark - KKPasscodeViewController delegate methods

///-----------------------------------
/// @name Changes in Pass Code
///-----------------------------------

/**
 * This method is called when there are changes in the passcode
 *
 * @param viewController -> KKPasscodeViewController (Controller where if it made the changes)
 *
 */
- (void)didSettingsChanged:(KKPasscodeViewController*)viewController{
    
    DLog(@"didSettingsChanged");
    [self.switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:NO];

}

///-----------------------------------
/// @name Cancel Pass Code View
///-----------------------------------

/**
 * Called when the user tap the cancel button in a pass code view
 *
*/
- (void)didCancelPassCodeTapped{
    
    //Refresh the switch pass code
    [self.switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:NO];
    [self.settingsTableView reloadData];

    
}

#pragma mark - Touch ID methods

- (void)switchTouchIDTo:(BOOL)value {
    [self.switchTouchID setOn:value animated:NO];
}

-(BOOL)isTouchIDAvailable {
    return [[ManageTouchID sharedSingleton] isTouchIDAvailable];
}

-(void)setPropertiesTouchIDToState:(BOOL)isTocuhIDActive{
    
    if (isTocuhIDActive) {
        [self switchTouchIDTo:YES];
        [ManageAppSettingsDB updateTouchIDTo:YES];
    } else {
        [self switchTouchIDTo:NO];
        [ManageAppSettingsDB updateTouchIDTo:NO];
    }
}

#pragma mark - Instant Upload

-(IBAction)changeSwitchImageInstantUpload:(id)sender {
    UISwitch *uiSwitch = (UISwitch *)sender;
    [[InstantUpload instantUploadManager] setImageInstantUploadEnabled:uiSwitch.on];
    [self refreshTable];
}

-(IBAction)changeSwitchVideoInstantUpload:(id)sender {
    UISwitch *uiSwitch = (UISwitch *)sender;
    [[InstantUpload instantUploadManager] setVideoInstantUploadEnabled:uiSwitch.on];
    [self refreshTable];
}

-(IBAction)changeSwitchBackgroundInstantUpload:(id)sender {
    UISwitch *uiSwitch = (UISwitch *)sender;
    [[InstantUpload instantUploadManager] setBackgroundInstantUploadEnabled:uiSwitch.on];
    [self refreshTable];
}

# pragma mark - menu account

- (void)showMenuAccountOptions:(UIButton *)sender {

    self.selectedUserAccount = [self.listUsers objectAtIndex:sender.tag];
    NSString *titleMenu = [UtilsUrls getFullRemoteServerPathWithoutProtocolBeginningWithUserDisplayName: self.selectedUserAccount];
    
    
    if (self.menuAccountActionSheet) {
        self.menuAccountActionSheet = nil;
    }
    
    self.menuAccountActionSheet = [[UIActionSheet alloc]
                                   initWithTitle:titleMenu
                                   delegate:self
                                   cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                                   destructiveButtonTitle:nil
                                   otherButtonTitles:NSLocalizedString(@"menu_account_edit", nil), NSLocalizedString(@"menu_account_clear_cache", nil), NSLocalizedString(@"menu_account_log_out", nil), nil];
    
    self.menuAccountActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    self.menuAccountActionSheet.tag = k_tag_actionSheet_menu_account;
    
    if (IS_IPHONE) {
        [self.menuAccountActionSheet showInView:self.tabBarController.view];
    } else {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [self.menuAccountActionSheet showInView:app.splitViewController.view];
    }
}


#pragma mark - Options menu account

- (void) didSelectEditAccount:(UserDto *)user  {
   
    UniversalLoginViewController *loginViewController = [UtilsLogin getLoginVCWithMode:LoginModeUpdate andUser:user];
    
    if (IS_IPHONE) {
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:loginViewController];
        [self.navigationController presentViewController:navController animated:YES completion:nil];
        
    } else {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        OCNavigationController *navController = nil;
        navController = [[OCNavigationController alloc] initWithRootViewController:loginViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
    }

}

- (void) didSelectClearCacheAccount:(UserDto *)user {

    [[OCLoadingSpinner sharedOCLoadingSpinner] initLoadingForViewController: self];
    
    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        void (^deletionBlock)(void) = ^{
            
            [DeleteUtils deleteAllDownloadedFilesByUser:user];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[OCLoadingSpinner sharedOCLoadingSpinner]  endLoading];
            });
        };
        
        deletionBlock();
        
    });
}

- (void) didSelectLogOutAccount:(UserDto *)user {
    
    [self performSelectorInBackground:@selector(cancelAllDownloads) withObject:nil];
    
    [[ManageThumbnails sharedManager] deleteThumbnailCacheFolderOfUserId: user.userId];
    
    //Delete the tables of this user
    [ManageUsersDB removeUserAndDataByUser:user];
    
    [self performSelectorInBackground:@selector(cancelAndRemoveFromTabRecentsAllInfoByUser:) withObject:user];
    
    //Delete files of user in the system
    NSString *userFolder = [NSString stringWithFormat:@"/%ld",(long)user.userId];
    NSString *path= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:userFolder];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    
    //if previous account is active we active the first by userId
    if(user.activeaccount) {
        
        [ManageUsersDB setActiveAccountAutomatically];
        
        //Update in appDelegate the active user
        APP_DELEGATE.activeUser = [ManageUsersDB getActiveUser];
        
        [self setCookiesOfActiveAccount];
        
        [UtilsFileSystem createFolderForUser:APP_DELEGATE.activeUser];
        
        //If ipad, clean the detail view
        if (!IS_IPHONE) {
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            [app presentWithView];
        }
    }
    
    self.listUsers = [ManageUsersDB getAllUsers];
    
    if([self.listUsers count] > 0) {
        [self.settingsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    } else {
        
        self.settingsTableView.editing = NO;
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        [self cancelAllDownloads];
        app.uploadArray=[[NSMutableArray alloc]init];
        [app updateRecents];
        [app restartAppAfterDeleteAllAccounts];
    }
}


#pragma mark - iOS 8 rotation method

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    if (self.menuAccountActionSheet) {
        [self.menuAccountActionSheet dismissWithClickedButtonIndex:3 animated:NO];
    }
    if (self.popupQuery) {
        [self.popupQuery dismissWithClickedButtonIndex:3 animated:NO];
    }

}

#pragma mark InstantUploadDelegate methods

- (void) instantUploadPermissionLostOrDenied {
    self.switchInstantUploadPhotos.on = NO;
    self.switchInstantUploadVideos.on = NO;
}

- (void) backgroundInstantUploadPermissionLostOrDenied {
    self.switchBackgroundInstantUpload.on = NO;
}

@end
