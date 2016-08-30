//
//  UploadFromOtherAppViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 29/10/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "SelectFolderNavigation.h"
#import "OverwriteFileOptions.h"
#import "UtilsNetworkRequest.h"


@interface UploadFromOtherAppViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SelectFolderDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate, OverwriteFileOptionsDelegate, UtilsNetworkRequestDelegate>
    

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) IBOutlet UINavigationItem *navItem;
@property (nonatomic, strong)  NSString *filePath;
@property (nonatomic, strong) IBOutlet UITextField *nameFileTextField;
@property (nonatomic, strong) IBOutlet UIAlertView *alertFileExist;

@property (nonatomic, strong) UITapGestureRecognizer *oneTap;
@property (nonatomic, strong) NSString *remoteFolder;
@property (nonatomic, strong) NSString *folderName;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *serverName;
@property (nonatomic, strong) OverwriteFileOptions *overWritteOption;
@property (nonatomic, strong) UtilsNetworkRequest *utilsNetworkRequest;
@property (nonatomic, strong) NSString *localFolder;
@property (nonatomic, strong) NSString *auxFileName;

@end
