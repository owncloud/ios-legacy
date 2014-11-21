/**
 * SURFnetConextIOSClient AuthenticationDbService
 * Created by Jochem  Knoops.
 
 * LICENSE
 *
 * Copyright 2012 SURFnet bv, The Netherlands
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and limitations under the License.
 */

#import "AuthenticationDbService.h"
#import "constants.h"
#import "Customization.h"

@implementation AuthenticationDbService

static AuthenticationDbService *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (AuthenticationDbService *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        
        demoProperties = [NSDictionary dictionaryWithObjectsAndKeys: 
                         @"owncloud", @"scheme",
                         k_oauth_authorize, @"authorize_url", 
                         @"code", @"authorize_response_type", 
                          @"authorization_code", @"authorize_grant_type",
                         k_oauth_client_id, @"authorize_client_id", 
                         @"grades", @"authorize_scope", 
                         @"owncloud://callback", @"authorize_redirect_uri", 
                         k_oauth_token, @"token_url", 
                         @"authorization_code", @"token_grant_type", 
                         k_oauth_webservice, @"webservice_url",
                         @"trace", @"logging",
         nil];
     
    }
    
    return self;
}

- (NSString*) getAuthorizationCode {
    return _authorization_code;
}

- (void) setAuthorizationCode:(NSString*)authorization_code {
    _authorization_code = authorization_code;
}

- (NSString*) getAccessToken
{
    return _access_token;
}

- (void) setAccessToken:(NSString*)access_token
{
    _access_token = access_token;
}

- (NSString*) getTokenType
{
    return _token_type;
}
- (void) setTokenType:(NSString*)token_type
{
    _token_type = token_type;
}

- (NSString*) getRefreshToken
{
    return _refresh_token;
}
- (void) setRefreshToken:(NSString*)refresh_token
{
    _refresh_token = refresh_token;
}

- (NSInteger*) getExpiresIn
{
    return _expires_in;
}
- (void) setExpiresIn:(NSInteger*)expires_in
{
    _expires_in = expires_in;
}

- (NSString*) getScheme
{
    return (NSString*)[demoProperties objectForKey:@"scheme"];
}

- (NSString*) getAuthorizeUrl
{
    return (NSString*)[demoProperties objectForKey:@"authorize_url"];
}

- (NSString*) getTokenUrl
{
    return (NSString*)[demoProperties objectForKey:@"token_url"];
}

- (NSString*) getGrantType
{
    return (NSString*)[demoProperties objectForKey:@"authorize_grant_type"];
}

- (NSString*) getResponseType
{
    return (NSString*)[demoProperties objectForKey:@"authorize_response_type"];
}

- (NSString*) getClientId
{
    return (NSString*)[demoProperties objectForKey:@"authorize_client_id"];
}

- (NSString*) getScope
{
    return (NSString*)[demoProperties objectForKey:@"authorize_scope"];
}

- (NSString*) getRedirectUri
{
    return (NSString*)[demoProperties objectForKey:@"authorize_redirect_uri"];
}

- (NSString*) getWebserviceUrl
{
    return (NSString*)[demoProperties objectForKey:@"webservice_url"];
}

- (NSString*) getData {
    return _data;
}

- (void) setData:(NSString*)newdata
{
    _data = newdata;
}

- (void) addData:(NSString*)newdata
{
    if (_data != nil) {
        _data = [NSString stringWithFormat:@"%@%@", _data, newdata];
    } else {
        _data = newdata;
    }
    
}
- (NSString*) resetData
{
    _data = @"";
    return _data;
}
                  

- (BOOL) isDebugLogEnabled
{
    NSString *level = (NSString*)[demoProperties objectForKey:@"logging"];
    if ([level isEqualToString:@"debug"]) {
        return TRUE;
    }
    
    return self.isTraceLogEnabled;
}

- (BOOL) isTraceLogEnabled
{
    NSString *level = (NSString*)[demoProperties objectForKey:@"logging"];
    if ([level isEqualToString:@"trace"]) {
        return TRUE;
    }
    return FALSE;
}
@end