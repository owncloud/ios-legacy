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

@implementation ManageNetworkErrors

/*
 * Method called when receive an error from server
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
        case OCErrorForbidenCharacters:
            //Forbidden characters from the server side
            [_delegate showError:NSLocalizedString(@"forbidden_characters_from_server", nil)];
            break;
            
        case NSURLErrorServerCertificateUntrusted: //-1202
            [[CheckAccessToServer sharedManager] isConnectionToTheServerByUrl:user.url];
            break;
            
        case kOCErrorSharedAPIWrong:    
        case kOCErrorServerForbidden:
        case kOCErrorServerPathNotFound:
                [self.delegate showError:errorConnection.localizedDescription];
            break;
            
        default:
            //Web Dav Error Code
            [self returnErrorMessageWithHttpStatusCode:errorHttp andError:errorConnection];
            break;
    }
}


/*
 * Method that show the suitable webdav error message in the delegate class
 * @errorHttp -> WebDav Server Error
 */

- (void)returnErrorMessageWithHttpStatusCode:(NSInteger) errorHttp andError:(NSError *) error {
    
    switch (errorHttp) {
        case kOCErrorServerUnauthorized:
            //Unauthorized (bad username or password)
            [self.delegate errorLogin];
            break;
        case kOCErrorServerForbidden:
            //403 Forbidden
            if (error.code == OCErrorForbidenUnknow) {
                [_delegate showError:[error.userInfo objectForKey:NSLocalizedDescriptionKey]];
            } else {
                [_delegate showError:NSLocalizedString(@"error_not_permission", nil)];
            }
            break;
        case kOCErrorServerPathNotFound:
            //404 Not Found. When for example we try to access a path that now not exist
            [_delegate showError:NSLocalizedString(@"error_path", nil)];
            break;
        case kOCErrorServerMethodNotPermitted:
            //405 Method not permitted
            [_delegate showError:NSLocalizedString(@"not_possible_create_folder", nil)];
            break;
        case kOCErrorServerTimeout:
            //408 timeout
            [_delegate showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
            break;
        case kOCErrorServerMaintenanceError:
            //503 Maintenance Error
            [_delegate showError:NSLocalizedString(@"maintenance_mode_on_server_message", nil)];
            break;
        default:
            [_delegate showError:NSLocalizedString(@"not_possible_connect_to_server", nil)];
            break;
    }
}

@end
