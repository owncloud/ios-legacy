//
//  SSOViewController.m
//  Owncloud iOs Client
//
// This class have the methods for allow to the users login in
// Shibboleth servers
//
//  Created by Javier González Pérez on 17/08/13.
//

/*
 Copyright (C) 2018, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "AppDelegate.h"
#import "SSOViewController.h"
#import "UserDto.h"
#import "ManageUsersDB.h"
#import "UIColor+Constants.h"
#import "Customization.h"
#import "UIColor+Constants.h"
#import "constants.h"
#import "OCCommunication.h"
#import "OCErrorMsg.h"
#import "UtilsFramework.h"
#import "UtilsCookies.h"
#import "ManageCookiesStorageDB.h"
#import "UIAlertView+Blocks.h"
#import "UtilsUrls.h"
#import "ManageAppSettingsDB.h"
#import "OCNavigationController.h"

//Cookie
#define k_cookie_user_value_name @"oc_username"


static NSString *const tmpFileName = @"tmp.der";


@interface SSOViewController ()

@property SSLCertificateManager* sslCertificateManager;

@end

@implementation SSOViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //We init the ManageNetworkErrors
        if (!_manageNetworkErrors) {
            _manageNetworkErrors = [ManageNetworkErrors new];
            _manageNetworkErrors.delegate = self;
        }
        
        //Init SSLCertificateManager instance to access user-accepted server certificates
        self.sslCertificateManager = [SSLCertificateManager new];
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self openLink:_urlString];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    /*UIBarButtonItem *retryButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"retry", nil) style:UIBarStyleDefault target:self action:@selector(retry:)];
    self.navigationItem.leftBarButtonItem = retryButton;*/
    
    //Set Background color
    [_webView setBackgroundColor:[UIColor colorOfWebViewBackground]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void) openLink:(NSString*) urlString {
    
    self.urlStringToRetryTheWholeProcess = urlString;
    
    NSString *connectURL =[NSString stringWithFormat:@"%@%@",urlString, k_url_webdav_server_without_last_slash];
    DLog(@"_openLink_ URL of shibbolet: %@",connectURL);
    _ownCloudServerUrlString = connectURL;
    
    NSURL *url = [NSURL URLWithString:connectURL];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:k_timeout_upload];
    
    //Add the user agent
    [request addValue:[UtilsUrls getUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    [UtilsFramework deleteAllCookies];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    _webView.delegate = self;
    [_webView setScalesPageToFit:YES];
    [_webView loadRequest:request];
}

- (void) retryOpenLink:(NSString*) urlString {
    
    self.urlStringToRetryTheWholeProcess = urlString;
    
    NSString *connectURL =[NSString stringWithFormat:@"%@%@",urlString, k_url_webdav_server];
    DLog(@"URL of shibbolet:%@",connectURL);
    _ownCloudServerUrlString = connectURL;
    
    NSURL *url = [NSURL URLWithString:connectURL];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:k_timeout_upload];
    
    //Add the user agent
    [request addValue:[UtilsUrls getUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    _webView.delegate = self;
    [_webView setScalesPageToFit:YES];
    [_webView loadRequest:request];
}

#pragma mark UIWebView Delegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    DLog(@"Did start loading: %@ auth:%d", [[request URL] absoluteString], _isCredentialsWritten);
    
    //We storage the request to use it again after make login
    self.authRequest = request;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delay) object:nil];
    [self performSelector:@selector(delay) withObject:nil afterDelay:15.0];
    
    return YES;
}

- (void) delay {
    DLog(@"_delay_ new NSURLConnection");
    //We make a NSURLConnection to detect if we receive an authentication challenge
    [NSURLConnection connectionWithRequest:self.authRequest delegate:self];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DLog(@"An error happened during load: %@", error);
    
    if ([error code] != -999) {
        [_webView setHidden:NO];
    }
    
    if ([error.domain isEqualToString: NSURLErrorDomain])
    {
        if (error.code == kCFURLErrorServerCertificateUntrusted         ||
            error.code == kCFURLErrorServerCertificateHasBadDate        ||
            error.code == kCFURLErrorServerCertificateHasUnknownRoot    ||
            error.code == kCFURLErrorServerCertificateNotYetValid)
        {
            
            if (![self.sslCertificateManager isCurrentCertificateTrusted]) {
                [self askToAcceptCertificate];
            }
          
        }
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    DLog(@"_webViewDidStartLoad_: %@", webView.request.URL.absoluteString);
    self.isLoading = true;
    
    [_webView endEditing:YES];
    
    [_webView setHidden:YES];
    
    if (_activity==nil) {
        _activity=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activity.center=CGPointMake(self.view.center.x, self.view.center.y);
        [self.view addSubview:_activity];
    }
    _activity.center=CGPointMake(self.view.center.x, self.view.center.y);
    [_activity startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    DLog(@"_webViewDidFinishLoad_");
    self.isLoading = false;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delay) object:nil];
    
    NSCachedURLResponse *resp = [[NSURLCache sharedURLCache] cachedResponseForRequest:webView.request];
    
    DLog(@"Response: %@", [(NSHTTPURLResponse*)resp.response allHeaderFields]);
    
    NSString *currentURL = webView.request.URL.absoluteString;
    DLog(@"currentURL: %@", currentURL);
    
    [_activity stopAnimating];
    [_webView setScalesPageToFit:YES];
    
    
    //Check for the reddirection to the first server
    if ([currentURL isEqualToString:_ownCloudServerUrlString]) {
        //Login is success with the third part server
        
        //Catch the cookie storage
        NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        
        //Get the cookies for specific url
        NSArray *cookiesArray = [cookieJar cookiesForURL:webView.request.URL];
        
        NSMutableString * cookieString = nil;
        cookieString = [NSMutableString new];
        
        //Loop for the cookies
        for (NSHTTPCookie * cookie in cookiesArray) {
            
            [cookie.name isEqualToString:k_cookie_user_value_name];
            
           // DLog(@"url: %@", webView.request.URL.absoluteString);
            [cookieString appendFormat:@"%@=%@;", cookie.name, cookie.value];
        }
        
        //Send to the delegate class the cookie receive from the server
        [_delegate setCookieForSSO:cookieString serverPath:_urlString];
        
        //Close this view
        [self cancel:nil];
    } else {
        [_webView setHidden:NO];
    }
}

/*
 * This method force to dismiss the keyboard automatically
 */
- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (void) connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    DLog(@"Challenge currentRequest URL: %@", connection.currentRequest.URL.absoluteString);
    
    if ([challenge previousFailureCount] == 0) {
        if (self.isCredentialsWritten && self.user && self.password) {
            //Second time. We reset the credentials to not enter here more than onceNSURLCredentialPersistenceNone
            [[challenge sender] useCredential:[NSURLCredential credentialWithUser:self.user password:self.password persistence:NSURLCredentialPersistenceNone] forAuthenticationChallenge:challenge];
            self.user = nil;
            self.password = nil;
        } else {
            //The first time. We do not have the credentials
            self.authRequest = self.webView.request;
            self.challenge = challenge;
            self.is401ErrorDetected = YES;
            [self showLoginInterface];
        }
    } else {
        
        //Error credentials
        [UIAlertView showWithTitle:NSLocalizedString(@"error_login_message", nil) message:@"" cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == [alertView cancelButtonIndex]) {
                //OK
                self.isCredentialsWritten = NO;
                self.authRequest = self.webView.request;
                self.challenge = challenge;
                self.is401ErrorDetected = YES;
                [self showLoginInterface];
            }
        }];
    }
    
//    NSLog(@"WebController Got auth challange via NSURLConnection");
//    
//    if ([challenge previousFailureCount] == 0)
//    {
//        _authenticated = YES;
//        
//        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
//        
//        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
//        
//    } else
//    {
//        [[challenge sender] cancelAuthenticationChallenge:challenge];
//    }
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    if (self.is401ErrorDetected && self.isCredentialsWritten) {
        DLog(@"self.authRequest: %@", self.authRequest.URL.absoluteString);
        self.is401ErrorDetected = NO;
        //With the right credentials we try to repeat the last request
        [_webView loadRequest:self.authRequest];
    }
    if (self.authenticated) {
        self.authenticated = NO;
        
        [_webView loadRequest:self.authRequest];
    }
   
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    DLog(@"Error connection: %@", error);
    
    //Too many HTTP redirects error. This error happens sometimes.
    if (error.code == kCFURLErrorHTTPTooManyRedirects) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"unknow_response_server", nil) message:NSLocalizedString(@"", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [alert show];
        
        [self initParemetersAndRetryOpenLink];
        
    } else if ([error.domain isEqualToString: NSURLErrorDomain]) {
        
        if (error.code == kCFURLErrorServerCertificateUntrusted         ||
            error.code == kCFURLErrorServerCertificateHasBadDate        ||
            error.code == kCFURLErrorServerCertificateHasUnknownRoot    ||
            error.code == kCFURLErrorServerCertificateNotYetValid)
        {
            
            if (![self.sslCertificateManager isCurrentCertificateTrusted]) {
                [self initParemetersAndRetryOpenLink];
            }
        }
    }
    
    
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;
{
    return NO;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    
    DLog(@"Request: %@", request.URL.absoluteString);
    DLog(@"redirectResponse: %@", redirectResponse.URL.absoluteString);
    return request;
}

#pragma mark - ManageNetworkErrorsDelegate

- (void)errorLogin {
    DLog(@"Error login");
}


- (void)showError:(NSString *) message {
    //Error credentials
    [UIAlertView showWithTitle:message message:@"" cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {

    }];
 
}

#pragma mark - Buttons
/*
 * This method close the view
 */
- (IBAction)cancel:(id)sender {
    
    [self dismissThisView];
}

- (void) dismissThisView {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
 *  This method repeat the original request that shown the initial UIWebView
 */
- (IBAction)retry:(id)sender {
    [self initParemetersAndRetryOpenLink];
}

- (void) initParemetersAndRetryOpenLink {
    self.isCredentialsWritten = NO;
    self.user = nil;
    self.password = nil;
    self.is401ErrorDetected = NO;
    [self retryOpenLink:self.urlStringToRetryTheWholeProcess];
}


#pragma mark - Credentials interface

- (void) showLoginInterface {
    
    if (!_loginAlertView || ![_loginAlertView isVisible]) {
        _loginAlertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"go_to_login", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:NSLocalizedString(@"login", nil), nil];
        _loginAlertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        [[_loginAlertView textFieldAtIndex:0] setAutocorrectionType:UITextAutocorrectionTypeNo];
        [[_loginAlertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        
        [_loginAlertView show];
    }
}

#pragma mark - UIalertViewDelegate

- (void) alertView: (UIAlertView *) alertView willDismissWithButtonIndex: (NSInteger) buttonIndex {
    // cancel
    if(alertView.tag != 2) {
        switch (buttonIndex) {
            case 0:
                //Cancel
                [self openLink:_urlString];
                break;
            case 1: {
                //Do login with the credendial
                self.isCredentialsWritten = YES;
                self.user = [_loginAlertView textFieldAtIndex:0].text;
                self.password = [_loginAlertView textFieldAtIndex:1].text;
                
                //After make login we send the credential to the request
                [[self.challenge sender] useCredential:[NSURLCredential credentialWithUser:self.user password:self.password persistence:NSURLCredentialPersistenceNone] forAuthenticationChallenge:self.challenge];
            }
                break;
            default:
                break;
        }
    }
}

/*
 *  Method to active or not the login button
 */
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL output = NO;

    if (alertView.tag !=2) {
        NSString *username = [alertView textFieldAtIndex:0].text;
        NSString *password = [alertView textFieldAtIndex:1].text;
    
        if ([username length] > 0 && [password length] > 0) {
            output = YES;
        }
    } else {
        output = YES;
    }
    return output;
}


#pragma NSURLConnectionDelegate

-(void) connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    NSLog(@"willSendRequestForAuthenticationChallenge");
    
    BOOL trusted = [self.sslCertificateManager isTrustedServerCertificateIn:challenge];
        
    if (trusted) {
        self.authenticated = YES;
        
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        
    } else {
        [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            DLog(@"user pressed YES");
            [self.sslCertificateManager trustCurrentCertificate];
        } else {
            NSLog(@"user pressed CANCEL");
            [self dismissThisView];
        }
    }
}


- (void) askToAcceptCertificate {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Your main thread code goes in here
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"invalid_ssl_cert", nil) delegate: self cancelButtonTitle:NSLocalizedString(@"no", nil) otherButtonTitles:NSLocalizedString(@"yes", nil), nil];
        alert.tag = 2;
        [alert show];
    });
}




#pragma mark - navigation

- (void) navigateFrom:(UIViewController *)currentVC {

    OCNavigationController *navController = [[OCNavigationController alloc] initWithRootViewController:self];

    //Check if is iPhone or iPad
    if (!IS_IPHONE) {
        //iPad
        navController.modalTransitionStyle=UIModalTransitionStyleCoverVertical;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [currentVC presentViewController:navController animated:YES completion:nil];
    
}




@end
