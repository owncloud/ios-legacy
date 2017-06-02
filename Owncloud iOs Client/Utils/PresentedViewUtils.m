//
//  PresentedViewUtils.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez  on 30/5/17.
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "PresentedViewUtils.h"
#import "SSOViewController.h"

@implementation PresentedViewUtils

+ (UIViewController *) getPresentedViewControllerInViewController: (UIViewController *) viewController {
    UIViewController *presentedVC = viewController;
    
    while (presentedVC.presentedViewController != nil) {
        presentedVC = presentedVC.presentedViewController;
    }
    
    return presentedVC;
}

+ (UIViewController *) getPresentedViewControllerInWindow: (UIWindow *)window {
    UIViewController *presentedVC = window.rootViewController;
    
    presentedVC = [self getPresentedViewControllerInViewController:presentedVC];
    
    if ([presentedVC isKindOfClass:[UINavigationController class]]){
        UINavigationController *navigationVC = (UINavigationController *) presentedVC;
        if (navigationVC.viewControllers[0] != nil) {
            presentedVC = [self getPresentedViewControllerInViewController:navigationVC.viewControllers[0]];
        }
    }
    
    return presentedVC;
}

+ (BOOL) isSSOViewControllerPresentedInWindow: (UIWindow *)window withPassCodeVisible: (BOOL) isPasscodeVisible{
    
    BOOL isSSOViewControllerPresented = false;
    
    UIViewController *presentedVC = [self getPresentedViewControllerInWindow:window];
    
    NSArray *childViewControllers;
    
    if (isPasscodeVisible) {
        childViewControllers = presentedVC.presentingViewController.childViewControllers;
    } else {
        childViewControllers = presentedVC.childViewControllers;
    }
    
    for (UIViewController *child in childViewControllers) {
        if ([child isKindOfClass:[SSOViewController class]]){
            isSSOViewControllerPresented = true;
        }
    }
    return isSSOViewControllerPresented;
}

+ (BOOL) isSSOViewControllerPresentedAndLoading: (UIWindow *) window {
    
    BOOL isSSOViewControllerAndLoading = false;
    
    UIViewController *presentedVC = [self getPresentedViewControllerInWindow:window];
    
    if ([presentedVC isKindOfClass:[SSOViewController class]]) {
        SSOViewController *SSOVC = (SSOViewController *) presentedVC;
        if (SSOVC.isLoading == true) {
            isSSOViewControllerAndLoading = true;
        }
    }
    
    return isSSOViewControllerAndLoading;
    
}

@end
