//
//  AddAccountViewController.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/2/12.
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

@protocol AddAccountDelegate

@optional
- (void)refreshTable;
@end

@interface AddAccountViewController : LoginViewController

@property(nonatomic,weak) __weak id<AddAccountDelegate> delegate; 

- (IBAction)cancelClicked:(id)sender;

@end
