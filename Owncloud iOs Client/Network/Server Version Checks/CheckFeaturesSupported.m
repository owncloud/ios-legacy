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
#import "ManageCapabilitiesDB.h"
#import "CheckCapabilities.h"

@implementation CheckFeaturesSupported

+ (void) updateServerFeaturesAndCapabilitiesOfActiveUser{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (app.activeUser.username == nil) {
            app.activeUser = [ManageUsersDB getActiveUser];
        }
        
        if (app.activeUser) {
            
            [CheckCapabilities getServerCapabilitiesOfActiveAccount:^(OCCapabilities *capabilities) {
                
                if (capabilities) {
                    [CheckCapabilities updateServerCapabilitiesOfActiveAccountInDB:capabilities];
                    
                    [self updateServerFeaturesOfActiveUserForVersion:capabilities.versionString];
                    
                    //update file list view if needed
                    BOOL capabilitiesShareAPIChanged = (app.activeUser.capabilitiesDto.isFilesSharingAPIEnabled == capabilities.isFilesSharingAPIEnabled)? NO:YES;
                    if(capabilitiesShareAPIChanged){
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [CheckCapabilities reloadFileList];
                        });
                    }
                    
                    app.activeUser.capabilitiesDto = [OCCapabilities new];
                    app.activeUser.capabilitiesDto = capabilities;
                }
                
            } failure:^(NSError *error) {
                DLog(@"error getting capabilities from server, we use previous capabilities from DB to update active user");
                
                app.activeUser.capabilitiesDto =  [ManageCapabilitiesDB getCapabilitiesOfUserId:app.activeUser.userId];
            }];
        }
    });
    
}

+ (void) updateServerFeaturesOfActiveUserForVersion:(NSString *)versionString {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    OCServerFeatures *serverFeatures = [[AppDelegate sharedOCCommunication] getFeaturesSupportedByServerForVersion:versionString];
    
    //Capabilities support
    
    if (serverFeatures.hasCapabilitiesSupport) {
        app.activeUser.hasCapabilitiesSupport = serverFunctionalitySupported;
    } else {
        app.activeUser.hasCapabilitiesSupport = serverFunctionalityNotSupported;
    }
    
    //Share Support
    
    if (serverFeatures.hasShareSupport) {
        app.activeUser.hasShareApiSupport = serverFunctionalitySupported;
    } else {
        app.activeUser.hasShareApiSupport = serverFunctionalityNotSupported;
    }
    
    //Sharee Support
    
    if (serverFeatures.hasShareeSupport) {
        app.activeUser.hasShareeApiSupport = serverFunctionalitySupported;
    } else {
        app.activeUser.hasShareeApiSupport = serverFunctionalityNotSupported;
    }
    
    if (app.activeUser.hasShareApiSupport) {
        //Launch the notification
        [[NSNotificationCenter defaultCenter] postNotificationName: RefreshSharesItemsAfterCheckServerVersion object: nil];
    }
    
     dispatch_async(dispatch_get_main_queue(), ^{
         [self updateSharedView];
     });
    
    //Cookies Support
    
    [AppDelegate sharedOCCommunication].isCookiesAvailable = serverFeatures.hasCookiesSupport;
    
    if (serverFeatures.hasCookiesSupport) {
        app.activeUser.hasCookiesSupport = serverFunctionalitySupported;
    } else {
        app.activeUser.hasCookiesSupport = serverFunctionalityNotSupported;
    }
    
    //Forbidden Character Support
    
    if (serverFeatures.hasForbiddenCharactersSupport) {
        app.activeUser.hasForbiddenCharactersSupport = serverFunctionalitySupported;
    } else {
        app.activeUser.hasForbiddenCharactersSupport = serverFunctionalityNotSupported;
    }
    
    //Federated shares has option to share
    
    if (serverFeatures.hasFedSharesOptionShareSupport) {
        app.activeUser.hasFedSharesOptionShareSupport = serverFunctionalitySupported;
    }
    
    
    //Public share link with option to change the link name
    
    if (serverFeatures.hasPublicShareLinkOptionNameSupport) {
        app.activeUser.hasPublicShareLinkOptionNameSupport = serverFunctionalitySupported;
    }
    
    //Public share link with option to show file listing
    
    if (serverFeatures.hasPublicShareLinkOptionUploadOnlySupport) {
        app.activeUser.hasPublicShareLinkOptionUploadOnlySupport = serverFunctionalitySupported;
    }
    
    [ManageUsersDB updateUserByUserDto:app.activeUser];

}

///-----------------------------------
/// @name Update Shared View
///-----------------------------------

/**
 * Update shared view
 */
+ (void) updateSharedView {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.sharedViewController) {
        [app.sharedViewController refreshSharedItems];
    }
}


@end
