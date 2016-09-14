//
//  RecentViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 8/6/12.
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


@class UploadsOfflineDto;
@interface RecentViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, OverwriteFileOptionsDelegate, SelectFolderDelegate, UIAlertViewDelegate, UITextFieldDelegate, UIActionSheetDelegate>
 
@property (nonatomic,strong) IBOutlet UITableView *uploadsTableView;
@property(nonatomic,strong) UIAlertView *renameAlertView;
@property (nonatomic,strong) NSArray *currentsUploads;
@property (nonatomic,strong) NSArray *recentsUploads;
@property (nonatomic,strong) NSArray *failedUploads;
@property (nonatomic,strong) UploadsOfflineDto *selectedUploadToResolveTheConflict;

@property (nonatomic,strong) NSMutableArray *progressViewArray;

@property (nonatomic, strong) NSString *currentRemoteFolder;
@property (nonatomic, strong) NSString *locationInfo;

@property (nonatomic, strong) OverwriteFileOptions *overWritteOption;

@property (nonatomic, strong) UploadsOfflineDto *selectedFileDtoToResolveNotPermission;

//UIActionSheet for + button
@property (nonatomic,strong) UIActionSheet *plusActionSheet;

- (void)updateRecents;
- (void) updateProgressView:(NSUInteger)num withPercent:(float)percent;

@end
