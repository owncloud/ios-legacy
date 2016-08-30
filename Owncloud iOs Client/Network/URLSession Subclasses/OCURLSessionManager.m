//
//  OCURLSessionManager.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 05/06/14.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "OCURLSessionManager.h"
#import "AppDelegate.h"
#import "ManageAppSettingsDB.h"
#import "CheckAccessToServer.h"
#import "UtilsUrls.h"

static NSString *const tmpFileName = @"tmp.der";

@implementation OCURLSessionManager
 
/*
 *  Delegate called when try to upload a file to a self signed server
 */
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    
    DLog(@"willSendRequestForAuthenticationChallenge");
    
    BOOL trusted = NO;
    SecTrustRef trust;
    NSURLProtectionSpace *protectionSpace;
    
    protectionSpace = [challenge protectionSpace];
    trust = [protectionSpace serverTrust];
    
    [[CheckAccessToServer sharedManager] createFolderToSaveCertificates];
    
    if(trust != nil) {
        [[CheckAccessToServer sharedManager] saveCertificate:trust withName:tmpFileName];
        
        NSString *localCertificatesFolder = [UtilsUrls getLocalCertificatesPath];
        
        NSMutableArray *listCertificateLocation = [ManageAppSettingsDB getAllCertificatesLocation];
        
        for (int i = 0 ; i < [listCertificateLocation count] ; i++) {
            
            NSString *currentLocalCertLocation = [listCertificateLocation objectAtIndex:i];
            NSFileManager *fileManager = [ NSFileManager defaultManager];
            if([fileManager contentsEqualAtPath:[NSString stringWithFormat:@"%@%@",localCertificatesFolder,tmpFileName] andPath:[NSString stringWithFormat:@"%@",currentLocalCertLocation]]) {
                DLog(@"Is the same certificate!!!");
                trusted = YES;
            }
        }
    } else {
        trusted = NO;
    }
    
    __block NSURLCredential *credential = nil;
    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    
    if (trusted) {
        completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, credential);
    }
}

@end
