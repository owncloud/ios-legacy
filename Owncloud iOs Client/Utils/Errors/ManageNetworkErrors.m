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
            
        default:
            //Web Dav Error Code
            if (errorHttp == kOCErrorServerUnauthorized) {
                [self.delegate errorLogin];
            } else {
                [self.delegate showError: [self returnErrorMessageWithHttpStatusCode:errorHttp andError:errorConnection] ];
            }
            break;
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
    
    if (error != nil) {
        switch (error.code) {
            case OCErrorForbiddenCharacters:
                //Forbidden characters from the server side
                return NSLocalizedString(@"forbidden_characters_from_server", nil);
                
            case OCErrorSslRecoverablePeerUnverified:
                return NSLocalizedString(@"server_certificate_untrusted", nil);
                
            case kOCErrorSharedAPIWrong:
            case kOCErrorServerForbidden:
            case kOCErrorServerPathNotFound:
            case kCFURLErrorUnsupportedURL:
            case kCFURLErrorCannotConnectToHost:
                return error.localizedDescription;
        }
    }
    
    switch (errorHttp) {
        case kOCErrorServerUnauthorized:
            //Unauthorized (bad username or password)
            if (k_is_sso_active) {
                return NSLocalizedString(@"session_expired", nil);
            } else {
                return NSLocalizedString(@"error_login_message", nil);
            }
            
        case kOCErrorServerForbidden:
            //403 Forbidden
            if (error && error.code == OCErrorForbiddenUnknown) {
                return [error.userInfo objectForKey:NSLocalizedDescriptionKey];
            } else {
                return NSLocalizedString(@"error_not_permission", nil);
            }
            
        case kOCErrorServerPathNotFound:
            //404 Not Found. When for example we try to access a path that now not exist
            return NSLocalizedString(@"error_path", nil);
            
        case kOCErrorServerMethodNotPermitted:
            //405 Method not permitted
            return NSLocalizedString(@"not_possible_create_folder", nil);

        case kOCErrorServerMaintenanceError:
            //503 Maintenance Error
            return NSLocalizedString(@"maintenance_mode_on_server_message", nil);

        case kOCErrorServerTimeout:
        default:
            return NSLocalizedString(@"not_possible_connect_to_server", nil);
            
    }
}


/**
 * Returns an error message corresponding to a remote operation result with no knowledge about
 * the operation performed.
 *
 * @param result        Result of a remote operation performed.
 * @return User message corresponding to 'result'.
 */
/*
- (NSString *) getCommonMessageForResult:(NSInteger) errorHttp andError:(NSError *) error {
    
    NSString* message = nil;
    
    if (error.code == ) {
        message = res.getString(R.string.network_error_socket_exception);
    
    } else if (result.getCode() == ResultCode.NO_NETWORK_CONNECTION) {
        message = res.getString(R.string.error_no_network_connection);
    
    } else if (result.getCode() == ResultCode.TIMEOUT) {
        message = res.getString(R.string.network_error_socket_timeout_exception);
        
        if (result.getException() instanceof ConnectTimeoutException) {
            message = res.getString(R.string.network_error_connect_timeout_exception);
        }
            
    } else if (result.getCode() == ResultCode.HOST_NOT_AVAILABLE) {
        message = res.getString(R.string.network_host_not_available);
            
    } else if (result.getCode() == ResultCode.SERVICE_UNAVAILABLE) {
        message = res.getString(R.string.service_unavailable);
            
    } else if (result.getCode() == ResultCode.SSL_RECOVERABLE_PEER_UNVERIFIED) {
        message = res.getString(
            R.string.ssl_certificate_not_trusted
        );
            
    } else if (result.getCode() == ResultCode.BAD_OC_VERSION) {
        message = res.getString(
            R.string.auth_bad_oc_version_title
        );
            
    } else if (result.getCode() == ResultCode.INCORRECT_ADDRESS) {
        message = res.getString(
            R.string.auth_incorrect_address_title
        );
            
    } else if (result.getCode() == ResultCode.SSL_ERROR) {
        message = res.getString(
            R.string.auth_ssl_general_error_title
        );
            
    } else if (result.getCode() == ResultCode.UNAUTHORIZED) {
        message = res.getString(
            R.string.auth_unauthorized
        );
        
    } else if (result.getCode() == ResultCode.INSTANCE_NOT_CONFIGURED) {
        message = res.getString(
            R.string.auth_not_configured_title
        );
            
    } else if (result.getCode() == ResultCode.FILE_NOT_FOUND) {
        message = res.getString(
            R.string.auth_incorrect_path_title
        );
        
    } else if (result.getCode() == ResultCode.OAUTH2_ERROR) {
        message = res.getString(
            R.string.auth_oauth_error
        );
            
    } else if (result.getCode() == ResultCode.OAUTH2_ERROR_ACCESS_DENIED) {
        message = res.getString(
            R.string.auth_oauth_error_access_denied
        );
            
    } else if (result.getCode() == ResultCode.ACCOUNT_NOT_NEW) {
        message = res.getString(
            R.string.auth_account_not_new
        );
            
    } else if (result.getCode() == ResultCode.ACCOUNT_NOT_THE_SAME) {
        message = res.getString(
            R.string.auth_account_not_the_same
        );
            
    } else if (result.getCode() == ResultCode.OK_REDIRECT_TO_NON_SECURE_CONNECTION) {
        message = res.getString(R.string.auth_redirect_non_secure_connection_title);
    }
        
    else if (result.getHttpPhrase() != null && result.getHttpPhrase().length() > 0) {
        // last chance: error message from server
        message = result.getHttpPhrase();
    }

    return message;
}
*/

@end
