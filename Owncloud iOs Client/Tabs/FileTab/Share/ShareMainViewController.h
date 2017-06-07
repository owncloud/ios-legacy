//
//  ShareMainViewController.h
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

#import <UIKit/UIKit.h>
#import "ShareFileOrFolder.h"
#import "MBProgressHUD.h"
#import "FileDto.h"
#import "AppsActivityProvider.h"
#import "TSMessage.h"

@interface ShareMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ShareFileOrFolderDelegate, MBProgressHUDDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate , TSMessageViewProtocol>

@property (weak, nonatomic) IBOutlet UITableView *shareTableView;

- (id) initWithFileDto:(FileDto *)fileDto;

@end
