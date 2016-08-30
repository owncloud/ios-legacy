//
//  WebViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 08/10/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController<UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *navigationTitleString;

@end
