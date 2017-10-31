//
//  ShareSearchUserViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 28/9/15.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ShareSearchUserViewController.h"
#import "Owncloud_iOs_Client-Swift.h"
#import "AppDelegate.h"
#import "constants.h"
#import "Customization.h"
#import "OCCommunication.h"
#import "UtilsUrls.h"
#import "OCShareUser.h"
#import "OCSharedDto.h"
#import "TSMessageView.h"
#import "OCConstants.h"
#import "ShareUtils.h"


#define heightOfShareWithUserRow 55.0
#define shareUserCellIdentifier @"ShareUserCellIdentifier"
#define shareUserCellNib @"ShareUserCell"
#define shareLoadingCellIdentifier @"ShareUserCellIdentifier"
#define shareLoadingCellNib @"ShareLoadingCell"
#define loadingVisibleSearchDelay 2.0
#define loadingVisibleSortDelay 0.1
#define searchResultsPerPage 30
#define shareSearchUserLaunchRequestDelay 1.0

@interface ShareSearchUserViewController ()

@property (strong, nonatomic) NSMutableArray *filteredItems;
@property (strong, nonatomic) NSMutableArray *selectedItems;
@property (nonatomic, strong) MBProgressHUD *loadingView;
@property (nonatomic) NSInteger indexSearchPage;
@property (nonatomic, strong) NSString *searchString;

@end

@implementation ShareSearchUserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _filteredItems = [NSMutableArray new];
        _selectedItems = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (IS_IPHONE == false) {
         self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    
    self.title = NSLocalizedString(@"add_user_or_group_title", nil);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Utils

- (void) insertUseroOrGroupObjectInSelectedItems: (OCShareUser *) item {
    
    BOOL exist = false;
    
    for (OCShareUser *tempItem in self.selectedItems) {
        
        if ([tempItem.name isEqualToString:item.name] && tempItem.shareeType == item.shareeType) {
            exist = true;
            break;
        }
    }
    
    if (exist == false) {
        [self.selectedItems addObject:item];
    }
}

- (void) setAndAddSelectedItems:(NSMutableArray *) selectedItems {
    
    for (OCShareUser *item in selectedItems) {
        [self.selectedItems addObject:item];
    }

}

- (void) initLoadingWithDelay:(CGFloat)delay {
    
    if (self.loadingView == nil) {
        self.loadingView = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
        self.loadingView.delegate = self;
    }
    
    self.loadingView.hidden = true;
    
    [self.view addSubview:self.loadingView];
    
    self.loadingView.labelText = NSLocalizedString(@"loading", nil);
    self.loadingView.dimBackground = false;
    
    [self.loadingView show:true];
    
    [self performSelector:@selector(setLoadingViewVisible) withObject:nil afterDelay:delay];
    
}

- (void) setLoadingViewVisible {
    
    if (self.loadingView != nil) {
        self.loadingView.hidden = true;
    }
}

- (void) endLoading {
    
    [self.loadingView removeFromSuperview];
}

#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        if (self.filteredItems.count == 0) {
            return self.filteredItems.count;
            
        }else if (self.filteredItems.count % searchResultsPerPage == 0){
            
             return self.filteredItems.count + 1;
            
        }else{
            
            return self.filteredItems.count;
        }
        
    }else {
        return self.selectedItems.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView && self.filteredItems.count == indexPath.row) {
        
        ShareLoadingCell *shareLoadingCell = (ShareLoadingCell*)[tableView dequeueReusableCellWithIdentifier:shareLoadingCellIdentifier];
        
        if (shareLoadingCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareLoadingCellNib owner:self options:nil];
            shareLoadingCell = (ShareLoadingCell *)[topLevelObjects objectAtIndex:0];
        }
        
        cell = shareLoadingCell;
        
    }else{
        
        ShareUserCell* shareUserCell = (ShareUserCell*)[tableView dequeueReusableCellWithIdentifier:shareUserCellIdentifier];
        
        if (shareUserCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
            shareUserCell = (ShareUserCell *)[topLevelObjects objectAtIndex:0];
        }
        
        OCShareUser *userOrGroup = nil;
        
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            userOrGroup = [self.filteredItems objectAtIndex:indexPath.row];
        }else{
            userOrGroup = [self.selectedItems objectAtIndex:indexPath.row];
            shareUserCell.selectionStyle = UITableViewCellEditingStyleNone;
        }


        NSString *name = [ShareUtils getDisplayNameForSharee:userOrGroup];
        
        shareUserCell.itemName.text = name;
        
        cell = shareUserCell;
        
    }
    
    return cell;
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.searchDisplayController.searchResultsTableView && self.filteredItems.count - 1 == indexPath.row && self.filteredItems.count % searchResultsPerPage == 0){
        [self sendSearchRequestToUpdateTheUsersListWith:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return heightOfShareWithUserRow;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
       
        OCShareUser *selectedUser = [self.filteredItems objectAtIndex:indexPath.row];
        
        [self sendShareWithRequestWithUserOrGroup:selectedUser];
        
    }
    
}


#pragma mark OCLibrary Block Methods

- (void) sendSearchRequestToUpdateTheUsersListWith: (NSString *)filterString {
    
    if (filterString != nil) {
        self.searchString = filterString;
        self.indexSearchPage = 1;
    }else{
        self.indexSearchPage++;
    }
    
    BOOL supportFederatedSharing = NO;
    
    if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported) {
        OCCapabilities *cap = APP_DELEGATE.activeUser.capabilitiesDto;
        
        if (cap.isFilesSharingAllowUserSendSharesToOtherServersEnabled) {
            supportFederatedSharing = YES;
        }
    }
    
    [self initLoadingWithDelay:loadingVisibleSearchDelay];
    
    [[AppDelegate sharedOCCommunication] setCredentials:APP_DELEGATE.activeUser.credDto];
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];

    [[AppDelegate sharedOCCommunication] searchUsersAndGroupsWith:self.searchString forPage:self.indexSearchPage with:searchResultsPerPage ofServer: APP_DELEGATE.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *itemList, NSString *redirectedServer) {
        
        [self endLoading];
        
        if (filterString != nil) {
            [self.filteredItems removeAllObjects];
        }
        
        [self.filteredItems addObjectsFromArray:itemList];
        
        if (supportFederatedSharing) {
            if ([filterString containsString:@"@"]) {
                [self manageTheFederatedUsers];
            }
        }

        self.filteredItems = [ShareUtils manageTheDuplicatedUsers:self.filteredItems];
        
        [self.searchDisplayController.searchResultsTableView reloadData];
        
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        [self endLoading];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self showWarningMessageWithText:error.localizedDescription];
        });
        
        
    }];
    
}

- (void) sendShareWithRequestWithUserOrGroup: (OCShareUser *)userOrGroup{
    
    [self initLoadingWithDelay:loadingVisibleSortDelay];
    
    [[AppDelegate sharedOCCommunication] setCredentials:APP_DELEGATE.activeUser.credDto];
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    NSString *path = [NSString stringWithFormat:@"/%@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:self.shareFileDto.filePath andUser:APP_DELEGATE.activeUser]];
    NSString *filePath = [NSString stringWithFormat: @"%@%@", path, self.shareFileDto.fileName];
    
    NSInteger permissions = k_read_share_permission;
    
    //File is shared to me by others or not
    if (userOrGroup.shareeType == shareTypeRemote && !APP_DELEGATE.activeUser.hasFedSharesOptionShareSupport) {
        if (self.shareFileDto.isDirectory) {
            permissions = k_default_folder_remote_share_permission_no_support_share_option;
        } else {
            permissions = k_default_file_remote_share_permission_no_support_share_option;
        }
        
    } else if (([self.shareFileDto.permissions rangeOfString:k_permission_shared].location != NSNotFound)) {
        if (self.shareFileDto.isDirectory) {
            permissions = k_min_folder_share_permission;
        } else {
            permissions = k_min_file_share_permission;
        }
    } else {
        if (self.shareFileDto.isDirectory) {
            permissions = k_max_folder_share_permission;
        } else {
            permissions = k_max_file_share_permission;
        }
    }
    
    [[AppDelegate sharedOCCommunication] shareWith:userOrGroup.name shareeType:userOrGroup.shareeType inServer:APP_DELEGATE.activeUser.url andFileOrFolderPath:filePath andPermissions:permissions onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSString *redirectedServer) {
        
        [self endLoading];
        
        [self insertUseroOrGroupObjectInSelectedItems:userOrGroup];
        
        [self.searchDisplayController setActive:NO animated:YES];
        
        self.selectedItems = [ShareUtils manageTheDuplicatedUsers:self.selectedItems];
        
        [self.searchTableView reloadData];
        
        if (!IS_IPHONE) {
        //Refresh the files view that is shown below 
        [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];
        }

        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        [self endLoading];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self showWarningMessageWithText:error.localizedDescription];
        });
        
    }];
    
}


#pragma mark - SearchViewController Delegate Methods

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    [self.searchDelayer invalidate], self.searchDelayer=nil;
    
    if  (![searchString isEqualToString:@""])
    {
        self.searchDelayer = [NSTimer scheduledTimerWithTimeInterval:shareSearchUserLaunchRequestDelay
                                                         target:self
                                                       selector:@selector(doDelayedSearch:)
                                                       userInfo:searchString
                                                        repeats:NO];
        return NO;
    }
    else
    {
        [self.filteredItems removeAllObjects];
        return YES;
    }
    
}

-(void)doDelayedSearch:(NSTimer *)t
{
    assert(t == self.searchDelayer);
    [self sendSearchRequestToUpdateTheUsersListWith:self.searchDelayer.userInfo];

    self.searchDelayer = nil;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.rowHeight = self.searchTableView.rowHeight;
}

#pragma mark - TSMessages

- (void)showWarningMessageWithText: (NSString *) message {
    
    //Run UI Updates
    [TSMessage setDelegate:self];
    [TSMessage showNotificationInViewController:self title:message subtitle:nil type:TSMessageNotificationTypeWarning];
    
}

#pragma mark - TSMessage Delegate

- (void)customizeMessageView:(TSMessageView *)messageView
{
    messageView.alpha = messageAlpha;
    messageView.duration = messageDuration;
}

#pragma mark - Federating user

- (void) manageTheFederatedUsers {
    for (OCShareUser *federatedUser in self.filteredItems) {
        if (federatedUser.shareeType == shareTypeRemote && federatedUser.server == nil){
            federatedUser.displayName = [NSString stringWithFormat:@"%@ (%@)",federatedUser.name, NSLocalizedString(@"share_user_federated_indicator", nil)];
            federatedUser.isDisplayNameDuplicated = NO;
        }
    }
}

@end
