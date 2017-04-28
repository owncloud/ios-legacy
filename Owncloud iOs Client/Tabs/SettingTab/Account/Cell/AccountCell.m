//
//  AccountCell.m
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

#import "AppDelegate.h"
#import "AccountCell.h"
#import "CheckAccessToServer.h"
#import "UtilsFramework.h"
#import "ManageUsersDB.h"
#import "Customization.h"
#import "OCKeychain.h"
#import "UtilsCookies.h"

@implementation AccountCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(IBAction)activeAccount:(id)sender {
    
    //We delete the cookies on SAML
    if (k_is_sso_active) {        
        [UtilsCookies eraseCredentialsAndUrlCacheOfActiveUser];
    }
    
    [self.delegate activeAccountByPosition:self.activeButton.tag];

}


@end
