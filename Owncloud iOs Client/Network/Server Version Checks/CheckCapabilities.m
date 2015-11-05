//
//  CheckCapabilities.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 3/11/15.
//
//

#import "CheckCapabilities.h"
#import "AppDelegate.h"
#import "ManageUsersDB.h"
#import "OCCommunication.h"
#import "OCCapabilities.h"
#import "CapabilitiesDto.h"
#import "ManageCapabilitiesDB.h"

@implementation CheckCapabilities

- (void) updateServerCapabilitiesOfActiveAccount {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.activeUser.username == nil) {
        app.activeUser = [ManageUsersDB getActiveUser];
    }
    
    if (app.activeUser) {
        
        [[AppDelegate sharedOCCommunication] getCapabilitiesOfServer:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, OCCapabilities *capabilities, NSString *redirectedServer) {
            
            NSLog(@"capabilities: %@", capabilities);
            
            CapabilitiesDto *cap = [ManageCapabilitiesDB getCapabilitiesOfUserId: app.activeUser.idUser];
            
            if (cap == nil) {
                cap = [ManageCapabilitiesDB insertCapabilities:capabilities ofUserId: app.activeUser.idUser];
            }else{
                cap = [ManageCapabilitiesDB updateCapabilitiesWith:capabilities ofUserId: app.activeUser.idUser];
            }
            
            
            
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error) {
            
             DLog(@"error when try to get server capabilities: %@", error);
            
        }];
        
    }
    
    
}

@end
