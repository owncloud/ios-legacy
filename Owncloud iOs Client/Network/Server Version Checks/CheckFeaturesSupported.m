//
//  CheckFeaturesSupported.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 6/11/15.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "CheckFeaturesSupported.h"
#import "AppDelegate.h"
#import "ManageUsersDB.h"
#import "OCCommunication.h"
#import "SharedViewController.h"
#import "OCCapabilities.h"
#import "CapabilitiesDto.h"
#import "ManageCapabilitiesDB.h"
#import "CheckCapabilities.h"

@implementation CheckFeaturesSupported

#pragma mark - Singleton

+ (id)sharedCheckFeaturesSupported {
    static CheckFeaturesSupported *sharedCheckFeaturesSupported = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCheckFeaturesSupported = [[self alloc] init];
    });
    return sharedCheckFeaturesSupported;
}

- (void) updateServerFeaturesOfActiveUser{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.activeUser.username == nil) {
        app.activeUser = [ManageUsersDB getActiveUser];
    }
    
    if (app.activeUser) {
        
        [[AppDelegate sharedOCCommunication] getFeaturesSupportedByServer:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, BOOL hasShareSupport, BOOL hasShareeSupport, BOOL hasCookiesSupport, BOOL hasForbiddenCharactersSupport, BOOL hasCapabilitiesSupport, BOOL hasFedSharesOptionShareSupport, NSString *redirectedServer) {
            
            //Share Support
            
            if (hasShareSupport) {
                app.activeUser.hasShareApiSupport = serverFunctionalitySupported;
            } else {
                app.activeUser.hasShareApiSupport = serverFunctionalityNotSupported;
            }
            
            //Sharee Support
            
            if (hasShareeSupport) {
                app.activeUser.hasShareeApiSupport = serverFunctionalitySupported;
            } else {
                app.activeUser.hasShareeApiSupport = serverFunctionalityNotSupported;
            }
            
            if (app.activeUser.hasShareApiSupport) {
                //Launch the notification
                [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];
            }
            
            [self updateSharedView];
            
            //Cookies Support
            
            [AppDelegate sharedOCCommunication].isCookiesAvailable = hasCookiesSupport;
            
            if (hasCookiesSupport) {
                app.activeUser.hasCookiesSupport = serverFunctionalitySupported;
            } else {
                app.activeUser.hasCookiesSupport = serverFunctionalityNotSupported;
            }
            
            //Forbidden Character Support
            
            if (hasForbiddenCharactersSupport) {
                app.activeUser.hasForbiddenCharactersSupport = serverFunctionalitySupported;
            } else {
                app.activeUser.hasForbiddenCharactersSupport = serverFunctionalityNotSupported;
            }

            //Capabilities support
            
            if (hasCapabilitiesSupport) {
                app.activeUser.hasCapabilitiesSupport = serverFunctionalitySupported;
                
                //Update capabilities of the active account
                [[CheckCapabilities sharedCheckCapabilities] updateServerCapabilitiesOfActiveAccount];
                
            }else{
                app.activeUser.hasCapabilitiesSupport = serverFunctionalityNotSupported;
                
            }
            
            if (hasFedSharesOptionShareSupport) {
                app.activeUser.hasFedSharesOptionShareSupport = serverFunctionalitySupported;
            }
            
            [ManageUsersDB updateUserByUserDto:app.activeUser];
            
        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            DLog(@"error when try to get server features: %@", error);
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


@end
