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

#import <Foundation/Foundation.h>

@interface AuthenticationDbService : NSObject {

    NSString * _authorization_code;
    NSString * _access_token;
    NSString * _token_type;
    NSString * _refresh_token;
    NSInteger * _expires_in;

    NSDictionary * demoProperties;
    NSString * _data;
}

+ (id)sharedInstance;

- (NSString*) getAuthorizeUrl;

- (NSString*) getAuthorizationCode;
- (void) setAuthorizationCode:(NSString*)authorization_code;

- (NSString*) getAccessToken;
- (void) setAccessToken:(NSString*)access_token;

- (NSString*) getTokenType;
- (void) setTokenType:(NSString*)token_type;

- (NSString*) getRefreshToken;
- (void) setRefreshToken:(NSString*)refresh_token;

- (NSInteger*) getExpiresIn;
- (void) setExpiresIn:(NSInteger*)expires_in;

- (NSString*) getScheme;
- (NSString*) getTokenUrl;
- (NSString*) getGrantType;
- (NSString*) getResponseType;
- (NSString*) getClientId;
- (NSString*) getScope;
- (NSString*) getRedirectUri;
- (NSString*) getWebserviceUrl;

- (NSString*) getData;
- (void) setData:(NSString*)newdata;
- (void) addData:(NSString*)newdata;
- (NSString*) resetData;


- (BOOL) isDebugLogEnabled;
- (BOOL) isTraceLogEnabled;

@end
