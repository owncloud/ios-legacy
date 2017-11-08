//
//  ManageNetworkErrors.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 26/06/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageNetworkErrors.h"
#import "UserDto.h"
#import "CheckAccessToServer.h"
#import "OCErrorMsg.h"
#import "OCCommunication.h"
#import "Customization.h"
#import "OCFrameworkConstants.h"

@implementation ManageNetworkErrors

/*
 * Method called when receive an error from server
 *
 * THIS METHOD WILL CRASH IF NO DELEGATE IS SET TO ManageNetworkErrors BEFORE
 *
 * @errorHttp -> WebDav Server Error of NSURLResponse
 * @errorConnection -> NSError of NSURLSession
 */

- (void)manageErrorHttp:(NSInteger)errorHttp andErrorConnection:(NSError *)errorConnection andUser:(UserDto *)user {
    
    DLog(@"Error code from  web dav server: %ld", (long) errorHttp);
    if (errorConnection != nil && [errorConnection isKindOfClass:[NSError class]]) {
        DLog(@"Error code from server: %ld", (long)errorConnection.code);
        
        //Server connection error
        switch (errorConnection.code) {
            case kCFURLErrorUserCancelledAuthentication: { //-1012
                [_delegate showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
                [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:user.url];
                break;
            }
                
            case NSURLErrorServerCertificateUntrusted: //-1202
                [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:user.url];
                break;
                
            case OCErrorOAuth2Error:
            case OCErrorOAuth2ErrorAccessDenied:
                    [self.delegate errorLogin];
                break;
            default:
                //Web Dav Error Code
                if (errorHttp == kOCErrorServerUnauthorized) {
                    [self.delegate errorLogin];
                } else {
                    [self.delegate showError: [self returnErrorMessageWithHttpStatusCode:errorHttp andError:errorConnection] ];
                }
                break;
        }
    } else {
        
    }
}


/*
 * Method that returns a user message appropriate for the given HTTP error code and/or NSError.
 *
 * THIS METHOD DOES NOT INTERACT WITH THE DELEGATE
 *
 * First step to get rid of ManageNetworkErrorsDelegate
 *
 * @errorHttp -> WebDav/HTTP Server Status code
 * @error -> iOS error
 */

- (NSString *)returnErrorMessageWithHttpStatusCode:(NSInteger) errorHttp andError:(NSError *) error {
    
    if (error != nil && [error isKindOfClass:[NSError class]]) {
        switch (error.code) {
            case NSURLErrorNotConnectedToInternet:
                return NSLocalizedString(@"not_connected_to_internet", nil);
                
            case OCErrorForbiddenCharacters:
                //Forbidden characters from the server side
                return NSLocalizedString(@"forbidden_characters_from_server", nil);
                
            case OCErrorSslRecoverablePeerUnverified:
            //case NSURLErrorServerCertificateUntrusted: //-1202
                return NSLocalizedString(@"server_certificate_untrusted", nil);
        }
    }
    
    if (error == nil || ![error.domain isEqualToString:k_domain_error_code]) {
        switch (errorHttp) {
            case kOCErrorServerBadRequest:
                // 400 Bad request
                return NSLocalizedString(@"bad_request", nil);
            
            case kOCErrorServerUnauthorized:
                //401 Unauthorized (bad username or password)
                if (k_is_sso_active) {
                    return NSLocalizedString(@"session_expired", nil);
                } else {
                    return NSLocalizedString(@"error_login_message", nil);
                }
            
            case kOCErrorServerForbidden:
                //403 Forbidden
                return NSLocalizedString(@"error_not_permission", nil);
            
            case kOCErrorServerPathNotFound:
                //404 Not Found. When for example we try to access a path that now not exist
                return NSLocalizedString(@"error_path", nil);
            
            case kOCErrorServerMethodNotPermitted:
                //405 Method not allowed
                return NSLocalizedString(@"method_not_allowed", nil);

            case kOCErrorProxyAuth:
                //407 Proxy authentication required
                return NSLocalizedString(@"proxy_auth_required", nil);
            
            case kOCErrorServerTimeout:
                //408
                return NSLocalizedString(@"not_possible_connect_to_server", nil);
            
            case kOCErrorServerConflict:
                //409
                return NSLocalizedString(@"conflict", nil);

            case kOCErrorServerInternalError:
                // 500
                return NSLocalizedString(@"internal_error", nil);
            
            case kOCErrorServerNotImplemented:
                // 501
                return NSLocalizedString(@"not_implemented", nil);
            
            case kOCErrorServerBadGateway:
                // 502
                return NSLocalizedString(@"bad_gateway", nil);
            
            case kOCErrorServerMaintenanceError:
                //503 Maintenance Error
                return NSLocalizedString(@"maintenance_mode_on_server_message", nil);
            
        }
    }
    
    if (error != nil) {
        // for app-specific errors, this is perfect provided that the error object is created with
        // correct values for code, domain and userInfo.localizedDescription ;
        // besides, should be good enough for errors generated by the framework when no other specific info is known
        return error.localizedDescription;
    } else {
        return NSLocalizedString(@"not_possible_connect_to_server", nil);
    }
    
}

@end
