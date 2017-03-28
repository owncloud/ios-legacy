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
    
    //AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    //We check the connection here because we need to accept the certificate on the self signed server before go to the files tab
    [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:self.urlServer.text];
    
    //We delete the cookies on SAML
    if (k_is_sso_active) {
        //app.activeUser.password = @"";
        
        //update keychain user
//        if(![OCKeychain updateCredentialsById:[NSString stringWithFormat:@"%ld", (long)app.activeUser.idUser] withUsername:nil andPassword:app.activeUser.password]) {
//            DLog(@"Error updating credentials of userId:%ld on keychain",(long)app.activeUser.idUser);
//        }
        
        [UtilsCookies eraseCredentialsAndUrlCacheOfActiveUser];
    }
    
    [self.delegate activeAccountByPosition:self.activeButton.tag];

}


@end
