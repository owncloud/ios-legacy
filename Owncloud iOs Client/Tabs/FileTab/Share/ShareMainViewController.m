//
//  ShareMainViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/8/15.
//  Edited by Noelia Alvarez
//

/*
 Copyright (C) 2017, ownCloud GmbH.
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
#import "ShareLinkViewController.h"

//tools
#define animationsDelay 0.5
#define largeDelay 1.0

//Xib
#define shareMainViewNibName @"ShareViewController"

//Cells and Sections
#define shareFileCellIdentifier @"ShareFileIdentifier"
#define shareFileCellNib @"ShareFileCell"

#define shareLinkHeaderIdentifier @"ShareLinkHeaderIdentifier"
#define shareLinkHeaderNib @"ShareLinkHeaderCell"

#define shareUserCellIdentifier @"ShareUserCellIdentifier"
#define shareUserCellNib @"ShareUserCell"

#define shareMainLinkCellIdentifier @"ShareMainLinkCellIdentifier"
#define shareMainLinkCellNib @"ShareMainLinkCell"

#define shareWarningLinkCellIdentifier @"ShareWarningLinkCellIdentifier"
#define shareWarningLinkCellNib @"ShareWarningLinkCell"

#define heighOfFileDetailrow 120.0

#define heightOfShareMainLinkRow 55.0
#define heightOfShareWithUserRow 55.0

#define heightOfShareLinkHeader 45.0

#define shareTableViewSectionsNumber  3


@interface ShareMainViewController ()

@property (nonatomic, strong) FileDto* sharedItem;
@property (nonatomic, strong) ShareFileOrFolder* sharedFileOrFolder;
@property (nonatomic, strong) MBProgressHUD* loadingView;
@property (nonatomic, strong) UIActivityViewController *activityView;
@property (nonatomic, strong) EditAccountViewController *resolveCredentialErrorViewController;
@property (nonatomic, strong) UIPopoverController* activityPopoverController;
@property (nonatomic, strong) NSMutableArray *sharedUsersOrGroups;
@property (nonatomic, strong) NSMutableArray *sharedPublicLinks;
@property (nonatomic, strong) NSMutableArray *sharesOfFile;

@end


@implementation ShareMainViewController


- (id) initWithFileDto:(FileDto *)fileDto {
    
    if ((self = [super initWithNibName:shareMainViewNibName bundle:nil]))
    {
        self.sharedItem = fileDto;
        self.sharedUsersOrGroups = [NSMutableArray new];
        self.sharedPublicLinks = [NSMutableArray new];
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
    [self updateSharesOfFileFromDB];
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
    
    [self.shareTableView reloadData];
}

- (void) updateSharesOfFileFromDB {
    
    NSString *path = [NSString stringWithFormat:@"/%@%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.sharedItem.filePath andUser:APP_DELEGATE.activeUser], self.sharedItem.fileName];
    
    [self.sharedUsersOrGroups removeAllObjects];
    [self.sharesOfFile removeAllObjects];
    [self.sharedPublicLinks removeAllObjects];
    
    self.sharesOfFile = [ManageSharesDB getSharesByUser:APP_DELEGATE.activeUser.idUser andPath:path];
    
    DLog(@"Number of Shares of file: %lu", (unsigned long)self.sharesOfFile.count);
    
    for (OCSharedDto *shareItem in self.sharesOfFile) {
        
        if (shareItem.shareType == shareTypeUser || shareItem.shareType == shareTypeGroup || shareItem.shareType == shareTypeRemote) {
            
            
            OCShareUser *shareUser = [OCShareUser new];
            shareUser.name = shareItem.shareWith;
            shareUser.displayName = shareItem.shareWithDisplayName;
            shareUser.sharedDto = shareItem;
            shareUser.shareeType = shareItem.shareType;
            
            [self.sharedUsersOrGroups addObject:shareUser];
            
        } else if(shareItem.shareType == shareTypeLink){
            
            [self.sharedPublicLinks addObject:shareItem];
        }
    }
    
    self.sharedUsersOrGroups = [ShareUtils manageTheDuplicatedUsers:self.sharedUsersOrGroups];
}



#pragma mark - Actions with ShareFileOrFolder class

- (void) unShareByIdRemoteShared:(NSInteger) idRemoteShared{
    
    if (self.sharedFileOrFolder == nil) {
        self.sharedFileOrFolder = [ShareFileOrFolder new];
        self.sharedFileOrFolder.delegate = self;
    }
    
    self.sharedFileOrFolder.parentViewController = self;
    
    [self.sharedFileOrFolder unshareTheFileByIdRemoteShared:idRemoteShared];
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


#pragma mark - TableView delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    NSInteger numberOfSections = shareTableViewSectionsNumber;
    
    if (!k_is_share_with_users_available) {
        numberOfSections--;
    }
    
    if (!k_is_share_by_link_available || !(APP_DELEGATE.activeUser.hasCapabilitiesSupport && APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingShareLinkEnabled)) {
        numberOfSections--;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger nOfRows = 0;
    
    if (section == 0) {
        nOfRows = 1;
    }else if (section == 1 && k_is_share_with_users_available){
        if (self.sharedUsersOrGroups.count == 0) {
           nOfRows = 1;
            
        }else{
           nOfRows = self.sharedUsersOrGroups.count;
        }
    } else if ((section == 1 || section == 2) && k_is_share_by_link_available){
        
        if (self.sharedPublicLinks.count == 0) {
            nOfRows = 1;
        }else{
            nOfRows = self.sharedPublicLinks.count;
        }
        
        if (k_warning_sharing_public_link) {
            nOfRows = nOfRows + 1;
        }
    }
    
    return nOfRows;
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
                
                cell = [self getCellOfUserOrGroupNameSharedByTableView:tableView andIndexPath:indexPath];
              
            } else if (k_is_share_by_link_available) {
               
                cell = [self getCellShareLinkByTableView:tableView andIndexPath:indexPath];
            }
            break;
            
        case 2:
            cell = [self getCellShareLinkByTableView:tableView andIndexPath:indexPath];

            break;
        default:
            break;
    }
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = 0.0;
    
    switch (indexPath.section) {
        case 0:
            height = heighOfFileDetailrow;
            break;
        case 1:
            if (k_is_share_with_users_available) {
                
                height = heightOfShareWithUserRow;
                
            } else {
                
                height = heightOfShareMainLinkRow;
            }
            break;
        case 2:
            height = heightOfShareMainLinkRow;
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (indexPath.section) {
        case 0:
            return NO;
            break;
        case 1:
            if (k_is_share_with_users_available && self.sharedUsersOrGroups.count > 0) {
                return YES;
            } else if (k_is_share_by_link_available && self.sharedPublicLinks.count > 0){
                return YES;
            } else {
                return NO;
            }
            break;
        case 2:
            if (k_is_share_by_link_available && self.sharedPublicLinks.count > 0) {
                if (indexPath.row == 0 && k_warning_sharing_public_link) {
                    return NO;
                } else {
                    return YES;
                }
            } else {
                return NO;
            }
            break;
        default:
            return NO;
            break;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        if (k_is_share_with_users_available && indexPath.section == 1) {
            
            OCShareUser *sharedUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
            [self unShareByIdRemoteShared: sharedUser.sharedDto.idRemoteShared];
            [self.sharedUsersOrGroups removeObjectAtIndex:indexPath.row];
            [self reloadView];
            
        } else {
            
            NSInteger indexLink = indexPath.row;
            if (k_warning_sharing_public_link) {
                indexLink = indexLink -1 ;
            }
            
            [self confirmRemoveShareLink:indexLink];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
    if (k_is_share_with_users_available && indexPath.section == 1) {
        //Edit share with user Privileges
        
        OCShareUser *shareUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
        OCSharedDto *sharedDto = shareUser.sharedDto;
        
        [self presentViewEditSharedUser:sharedDto ofFile:self.sharedItem];
        
    } else if (k_is_share_by_link_available) {
        //Edit share link options
        
        NSInteger indexShareLink = indexShareLink = indexPath.row;
        if (k_warning_sharing_public_link) {
            indexShareLink = indexPath.row-1;
        }
        OCSharedDto *sharedDto = [self.sharedPublicLinks objectAtIndex:indexShareLink];
        
        [self presentViewLinkOptionsOfSharedLink:sharedDto ofFile:self.sharedItem withLinkOptionsViewMode:LinkOptionsViewModeEdit];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ((!k_is_share_with_users_available && k_is_share_by_link_available && indexPath.section == 1 )|| indexPath.section == 2 ) {
        
        if (!k_warning_sharing_public_link || (k_warning_sharing_public_link && indexPath.row != 0 && [self.sharedPublicLinks count] > 0) ) {
            
            NSInteger indexShareLink = indexPath.row;
            if (k_warning_sharing_public_link) {
                indexShareLink = indexPath.row-1;
            }
            
            NSURL *urlShareLink = [ShareUtils getNormalizedURLOfShareLink:self.sharedPublicLinks[indexShareLink]];
            
            UIButton *cellGetPublicLinkButton = [self.shareTableView viewWithTag:indexPath.row];

            [self presentActivityViewForShareLink:urlShareLink inView:cellGetPublicLinkButton fromRect:cellGetPublicLinkButton.bounds];
        }
    }
}


#pragma mark - Cells

- (ShareLinkHeaderCell *) getHeaderCellForShareWithUsersOrGroups:(ShareLinkHeaderCell *) shareLinkHeaderCell {
    
    shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_with_users_or_groups", nil);
    shareLinkHeaderCell.switchSection.hidden = YES;
    shareLinkHeaderCell.addButtonSection.hidden = NO;
    
    [shareLinkHeaderCell.addButtonSection addTarget:self action:@selector(didSelectAddUserOrGroup) forControlEvents:UIControlEventTouchUpInside];
    
    return shareLinkHeaderCell;
}

- (ShareLinkHeaderCell *) getHeaderCellForShareByLink:(ShareLinkHeaderCell *) shareLinkHeaderCell {
    
    shareLinkHeaderCell.titleSection.text = NSLocalizedString(@"share_link_title", nil);
    shareLinkHeaderCell.switchSection.hidden = YES;
    
    if ([self.sharedPublicLinks count] > 0 && ![ShareUtils hasMultipleShareLinkAvailable]) {
        shareLinkHeaderCell.addButtonSection.hidden = YES;
    } else {
        shareLinkHeaderCell.addButtonSection.hidden = NO;
        [shareLinkHeaderCell.addButtonSection addTarget:self action:@selector(didSelectAddPublicLink) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return shareLinkHeaderCell;
}

- (UITableViewCell *) getCellOfFileOrFolderInformationByTableView:(UITableView *) tableView {
    
    ShareFileCell* shareFileCell = (ShareFileCell*)[tableView dequeueReusableCellWithIdentifier:shareFileCellIdentifier];
    
    if (shareFileCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareFileCellNib owner:self options:nil];
        shareFileCell = (ShareFileCell *)[topLevelObjects objectAtIndex:0];
    }
    
    NSString *itemName = [self.sharedItem.fileName stringByRemovingPercentEncoding];
    
    shareFileCell.fileName.hidden = self.sharedItem.isDirectory;
    shareFileCell.fileSize.hidden = self.sharedItem.isDirectory;
    shareFileCell.folderName.hidden = !self.sharedItem.isDirectory;
    
    //Add long press event
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressPrivateLinkButton:)];
   // longPress.minimumPressDuration = 3; //seconds
    longPress.delegate = self;
    [shareFileCell.privateLinkButton addGestureRecognizer:longPress];
    
    //Add tap event
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapPrivateLinkButton)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [shareFileCell.privateLinkButton addGestureRecognizer:tapGesture];
    
    shareFileCell.privateLinkButton.tag = -1;

    
    if (self.sharedItem.isDirectory) {
        shareFileCell.fileImage.image = [UIImage imageNamed:@"folder_icon"];
        shareFileCell.folderName.text = @"";
        //Remove the last character (folderName/ -> folderName)
        shareFileCell.folderName.text = [itemName substringToIndex:[itemName length]-1];
        
    }else{
        shareFileCell.fileImage.image = [UIImage imageNamed:[FileNameUtils getTheNameOfTheImagePreviewOfFileName:[self.sharedItem.fileName stringByRemovingPercentEncoding]]];
        shareFileCell.fileSize.text = [NSByteCountFormatter stringFromByteCount:[NSNumber numberWithLong:self.sharedItem.size].longLongValue countStyle:NSByteCountFormatterCountStyleMemory];
        shareFileCell.fileName.text = itemName;
    }
    
    return shareFileCell;
    
}


- (UITableViewCell *) getCellOfUserOrGroupNameSharedByTableView:(UITableView *) tableView andIndexPath:(NSIndexPath *) indexPath {
    
    ShareUserCell* shareUserCell = (ShareUserCell*)[tableView dequeueReusableCellWithIdentifier:shareUserCellIdentifier];
    
    if (shareUserCell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
        shareUserCell = (ShareUserCell *)[topLevelObjects objectAtIndex:0];
    }
    
    NSString *name;
    
    if (self.sharedUsersOrGroups.count == 0) {
        
        name = NSLocalizedString(@"not_share_with_users_yet", nil);
        
        shareUserCell.itemName.textColor = [UIColor grayColor];
        
    } else {
        
        OCShareUser *shareUser = [self.sharedUsersOrGroups objectAtIndex:indexPath.row];
        
        name = [ShareUtils getDisplayNameForSharee:shareUser];
        
        shareUserCell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    
    shareUserCell.itemName.text = name;
    shareUserCell.selectionStyle = UITableViewCellEditingStyleNone;
    
    return shareUserCell;
}


- (UITableViewCell *) getCellShareLinkByTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath {
    
    if (k_warning_sharing_public_link && indexPath.row == 0) {
        
        ShareWarningLinkCell* shareWarningLinkCell = (ShareWarningLinkCell*)[tableView dequeueReusableCellWithIdentifier:shareWarningLinkCellIdentifier];
        
        if (shareWarningLinkCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareWarningLinkCellNib owner:self options:nil];
            shareWarningLinkCell = (ShareWarningLinkCell *)[topLevelObjects objectAtIndex:0];
        }
        
        shareWarningLinkCell.labelName.text =  NSLocalizedString(@"warning_sharing_public_link", nil);
        shareWarningLinkCell.labelName.textColor = [UIColor grayColor];
        shareWarningLinkCell.backgroundColor = [UIColor colorOfBackgroundWarningSharingPublicLink];
        shareWarningLinkCell.selectionStyle = UITableViewCellEditingStyleNone;
        
        return shareWarningLinkCell;
        
    } else {
        
        ShareMainLinkCell* shareLinkCell = (ShareMainLinkCell*)[tableView dequeueReusableCellWithIdentifier:shareMainLinkCellIdentifier];
        
        if (shareLinkCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareMainLinkCellNib owner:self options:nil];
            shareLinkCell = (ShareMainLinkCell *)[topLevelObjects objectAtIndex:0];
        }
        
        if (self.sharedPublicLinks.count == 0) {
            
            shareLinkCell.itemName.text = NSLocalizedString(@"not_share_by_link_yet", nil);
            shareLinkCell.itemName.textColor = [UIColor grayColor];
            shareLinkCell.buttonGetLink.hidden = YES;
            
        } else {
            
            NSInteger indexLink = indexPath.row;

            if (k_warning_sharing_public_link) {
                indexLink = indexLink -1 ;
            }
            
            OCSharedDto *shareLink = [self.sharedPublicLinks objectAtIndex:indexLink];
            
            shareLinkCell.itemName.text = ([shareLink.name length] == 0 || [shareLink.name isEqualToString:@"(null)"] ) ? shareLink.token: shareLink.name;
            shareLinkCell.accessoryType = UITableViewCellAccessoryDetailButton;
            shareLinkCell.buttonGetLink.tag = indexPath.row;
        }
        
        shareLinkCell.selectionStyle = UITableViewCellEditingStyleNone;
        
        return shareLinkCell;
    }
}


#pragma mark - did select actions

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

- (void) didSelectAddPublicLink {
    [self presentViewLinkOptionsOfSharedLink:nil ofFile:self.sharedItem withLinkOptionsViewMode:LinkOptionsViewModeCreate];
}

- (void) didTapPrivateLinkButton {
    
    UIButton *cellPrivateLinkButton = [self.shareTableView viewWithTag:-1];

    [self presentActivityViewForShareLink: [NSURL URLWithString:[ShareUtils getPrivateLinkOfFile:self.sharedItem]] inView:cellPrivateLinkButton fromRect:cellPrivateLinkButton.bounds];
}

- (void) didLongPressPrivateLinkButton:(UILongPressGestureRecognizer*)gesture {
    
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        
        [self showWarningMessageWithText:NSLocalizedString(@"message_private_link", nil)];
    }
    
}

- (void) didSelectCloseView {
    
    [self dismissViewControllerAnimated:true completion:nil];
}


#pragma mark - TSMessages

- (void)showWarningMessageWithText: (NSString *) message {
    
    //Run UI Updates
    [TSMessage setDelegate:self];
    [TSMessage showNotificationInViewController:self title:message subtitle:nil type:TSMessageNotificationTypeWarning];
    
}


#pragma mark - present views

-(void) presentViewEditSharedUser:(OCSharedDto  *)sharedDto ofFile:(FileDto *)fileShared {
    
    ShareEditUserViewController *viewController = [[ShareEditUserViewController alloc] initWithFileDto:fileShared andOCSharedDto:sharedDto];
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

-(void) presentViewLinkOptionsOfSharedLink:(OCSharedDto *)sharedDto ofFile:(FileDto *)fileShared withLinkOptionsViewMode:(LinkOptionsViewMode)viewMode{
    
    NSString *defaultLinkName = [ShareUtils getDefaultLinkNameNormalizedOfFile:fileShared withLinkShares:self.sharedPublicLinks];
    
    ShareLinkViewController *viewController = [[ShareLinkViewController alloc] initWithFileDto:fileShared andOCSharedDto:sharedDto andDefaultLinkName:defaultLinkName andLinkOptionsViewMode:viewMode];
    viewController.sharedFileOrFolder = self.sharedFileOrFolder;
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


- (void) presentActivityViewForShareLink:(NSURL *)urlShareLink inView:(id)sender fromRect:(CGRect)cgRect {
    
    UIActivityItemProvider *activityProvider = [[UIActivityItemProvider alloc] initWithPlaceholderItem:urlShareLink];
    NSArray *items = @[activityProvider,urlShareLink];
    
    //Adding the bottom buttons on the share view
    APCopyActivityIcon *copyLink = [[APCopyActivityIcon alloc] initWithLink:urlShareLink.absoluteString];
    
    NSMutableArray *activities = [NSMutableArray new];
    
    if ([copyLink isAppInstalled]) {
        [activities addObject:copyLink];
    }
    
    UIActivityViewController *activityView = [[UIActivityViewController alloc]
                                              initWithActivityItems:items
                                              applicationActivities:activities];
    
    [activityView setExcludedActivityTypes:
     @[UIActivityTypeAssignToContact,
       UIActivityTypeCopyToPasteboard,
       UIActivityTypePrint,
       UIActivityTypeSaveToCameraRoll,
       UIActivityTypePostToWeibo]];
    
    if (IS_IPHONE) {
        
        [self presentViewController:activityView animated:YES completion:nil];
        
    } else {
        
        self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityView];

        [self.activityPopoverController presentPopoverFromRect:cgRect inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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
}


- (void) sharelinkOptionsUpdated {
    [self checkSharedStatusOFile];
}

- (void) finishCheckSharesAndReloadShareView {
    [self updateSharesOfFileFromDB];
    [self reloadView];
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

#pragma mark - Confirm remove shares

- (void) confirmRemoveShareLink:(NSInteger)indexLink {
    OCSharedDto *sharedLinkToRemove = self.sharedPublicLinks[indexLink];
    NSString *sharedLinkNameToShow = @"";
    if (sharedLinkToRemove.name && ![sharedLinkToRemove.name isEqualToString:@"(null)"] ) {
        sharedLinkNameToShow = sharedLinkToRemove.name;
    }

    NSString *message = [NSLocalizedString(@"message_confirm_delete_link", nil)  stringByReplacingOccurrencesOfString:@"$sharedLink" withString:sharedLinkNameToShow];
    UIAlertController * alert =  [UIAlertController
                                  alertControllerWithTitle:NSLocalizedString(@"title_confirm_delete_link", nil)
                                  message: message
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:NSLocalizedString(@"ok", nil)
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [self unShareByIdRemoteShared: sharedLinkToRemove.idRemoteShared];
                             [self.sharedPublicLinks removeObjectAtIndex:indexLink];
                             [self reloadView];
                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"cancel", nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}


@end
