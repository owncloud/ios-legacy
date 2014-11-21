//
//  CheckHasCookiesSupport.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 06/08/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "CheckHasCookiesSupport.h"
#import "AppDelegate.h"
#import "ManageUsersDB.h"
#import "OCCommunication.h"

@implementation CheckHasCookiesSupport

///-----------------------------------
/// @name Check if server has cookies support
///-----------------------------------

/**
 * This method check the current server looking for cookies support
 * and store (YES/NO) in the library to use cookies or not.
 *
 */
- (void)checkIfServerHasCookiesSupport {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.activeUser.username==nil) {
        app.activeUser=[ManageUsersDB getActiveUser];
    }
    
    if (app.activeUser) {
        
        [[AppDelegate sharedOCCommunication] hasServerCookiesSupport:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, BOOL hasSupport, NSString *redirectedServer) {
            
            //Update the support on the library
            [AppDelegate sharedOCCommunication].isCookiesAvailable = hasSupport;
            
            if (hasSupport) {
                app.activeUser.hasCookiesSupport = serverFunctionalitySupported;
            } else {
                app.activeUser.hasCookiesSupport = serverFunctionalityNotSupported;
            }
            
            [ManageUsersDB updateUserByUserDto:app.activeUser];
                
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            DLog(@"error when try to get the cookies support: %@", error);
        }];
    }
}

@end
