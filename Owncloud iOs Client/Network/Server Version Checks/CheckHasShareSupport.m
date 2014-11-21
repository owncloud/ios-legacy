//
//  CheckHasShareSupport.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 05/08/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "CheckHasShareSupport.h"
#import "AppDelegate.h"
#import "ManageUsersDB.h"
#import "OCCommunication.h"
#import "SharedViewController.h"

@implementation CheckHasShareSupport


///-----------------------------------
/// @name Check if server has share support
///-----------------------------------

/**
 * This method check the current server looking for support Share API
 * and store (YES/NOT) in the global variable.
 *
 */
- (void)checkIfServerHasShareSupport {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.activeUser.username==nil) {
        app.activeUser=[ManageUsersDB getActiveUser];
    }
    
    if (app.activeUser) {
        
        [[AppDelegate sharedOCCommunication] hasServerShareSupport:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, BOOL hasSupport, NSString *redirectedServer) {
            
            if (hasSupport) {
                app.activeUser.hasShareApiSupport = serverFunctionalitySupported;
            } else {
                app.activeUser.hasShareApiSupport = serverFunctionalityNotSupported;
            }
            
            [ManageUsersDB updateUserByUserDto:app.activeUser];
            
            if (app.activeUser.hasShareApiSupport) {
                //Launch the notification
                [self updateSharesFromServer];
            }
            
            [self updateSharedView];
            
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            
            DLog(@"error when try to get the share support: %@", error);
            
            [self updateSharedView];
            
        }];
    }
}

///-----------------------------------
/// @name Update Shared View
///-----------------------------------

/**
 * Update shared view
 */
- (void) updateSharedView {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.sharedViewController) {
        [app.sharedViewController refreshSharedItems];
    }
}

///-----------------------------------
/// @name updateSharesFromServer
///-----------------------------------

/**
 * Method that force to check the shares files and folders
 *
 */

- (void) updateSharesFromServer {
    [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];
}

@end
