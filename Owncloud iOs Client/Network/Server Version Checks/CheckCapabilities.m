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
#import "ManageCapabilitiesDB.h"
#import "FileNameUtils.h"
#import "Customization.h"
#import "FilesViewController.h"
#import "UtilsUrls.h"

NSString * CapabilitiesUpdatedNotification = @"CapabilitiesUpdatedNotification";

@implementation CheckCapabilities

+ (void) getServerCapabilitiesOfActiveAccount:(void(^)(OCCapabilities *capabilities))success failure:(void(^)(NSError *error))failure{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.activeUser) {
        
        //Set the right credentials
        if (k_is_sso_active) {
            [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:app.activeUser.password];
        } else if (k_is_oauth_active) {
            [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:app.activeUser.password];
        } else {
            [[AppDelegate sharedOCCommunication] setCredentialsWithUser:app.activeUser.username andPassword:app.activeUser.password];
        }
        
        [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
        
        [[AppDelegate sharedOCCommunication] getCapabilitiesOfServer:app.activeUser.url onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, OCCapabilities *capabilities, NSString *redirectedServer) {
            
            BOOL isSamlCredentialsError=NO;
            
            //Check the login error in shibboleth
            if (k_is_sso_active) {
                //Check if there are fragmens of saml in url, in this case there are a credential error
                isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            }
            
            if (!isSamlCredentialsError) {
                success(capabilities);
            } else {
                success(nil);
            }

        } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
            
            DLog(@"error when try to get server capabilities: %@", error);
            failure(error);
        }];
    }
    
}


+ (void) updateServerCapabilitiesOfActiveAccountInDB:(OCCapabilities *)capabilities {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    OCCapabilities *capDB = [ManageCapabilitiesDB getCapabilitiesOfUserId: app.activeUser.idUser];
    
    if (capDB == nil) {
        [ManageCapabilitiesDB insertCapabilities:capabilities ofUserId: app.activeUser.idUser];
    }else{
        [ManageCapabilitiesDB updateCapabilitiesWith:capabilities ofUserId: app.activeUser.idUser];
    }
}


#pragma mark - FilesViewController callBacks

/*
 * Method to reload the data of the file list.
 */
+ (void)reloadFileList{
    [[NSNotificationCenter defaultCenter] postNotificationName: CapabilitiesUpdatedNotification object: nil];
}

@end
