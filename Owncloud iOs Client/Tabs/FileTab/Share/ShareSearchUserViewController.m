//
//  ShareSearchUserViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 28/9/15.
//
//

#import "ShareSearchUserViewController.h"
#import "Owncloud_iOs_Client-Swift.h"


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

        shareUserCell.itemName.text = @"User test name";
    
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

#pragma mark - SearchViewController Delegate Methods

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    if  ([searchString isEqualToString:@""] == NO)
    {
       // [self sendSearchRequestToUpdateSongListWithSearchString:searchString];
        
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
