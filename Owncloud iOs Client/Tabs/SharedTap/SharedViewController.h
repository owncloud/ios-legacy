//
//  SharedViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 17/01/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import <UIKit/UIKit.h>
#import "CheckAccessToServer.h"
#import "SWTableViewCell.h"
#import "ShareFileOrFolder.h"
#import "MBProgressHUD.h"

@interface SharedViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SWTableViewCellDelegate, ShareFileOrFolderDelegate, MBProgressHUDDelegate, ManageNetworkErrorsDelegate>

//Share Table
@property (nonatomic,strong) IBOutlet UITableView *sharedTableView;
//Refresh Control
@property(nonatomic, strong) UIRefreshControl *refreshControl;
//To check if there are access with the server
@property(nonatomic, retain) CheckAccessToServer *mCheckAccessToServer;
//Share file or folder
@property(nonatomic, strong) ShareFileOrFolder *mShareFileOrFolder;

//Loading view
@property(nonatomic, strong) MBProgressHUD  *HUD;


//Store if the refreshShared it's in progress
@property(nonatomic)BOOL isRefreshSharedInProgress;
//Number of folders and files in the share list
@property (nonatomic) int numberOfFolders;
@property (nonatomic) int numberOfFiles;

@property (nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;


///-----------------------------------
/// @name Refresh Shared Path
///-----------------------------------

/**
 * This method do the request to the server, get the shared data of the all files
 * Then update the DataBase with the shared data in the files of the current path
 * Finally, reload the file list with the database data
 */
- (void) refreshSharedItems;




@end
