//
//  CheckShibbolethServer.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 16/10/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "CheckSSOServer.h"
#import "Customization.h"
#import "FileNameUtils.h"
#import "UtilsUrls.h"
#import "OCConstants.h"

@implementation CheckSSOServer

///-----------------------------------
/// @name Check URL Server For Shibboleth
///-----------------------------------

/**
 * This method checks the URL in URLTextField in order to know if
 * is a valid SSO server.
 *
 * @warning This method uses a NSURLConnection delegate methods
 */

-(void) checkURLServerForSSOForThisPath:(NSString *)urlString {
    
    //Set boolean
    _isSSOServer = NO;
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:40.0];
    [request setHTTPShouldHandleCookies:NO];
    
    //Add the user agent
    [request addValue:[UtilsUrls getUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    // Create url connection and fire request
    [NSURLConnection connectionWithRequest:request delegate:self];
    
}

#pragma mark NSURLConnection Delegate Methods

/*- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
 // A response has been received, this is where we initialize the instance var you created
 // so that we can append data to it in the didReceiveData method
 // Furthermore, this method is called each time there is a redirect so reinitializing it
 // also serves to clear it
 }*/

/* -(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
 // Append the new data to the instance variable you declared
 
 }*/

/*- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
 willCacheResponse:(NSCachedURLResponse*)cachedResponse {
 // Return nil to indicate not necessary to store a cached response for this connection
 return nil;
 }*/

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    if (!_isSSOServer) {
        [_delegate showSSOErrorServer];
    }
}

///-----------------------------------
/// @name Conection Fail NSURLConnection delegate method
///-----------------------------------

/**
 * Method is called when the connection fails
 * In this method the app shows an alert view with the error.
 *
 * @param connection -> NSURLConnection
 * @param error -> NSError
 *
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    DLog(@"Error checking SAML: %@", error);
    [_delegate showErrorConnection];
    
    
   
    
}

#pragma mark - Redirection protection

///-----------------------------------
/// @name Connection redirected (NSURLConnection Delegate Method)
///-----------------------------------

/**
 * This method is called when the NSURLConnection detects that
 * there is a redirecction
 *
 * @param connection -> NSURLConnection
 * @param requestRed -> NSURLRequest
 * @param redirectResponse -> NSURLResponse
 *
 * @return NSURLRequest
 *
 */
- (NSURLRequest *)connection: (NSURLConnection *)connection
             willSendRequest: (NSURLRequest *)requestRed
            redirectResponse: (NSURLResponse *)redirectResponse;
{
    //If there is a redireccion
    if (redirectResponse) {
        DLog(@"redirecction");
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) redirectResponse;
        NSInteger statusCode = [httpResponse statusCode];
        DLog(@"HTTP status %ld", (long)statusCode);
        
        if (k_is_sso_active && (statusCode == k_redirected_code_1 || statusCode == k_redirected_code_2 || statusCode == k_redirected_code_3)) {
            //sso login error
            DLog(@"redirection with saml");
            //We get all the headers in order to obtain the Location
            NSHTTPURLResponse *hr = (NSHTTPURLResponse*)redirectResponse;
            NSDictionary *dict = [hr allHeaderFields];
            
            //Server path of redirected server
            NSString *responseURLString = [dict objectForKey:@"Location"];
            DLog(@"Shibboleth redirected server is: %@", responseURLString);
            
            if ([FileNameUtils isURLWithSamlFragment:responseURLString]) {
                _isSSOServer = YES;
                [_delegate showSSOLoginScreen];
            }
            
        }
    }
    
    return requestRed;
}

// In iOS6 obligate to accept the certificates
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return YES;
}


//Handle the change on the certificate
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
}



@end
