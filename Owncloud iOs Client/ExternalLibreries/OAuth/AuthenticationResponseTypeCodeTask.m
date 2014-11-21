/**
 * SURFnetConextIOSClient AuthenticationResponseTypeCodeTask
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

#import "AuthenticationResponseTypeCodeTask.h"
#import "AuthenticationDbService.h"

@implementation AuthenticationResponseTypeCodeTask

- (NSString*)getUrl
{
    AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
    
    NSString *authorize_url= [dbService getAuthorizeUrl];
    NSString *response_type = [dbService getResponseType];
    NSString *client_id = [dbService getClientId];
    NSString *scope = [dbService getScope];
    NSString *redirect_uri = [dbService getRedirectUri];
    
    NSString *full_token_url = [NSString stringWithFormat:@"%@?response_type=%@&client_id=%@&scope=%@&redirect_uri=%@", authorize_url, response_type, client_id, scope, redirect_uri];
    
    DLog(@"%@", full_token_url);
    
    return full_token_url;
}

- (void)executeRetrieveTask
{
    NSURL *url = [NSURL URLWithString:self.getUrl];
    [[UIApplication sharedApplication] openURL:url];
}

@end
