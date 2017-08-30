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



@end
