/**
 * SURFnetConextIOSClient RetrieveRefreshAndAccessTokenTask
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

#import "RetrieveRefreshAndAccessTokenTask.h"
#import "AuthenticationDbService.h"
#import "RetrieveDataResponseTypeCodeTask.h"
#import "UserDto.h"
#import "constants.h"

#import "AppDelegate.h"


@implementation RetrieveRefreshAndAccessTokenTask

- (NSString*)getUrl
{
    AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
    
    NSString *token_url= [dbService getTokenUrl];
    NSString *grant_type = [dbService getGrantType];
    NSString *client_id = [dbService getClientId];
    NSString *redirect_uri = [dbService getRedirectUri];
    NSString *code = [dbService getAuthorizationCode];
    
    NSString *full_token_url = [NSString stringWithFormat:@"%@?grant_type=%@&client_id=%@&redirect_uri=%@&code=%@", token_url, grant_type, client_id, redirect_uri, code];
    
    DLog(@"TOKEN: %@", token_url);

    return full_token_url;
}

- (NSString*)getParameters
{
    AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
    
    NSString *grant_type = [dbService getGrantType];
    NSString *client_id = [dbService getClientId];
    NSString *redirect_uri = [dbService getRedirectUri];
    NSString *code = [dbService getAuthorizationCode];    

    NSString *full_token_param = [NSString stringWithFormat:@"grant_type=%@&client_id=%@&redirect_uri=%@&code=%@", grant_type, client_id, redirect_uri, code];
    
    return full_token_param;
}

- (void)executeRetrieveTask
{
    AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
    if (dbService.isDebugLogEnabled) {
        DLog(@"Trying to connect to %@", self.getUrl);
        DLog(@"Trying to connect with %@", self.getParameters);
    }
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.getUrl]
                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                      timeoutInterval:60.0];
    
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setHTTPBody:[self.getParameters dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    if (theConnection) {
        receivedData = [[NSMutableData alloc] init];
    } else {
        // Inform the user that the connection failed.
    }

}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
    if (dbService.isTraceLogEnabled) {
        DLog(@"didReceiveResponse");
    }
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
        if (dbService.isDebugLogEnabled) {
            DLog(@"response1 = %ld", (long)[httpResponse statusCode]);
            DLog(@"response2 = %@", [httpResponse allHeaderFields]);
        }
    }
    
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
    if (dbService.isTraceLogEnabled) {
        DLog(@"didReceiveData");
    }
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
    if (dbService.isTraceLogEnabled) {
        DLog(@"didFailWithError");
    }
    
    // inform the user
    DLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    AuthenticationDbService * dbService = [AuthenticationDbService sharedInstance];
    if (dbService.isTraceLogEnabled) {
        DLog(@"connectionDidFinishLoading");
    }
    NSError* error;
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:receivedData options:kNilOptions error:&error];
    
    NSString * access_token = [dictionary objectForKey:@"access_token"];
    if (dbService.isDebugLogEnabled) {
        DLog(@"access_token = %@", access_token);
        
        
       /*
        UserDto *userDto = [[UserDto alloc] init];
        
        
        NSString *userName = @"OAuth";
        NSString *password = access_token;
        
        userDto.url = k_default_url_server;
        userDto.username = userName;
        userDto.password = password;
        userDto.ssl = [k_default_url_server hasPrefix:@"https"];
        userDto.activeaccount = YES;
        
        [ExecuteManager insertUser:userDto];*/
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        appDelegate.oauthToken = access_token;
        [appDelegate doLoginWithOauthToken];
    }
    [dbService setAccessToken:access_token];
    
    NSString * token_type = [dictionary objectForKey:@"token_type"];
    if (dbService.isDebugLogEnabled) {
        DLog(@"token_type = %@", token_type);
    }
    [dbService setTokenType:token_type];
    
    NSString * refresh_token = [dictionary objectForKey:@"refresh_token"];
    if (refresh_token != nil) {
        if (dbService.isDebugLogEnabled) {
            DLog(@"refresh_token = %@", refresh_token);
        }
        [dbService setRefreshToken:refresh_token];
    }
    
    int expires_in = (int)[dictionary objectForKey:@"expires_in"];
    if (expires_in != 0) {
        if (dbService.isDebugLogEnabled) {
            DLog(@"expires_in = %d", expires_in);
        }
        NSInteger expiresin = [[NSNumber numberWithInt:expires_in] integerValue];
        [dbService setExpiresIn:(NSInteger*)expiresin];
    }
    
    NSString * scope = [dictionary objectForKey:@"scope"];
    if (scope != nil) {
        if (dbService.isDebugLogEnabled) {
            DLog(@"scope = %@", scope);
        }
    }
    
    

    /*RetrieveDataResponseTypeCodeTask *task = [[RetrieveDataResponseTypeCodeTask alloc] init];
    [task executeRetrieveTask];*/
}

@end
