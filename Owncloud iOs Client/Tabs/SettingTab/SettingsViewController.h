//
//  SettingsViewController.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/11/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "DetailViewController.h"
#import <Social/Social.h>
#import <Twitter/Twitter.h>
#import <MessageUI/MessageUI.h>
#import "UserDto.h"
#import "KKPasscodeViewController.h"
#import "AccountCell.h"
#import "AddAccountViewController.h"
#import "MBProgressHUD.h"
#import "SyncFolderManager.h"


typedef enum {
    help = 0,
    recommend = 1,
    feedback = 2,
    impress = 3,
    
} enumInfoSetting;

@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, KKPasscodeViewControllerDelegate, AccountCellDelegate, AddAccountDelegate, MBProgressHUDDelegate, SyncFolderManagerDelegate>

@property(nonatomic,strong)IBOutlet UITableView *settingsTableView;
@property(nonatomic,strong)UISwitch *switchPasscode;
@property(nonatomic,strong)UISwitch *switchTouchID;
@property(nonatomic,strong)UISwitch *switchInstantUploadPhotos;
@property(nonatomic,strong)UISwitch *switchInstantUploadVideos;
@property(nonatomic,strong)UISwitch *switchBackgroundInstantUpload;
@property(nonatomic, strong)DetailViewController *detailViewController;
@property(nonatomic, strong)UserDto *user;

//App pin
@property (nonatomic,strong) KKPasscodeViewController* vc;

//Social
@property (nonatomic,strong) UIActionSheet *popupQuery;
@property (nonatomic,strong) SLComposeViewController *twitter;
@property (nonatomic,strong) SLComposeViewController *facebook;
@property (nonatomic,strong) MFMailComposeViewController *mailer;
@property (nonatomic) BOOL isMailComposeVisible;

//View for loading screen
@property(nonatomic, strong) MBProgressHUD  *HUD;
@property(nonatomic, strong) dispatch_semaphore_t semaphoreChangeUser;

@property (nonatomic,strong) UIActionSheet *menuAccountActionSheet;
@property (nonatomic,strong) UserDto *selectedUserAccount;

- (IBAction)changeSwitchPasscode:(id)sender;
- (IBAction)changeSwitchTouchID:(id)sender;
- (void)disconnectUser;
@end
