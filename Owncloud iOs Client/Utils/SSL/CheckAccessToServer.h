//
//  CheckAccessToServer.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 8/21/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CheckAccessToServerDelegate

typedef enum {
    sslStatusNotChecked = 0, //Available for streaming because this status should change quickly when the user open the app or change the tab
    sslStatusSelfSigned = 1, //Not available for streaming
    sslStatusSignedOrNotSSL = 2 //Available for streaming
} enumSslStatus;

@optional
-(void)connectionToTheServer:(BOOL)isConnection;
-(void)repeatTheCheckToTheServer;
-(void)badCertificateNoAcceptedByUser;
@end

@interface CheckAccessToServer : NSObject <UIAlertViewDelegate, NSURLSessionTaskDelegate, NSURLSessionDelegate> {
    __weak id<CheckAccessToServerDelegate> _delegate;
}

@property (nonatomic, weak) __weak id<CheckAccessToServerDelegate> delegate;
@property (nonatomic, strong) NSString *urlStatusCheck;
@property (nonatomic, strong) UIViewController *viewControllerToShow;
@property (nonatomic, strong) NSString *urlUserToCheck;
@property NSInteger sslStatus;
@property BOOL isSameCertificateSelfSigned;

+ (id)sharedManager;
- (void) isConnectionToTheServerByUrl:(NSString *) url;
- (void)isConnectionToTheServerByUrl:(NSString *) url withTimeout:(NSInteger) timeout;
- (BOOL) isNetworkIsReachable;
- (void)createFolderToSaveCertificates;
- (void)saveCertificate:(SecTrustRef) trust withName:(NSString *) certName;
- (BOOL) isTemporalCertificateTrusted;
- (void) acceptCertificate;
- (void) askToAcceptCertificate;
- (NSInteger) getSslStatus;

@end

