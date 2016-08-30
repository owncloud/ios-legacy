//
//  CheckSSOServer.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 16/10/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>


@protocol CheckSSOServerDelegate

@optional
- (void)showSSOLoginScreen;
- (void)showSSOErrorServer;
- (void)showErrorConnection;

@end


@interface CheckSSOServer: NSObject <NSURLConnectionDelegate>

@property (nonatomic,strong) NSString *urlString;
@property (nonatomic) BOOL isSSOServer;
@property (nonatomic,weak) __weak id<CheckSSOServerDelegate> delegate;


///-----------------------------------
/// @name Check URL Server For Shibboleth
///-----------------------------------

/**
 * This method checks the URL in URLTextField in order to know if
 * is a valid SSO server.
 *
 * @warning This method uses a NSURLConnection delegate methods
 */

-(void) checkURLServerForSSOForThisPath:(NSString *)urlString;

@end
