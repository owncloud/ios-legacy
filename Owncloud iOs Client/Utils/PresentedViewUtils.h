//
//  PresentedViewUtils.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez  on 30/5/17.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@interface PresentedViewUtils : NSObject

+ (UIViewController *) getPresentedViewControllerInWindow: (UIWindow *)window;
+ (BOOL) isSSOViewControllerPresentedInWindow: (UIWindow *)window withPassCodeVisible: (BOOL) isPasscodeVisible;
+ (BOOL) isSSOViewControllerPresentedAndLoading: (UIWindow *) window;

@end
