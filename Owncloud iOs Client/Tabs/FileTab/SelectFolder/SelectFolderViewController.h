//
//  SelectFolderViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 28/09/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
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
    
    //Inteface
    UIBarButtonItem *_createButton;
    UIBarButtonItem *_chooseButton;
    UILabel *_toolBarLabel;
    OCToolBar *_toolBar;
    
    //Info
    UserDto *_mUser;
    CheckAccessToServer *_mCheckAccessToServer; 
    FileDto *_selectedFileDto;
    __weak id parent;
    
    //Folders
    NSArray *_sortedArray;
    NSArray *_currentDirectoryArray;    
    NSString *_currentRemoteFolder;
    NSString *_currentLocalFolder;
    NSString *_nextRemoteFolder; 
    FileDto *_fileIdToShowFiles;
    
    NSString *_toolBarLabelTxt;
    
    //Create Folder    
    UIAlertView *_folderView;
    
    //Alert
    UIAlertView *_alert;
}

@property (nonatomic, strong) IBOutlet UIBarButtonItem *createButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *chooseButton;
@property (nonatomic, strong) IBOutlet UILabel *toolBarLabel;
@property (nonatomic, strong) IBOutlet OCToolBar *toolBar;
@property(nonatomic, strong) UserDto *mUser;
@property(nonatomic, retain) CheckAccessToServer *mCheckAccessToServer;
@property(nonatomic, strong) FileDto *selectedFileDto;
@property (nonatomic, weak) id parent;
@property(nonatomic, strong) NSArray *sortedArray;
@property(nonatomic, strong) NSArray *currentDirectoryArray;
@property(nonatomic, strong) NSString *currentRemoteFolder;
@property(nonatomic, strong) NSString *currentLocalFolder;
@property(nonatomic, strong) NSString *nextRemoteFolder;
@property(nonatomic, strong) FileDto *fileIdToShowFiles;
@property(nonatomic, strong) NSString *toolBarLabelTxt;
@property(nonatomic, strong) UIAlertView *folderView;
@property(nonatomic, strong) UIAlertView *alert;

//Custom init
- (id) initWithNibName:(NSString *) nibNameOrNil onFolder:(NSString *) currentFolder andFileId:(int) fileIdToShowFiles andCurrentLocalFolder:(NSString *) currentLocalFoler;

//Actions
- (IBAction)chooseFolder;
- (IBAction)showCreateFolder;

@end
