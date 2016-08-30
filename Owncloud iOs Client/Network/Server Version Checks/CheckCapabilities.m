//
//  CheckCapabilities.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 3/11/15.
//
//


/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "CheckCapabilities.h"
#import "AppDelegate.h"
#import "ManageUsersDB.h"
#import "OCCommunication.h"
#import "OCCapabilities.h"
#import "CapabilitiesDto.h"
#import "ManageCapabilitiesDB.h"
#import "FileNameUtils.h"
#import "Customization.h"
#import "FilesViewController.h"

NSString * CapabilitiesUpdatedNotification = @"CapabilitiesUpdatedNotification";

@implementation CheckCapabilities

+ (id)sharedCheckCapabilities{
    
    static CheckCapabilities *sharedCheckCapabilities = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCheckCapabilities = [[self alloc] init];
    });
    return sharedCheckCapabilities;
    
}

- (void) updateServerCapabilitiesOfActiveAccount {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.activeUser.username == nil) {
        app.activeUser = [ManageUsersDB getActiveUser];
    }
    
    if (app.activeUser) {
        
        [[AppDelegate sharedOCCommunication] getCapabilitiesOfServer:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, OCCapabilities *capabilities, NSString *redirectedServer) {
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active && redirectedServer) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:redirectedServer];
            }
            
            CapabilitiesDto *cap = [ManageCapabilitiesDB getCapabilitiesOfUserId: app.activeUser.idUser];

            if (!isSamlCredentialsError) {
                
                BOOL capabilitiesShareAPIChanged = (cap.isFilesSharingAPIEnabled == capabilities.isFilesSharingAPIEnabled)? NO:YES;
                
                if (cap == nil) {
                    cap = [ManageCapabilitiesDB insertCapabilities:capabilities ofUserId: app.activeUser.idUser];
                }else{
                    cap = [ManageCapabilitiesDB updateCapabilitiesWith:capabilities ofUserId: app.activeUser.idUser];
                }
                
                //update active userDto
                app.activeUser.capabilitiesDto = [CapabilitiesDto new];
                app.activeUser.capabilitiesDto = cap;
                
                //update file list view if needed
                if(capabilitiesShareAPIChanged){
                    [self reloadFileList];
                }

            }

        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
             DLog(@"error when try to get server capabilities: %@", error);
            
        }];
    }
    
}


#pragma mark - FilesViewController callBacks

/*
 * Method to reload the data of the file list.
 */
- (void)reloadFileList{
    [[NSNotificationCenter defaultCenter] postNotificationName: CapabilitiesUpdatedNotification object: nil];
}

@end
