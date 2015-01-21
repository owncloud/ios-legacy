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
#import "AccountsViewController.h"
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
#import "ManageInstantUpload.h"



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

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isMailComposeVisible = NO;
       
        //Set the instant upload
        [self initStateInstantUpload];
    
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
   // DLog(@"Hello in settings view");
    
    self.title=NSLocalizedString(@"settings", nil);
    
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
   [_switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:NO];
    
    _user = app.activeUser;

}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}


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
    _vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
    _vc.delegate = self;
    
    //Create the navigation bar of portrait
    OCPortraitNavigationViewController *oc = [[OCPortraitNavigationViewController alloc]initWithRootViewController:_vc];

    //Indicate the pass code view mode
    if(![ManageAppSettingsDB isPasscode]) {
        //Set mode
        _vc.mode = KKPasscodeModeSet;
    } else {
        //Dissable mode
        _vc.mode = KKPasscodeModeDisabled;
    }
    
    if (IS_IPHONE) {
        //is iphone
        [self presentViewController:oc animated:YES completion:nil];
    } else {
        //is ipad
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        oc.modalPresentationStyle = UIModalPresentationFormSheet;
        
        if (IS_IOS8) {
            [app.detailViewController.popoverController dismissPopoverAnimated:YES];
        }
        
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
    
    //AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //NSString *path= [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:userFolder];
    NSString *path= [[UtilsUrls getOwnCloudFilePath] stringByAppendingPathComponent:userFolder];
    
    NSError *error;     
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];    
   
    //[appDelegate dismissPopover];
    
   // AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //app.downloadsArray=[[NSMutableArray alloc]init];
    [app.downloadManager cancelDownloads];
    app.uploadArray=[[NSMutableArray alloc]init];
    [app updateRecents];
    [app restartAppAfterDeleteAllAccounts];
   
}

-(void)goToAccounts {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    
    AccountsViewController *viewController = [[AccountsViewController alloc]initWithNibName:@"AccountsViewController_iPhone" bundle:nil];

    [self.navigationController pushViewController:viewController animated:YES];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPHONE) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - UITableView datasource

// Asks the data source to return the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

// Returns the table view managed by the controller object.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger n = 0;
    
    
    if (section == 0) {
        n = 1;
    } else if (section == 1){
        n = 1;
    } else if (section == 2){
        n = 1;
    } else if (section == 3){
        if (k_show_recommend_option_on_settings && k_show_imprint_option_on_settings && k_show_help_option_on_settings) {
            n = 4;
        } else if (!k_show_recommend_option_on_settings && !k_show_imprint_option_on_settings && !k_show_help_option_on_settings)  {
            n = 1;
        } else if ((!k_show_recommend_option_on_settings && k_show_imprint_option_on_settings && k_show_help_option_on_settings) || (k_show_recommend_option_on_settings && !k_show_imprint_option_on_settings && k_show_help_option_on_settings) || (k_show_recommend_option_on_settings && k_show_imprint_option_on_settings && !k_show_help_option_on_settings)) {
            n = 3;
        } else {
            n = 2;
        }
    }
    
    return n;
}


// Returns the table view managed by the controller object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SettingsCell";
    
    UITableViewCell *cell;
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    
    if (indexPath.section==0) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [self getSectionManageAccountBlock:cell byRow:indexPath.row];
    } else if (indexPath.section==1) {
        [self getSectionAppPinBlock:cell byRow:indexPath.row];
    } else if (indexPath.section==2) {
        [self getSectionAppInstantUpload:cell byRow:indexPath.row];
    } else if (indexPath.section==3) {
        [self getSectionInfoBlock:cell byRow:indexPath.row];
    }
    
    return cell;
}


-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    //Set the text of the footer section
    UILabel *label = [[UILabel alloc] init];
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:13];
    
    int sectionToShowFooter = 3;

    if (section == sectionToShowFooter) {
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        label.text = [NSString stringWithFormat:@"%@ %d    iOS %@", appName, k_year, appVersion];
        label.font = appFont; //[UIFont systemFontOfSize:13.0];
        label.textColor = [UIColor grayColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
    } else {
        label.backgroundColor = [UIColor clearColor];
        label.text = @"";
    }
    return label;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 20;
}


#pragma mark - Sections of TableView

-(UITableViewCell *) getSectionInfoBlock:(UITableViewCell *) cell byRow:(NSInteger) row {
    switch (row) {
        case 0:
            if (k_show_help_option_on_settings) {
                [self setTitleOfRow:help inCell:cell];
            } else if (k_show_recommend_option_on_settings && !k_show_help_option_on_settings) {
                [self setTitleOfRow:recommend inCell:cell];
            } else {
                [self setTitleOfRow:feedback inCell:cell];
            }
            break;
        case 1:
            if ((!k_show_imprint_option_on_settings || k_show_imprint_option_on_settings) && k_show_recommend_option_on_settings && k_show_help_option_on_settings) {
                [self setTitleOfRow:recommend inCell:cell];
            } else if (!k_show_help_option_on_settings && !k_show_recommend_option_on_settings) {
                [self setTitleOfRow:impress inCell:cell];
            } else {
                [self setTitleOfRow:feedback inCell:cell];
            }
            break;
        case 2:
            if ((!k_show_imprint_option_on_settings || k_show_imprint_option_on_settings) && k_show_recommend_option_on_settings && k_show_help_option_on_settings) {
                [self setTitleOfRow:feedback inCell:cell];
            } else {
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
    
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    cell.textLabel.font = appFont;
    
    switch (row) {
        case help:
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
            cell.textLabel.text=NSLocalizedString(@"help", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case recommend:
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
            cell.textLabel.text=NSLocalizedString(@"recommend_to_friend", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case feedback:
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
            cell.textLabel.text=NSLocalizedString(@"send_feedback", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case impress:
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
            cell.textLabel.text=NSLocalizedString(@"imprint_button", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            break;
        default:
            break;
    }
}


-(UITableViewCell *) getSectionStorageBlock:(UITableViewCell *) cell byRow:(int) row {
    
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
    
    switch (row) {
        case 0:
            
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
            cell.textLabel.text=NSLocalizedString(@"Storage", nil);
            
            NSInteger percent = 0;
            if(_user.storage > 0) {
                percent = (_user.storageOccupied * 100)/_user.storage;
            }
                        
            cell.detailTextLabel.text=[NSString stringWithFormat:@"%ld%% %@ %ldMB %@", (long)percent, NSLocalizedString(@"of_storage", nil), _user.storage, NSLocalizedString(@"occupied_storage", nil)];
            
            
            //[cell.detailTextLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:15.0]];
            [cell.detailTextLabel setFont:appFont];
            [cell.detailTextLabel setTextColor:[UIColor colorOfDetailTextSettings]];
            
            break;
        case 1:
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
            cell.textLabel.text=NSLocalizedString(@"storage_upgrade", nil);
            [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            
            break;
            
        default:
            break;
    }
    
    return cell;
}

-(UITableViewCell *) getSectionAppPinBlock:(UITableViewCell *) cell byRow:(NSInteger) row {
    UIFont *itemFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    cell.textLabel.font = itemFont;
    
    switch (row) {
        case 0:
            cell.textLabel.text=NSLocalizedString(@"title_app_pin", nil);
            _switchPasscode = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = _switchPasscode;
            [_switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:YES];
            [_switchPasscode addTarget:self action:@selector(changeSwitchPasscode:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            break;
        default:
            break;
    }
    
    return cell;
}

-(UITableViewCell *) getSectionAppInstantUpload:(UITableViewCell *) cell byRow:(NSInteger) row {
    UIFont *itemFont = [UIFont fontWithName:@"HelveticaNeue" size:17];
    cell.textLabel.font = itemFont;
    
    switch (row) {
        case 0:
            cell.textLabel.text=NSLocalizedString(@"title_instant_upload", nil);
            _switchInstantUpload = [[UISwitch alloc] initWithFrame:CGRectZero];
            cell.accessoryView = _switchInstantUpload;
            [_switchInstantUpload setOn:[ManageAppSettingsDB isInstantUpload] animated:YES];
            [_switchInstantUpload addTarget:self action:@selector(changeSwitchInstantUpload:) forControlEvents:UIControlEventValueChanged];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            break;
        default:
            break;
    }
    
    return cell;
}

-(UITableViewCell *) getSectionManageAccountBlock:(UITableViewCell *) cell byRow:(NSInteger) row {
    
   // UIFont *cellBoldFont = [UIFont boldSystemFontOfSize:16.0];
    UIFont *cellBoldFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
    
    switch (row) {
        case 0:
            cell.selectionStyle=UITableViewCellSelectionStyleBlue;
            cell.textLabel.font=cellBoldFont;
            cell.textLabel.textAlignment=NSTextAlignmentCenter;
            if (k_multiaccount_available) {
                cell.textLabel.text=NSLocalizedString(@"manage_accounts", nil);
            } else {
                cell.textLabel.text=NSLocalizedString(@"disconnect_button", nil);
            }
            
            [cell setBackgroundColor:[UIColor colorOfBackgroundButtonOnList]];
            cell.textLabel.textColor = [UIColor colorOfTextButtonOnList];
            
            break;
        default:
            break;
    }
    return cell;
}


#pragma mark - UITableView delegate

-(void)toDelete {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    [appDelegate.downloadManager cancelDownloads];
    appDelegate.uploadArray=[[NSMutableArray alloc]init];
    [appDelegate updateRecents];
    [appDelegate restartAppAfterDeleteAllAccounts];
}

// Tells the delegate that the specified row is now selected.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section==0) {
        [self didPressOnManageAccountsBlock:indexPath.row];
    } else if (indexPath.section==3) {
        [self didPressOnInfoBlock:indexPath.row];
    }
}

#pragma mark - DidSelectRow Sections


-(void) didPressOnInfoBlock:(NSInteger) row {

    switch (row) {
        case 0:
            if (k_show_help_option_on_settings) {
                [self setContentOfRow:help];
            } else if (k_show_recommend_option_on_settings && !k_show_help_option_on_settings) {
                [self setContentOfRow:recommend];
            } else {
                [self setContentOfRow:feedback];
            }
            break;
        case 1:
            if ((!k_show_imprint_option_on_settings || k_show_imprint_option_on_settings) && k_show_recommend_option_on_settings && k_show_help_option_on_settings) {
                [self setContentOfRow:recommend];
            } else if (!k_show_help_option_on_settings && !k_show_recommend_option_on_settings) {
                [self setContentOfRow:impress];
            } else {
                [self setContentOfRow:feedback];
            }
            break;
        case 2:
            if ((!k_show_imprint_option_on_settings || k_show_imprint_option_on_settings) && k_show_recommend_option_on_settings && k_show_help_option_on_settings) {
                [self setContentOfRow:feedback];
            } else {
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
                WebViewController *webView=[[WebViewController alloc]initWithNibName:@"WebViewController" bundle:nil];
                
                webView.urlString = k_help_url;
                webView.navigationTitleString = NSLocalizedString(@"help", nil);
                
                [self.navigationController pushViewController:webView animated:YES];

            } else {
                DLog(@"2.2-Press Help");
                if(!_detailViewController) {
                    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                    _detailViewController = app.detailViewController;
                }
                [_detailViewController openLink:k_help_url];
                _detailViewController.linkTitle=NSLocalizedString(@"help", nil);
            }
            break;
            
        case recommend:
        {
            DLog(@"");
            
            if (IS_IPHONE &&
                (!IS_PORTRAIT)) {
                
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
                    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                    if (IS_IOS8) {
                        [app.detailViewController.popoverController dismissPopoverAnimated:YES];
                        
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

-(void) didPressOnManageAccountsBlock:(NSInteger) row {
    switch (row) {
        case 0:
            if(k_multiaccount_available) {
                [self goToAccounts];
            } else {
                [self disconnectUser];
            }
            break;
        default:
            break;
    }
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
            [app.detailViewController.popoverController dismissPopoverAnimated:YES];
            
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
            [app.detailViewController.popoverController dismissPopoverAnimated:YES];
            
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
            [app.detailViewController.popoverController dismissPopoverAnimated:YES];
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
            [app.detailViewController.popoverController dismissPopoverAnimated:YES];
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

/*- (void)didPasscodeEnteredCorrectly:(KKPasscodeViewController*)viewController{
    
    DLog(@"didPasscodeEnteredCorrectly");
    
}
- (void)didPasscodeEnteredIncorrectly:(KKPasscodeViewController*)viewController{
    
    DLog(@"didPasscodeEnteredIncorrectly");
    
}

- (void)shouldLockApplication:(KKPasscodeViewController*)viewController{
    
    DLog(@"shouldLockApplication");
    
}
- (void)shouldEraseApplicationData:(KKPasscodeViewController*)viewController{
    
    DLog(@"shouldEraseApplicationData");
    
}*/

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
    [_switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:NO];

}

///-----------------------------------
/// @name Cancel Pass Code View
///-----------------------------------

/**
 * Called when the user tap the cancel button in a pass code view
 *
*/
- (void)didCancelPassCodeTapped{
    
    //DLog(@"didCancelPassCodeTapped");
    //Refresh the switch pass code
    [_switchPasscode setOn:[ManageAppSettingsDB isPasscode] animated:NO];
    
}


#pragma mark - Instant Upload, Location

- (void)switchInstantUploadTo:(BOOL)value {
     [_switchInstantUpload setOn:value animated:NO];
}

-(IBAction)changeSwitchInstantUpload:(id)sender {
    
    //k_path_instant_upload
    
    
    [self switchInstantUploadTo:NO];

    if(![ManageAppSettingsDB isInstantUpload]) {
       [self checkIfLocationIsEnabled];
    } else {
        //Dissable mode
        [ManageAppSettingsDB updateInstantUpload:NO];
        [[ManageLocation sharedSingleton] stopSignificantChangeUpdates];
    }
}


-(void)checkIfLocationIsEnabled {
    [ManageLocation sharedSingleton].delegate = self;


    if ([CLLocationManager locationServicesEnabled]) {
        
        DLog(@"authorizationStatus: %d", [CLLocationManager authorizationStatus]);
        
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
            
           // if (!([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)) {
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined ) {
                
                DLog(@"Location services not determined");
                [[ManageLocation sharedSingleton] startSignificantChangeUpdates];
                
            }else {
                [ManageAppSettingsDB updateInstantUpload:NO];
                [[ManageLocation sharedSingleton] stopSignificantChangeUpdates];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_not_enabled", nil)
                                                            message:NSLocalizedString(@"message_location_not_enabled", nil)
                                                            delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                [alert show];
            }
        } else {
            if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                [self switchInstantUploadTo:YES];
                [[ManageLocation sharedSingleton] startSignificantChangeUpdates];
                [ManageAppSettingsDB updateInstantUpload:YES];
                [ManageAppSettingsDB updateDateInstantUpload:[[NSDate date] timeIntervalSince1970]];
                ManageAsset * manageAsset = [[ManageAsset alloc] init];
                NSArray * newItemsToUpload = [manageAsset getCameraRollNewItems];
                [self initPrepareFiles:newItemsToUpload andRemoteFolder:k_path_instant_upload];
            } else {
                [ManageAppSettingsDB updateInstantUpload:NO];
                [[ManageLocation sharedSingleton] stopSignificantChangeUpdates];
                NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                                 message:[NSLocalizedString(@"no_access_to_gallery", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName]
                                                                delegate:nil
                                                       cancelButtonTitle:@"Ok"
                                                       otherButtonTitles:nil];
                [alert show];
            }
        }
    } else {
        [ManageAppSettingsDB updateInstantUpload:NO];
        [[ManageLocation sharedSingleton] stopSignificantChangeUpdates];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_not_enabled", nil)
                                                        message:NSLocalizedString(@"message_location_not_enabled", nil)
                                                        delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
        [alert show];
    }
}


-(void)initStateInstantUpload{
    
    [self switchInstantUploadTo:NO];
    
    if([ManageAppSettingsDB isInstantUpload]) {
        [self checkIfLocationIsEnabled];
        
    } else {
        //Dissable mode
        [ManageAppSettingsDB updateInstantUpload:NO];
        [[ManageLocation sharedSingleton] stopSignificantChangeUpdates];
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
   // if ([CLLocationManager locationServicesEnabled]) {

      if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined){
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            //activated only when user allow location first alert
            if (![ManageLocation sharedSingleton].firstChangeAuthorizationDone) {
                if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
                    [self switchInstantUploadTo:YES];
                    [ManageAppSettingsDB updateInstantUpload:YES];
                    [ManageAppSettingsDB updateDateInstantUpload:[[NSDate date] timeIntervalSince1970]];
                } else {
                    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil
                                                                     message:[NSLocalizedString(@"no_access_to_gallery", nil) stringByReplacingOccurrencesOfString:@"$appname" withString:appName]
                                                                    delegate:nil
                                                           cancelButtonTitle:@"Ok"
                                                           otherButtonTitles:nil];
                    [alert show];
                }
                                     
            }            
            
        } else if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusNotDetermined){
            if([ManageAppSettingsDB isInstantUpload]) {
                [ManageAppSettingsDB updateInstantUpload:NO];
                [self switchInstantUploadTo:NO];
                [[ManageLocation sharedSingleton] stopSignificantChangeUpdates];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_not_enabled", nil)
                                                      message:NSLocalizedString(@"message_location_not_enabled", nil)
                                                      delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
        
    
        if (![ManageLocation sharedSingleton].firstChangeAuthorizationDone) {
            [ManageLocation sharedSingleton].firstChangeAuthorizationDone = YES;
        }
     }

 //   } else {
 //       if([ManageAppSettingsDB isInstantUpload]) {
 //         [ManageAppSettingsDB updateInstantUpload:NO];
 //           [self switchInstantUploadTo:NO];
 //           [[ManageLocation sharedSingleton] stopSignificantChangeUpdates];
 //       }
 //   }
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
            if (newItemsToUpload != nil) {
                [self initPrepareFiles:newItemsToUpload andRemoteFolder:k_path_instant_upload];
            }
            
        }
    } else {
        [ManageAppSettingsDB updateInstantUpload:NO];
    }
}

}

@end






