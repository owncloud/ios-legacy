//
//  UIAlertView+Blocks.m
//  UIAlertViewBlocks
//
//  Created by Ryan Maxwell on 29/08/13.
//  Copyright (c) 2013 Ryan Maxwell. All rights reserved.
//

#import "UIAlertView+Blocks.h"

#import <objc/runtime.h>

static const void *UIAlertViewOriginalDelegateKey                   = &UIAlertViewOriginalDelegateKey;

static const void *UIAlertViewTapBlockKey                           = &UIAlertViewTapBlockKey;
static const void *UIAlertViewWillPresentBlockKey                   = &UIAlertViewWillPresentBlockKey;
static const void *UIAlertViewDidPresentBlockKey                    = &UIAlertViewDidPresentBlockKey;
static const void *UIAlertViewWillDismissBlockKey                   = &UIAlertViewWillDismissBlockKey;
static const void *UIAlertViewDidDismissBlockKey                    = &UIAlertViewDidDismissBlockKey;
static const void *UIAlertViewCancelBlockKey                        = &UIAlertViewCancelBlockKey;
static const void *UIAlertViewShouldEnableFirstOtherButtonBlockKey  = &UIAlertViewShouldEnableFirstOtherButtonBlockKey;

@implementation UIAlertView (Blocks)

+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
                style:(UIAlertViewStyle)style
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles
             tapBlock:(UIAlertViewCompletionBlock)tapBlock {
    
    UIAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                                delegate:nil
                                       cancelButtonTitle:cancelButtonTitle
                                       otherButtonTitles:nil];
    
    alertView.alertViewStyle = style;
    
    for (NSString *buttonTitle in otherButtonTitles) {
        [alertView addButtonWithTitle:buttonTitle];
    }
    
    if (tapBlock) {
        alertView.tapBlock = tapBlock;
    }
    
    [alertView show];
#if !__has_feature(objc_arc)
    [alertView release];
#endif
    
}


+ (void)showWithTitle:(NSString *)title
              message:(NSString *)message
    cancelButtonTitle:(NSString *)cancelButtonTitle
    otherButtonTitles:(NSArray *)otherButtonTitles
             tapBlock:(UIAlertViewCompletionBlock)tapBlock {
    
    [self showWithTitle:title
                message:message
                  style:UIAlertViewStyleDefault
      cancelButtonTitle:cancelButtonTitle
      otherButtonTitles:otherButtonTitles
               tapBlock:tapBlock];
}

#pragma mark -

- (void)_checkAlertViewDelegate {
    if (self.delegate != (id<UIAlertViewDelegate>)self) {
        objc_setAssociatedObject(self, UIAlertViewOriginalDelegateKey, self.delegate, OBJC_ASSOCIATION_ASSIGN);
        self.delegate = (id<UIAlertViewDelegate>)self;
    }
}

- (UIAlertViewCompletionBlock)tapBlock {
    return objc_getAssociatedObject(self, UIAlertViewTapBlockKey);
}

- (void)setTapBlock:(UIAlertViewCompletionBlock)tapBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewTapBlockKey, tapBlock, OBJC_ASSOCIATION_COPY);
}

- (UIAlertViewCompletionBlock)willDismissBlock {
    return objc_getAssociatedObject(self, UIAlertViewWillDismissBlockKey);
}

- (void)setWillDismissBlock:(UIAlertViewCompletionBlock)willDismissBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewWillDismissBlockKey, willDismissBlock, OBJC_ASSOCIATION_COPY);
}

- (UIAlertViewCompletionBlock)didDismissBlock {
    return objc_getAssociatedObject(self, UIAlertViewDidDismissBlockKey);
}

- (void)setDidDismissBlock:(UIAlertViewCompletionBlock)didDismissBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewDidDismissBlockKey, didDismissBlock, OBJC_ASSOCIATION_COPY);
}

- (UIAlertViewBlock)willPresentBlock {
    return objc_getAssociatedObject(self, UIAlertViewWillPresentBlockKey);
}

- (void)setWillPresentBlock:(UIAlertViewBlock)willPresentBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewWillPresentBlockKey, willPresentBlock, OBJC_ASSOCIATION_COPY);
}

- (UIAlertViewBlock)didPresentBlock {
    return objc_getAssociatedObject(self, UIAlertViewDidPresentBlockKey);
}

- (void)setDidPresentBlock:(UIAlertViewBlock)didPresentBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewDidPresentBlockKey, didPresentBlock, OBJC_ASSOCIATION_COPY);
}

- (UIAlertViewBlock)cancelBlock {
    return objc_getAssociatedObject(self, UIAlertViewCancelBlockKey);
}

- (void)setCancelBlock:(UIAlertViewBlock)cancelBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewCancelBlockKey, cancelBlock, OBJC_ASSOCIATION_COPY);
}

- (void)setShouldEnableFirstOtherButtonBlock:(BOOL(^)(UIAlertView *alertView))shouldEnableFirstOtherButtonBlock {
    [self _checkAlertViewDelegate];
    objc_setAssociatedObject(self, UIAlertViewShouldEnableFirstOtherButtonBlockKey, shouldEnableFirstOtherButtonBlock, OBJC_ASSOCIATION_COPY);
}

- (BOOL(^)(UIAlertView *alertView))shouldEnableFirstOtherButtonBlock {
    return objc_getAssociatedObject(self, UIAlertViewShouldEnableFirstOtherButtonBlockKey);
}

#pragma mark - UIAlertViewDelegate

- (void)willPresentAlertView:(UIAlertView *)alertView {
    UIAlertViewBlock block = alertView.willPresentBlock;
    
    if (block) {
        block(alertView);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(willPresentAlertView:)]) {
        [originalDelegate willPresentAlertView:alertView];
    }
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
    UIAlertViewBlock block = alertView.didPresentBlock;
    
    if (block) {
        block(alertView);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(didPresentAlertView:)]) {
        [originalDelegate didPresentAlertView:alertView];
    }
}


- (void)alertViewCancel:(UIAlertView *)alertView {
    UIAlertViewBlock block = alertView.cancelBlock;
    
    if (block) {
        block(alertView);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(alertViewCancel:)]) {
        [originalDelegate alertViewCancel:alertView];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIAlertViewCompletionBlock completion = alertView.tapBlock;
    
    if (completion) {
        completion(alertView, buttonIndex);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(alertView:clickedButtonAtIndex:)]) {
        [originalDelegate alertView:alertView clickedButtonAtIndex:buttonIndex];
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    UIAlertViewCompletionBlock completion = alertView.willDismissBlock;
    
    if (completion) {
        completion(alertView, buttonIndex);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)]) {
        [originalDelegate alertView:alertView willDismissWithButtonIndex:buttonIndex];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    UIAlertViewCompletionBlock completion = alertView.didDismissBlock;
    
    if (completion) {
        completion(alertView, buttonIndex);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)]) {
        [originalDelegate alertView:alertView didDismissWithButtonIndex:buttonIndex];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL(^shouldEnableFirstOtherButtonBlock)(UIAlertView *alertView) = alertView.shouldEnableFirstOtherButtonBlock;
    
    if (shouldEnableFirstOtherButtonBlock) {
        return shouldEnableFirstOtherButtonBlock(alertView);
    }
    
    id originalDelegate = objc_getAssociatedObject(self, UIAlertViewOriginalDelegateKey);
    if (originalDelegate && [originalDelegate respondsToSelector:@selector(alertViewShouldEnableFirstOtherButton:)]) {
        return [originalDelegate alertViewShouldEnableFirstOtherButton:alertView];
    }
    
    return YES;
}

@end
