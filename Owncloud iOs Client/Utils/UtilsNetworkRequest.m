//
//  UtilsNetworkRequest.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 7/10/13.
//


/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "UtilsNetworkRequest.h"
#import "AppDelegate.h"
#import "Customization.h"
#import "constants.h"
#import "FileNameUtils.h"
#import "OCCommunication.h"
#import "OCErrorMsg.h"
#import "UtilsUrls.h"
#import "UtilsFramework.h"

@implementation UtilsNetworkRequest

/*
 * This method check in the server if are the item in the folder with
 * the same name
 * @path --> path of the item
 */
- (void)checkIfTheFileExistsWithThisPath:(NSString*)path andUser:(UserDto *) user {
    
    //Set the right credentials
    if (k_is_sso_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:user.password];
    } else if (k_is_oauth_active) {
        [[AppDelegate sharedOCCommunication] setCredentialsOauthWithToken:user.password];
    } else {
        [[AppDelegate sharedOCCommunication] setCredentialsWithUser:user.username andPassword:user.password];
    }
    
    [[AppDelegate sharedOCCommunication] setUserAgent:[UtilsUrls getUserAgent]];
    
    //FileName full path
    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    DLog(@"Path to check: %@", path);
    
    [[AppDelegate sharedOCCommunication] readFile:path onCommunication:[AppDelegate sharedOCCommunication] successRequest:^(NSHTTPURLResponse *response, NSArray *items, NSString *redirectedServer) {
        
        BOOL isSamlCredentialsError=NO;
        
        //Check the login error in shibboleth
        if (k_is_sso_active) {
            //Check if there are fragmens of saml in url, in this case there are a credential error
            isSamlCredentialsError = [FileNameUtils isURLWithSamlFragment:response];
            if (isSamlCredentialsError) {
                [_delegate theFileIsInThePathResponse:credentialsError];
            }
        }
        if (!isSamlCredentialsError) {
            DLog(@"The name of the item exists");
            [_delegate theFileIsInThePathResponse:isInThePath];
        }
    } failureRequest:^(NSHTTPURLResponse *response, NSError *error, NSString *redirectedServer) {
        
        DLog(@"error: %@", error);
        
        DLog(@"error.code: %ld", (long)error.code);
        //Select the correct msg and action for this error
        
        DLog(@"server error: %ld", (long)response.statusCode);
        
        NSInteger code = response.statusCode;
        
        if (code == 0) {
            //Network errors
            switch (error.code) {
                case kCFURLErrorUserCancelledAuthentication: //-1012
                    [_delegate theFileIsInThePathResponse:errorSSL];
                    break;
                case kCFURLErrorNotConnectedToInternet: //-1009
                    [_delegate theFileIsInThePathResponse:serverConnectionError];
                    break;
                default:
                    [_delegate theFileIsInThePathResponse:serverConnectionError];
                    break;
            }
        } else {
            //Http erros
            switch (code) {
                case kOCErrorServerUnauthorized: case kOCErrorProxyAuth:
                    [_delegate theFileIsInThePathResponse:credentialsError];
                    break;
                case kOCErrorServerPathNotFound: case kOCErrorServerForbidden: case kOCErrorServerTimeout:
                    DLog(@"The name of the item not exists");
                    [_delegate theFileIsInThePathResponse:isNotInThePath];
                    break;
                default:
                    [_delegate theFileIsInThePathResponse:isNotInThePath];
                    break;
            }
        }
    }];
}

+ (NSMutableDictionary *) getHttpLoginHeaders {
    
    NSMutableDictionary *headers = [NSMutableDictionary new];
    
    if (k_is_sso_active) {
        [headers setValue:APP_DELEGATE.activeUser.password forKey:@"Cookie"];
    } else if (k_is_oauth_active) {
        [headers setValue:[NSString stringWithFormat:@"Bearer %@", APP_DELEGATE.activeUser.password] forKey:@"Authorization"];
    } else {
        NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", APP_DELEGATE.activeUser.username, APP_DELEGATE.activeUser.password];
        [headers setValue:[NSString stringWithFormat:@"Basic %@", [UtilsFramework AFBase64EncodedStringFromString:basicAuthCredentials]] forKey:@"Authorization"];
    }
    
    [headers setValue:[UtilsUrls getUserAgent] forKey:@"User-Agent"];
    
    return headers;
    
}

@end
