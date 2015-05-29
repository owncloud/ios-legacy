//
//  SettingsViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/11/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
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
#import "ManageLocation.h"
#import "ManageAsset.h"
#import "PrepareFilesToUpload.h"
#import "UploadUtils.h"
#import "UtilsCookies.h"
#import "ManageCookiesStorageDB.h"
#import "Accessibility.h"

//Settings table view size separator
#define k_padding_normal_section 20.0
#define k_padding_under_section 5.0

//Settings custom font
#define k_settings_normal_font [UIFont fontWithName:@"HelveticaNeue" size:17]
#define k_settings_bold_font [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];


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


-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(UIViewController *)childViewControllerForStatusBarStyle
{
    return nil;
}

@end

@interface SettingsViewController ()

@property (nonatomic, strong) NSMutableArray *listUsers;

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isMailComposeVisible = NO;
       
        //Set the instant upload
        [self performSelector:@selector(initStateInstantUpload) withObject:nil afterDelay:4.0];
    
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"settings", nil);
    
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.edgesForExtendedLayout = UIRectCornerAllCorners;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //Relaunch the uploads that failed before
    [app performSelector:@selector(relaunchUploadsFailedNoForced) withObject:nil afterDelay:5.0];
    
    //Set the passcode swith asking to database
   [self.switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:NO];
    
    self.user = app.activeUser;
    
    self.listUsers = [ManageUsersDB getAllUsers];

}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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
    if(![ManageAppSettingsDB isPasscode]) {
        //Set mode
        self.vc.mode = KKPasscodeModeSet;
    } else {
        //Dissable mode
        self.vc.mode = KKPasscodeModeDisabled;
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
}


-(void)disconnectUser {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [ManageUsersDB removeUserAndDataByIdUser: app.activeUser.idUser];
    
    [UtilsFramework deleteAllCookies];
    
    DLog(@"ID to delete user: %ld", (long)app.activeUser.idUser);
    
    //Delete files os user in the system
    NSString *userFolder = [NSString stringWithFormat:@"/%ld", (long)app.activeUser.idUser];
    NSString *path= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:userFolder];
    
    NSError *error;     
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    [app.downloadManager cancelDownloads];
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
            
            [self.navigationController pushViewController:webView animated:YES];

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
    
    NSInteger sections = 0;
    
    if (k_multiaccount_available) {
        sections = 5;
     } else {
        sections = 4;
     }
    return sections;
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
            n = 1;
            break;
            
        case 2:
            n = 1;
            break;
            
        case 3:
            
            if (k_multiaccount_available) {
               n = 1;
            }else{
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
            }

            break;
            
        case 4:
            n = 0;
            if (k_multiaccount_available) {
               
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
            if (k_multiaccount_available) {
                cell = [self getSectionManageAccountBlock:cell byRow:indexPath.row];
            }else{
                cell = [self getSectionDisconnectButton:cell byRow:indexPath.row];
            }
            break;
            
        case 1:
            if (k_multiaccount_available) {
               cell = [self getSectionAddAccountButton:cell byRow:indexPath.row];
            }else{
                [self getSectionAppPinBlock:cell byRow:indexPath.row];
            }
            break;
            
        case 2:
            if (k_multiaccount_available) {
                [self getSectionAppPinBlock:cell byRow:indexPath.row];
            }else{
                [self getSectionAppInstantUpload:cell byRow:indexPath.row];
            }
            break;
            
        case 3:
            if (k_multiaccount_available) {
                [self getSectionAppInstantUpload:cell byRow:indexPath.row];
            }else{
                [self getSectionInfoBlock:cell byRow:indexPath.row];
            }
            break;
            
        case 4:
            if (k_multiaccount_available) {
                [self getSectionInfoBlock:cell byRow:indexPath.row];
            }else{
                //Nothing
            }
            
            break;
            
        default:
            break;
    }
    
    
    return cell;
}


-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    //Set the text of the footer section
    UILabel *label = [[UILabel alloc] init];
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:13];
    
    NSInteger sectionToShowFooter = 3;
    
    if (k_multiaccount_available) {
        sectionToShowFooter = 4;
    }

    if (section == sectionToShowFooter) {
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        label.text = [NSString stringWithFormat:@"%@ %d    iOS %@", appName, k_year, appVersion];
        label.font = appFont;
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
    } else {
        label.backgroundColor = [UIColor clearColor];
        label.text = @"";
    }
    return label;
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
                height = k_padding_normal_section;
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
            
        case 1:
            
            if (!k_multiaccount_available) {
                title = NSLocalizedString(@"security_section", nil);
            }
            
            break;
            
        case 2:
            
            if (k_multiaccount_available) {
                title = NSLocalizedString(@"security_section", nil);
            }else{
                title = NSLocalizedString(@"instant_updloads_section", nil);
            }
            
            break;
            
        case 3:
            
            if (k_multiaccount_available) {
                title = NSLocalizedString(@"instant_updloads_section", nil);
            }else{
                title = NSLocalizedString(@"more_section", nil);
            }
            
            break;
            
        case 4:
            if (k_multiaccount_available) {
                title = NSLocalizedString(@"more_section", nil);
            }
    
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
            cell.textLabel.text=NSLocalizedString(@"title_app_pin", nil);
            self.switchPasscode = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = self.switchPasscode;
            [self.switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:YES];
            [self.switchPasscode addTarget:self action:@selector(changeSwitchPasscode:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            //Add accesibility label for Automation
            self.switchPasscode.accessibilityLabel = ACS_SETTINGS_PASSCODE_SWITCH;
            
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
            cell.textLabel.text = NSLocalizedString(@"title_instant_upload", nil);
            self.switchInstantUpload = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = self.switchInstantUpload;
            [self.switchInstantUpload setOn:[ManageAppSettingsDB isInstantUpload] animated:YES];
            [self.switchInstantUpload addTarget:self action:@selector(changeSwitchInstantUpload:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            //Add accesibility label for Automation
            self.switchInstantUpload.accessibilityLabel = ACS_SETTINGS_INSTANT_UPLOADS_SWITCH;
            
            break;
        default:
            break;
    }
    
    return cell;
}

- (AccountCell *) getSectionManageAccountBlock:(UITableViewCell *) cell byRow:(NSInteger) row {
    
    static NSString *CellIdentifier = @"AccountCell";
    
    AccountCell *accountCell = (AccountCell *) [self.settingsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (accountCell == nil) {
        
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"AccountCell" owner:self options:nil];
        
        for (id currentObject in topLevelObjects){
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                accountCell =  (AccountCell *) currentObject;
                break;
            }
        }
    }
    
    accountCell.delegate = self;
    [accountCell.activeButton setTag:row];
    
    accountCell.selectionStyle = UITableViewCellSelectionStyleNone;
    accountCell.userName.text = ((UserDto *) [self.listUsers objectAtIndex:row]).username;
    
    //If saml needs change the name to utf8
    if (k_is_sso_active) {
        accountCell.userName.text = [accountCell.userName.text stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    accountCell.urlServer.text = ((UserDto *) [self.listUsers objectAtIndex:row]).url;
    accountCell.accessoryType = UITableViewCellAccessoryDetailButton;
    
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

- (UITableViewCell *) getSectionDisconnectButton:(UITableViewCell *) cell byRow:(NSInteger) row {
    
    
    static NSString *CellIdentifier = @"DisconnectCell";
    
    UITableViewCell *disconnectCell;
    
    disconnectCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
   
    disconnectCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    disconnectCell.textLabel.font = k_settings_bold_font;
    disconnectCell.textLabel.textAlignment = NSTextAlignmentCenter;
    disconnectCell.editing = NO;
    disconnectCell.textLabel.text = NSLocalizedString(@"disconnect_button", nil);
    disconnectCell.backgroundColor = [UIColor colorOfBackgroundButtonOnList];
    disconnectCell.textLabel.textColor = [UIColor colorOfTextButtonOnList];
    
    return disconnectCell;
}

#pragma mark - Accesories support for Accounts Section

- (void) pressedInfoAccountButton:(UIButton *)sender{
    
    //Edit Account
    EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:(UserDto *)[self.listUsers objectAtIndex:sender.tag]];
    
    if (IS_IPHONE)
    {
        viewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
    }
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
            }else{
                [self disconnectUser];
            }
            break;
            
        case 1:
            if (k_multiaccount_available) {
                [self didPressOnAddAccountButton];
            }
            break;
            
        case 3:
            if (!k_multiaccount_available) {
                [self didPressOnInfoBlock:indexPath.row];
            }
            break;
            
        case 4:
            if (k_multiaccount_available) {
                [self didPressOnInfoBlock:indexPath.row];
            }
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
    DLog(@"DELETE!!! %ld", (long)indexPath.row);
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        UserDto *selectedUser = (UserDto *)[self.listUsers objectAtIndex:indexPath.row];
        
        //Cancel downloads of the active user
        if (selectedUser.idUser == app.activeUser.idUser) {
            [self cancelAllDownloadsOfActiveUser];
        }
        
        //Delete the tables of this user
        [ManageUsersDB removeUserAndDataByIdUser: selectedUser.idUser];
        
        [self performSelectorInBackground:@selector(cancelAndRemoveFromTabRecentsAllInfoByUser:) withObject:selectedUser];
        
        //Delete files os user in the system
        NSString *userFolder = [NSString stringWithFormat:@"/%ld",(long)selectedUser.idUser];
        NSString *path= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:userFolder];
        

        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        
        
        //if previeus account is active we active the first by iduser
        if(selectedUser.activeaccount) {
            
            [ManageUsersDB setActiveAccountAutomatically];
            
            //Update in appDelegate the active user
            app.activeUser = [ManageUsersDB getActiveUser];
            
            [self setCookiesOfActiveAccount];
            
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
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            [appDelegate.downloadManager cancelDownloads];
            appDelegate.uploadArray=[[NSMutableArray alloc]init];
            [appDelegate updateRecents];
            [appDelegate restartAppAfterDeleteAllAccounts];
        }
        
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
    //Edit Account
    EditAccountViewController *viewController = [[EditAccountViewController alloc]initWithNibName:@"EditAccountViewController_iPhone" bundle:nil andUser:(UserDto *)[self.listUsers objectAtIndex:indexPath.row]];
    
    if (IS_IPHONE)
    {
        viewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
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
                
                [self.navigationController pushViewController:webView animated:YES];

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
                self.popupQuery = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"E-Mail", nil];
                
                if (IS_IPHONE) {
                    [self.popupQuery showInView:[self.view window]];
                }else {
                    
                    if (IS_IOS8) {
                        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                        [self.popupQuery showInView:app.splitViewController.view];
                    } else {
                        [self.popupQuery showInView:[self.view window]];
                    }
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
    
    //Add Account
    AddAccountViewController *viewController = [[AddAccountViewController alloc]initWithNibName:@"AddAccountViewController_iPhone" bundle:nil];
    viewController.delegate = self;
    
    if (IS_IPHONE)
    {
        viewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        
        OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:viewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [app.splitViewController presentViewController:navController animated:YES completion:nil];
    }

}

- (void) didPressOnAccountIndexPath:(NSIndexPath*)indexPath {
    
    [self cancelAllDownloadsOfActiveUser];
    
    //Method to change the account
    AccountCell *cell = (AccountCell *) [self.settingsTableView cellForRowAtIndexPath:indexPath];
    [cell activeAccount:nil];
}

#pragma mark - AccountCell Delegate Methods

-(void)activeAccountByPosition:(NSInteger)position {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    UserDto *selectedUser = (UserDto *)[self.listUsers objectAtIndex:position];
    
    if (app.activeUser.idUser != selectedUser.idUser) {
        //Cancel downloads of the previous user
        [self cancelAllDownloadsOfActiveUser];
        
        //If ipad, clean the detail view
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [app presentWithView];
        }
        
        [ManageUsersDB setAllUsersNoActive];
        [ManageUsersDB setActiveAccountByIdUser:selectedUser.idUser];
        selectedUser.activeaccount = YES;
        
        //Restore the cookies of the future activeUser
        //1- Storage the new cookies on the Database
        [UtilsCookies setOnDBStorageCookiesByUser:app.activeUser];
        //2- Clean the cookies storage
        [UtilsFramework deleteAllCookies];
        //3- We restore the previous cookies of the active user on the System cookies storage
        [UtilsCookies setOnSystemStorageCookiesByUser:selectedUser];
        //4- We delete the cookies of the active user on the databse because it could change and it is not necessary keep them there
        [ManageCookiesStorageDB deleteCookiesByUser:selectedUser];
        
        //Change the active user in appDelegate global variable
        app.activeUser = selectedUser;
        
        //Check if the server is Chunk
        [self performSelectorInBackground:@selector(checkShareItemsInAppDelegate) withObject:nil];
        
        [UtilsCookies eraseURLCache];
        
        self.listUsers = [ManageUsersDB getAllUsers];
        [self.settingsTableView reloadData];
        
        //We get the current folder to create the local tree
        //we create the user folder to haver multiuser
        NSString *currentLocalFileToCreateFolder = [NSString stringWithFormat:@"%@%ld/",[UtilsUrls getOwnCloudFilePath],(long)selectedUser.idUser];
        DLog(@"current: %@", currentLocalFileToCreateFolder);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:currentLocalFileToCreateFolder]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:currentLocalFileToCreateFolder withIntermediateDirectories:NO attributes:nil error:&error];
            DLog(@"Error: %@", [error localizedDescription]);
        }
        app.isNewUser = YES;
    }
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
        
        if (currentManageUploadRequest.userUploading.idUser == selectedUser.idUser) {
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

- (void) cancelAllDownloadsOfActiveUser {
    //Cancel downloads in ipad
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    [appDelegate.downloadManager cancelDownloads];
}

#pragma mark - Check Server version in order to use chunks to upload or not
- (void)checkShareItemsInAppDelegate{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate checkIfServerSupportThings];
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
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
                        [self.mailer setSubject:[subject stringByReplacingOccurrencesOfString:@"$username" withString:_user.username]];
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
        
        NSArray *toRecipients = [NSArray arrayWithObjects:nil];
        [self.mailer setToRecipients:toRecipients];
        
        UIImage *myImage = [UIImage imageNamed:@"CompanyLogo.png"];
        NSData *imageData = UIImagePNGRepresentation(myImage);
        [self.mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"logo"];
        
        if(k_is_custom_recommend_mail) {
            if(k_is_sign_custom_usign_username) {
                [self.mailer setMessageBody:[NSString stringWithFormat:@"%@%@",k_text_recommend_mail,_user.username] isHTML:NO];
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
        [self.mailer setSubject:[NSLocalizedString(@"mail_feedback_subject", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName]];
        
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
    
}


#pragma mark - Instant Upload - Location Support

- (void)switchInstantUploadTo:(BOOL)value {
     [self.switchInstantUpload setOn:value animated:NO];
}

-(void)setPropertiesInstantUploadToState:(BOOL)stateInstantUpload{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (app.activeUser.username == nil) {
        app.activeUser = [ManageUsersDB getActiveUser];
    }
    
    if (stateInstantUpload) {
        [self switchInstantUploadTo:YES];
        app.activeUser.instantUpload = YES;
        [ManageAppSettingsDB updateInstantUploadTo:YES];
    } else {
        [self switchInstantUploadTo:NO];
        app.activeUser.instantUpload = NO;
        [ManageAppSettingsDB updateInstantUploadTo:NO];
        [[ManageLocation sharedSingleton] stopSignificantChangeUpdates];
    }
}

-(void)setDateInstantUpload{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (app.activeUser.username == nil) {
        app.activeUser = [ManageUsersDB getActiveUser];
    }
    
    long dateInstantUpload = [[NSDate date] timeIntervalSince1970];
    app.activeUser.dateInstantUpload = dateInstantUpload;
    [ManageAppSettingsDB updateDateInstantUpload:dateInstantUpload];
}

-(IBAction)changeSwitchInstantUpload:(id)sender {
    
    [self switchInstantUploadTo:NO];

    if(![ManageAppSettingsDB isInstantUpload]) {
       [self checkIfLocationIsEnabled];
    } else {
        //Dissable mode
        [self setPropertiesInstantUploadToState:NO];
    }
}


-(void)checkIfLocationIsEnabled {
    [ManageLocation sharedSingleton].delegate = self;
    
    if ([CLLocationManager locationServicesEnabled]) {
        
        DLog(@"authorizationStatus: %d", [CLLocationManager authorizationStatus]);
        
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
            
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined ) {
                
                DLog(@"Location services not determined");
                [[ManageLocation sharedSingleton] startSignificantChangeUpdates];
                
            } else {
                
                if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                    [ManageAppSettingsDB updateInstantUploadTo:NO];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_not_enabled", nil)
                                                                    message:NSLocalizedString(@"message_location_not_enabled", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"access_photos_and_location_not_enabled", nil)
                                                                    message:NSLocalizedString(@"message_access_photos_and_location_not_enabled", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            }
        } else {
            
            if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                if(![ManageAppSettingsDB isInstantUpload]) {
                    [self setDateInstantUpload];
                }
                
                [self setPropertiesInstantUploadToState:YES];
                [[ManageLocation sharedSingleton] startSignificantChangeUpdates];
                ManageAsset * manageAsset = [[ManageAsset alloc] init];
                NSArray * newItemsToUpload = [manageAsset getCameraRollNewItems];
                if (newItemsToUpload != nil && [newItemsToUpload count] != 0) {
                    [self initPrepareFiles:newItemsToUpload andRemoteFolder:k_path_instant_upload];
                }
            } else {
                [self setPropertiesInstantUploadToState:NO];
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil)
                                                                 message:NSLocalizedString(@"message_access_photos_not_enabled", nil)
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                       otherButtonTitles:nil];
                [alert show];
            }
        }
    } else {
        
        [self setPropertiesInstantUploadToState:NO];
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_not_enabled", nil)
                                                            message:NSLocalizedString(@"message_location_not_enabled", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"access_photos_and_location_not_enabled", nil)
                                                            message:NSLocalizedString(@"message_access_photos_and_location_not_enabled", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}


-(void)initStateInstantUpload{
    
    [self switchInstantUploadTo:NO];
    
    if([ManageAppSettingsDB isInstantUpload]) {
        [self checkIfLocationIsEnabled];
    } else {
        //Dissable mode
        [self setPropertiesInstantUploadToState:NO];
    }
    
}

- (void) initPrepareFiles:(NSArray *) newAsssets andRemoteFolder: (NSString *) remoteFolder{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if(app.prepareFiles == nil) {
        app.prepareFiles = [[PrepareFilesToUpload alloc] init];
        app.prepareFiles.listOfFilesToUpload = [[NSMutableArray alloc] init];
        app.prepareFiles.listOfAssetsToUpload = [[NSMutableArray alloc] init];
        app.prepareFiles.arrayOfRemoteurl = [[NSMutableArray alloc] init];
        app.prepareFiles.listOfUploadOfflineToGenerateSQL = [[NSMutableArray alloc] init];
    }
    app.prepareFiles.delegate = app;
    app.prepareFiles.counterUploadFiles = 0;
    app.uploadTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // If you’re worried about exceeding 10 minutes, handle it here
    }];
    
    [app.prepareFiles addAssetsToUpload: newAsssets andRemoteFolder: remoteFolder];
  
   
}

#pragma mark - ManageLocationDelegate Method

- (void)statusAuthorizationLocationChanged{
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined){
        
        if (![ManageLocation sharedSingleton].firstChangeAuthorizationDone) {
            ALAssetsLibrary *assetLibrary = [UploadUtils defaultAssetsLibrary];
            [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                            
                                        } failureBlock:^(NSError *error) {
                                            
                                        }];
        }
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            
            if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                
                if (![ManageLocation sharedSingleton].firstChangeAuthorizationDone) {
                    //activated only when user allow location first alert
                    [self setPropertiesInstantUploadToState:YES];
                    [self setDateInstantUpload];
                } else {
                    [self setPropertiesInstantUploadToState:NO];
                }
            } else {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"access_photos_library_not_enabled", nil)
                                                                 message:NSLocalizedString(@"message_access_photos_not_enabled", nil)
                                                                delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                       otherButtonTitles:nil];
                [alert show];
            }
        } else if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined){
            if([ManageAppSettingsDB isInstantUpload]) {
                [self setPropertiesInstantUploadToState:NO];
                
                if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_not_enabled", nil)
                                                                    message:NSLocalizedString(@"message_location_not_enabled", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                    
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"access_photos_and_location_not_enabled", nil)
                                                                    message:NSLocalizedString(@"message_access_photos_and_location_not_enabled", nil)
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            }
        }
        
        if (![ManageLocation sharedSingleton].firstChangeAuthorizationDone) {
            [ManageLocation sharedSingleton].firstChangeAuthorizationDone = YES;
        }
    }
    
}


-(void) changedLocation{
    
    NSArray * newItemsToUpload = [[NSArray alloc]init];
    
    if([ManageAppSettingsDB isInstantUpload]) {
        
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
            //check location
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
                //upload new photos
                ManageAsset * manageAsset = [[ManageAsset alloc] init];
                newItemsToUpload = [manageAsset getCameraRollNewItems];
                if (newItemsToUpload != nil && [newItemsToUpload count] != 0) {
                    [self initPrepareFiles:newItemsToUpload andRemoteFolder:k_path_instant_upload];
                }
            }
        } else {
            [self setPropertiesInstantUploadToState:NO];
        }
    }
}

@end






