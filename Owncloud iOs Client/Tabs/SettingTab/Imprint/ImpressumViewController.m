//
//  ImpressumViewController.m
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 2/7/13.
//


/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ImpressumViewController.h"
#import "AppDelegate.h"
#import "UIColor+Constants.h"
#import "Customization.h"
#import "UtilsUrls.h"

@interface ImpressumViewController ()

@end

@implementation ImpressumViewController

@synthesize previewWebView = _previewWebView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.currentViewVisible = self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib
    
    [self.navigationItem setTitle:NSLocalizedString(@"imprint_button", nil)];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"ok", nil) style:UIBarButtonItemStylePlain target:self action:@selector(removeView)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    _previewWebView.delegate = self;
    _previewWebView.hidden=NO;
    
    [_previewWebView setScalesPageToFit:YES];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Impressum" ofType:@"rtf"];
    
    NSURL *targetURL = [NSURL fileURLWithPath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:targetURL];
    [request setHTTPShouldHandleCookies:false];
    
    //Add the user agent
    [request addValue:[UtilsUrls getUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    [_previewWebView loadRequest:request];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)removeView {
    [self.navigationController popToRootViewControllerAnimated:NO];
    //iOS6
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIWebView Delegate methods

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLog(@"An error happened during load");
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    DLog(@"loading started");
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    DLog(@"webViewDidFinishLoad");    
}

@end
