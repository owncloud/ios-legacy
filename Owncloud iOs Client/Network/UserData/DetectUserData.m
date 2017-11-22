//
//  DetectUserData.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 18/10/2017.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DetectUserData.h"
#import "OCCommunication.h"
#import "UtilsUrls.h"
#import "UtilsFramework.h"
#import "OCErrorMsg.h"
#import "AppDelegate.h"

@implementation DetectUserData


+ (void) getUserDisplayNameOfServer:(NSString*)path credentials:(OCCredentialsDto *)credentials
                            withCompletion:(void(^)(NSString *displayName, NSError *error))completion {

        [[AppDelegate sharedOCCommunication] setCredentials:credentials];
        
        [[AppDelegate sharedOCCommunication] setValueOfUserAgent:[UtilsUrls getUserAgent]];
        
        [[AppDelegate sharedOCCommunication] getUserDisplayNameOfServer:path onCommunication:[AppDelegate sharedOCCommunication]
            success:^(NSHTTPURLResponse *response, NSString *displayName, NSString *redirectedServer) {
                if (displayName && ![displayName isEqualToString:@""]) {
                    completion(displayName, nil);
                } else {
                    completion(nil, [UtilsFramework getErrorWithCode:0 andCustomMessageFromTheServer:NSLocalizedString(@"server_does_not_give_user_id", nil)]);
                }
            } failure:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
                DLog(@"error when try to get server displayName: %@", error);
                completion(nil, error);
            }];    
}


@end
