//
//  OffieFileViewController.h
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

#import <UIKit/UIKit.h>

@protocol OfficeFileDelegate

@optional
- (void)finishLinkLoad;
@optional
- (void)setFullscreenOfficeFileView:(BOOL) isFullscreen;
@end


@interface OfficeFileView : UIView<UIWebViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>{
    
    UIWebView *_webView;
    UIActivityIndicatorView *_activity;
    BOOL _isDocument;
    
    __weak id<OfficeFileDelegate> _delegate;
}

@property (nonatomic,strong) UIWebView *webView;
@property (nonatomic,strong) UIActivityIndicatorView *activity;
@property (nonatomic) BOOL isDocument;
@property (nonatomic) BOOL isFullscreen;
@property(nonatomic,weak) __weak id<OfficeFileDelegate> delegate;


/*
 * Method to load a document by filePath.
 */
- (void)openOfficeFileWithPath:(NSString*)filePath andFileName: (NSString *)fileName;

/*
 * Method to load a link by path
 */
- (void)openLinkByPath:(NSString*)path;


@end
