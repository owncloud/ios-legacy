//
//  ShareSearchUserViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 28/9/15.
//
//

/*
 Copyright (C) 2015, ownCloud, Inc.
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


#define heightOfShareLinkOptionRow 55.0
#define shareUserCellIdentifier @"ShareUserCellIdentifier"
#define shareUserCellNib @"ShareUserCell"

@interface ShareSearchUserViewController ()

@property (strong, nonatomic) NSMutableArray *filteredItems;

@end

@implementation ShareSearchUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.filteredItems = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - TableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.filteredItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
   
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        ShareUserCell* shareUserCell = (ShareUserCell*)[tableView dequeueReusableCellWithIdentifier:shareUserCellIdentifier];
        
        if (shareUserCell == nil) {
            NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:shareUserCellNib owner:self options:nil];
            shareUserCell = (ShareUserCell *)[topLevelObjects objectAtIndex:0];
        }

        shareUserCell.itemName.text = [self.filteredItems objectAtIndex:indexPath.row];
    
        cell = shareUserCell;
        
        
    }

    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return heightOfShareLinkOptionRow;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    
}

#pragma mark OCLibrary Search Block Methods

- (void) sendSearchRequestToUpdateTheUsersListWith: (NSString *)searchString {
    
   // AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //  [self initLoading];
    
    //In iPad set the global variable
    /* if (!IS_IPHONE) {
     //Set global loading screen global flag to YES (only for iPad)
     app.isLoadingVisible = YES;
     }*/
    
    if (searchString) {
        [self.filteredItems removeAllObjects];
    }
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:APP_DELEGATE.activeUser.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:APP_DELEGATE.activeUser.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:APP_DELEGATE.activeUser.username andPassword:APP_DELEGATE.activeUser.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    [[AppDelegate sharedOCCommunication] searchUsersAndGroupsWith: searchString ofServer: APP_DELEGATE.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *itemList, NSString *redirectedServer) {
        
        [self.filteredItems addObjectsFromArray:itemList];
        
        [self.searchDisplayController.searchResultsTableView reloadData];
        
        
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
        
        
        
    }];
    
}



#pragma mark - SearchViewController Delegate Methods

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    if  ([searchString isEqualToString:@""] == NO)
    {
        [self sendSearchRequestToUpdateTheUsersListWith:searchString];
        
        return NO;
    }
    else
    {
        [self.filteredItems removeAllObjects];
        return YES;
    }
    
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
   // [self.searchQueue cancelAllOperations];
}


- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.rowHeight = self.searchTableView.rowHeight;
}





@end
