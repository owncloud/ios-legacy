//
//  SSOViewController.h
//  Owncloud iOs Client
//
// This class have the methods for allow to the users login in
// Shibboleth servers
//
//
//  Created by Javier González Pérez on 17/08/13.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "ManageNetworkErrors.h"


@protocol SSODelegate

@optional
- (void)setCookieForSSO:(NSString *) cookieString andSamlUserName:(NSString*)samlUserName;
@end

@interface SSOViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate, UITextFieldDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, ManageNetworkErrorsDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) NSString *ownCloudServerUrlString;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic) BOOL isLoading;
@property (nonatomic,weak) __weak id<SSODelegate> delegate;

#pragma mark - Properties for SAML server with 401 error. Like Microsoft NTLM
//Object used to show the login alert view just once
@property (nonatomic, strong) UIAlertView *loginAlertView;
//Authentication challenge to try to do login just after hide the loginAlertView
@property (nonatomic, strong) NSURLAuthenticationChallenge *challenge;

@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *password;
//Request to repeat after make login
@property (nonatomic, strong) NSURLRequest *authRequest;

@property (nonatomic) BOOL authenticated;

@property (nonatomic, strong) NSURLConnection *connection;

//Retry link
@property (nonatomic, strong) NSString *urlStringToRetryTheWholeProcess;

//Bools to control if the credentials was shown
@property BOOL is401ErrorDetected;
@property BOOL isCredentialsWritten;

//Manage Errors
@property ManageNetworkErrors *manageNetworkErrors;

- (IBAction)cancel:(id)sender;

@end
