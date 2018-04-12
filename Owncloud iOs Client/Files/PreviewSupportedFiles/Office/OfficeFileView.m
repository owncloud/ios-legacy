//
//  OffieFileViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 03/04/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OfficeFileView.h"
#import "UIColor+Constants.h"
#import "FileNameUtils.h"
#import "constants.h"
#import "Customization.h"
#import "UtilsUrls.h"

@implementation OfficeFileView

@synthesize webView=_webView;
@synthesize activityIndicator=_activityIndicator;
@synthesize isDocument=_isDocument;
@synthesize delegate=_delegate;
@synthesize isFullScreen = _isFullScreen;


CGPoint _lastContentOffset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delegate = self;
        [self addGestureRecognizer:doubleTapRecognizer];

        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        recognizer.numberOfTapsRequired = 1;
        recognizer.delegate = self;
        [recognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        [self addGestureRecognizer:recognizer];

        _isFullScreen = NO;
        _lastContentOffset = CGPointZero;
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (_webView) {
        CGRect webViewFrame = frame;
        webViewFrame.origin.x = 0;
        webViewFrame.origin.y = 0;
        _webView.frame = webViewFrame;
    }
}

///-----------------------------------
/// @name Go Back
///-----------------------------------

/**
 * Method to go back in the navigation
 */
- (void)goBack{
    
    if ([_webView canGoBack]) {
        [_webView goBack];
    }
}

///-----------------------------------
/// @name Go Forward
///-----------------------------------

/**
 * Method to go Forward in the navigation
 */
- (void)goForward{
    
    if ([_webView canGoForward]) {
        [_webView goForward];
    }
}

///-----------------------------------
/// @name Add Control Panel to Navigate
///-----------------------------------

/**
 * This method add control panel to navigate between the pages
 *
 */
- (void)addControlPanelToNavigate{
    
    //BackButton
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake(_webView.frame.size.width - 150, 10, 50, 30)];
    [backButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [backButton setTitle:@"Back" forState:UIControlStateNormal];
    
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    
    //FordwardButton
    UIButton *forwardButton = [[UIButton alloc]initWithFrame:CGRectMake(_webView.frame.size.width - 75, 10, 70, 30)];
    [forwardButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [forwardButton setTitle:@"Forwd" forState:UIControlStateNormal];
    
    [forwardButton addTarget:self action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
    
    [_webView addSubview:backButton];
    [_webView addSubview:forwardButton];
}

/*
 * Method to load a document by filePath.
 */
- (void)openOfficeFileWithPath:(NSString*)filePath andFileName: (NSString *) fileName {
        _isDocument=YES;

    [[self class] externalContentBlockingRuleListWithCompletionHandler:^(WKContentRuleList *blockList, NSError *error) {

        WKWebViewConfiguration *wkConfiguration;

        if ((blockList == nil) || (error!=nil))
        {
            return;
        }

        if ((wkConfiguration = [WKWebViewConfiguration new]) != nil)
        {

            wkConfiguration.preferences.javaScriptEnabled = NO;

            if (blockList!=nil)
            {
                [wkConfiguration.userContentController addContentRuleList:blockList];
            }

            _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:wkConfiguration];
            _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

            [self addSubview:_webView];


            NSURL *url = [NSURL fileURLWithPath:filePath];

            NSString *ext=@"";
            ext = [FileNameUtils getExtension:fileName];

            if ( [ext isEqualToString:@"CSS"] || [ext isEqualToString:@"PY"] || [ext isEqualToString:@"TEX"] || [ext isEqualToString:@"XML"] || [ext isEqualToString:@"JS"] ) {

                NSString *dataFile = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:url] encoding:NSASCIIStringEncoding];

                if (IS_IPHONE) {
                    [self.webView  loadHTMLString:[NSString stringWithFormat:@"<div style='font-size:%@;font-family:%@;'><pre>%@",k_txt_files_font_size_iphone,k_txt_files_font_family,dataFile] baseURL:[NSURL URLWithString:@"about:blank"]];
                }else{
                    [self.webView  loadHTMLString:[NSString stringWithFormat:@"<div style='font-size:%@;font-family:%@;'><pre>%@",k_txt_files_font_size_ipad,k_txt_files_font_family,dataFile] baseURL:[NSURL URLWithString:@"about:blank"]];
                }

            } else {

                [self.webView loadFileURL: url allowingReadAccessToURL:url];
            }

            [_webView setHidden:NO];
        }
    }];
}

/*
 * Method to load a link by path
 */
- (void)openLinkByPath:(NSString*)path {
    _isDocument=NO;
    
    NSURL *url = [NSURL URLWithString:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //Add the user agent
    [request addValue:[UtilsUrls getUserAgent] forHTTPHeaderField:@"User-Agent"];

    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    _webView.hidden  = NO;
    _webView.navigationDelegate = self;
    
    [_webView loadRequest:request];
}

#pragma mark - Fullscreen Methods

- (void)setIsFullscreen:(BOOL)isFullScreen {
    if (isFullScreen != _isFullScreen) {
        if (IS_IPHONE) {
            [self.delegate setFullscreenOfficeFileView:isFullScreen];
        }
    }
    _isFullScreen = isFullScreen;
}

#pragma mark - Gesture Methods

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer {
    self.isFullscreen = !self.isFullScreen;
}

- (void)handleDoubleTap:(UIGestureRecognizer *)recognizer {
    // nothing to do
}

#pragma mark - UIGestureRecognizer Delegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]];
}

#pragma mark UIWebView Delegate methods

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DLog(@"Office webview an error happened during load");
    [_activityIndicator stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    DLog(@"Office webview loading started");
    
    if (_activityIndicator == nil) {
        _activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.center = CGPointMake(_webView.frame.size.width/2, _webView.frame.size.height/2);
        [_webView addSubview:_activityIndicator];
    }
    _activityIndicator.center = CGPointMake(_webView.frame.size.width/2, _webView.frame.size.height/2);
    [_activityIndicator startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    DLog(@"webViewDidFinishLoad");
    [_activityIndicator stopAnimating];
    
    [_webView setHidden:NO];

    if (_isDocument == NO) {
        [_delegate finishLinkLoad];        
    }
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    if ([navigationAction navigationType] == WKNavigationTypeOther) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.isFullscreen = _lastContentOffset.y <= scrollView.contentOffset.y;
    _lastContentOffset = scrollView.contentOffset;
}

+ (void)externalContentBlockingRuleListWithCompletionHandler:(void(^)(WKContentRuleList *blockList, NSError *error))completionHandler
{
    static dispatch_once_t onceToken;
    static WKContentRuleList *contentRuleList = nil;
    static NSError *contentError = nil;
    static dispatch_queue_t serialQueue;

    dispatch_once(&onceToken, ^{
        NSData *blockRulesJSONData;
        NSString *blockRulesJSONString;
        NSArray *blockRulesArray = @[

                                     @{
                                         @"trigger" : @{
                                                 @"url-filter" : @".*"
                                                 },

                                         @"action" : @{
                                                 @"type" : @"ignore-previous-rules"
                                                 }
                                         },

                                     @{
                                         @"trigger" : @{
                                                 @"url-filter" : @"^file\\:.*"
                                                 },

                                         @"action" : @{
                                                 @"type" : @"ignore-previous-rules"
                                                 }
                                         },

                                     @{
                                         @"trigger" : @{
                                                 @"url-filter" : @"^x\\-apple.*\\:.*"
                                                 },

                                         @"action" : @{
                                                 @"type" : @"ignore-previous-rules"
                                                 }
                                         }
                                     ];

        serialQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL);

        dispatch_suspend(serialQueue);

        if ((blockRulesJSONData = [NSJSONSerialization dataWithJSONObject:blockRulesArray options:NSJSONWritingPrettyPrinted error:nil]) != nil)
        {
            if ((blockRulesJSONString = [[NSString alloc] initWithData:blockRulesJSONData encoding:NSUTF8StringEncoding]) != nil)
            {
                [[WKContentRuleListStore defaultStore] compileContentRuleListForIdentifier:@"ContentBlockingRules" encodedContentRuleList:blockRulesJSONString completionHandler:^(WKContentRuleList *blockList, NSError *error) {
                    contentRuleList = blockList;
                    contentError = error;

                    dispatch_resume(serialQueue);
                }];
            }
        }
    });

    dispatch_async(serialQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler != nil)
            {
                completionHandler(contentRuleList, contentError);
            }
        });
    });
}

@end
