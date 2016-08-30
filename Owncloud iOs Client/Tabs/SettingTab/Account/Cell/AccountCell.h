//
//  AccountCell.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 10/1/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>

@protocol AccountCellDelegate

@optional
- (void)activeAccountByPosition:(NSInteger) position;
@end

@interface AccountCell : UITableViewCell


@property(nonatomic, weak) IBOutlet UILabel *userName;
@property(nonatomic, weak) IBOutlet UILabel *urlServer;
@property(nonatomic, weak) IBOutlet UIButton *activeButton;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property(nonatomic, weak) __weak id <AccountCellDelegate> delegate;


- (IBAction)activeAccount:(id)sender;



@end
