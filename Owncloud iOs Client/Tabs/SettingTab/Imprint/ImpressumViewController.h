//
//  ImpressumViewController.h
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

#import <UIKit/UIKit.h>

@interface ImpressumViewController : UIViewController <UIWebViewDelegate> {
   UIWebView *_previewWebView;
}

@property (nonatomic, strong) IBOutlet UIWebView *previewWebView;

@end
