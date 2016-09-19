//
//  SelectFolderViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 28/09/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "UserDto.h"
#import "CheckAccessToServer.h"
#import "MBProgressHUD.h"
#import "FileDto.h"
#import "OCToolBar.h"
#import "SimpleFileListTableViewController.h"


@interface SelectFolderViewController : SimpleFileListTableViewController <CheckAccessToServerDelegate, UIAlertViewDelegate, UITextFieldDelegate>{
    __weak id parent;
}

@property (nonatomic, strong) IBOutlet UIBarButtonItem *createButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *chooseButton;
@property (nonatomic, strong) IBOutlet UILabel *toolBarLabel;
@property (nonatomic, strong) IBOutlet OCToolBar *toolBar;
@property(nonatomic, retain) CheckAccessToServer *mCheckAccessToServer;
@property(nonatomic, strong) FileDto *selectedFileDto;
@property (nonatomic, weak) id parent;
@property(nonatomic, strong) NSString *currentRemoteFolder;
@property(nonatomic, strong) NSString *currentLocalFolder;
@property(nonatomic, strong) NSString *nextRemoteFolder;
@property(nonatomic, strong) FileDto *fileIdToShowFiles;
@property(nonatomic, strong) NSString *toolBarLabelTxt;
@property(nonatomic, strong) UIAlertView *folderView;
@property(nonatomic, strong) UIAlertView *alert;
@property(nonatomic, strong) SelectFolderViewController *selectFolderViewController;

//Actions
- (IBAction)chooseFolder;
- (IBAction)showCreateFolder;

@end
