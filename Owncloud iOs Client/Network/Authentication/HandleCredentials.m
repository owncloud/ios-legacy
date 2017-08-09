//
//  HandleCredentials.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/08/2017.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "HandleCredentials.h"

@implementation HandleCredentials

+(void)setUserAgentAndCredentials:(CredentialsDto *)credentials ofSharedOCCommunication:(OCCommunication *)sharedOCCommunication {
    [sharedOCCommunication setValueOfUserAgent:[UtilsUrls getUserAgent]];
    
    switch (credentials.authenticationMethod) {
        case AuthenticationMethodSAML_WEB_SSO:
            
            [sharedOCCommunication setCredentialsWithCookie:credentials.accessToken];
            break;
            
        case AuthenticationMethodBEARER_TOKEN:
            
            [sharedOCCommunication setCredentialsOauthWithToken:credentials.accessToken];
            break;
            
        default:
            [sharedOCCommunication setCredentialsWithUser:credentials.userName andPassword:credentials.accessToken];
            break;
    }
}

@end
