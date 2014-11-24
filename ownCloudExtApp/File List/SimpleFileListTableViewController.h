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

@interface SimpleFileListTableViewController : UITableViewController <MBProgressHUDDelegate, CheckAccessToServerDelegate, ManageNetworkErrorsDelegate>

extern NSString * userHasChangeNotification;

// init method to load view from nib with an array of files
-(id) initWithNibName:(NSString *) nibNameOrNil onFolder:(FileDto *) currentFolder;

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
