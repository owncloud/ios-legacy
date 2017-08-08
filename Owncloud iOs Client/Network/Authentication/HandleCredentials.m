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


+(void)setSharedOCCommunicationCredentials:(CredentialsDto *)credentials {
    
    switch (credentials.authenticationMethod) {
        case AuthenticationMethodSAML_WEB_SSO:
            
            [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:credentials.accessToken];
            break;
            
        case AuthenticationMethodBEARER_TOKEN:
            
            [[AppDelegate sharedOCCommunication] setCredentialsWithCookie:credentials.accessToken];
            break;
            
        default:
            [[AppDelegate sharedOCCommunication] setCredentialsWithUser:credentials.userName andPassword:credentials.accessToken];
            break;
    }
}


+(void)setSharedOCCommunicationUserAgentAndCredentials:(CredentialsDto *)credentials{
    
    [[AppDelegate sharedOCCommunication] setValueOfUserAgent:[UtilsUrls getUserAgent]];
    
    [self setSharedOCCommunicationUserAgentAndCredentials:credentials];
}


@end
