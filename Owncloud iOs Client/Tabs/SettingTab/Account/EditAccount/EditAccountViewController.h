//
//  EditAccountViewController.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/5/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "UserDto.h"

//Define a extern notification
extern NSString *relaunchErrorCredentialFilesNotification;

@interface EditAccountViewController : LoginViewController {
    UserDto *_selectedUser;
    
}

@property(nonatomic,strong)UserDto *selectedUser;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andUser:(UserDto *) selectedUser andModeUpdateToPredefinedUrl:(BOOL)modeUpdateToPredefinedUrl;
- (void)setBarForCancelForLoadingFromModal;
- (void)setBrandingNavigationBarWithCancelButton;
- (IBAction)cancelClicked:(id)sender;

@end
