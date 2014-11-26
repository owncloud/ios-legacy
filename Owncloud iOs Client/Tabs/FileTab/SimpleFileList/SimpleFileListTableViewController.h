//
//  SimpleFileListTableViewController.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 04/11/14.
//
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "CheckAccessToServer.h"
#import "ManageNetworkErrors.h"

@class UserDto;
@class FileDto;

@class SimpleFileListTableViewController;

@interface SimpleFileListTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MBProgressHUDDelegate, CheckAccessToServerDelegate, ManageNetworkErrorsDelegate>

// init method to load view from nib with an array of files
- (id) initWithNibName:(NSString *) nibNameOrNil onFolder:(FileDto *) currentFolder;

- (void) fillTheArraysFromDatabase;

- (void) checkBeforeNavigationToFolder:(FileDto *) file;

- (void) navigateToFile:(FileDto *) file;

- (void) reloadCurrentFolder;

- (NSArray *)partitionObjects:(NSArray *)array collationStringSelector:(SEL)selector;

//Loading methods
- (void)initLoading;
- (void)endLoading;

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) UserDto *user;
@property (nonatomic, strong) FileDto *currentFolder;
@property (nonatomic, strong) NSArray *currentDirectoryArray;
@property (nonatomic, strong) NSArray *sortedArray;

@property BOOL isRefreshInProgress;

//View for loading screen
@property(nonatomic, strong) MBProgressHUD  *HUD;
//Refresh Control
@property(nonatomic, strong) UIRefreshControl *refreshControl;
//Manage network errors
@property(nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;

@end
