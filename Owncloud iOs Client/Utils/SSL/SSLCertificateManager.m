//
//  SSLCertificateManager.m
//  Owncloud iOs Client
//
//  Created by David A. Velasco on 29/8/17.
//
//

#import <Foundation/Foundation.h>

#import "SSLCertificateManager.h"

#import <openssl/x509.h>
#import <openssl/bio.h>
#import <openssl/err.h>
#include <openssl/pem.h>

#import "ManageAppSettingsDB.h"
#import "UtilsUrls.h"


static NSString *const tmpFileName = @"tmp.der";

@implementation SSLCertificateManager

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



- (BOOL) isTrustedServerCertificateIn:(NSURLAuthenticationChallenge *)challenge {
    BOOL trusted = NO;
    SecTrustRef trust;
    NSURLProtectionSpace *protectionSpace;
    
    protectionSpace = [challenge protectionSpace];
    trust = [protectionSpace serverTrust];
    
    if(trust != nil) {
        [self saveCertificate:trust withName:tmpFileName];
        
        NSString *localCertificatesFolder = [UtilsUrls getLocalCertificatesPath];
        
        NSMutableArray *listCertificateLocation = [ManageAppSettingsDB getAllCertificatesLocation];
        
        for (int i = 0 ; i < [listCertificateLocation count] ; i++) {
            
            NSString *currentLocalCertLocation = [listCertificateLocation objectAtIndex:i];
            NSFileManager *fileManager = [ NSFileManager defaultManager];
            if([fileManager contentsEqualAtPath:[NSString stringWithFormat:@"%@%@",localCertificatesFolder,tmpFileName] andPath:[NSString stringWithFormat:@"%@",currentLocalCertLocation]]) {
                DLog(@"Is the same certificate!!!");
                trusted = YES;
                break;
            }
        }
    }
    
    return trusted;
}


- (BOOL) isCurrentCertificateTrusted {
    
    BOOL trusted = NO;
    
    NSString *localCertificatesFolder = [UtilsUrls getLocalCertificatesPath];
    
    NSMutableArray *listCertificateLocation = [ManageAppSettingsDB getAllCertificatesLocation];
    
    for (int i = 0 ; i < [listCertificateLocation count] ; i++) {
        
        NSString *currentLocalCertLocation = [listCertificateLocation objectAtIndex:i];
        NSFileManager *fileManager = [ NSFileManager defaultManager];
        if([fileManager contentsEqualAtPath:[NSString stringWithFormat:@"%@%@",localCertificatesFolder,tmpFileName] andPath:[NSString stringWithFormat:@"%@",currentLocalCertLocation]]) {
            DLog(@"Is the same certificate!!!");
            trusted = YES;
            break;
        }
    }
    
    return trusted;
}



- (void) trustCurrentCertificate {
    
    NSString *localCertificatesFolder = [UtilsUrls getLocalCertificatesPath];
    
    NSError * err = NULL;
    NSFileManager * fm = [[NSFileManager alloc] init];
    
    NSDate *date = [NSDate date];
    NSString *currentCertLocation = [NSString stringWithFormat:@"%@%f.der",localCertificatesFolder, [date timeIntervalSince1970]];
    
    DLog(@"currentCertLocation: %@", currentCertLocation);
    
    BOOL result = [fm moveItemAtPath:[NSString stringWithFormat:@"%@%@",localCertificatesFolder, tmpFileName] toPath:currentCertLocation error:&err];
    if(!result) {
        DLog(@"Error: %@", [err localizedDescription]);
    } else {
        [ManageAppSettingsDB insertCertificate:[NSString stringWithFormat:@"%f.der", [date timeIntervalSince1970]]];
        
    }
    
}

- (void)saveCertificate:(SecTrustRef) trust withName:(NSString *) certName {
    
    [self createFolderToSaveCertificates];
    
    SecCertificateRef currentServerCert = SecTrustGetLeafCertificate(trust);
    
    CFDataRef data = SecCertificateCopyData(currentServerCert);
    X509 *x509cert = NULL;
    if (data) {
        BIO *mem = BIO_new_mem_buf((void *)CFDataGetBytePtr(data), (int)CFDataGetLength(data));
        x509cert = d2i_X509_bio(mem, NULL);
        BIO_free(mem);
        CFRelease(data);
        
        if (!x509cert) {
            DLog(@"OpenSSL couldn't parse X509 Certificate");
            
        } else {
            
            NSString *localCertificatesFolder = [UtilsUrls getLocalCertificatesPath];
            
            certName = [NSString stringWithFormat:@"%@%@",localCertificatesFolder,certName];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:certName]) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:certName error:&error];
            }
            
            FILE *file;
            file = fopen( [certName UTF8String], "w" );
            if (file) {
                PEM_write_X509(file, x509cert);
            }
            fclose(file);
            
        }
        
    } else {
        DLog(@"Failed to retrieve DER data from Certificate Ref");
    }
    //Free
    X509_free(x509cert);
}

- (void)createFolderToSaveCertificates {
    NSString *documentsDirectory = [UtilsUrls getOwnCloudFilePath]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"Certificates"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        NSError *error = nil;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
        
        DLog(@"Error: %@", [error localizedDescription]);
    }
}

static SecCertificateRef SecTrustGetLeafCertificate(SecTrustRef trust)
// Returns the leaf certificate from a SecTrust object (that is always the
// certificate at index 0).
{
    SecCertificateRef   result;
    
    assert(trust != NULL);
    
    if (SecTrustGetCertificateCount(trust) > 0) {
        result = SecTrustGetCertificateAtIndex(trust, 0);
        assert(result != NULL);
    } else {
        result = NULL;
    }
    return result;
}



@end
