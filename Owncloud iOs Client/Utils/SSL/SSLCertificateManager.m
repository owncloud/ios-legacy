//
//  SSLCertificateManager.m
//  Owncloud iOs Client
//
//  Created by David A. Velasco on 29/8/17.
//
//

#import <Foundation/Foundation.h>

#import "SSLCertificateManager.h"


@implementation SSLCertificateManager

@synthesize delegate = _delegate;

NSURLRequest * _requestToInspectCertificate;

BOOL _trusted;


- (BOOL) isUntrustedServerCertificate: (NSError*) error {
    return (
            [error.domain isEqualToString: NSURLErrorDomain]    &&
            
            (   error.code == kCFURLErrorServerCertificateUntrusted         ||
                error.code == kCFURLErrorServerCertificateHasBadDate        ||
                error.code == kCFURLErrorServerCertificateHasUnknownRoot    ||
                error.code == kCFURLErrorServerCertificateNotYetValid
             )
            );
}


- (void) isAcceptedCertificateIn:(NSURLRequest *) request {
    _requestToInspectCertificate = request;
    _trusted = NO;
    
    //We make a NSURLConnection to detect if we receive an authentication challenge
    [NSURLConnection connectionWithRequest:request delegate:self];
    
}


#pragma mark NSURLConnection Delegate Methods


- (void) connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        NSString* inspectedHost = [_requestToInspectCertificate URL].host;
        
        /// TODO check if certificate corresponds to known certificates
        
        if ([challenge.protectionSpace.host isEqualToString:inspectedHost]) {
            NSLog(@"trusting connection to host %@", challenge.protectionSpace.host);
            
            _trusted = YES; // TODO - fix; can be only the first time
            
            // TRUST -> after this, we expect a success on didReceiveResponse, BUT WHAT HAPPENS IN CASE OF REDIRECTION, OR OTHER AUTHENTICATION_CHALLEGNE, OR ERROR RESPONSE, OR OTHER ERROR??? -- KK
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
            // would it also work if [connection cancel] immediately?
            
        } else {
            
            // IF NOT
            _trusted = NO;
            
            NSLog(@"Not trusting connection to host %@", challenge.protectionSpace.host);
        }
        
    } else {
        NSLog(@"WARNING: SSLCertificateManager only manages NSURLAuthenticationMethodServerTrust, received %@, will continue without credentials", challenge);
    }

    if (!_trusted) {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    
    [self finish:connection];
}

/*
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)pResponse {
    // should get here only if connection was authenticated!; otherwise would go to different delegate method ; right?
    
    [self finish:connection];

}
 */

- (void) finish:(NSURLConnection *)connection {
 
    [connection cancel];
    _requestToInspectCertificate = nil;
    
    id<SSLCertificateManagerDelegate> delegate = self.delegate;
    if(delegate) {
        [delegate certificateWasChecked:_trusted];
    }
}



@end
