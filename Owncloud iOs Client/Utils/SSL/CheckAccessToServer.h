//
//  CheckAccessToServer.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 8/21/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol CheckAccessToServerDelegate

@optional
-(void)connectionToTheServer:(BOOL)isConnection;
-(void)repeatTheCheckToTheServer;
-(void)badCertificateNoAcceptedByUser;
@end

@interface CheckAccessToServer : NSObject <UIAlertViewDelegate, NSURLConnectionDataDelegate> {
    __weak id<CheckAccessToServerDelegate> _delegate;
}


- (void) isConnectionToTheServerByUrl:(NSString *) url;
- (BOOL) isNetworkIsReachable;
- (NSString *) getConnectionToTheServerByUrlAndCheckTheVersion:(NSString *)url;
- (void)createFolderToSaveCertificates;
- (void)saveCertificate:(SecTrustRef) trust withName:(NSString *) certName;


@property (nonatomic, weak) __weak id<CheckAccessToServerDelegate> delegate;
@property (nonatomic, strong) NSString *urlStatusCheck;
@property (nonatomic, strong) UIViewController *viewControllerToShow;
@property (nonatomic, strong) NSString *urlUserToCheck;


@end

