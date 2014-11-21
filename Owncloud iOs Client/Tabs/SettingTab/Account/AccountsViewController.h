//
//  AccountsViewController.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/1/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "AccountCell.h"
#import "AddAccountViewController.h"

@interface AccountsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, AccountCellDelegate, AddAccountDelegate> {
    
    UITableView *_tableView;
    NSMutableArray *_listUsers;

}

@property(nonatomic,strong)IBOutlet UITableView *tableView;
@property(nonatomic,strong)IBOutlet NSMutableArray *listUsers;

@end
