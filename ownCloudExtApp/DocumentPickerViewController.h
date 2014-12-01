//
//  DocumentPickerViewController.h
//  ownCloudExtApp
//
//  Created by Gonzalo Gonzalez on 14/10/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "FMDatabaseQueue.h"
#import "KKPasscodeViewController.h"

@class SimpleFileListTableViewController;
@class OCCommunication;
@class UserDto;

@interface DocumentPickerViewController : UIDocumentPickerExtensionViewController <KKPasscodeViewControllerDelegate>

+ (FMDatabaseQueue*)sharedDatabase;
+ (OCCommunication*)sharedOCCommunication;

@property (weak, nonatomic) IBOutlet UILabel *labelErrorLogin;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewLogo;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewError;

@property (nonatomic, strong) UserDto *user;

@end
