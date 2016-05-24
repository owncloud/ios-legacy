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
#import "OCFrameworkConstants.h"

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
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:k_timeout_webdav];
    [request setHTTPShouldHandleCookies:NO];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    //Configure connectionSession
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    //If there is a redireccion
    if (response) {
        DLog(@"redirecction");
        NSInteger statusCode = [response statusCode];
        DLog(@"HTTP status %ld", (long)statusCode);
        
        if (k_is_sso_active && (statusCode == k_redirected_code_1 || statusCode == k_redirected_code_2 || statusCode == k_redirected_code_3)) {
            //sso login error
            DLog(@"redirection with saml");
            //We get all the headers in order to obtain the Location
            NSDictionary *dict = [response allHeaderFields];
            
            //Server path of redirected server
            NSString *responseURLString = [dict objectForKey:@"Location"];
            DLog(@"Shibboleth redirected server is: %@", responseURLString);
            
            if ([FileNameUtils isURLWithSamlFragment:responseURLString]) {
                _isSSOServer = YES;
                [_delegate showSSOLoginScreen];
            }
            
        }
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    completionHandler(NSURLSessionAuthChallengeUseCredential,[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (error) {
        DLog(@"Error checking SAML: %@", error);
        [self.delegate showErrorConnection];
    } else {
        if (!self.isSSOServer) {
            [self.delegate showSSOErrorServer];
        }
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    DLog(@"Error checking SAML: %@", error);
    [self.delegate showErrorConnection];
}


/* The task has received a request specific authentication challenge.
 * If this delegate is not implemented, the session specific authentication challenge
 * will *NOT* be called and the behavior will be the same as using the default handling
 * disposition.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler {
    
}

/* Sent if a task requires a new, unopened body stream.  This may be
 * necessary when authentication has failed for any request that
 * involves a body stream.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream * __nullable bodyStream))completionHandler {
    
}

/* Sent periodically to notify the delegate of upload progress.  This
 * information is also available as properties of the task.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
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
/*
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
}*/



@end
