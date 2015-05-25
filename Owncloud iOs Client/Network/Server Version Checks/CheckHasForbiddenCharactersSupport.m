//
//  CheckHasForbiddenCharactersSupport.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 25/5/15.
//
//

#import "CheckHasForbiddenCharactersSupport.h"
#import "AppDelegate.h"
#import "ManageUsersDB.h"
#import "OCCommunication.h"

@implementation CheckHasForbiddenCharactersSupport

///-----------------------------------
/// @name Check if server has Forbidden Characters support
///-----------------------------------

/**
 * This method check if the current has forbbiden characters support.
 * and store (YES/NOT) in the global variable.
 */
- (void)checkIfServerHasForbiddenCharactersSupport {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.activeUser.username == nil) {
        app.activeUser = [ManageUsersDB getActiveUser];
    }
    
    if (app.activeUser) {
        
        [[AppDelegate sharedOCCommunication] hasServerForbiddenCharactersSupport:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, BOOL hasSupport, NSString *redirectedServer) {
            
            if (hasSupport) {
               //TODO: Store the value in a global variable
            } else {
               //TODO: Store the value in a global variable
            }
            
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            DLog(@"error when try to get the forbidden characters support support: %@", error);
        }];
        
    }
}


@end
