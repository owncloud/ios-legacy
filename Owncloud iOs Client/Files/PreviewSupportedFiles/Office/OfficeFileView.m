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

@interface OfficeFileView ()

@end

@implementation OfficeFileView
@synthesize webView=_webView;
@synthesize activity=_activity;
@synthesize isDocument=_isDocument;
@synthesize delegate=_delegate;
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

        _isFullscreen = NO;
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


- (void)configureWebView{
    
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.frame];
        _webView.scrollView.delegate = self;
        [self addSubview:_webView];
    }
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

/*
 * Method to load a document by filePath.
 */
- (void)openOfficeFileWithPath:(NSString*)filePath andFileName: (NSString *) fileName {
    _isDocument=YES;
    
    [self configureWebView];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    
    NSString *ext=@"";
    ext = [FileNameUtils getExtension:fileName];
    
    if ( [ext isEqualToString:@"CSS"] || [ext isEqualToString:@"PY"] || [ext isEqualToString:@"TEX"] || [ext isEqualToString:@"XML"] || [ext isEqualToString:@"JS"] ) {
        
        NSString *dataFile = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:url] encoding:NSASCIIStringEncoding];

        if (IS_IPHONE) {
            [self.webView  loadHTMLString:[NSString stringWithFormat:@"<div style='font-size:%@;font-family:%@;'><pre>%@",k_txt_files_font_size_iphone,k_txt_files_font_family,dataFile] baseURL:nil];
        }else{
            [self.webView  loadHTMLString:[NSString stringWithFormat:@"<div style='font-size:%@;font-family:%@;'><pre>%@",k_txt_files_font_size_ipad,k_txt_files_font_family,dataFile] baseURL:nil];
        }
        
    } else if ([ext isEqualToString:@"TXT"]) {
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];

        NSMutableURLRequest *headRequest = [NSMutableURLRequest requestWithURL:url];
        [headRequest setHTTPMethod:@"HEAD"];
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:headRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [_webView loadData:[NSData dataWithContentsOfURL: url] MIMEType:response.MIMEType textEncodingName:@"utf-8" baseURL:url];
        }];
        
        [task resume];
        
    } else if ([ext isEqualToString:@"PDF"]) {
        NSURL *targetURL = [NSURL fileURLWithPath:filePath];
        NSData *pdfData = [[NSData alloc] initWithContentsOfURL:targetURL];
        [self.webView loadData:pdfData MIMEType:@"application/pdf" textEncodingName:@"utf-8" baseURL:url];
    } else {
        [self.webView loadRequest:[NSMutableURLRequest requestWithURL:url]];
    }
    
    [_webView setHidden:NO];
    [_webView setScalesPageToFit:YES];
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
    
    [self configureWebView];
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    _webView.hidden  = NO;
    _webView.delegate = self;
    
    [_webView loadRequest:request];
}

#pragma mark - Fullscreen Methods

- (void)setIsFullscreen:(BOOL)isFullscreen {
    if (isFullscreen != _isFullscreen) {
        if (IS_IPHONE) {
            [self.delegate setFullscreenOfficeFileView:isFullscreen];
        }
    }
    _isFullscreen = isFullscreen;
}

#pragma mark - Gesture Methods

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer {
    self.isFullscreen = !self.isFullscreen;
}

- (void)handleDoubleTap:(UIGestureRecognizer *)recognizer {
    // nothing to do
}

#pragma mark - UIGestureRecognizer Delegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]];
}

#pragma mark - UIWebView Delegate Methods
#pragma mark UIWebView Delegate methods

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    DLog(@"Office webview an error happened during load");
    [_activity stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    DLog(@"Office webview loading started");
    
    if (_activity == nil) {
        _activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activity.center = CGPointMake(_webView.frame.size.width/2, _webView.frame.size.height/2);
        [_webView addSubview:_activity];
    }
    _activity.center = CGPointMake(_webView.frame.size.width/2, _webView.frame.size.height/2);
    [_activity startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    DLog(@"webViewDidFinishLoad");
    [_activity stopAnimating];
    
    [_webView setHidden:NO];
    [_webView setScalesPageToFit:YES];
    
    if (_isDocument == NO) {
        [_delegate finishLinkLoad];        
    }
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.isFullscreen = _lastContentOffset.y <= scrollView.contentOffset.y;
    _lastContentOffset = scrollView.contentOffset;
}

@end
