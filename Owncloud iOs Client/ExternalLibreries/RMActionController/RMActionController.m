//
//  RMActionController.m
//  RMActionController
//
//  Created by Roland Moers on 01.05.15.
//  Copyright (c) 2015 Roland Moers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "RMActionController+Private.h"
#import <QuartzCore/QuartzCore.h>

#import "RMAction+Private.h"
#import "RMActionControllerTransition.h"
#import "NSProcessInfo+RMActionController.h"
#import "UIView+RMActionController.h"

#pragma mark - Defines

#if !__has_feature(attribute_availability_app_extension)
//Normal App
#define RM_CURRENT_ORIENTATION_IS_LANDSCAPE_PREDICATE UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)
#else
//App Extension
#define RM_CURRENT_ORIENTATION_IS_LANDSCAPE_PREDICATE [UIScreen mainScreen].bounds.size.height < [UIScreen mainScreen].bounds.size.width
#endif

#pragma mark - Interfaces

@interface RMActionController () <UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, assign, readwrite) RMActionControllerStyle style;

@property (nonatomic, strong) NSMutableArray *additionalActions;
@property (nonatomic, strong) NSMutableArray *doneActions;
@property (nonatomic, strong) NSMutableArray *cancelActions;

@property (nonatomic, strong) UIScrollView *topViewScrollView;
@property (nonatomic, strong) UIView *topContainer;
@property (nonatomic, strong) UIView *bottomContainer;

@property (nonatomic, strong) UILabel *headerTitleLabel;
@property (nonatomic, strong) UILabel *headerMessageLabel;

- (nonnull instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@end

#pragma mark - Implementations

@implementation RMActionController

@synthesize disableMotionEffects = _disableMotionEffects;

#pragma mark - Class
+ (nullable instancetype)actionControllerWithStyle:(RMActionControllerStyle)style {
    return [self actionControllerWithStyle:style selectAction:nil andCancelAction:nil];
}

+ (nullable instancetype)actionControllerWithStyle:(RMActionControllerStyle)style selectAction:(nullable RMAction *)selectAction andCancelAction:(nullable RMAction *)cancelAction {
    return [self actionControllerWithStyle:style title:nil message:nil selectAction:selectAction andCancelAction:cancelAction];
}

+ (nullable instancetype)actionControllerWithStyle:(RMActionControllerStyle)style title:(nullable NSString *)aTitle message:(nullable NSString *)aMessage selectAction:(nullable RMAction *)selectAction andCancelAction:(nullable RMAction *)cancelAction {
    return [[self alloc] initWithStyle:style title:aTitle message:aMessage selectAction:selectAction andCancelAction:cancelAction];
}

#pragma mark - Init and Dealloc
- (nonnull instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        [self setup];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(RMActionControllerStyle)aStyle title:(NSString *)aTitle message:(NSString *)aMessage selectAction:(RMAction *)selectAction andCancelAction:(RMAction *)cancelAction {
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        
        [self setup];
        
        self.style = aStyle;
        self.title = aTitle;
        self.message = aMessage;
        
        if(selectAction && cancelAction) {
            RMGroupedAction *action = [RMGroupedAction actionWithStyle:RMActionStyleDefault andActions:@[cancelAction, selectAction]];
            [self addAction:action];
        } else {
            if(cancelAction) {
                [self addAction:cancelAction];
            }
            
            if(selectAction) {
                [self addAction:selectAction];
            }
        }
    }
    return self;
}

- (void)setup {
    self.additionalActions = [NSMutableArray array];
    self.doneActions = [NSMutableArray array];
    self.cancelActions = [NSMutableArray array];
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    } else {
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    
    self.transitioningDelegate = self;
    
    [self setupUIElements];
}

- (void)setupUIElements {
    //Instantiate elements
    self.headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.headerMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    
    //Setup properties of elements
    //self.headerTitleLabel.backgroundColor = [UIColor clearColor];
    self.headerTitleLabel.textColor = [UIColor grayColor];
    self.headerTitleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
    self.headerTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.headerTitleLabel.numberOfLines = 0;
    
    //self.headerMessageLabel.backgroundColor = [UIColor clearColor];
    self.headerMessageLabel.textColor = [UIColor grayColor];
    self.headerMessageLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    self.headerMessageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerMessageLabel.textAlignment = NSTextAlignmentCenter;
    self.headerMessageLabel.numberOfLines = 0;
}

- (void)setupContainerElements {
    
    //Top container
    if(self.disableBlurEffects) {
        self.topContainer = [[UIView alloc] initWithFrame:CGRectZero];
        [self.topContainer addSubview:self.contentView];
        
        if([self.headerTitleLabel.text length] > 0) {
            [self.topContainer addSubview:self.headerTitleLabel];
        }
        
        if([self.headerMessageLabel.text length] > 0) {
            [self.topContainer addSubview:self.headerMessageLabel];
        }
        
        for(RMAction *anAction in self.additionalActions) {
            [self.topContainer addSubview:anAction.view];
        }
        
        for(RMAction *anAction in self.doneActions) {
            [self.topContainer addSubview:anAction.view];
        }
    } else {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:[self containerBlurEffectStyleForCurrentStyle]];
        UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:blur];
        
        UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        vibrancyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        if(!self.disableBlurEffectsForContentView) {
            [vibrancyView.contentView addSubview:self.contentView];
        }
        
        if([self.headerTitleLabel.text length] > 0) {
            [vibrancyView.contentView addSubview:self.headerTitleLabel];
        }
        
        if([self.headerMessageLabel.text length] > 0) {
            [vibrancyView.contentView addSubview:self.headerMessageLabel];
        }
        
        for(RMAction *anAction in self.additionalActions) {
            [vibrancyView.contentView addSubview:anAction.view];
        }
        
        for(RMAction *anAction in self.doneActions) {
            [vibrancyView.contentView addSubview:anAction.view];
        }
        
        UIVisualEffectView *container = [[UIVisualEffectView alloc] initWithEffect:blur];
        [container.contentView addSubview:vibrancyView];
        
        self.topContainer = container;
        
        if(self.disableBlurEffectsForContentView) {
            [self.topContainer addSubview:self.contentView];
        }
    }
    
    //Botoom container
    if(self.disableBlurEffects) {
        self.bottomContainer = [[UIView alloc] initWithFrame:CGRectZero];
        
        for(RMAction *anAction in self.cancelActions) {
            [self.bottomContainer addSubview:anAction.view];
        }
    } else {
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:[self containerBlurEffectStyleForCurrentStyle]];
        UIVibrancyEffect *vibrancy = [UIVibrancyEffect effectForBlurEffect:blur];
        
        UIVisualEffectView *vibrancyView = [[UIVisualEffectView alloc] initWithEffect:vibrancy];
        vibrancyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        for(RMAction *anAction in self.cancelActions) {
            [vibrancyView.contentView addSubview:anAction.view];
        }
        
        UIVisualEffectView *container = [[UIVisualEffectView alloc] initWithEffect:blur];
        [container.contentView addSubview:vibrancyView];
        
        self.bottomContainer = container;
    }
    
    //Container properties
    self.topContainer.layer.cornerRadius = [NSProcessInfo runningAtLeastiOS9] ? 12 : 4;
    self.topContainer.clipsToBounds = YES;
    self.topContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    
    
    if(!self.disableBlurEffects) {
        self.topContainer.backgroundColor = [UIColor clearColor];
    } else {
        self.topContainer.backgroundColor = [UIColor whiteColor];
    }
    
    self.bottomContainer.layer.cornerRadius = [NSProcessInfo runningAtLeastiOS9] ? 12 : 4;
    self.bottomContainer.clipsToBounds = YES;
    self.bottomContainer.translatesAutoresizingMaskIntoConstraints = NO;
    
    if(!self.disableBlurEffects) {
        self.bottomContainer.backgroundColor = [UIColor clearColor];
    } else {
        self.bottomContainer.backgroundColor = [UIColor whiteColor];
    }
    
    //Debugging Accessibility Labels
#ifdef DEBUG
    self.topContainer.accessibilityLabel = @"TopContainer";
    self.bottomContainer.accessibilityLabel = @"BottomContainer";
#endif
}

- (void)setupConstraints {
    NSDictionary *metrics = @{@"seperatorHeight": @(1.f / [[UIScreen mainScreen] scale])};
    
    UIView *topContainer = self.topContainer;
    UIView *bottomContainer = self.bottomContainer;
    
    UILabel *headerTitleLabel = self.headerTitleLabel;
    UILabel *headerMessageLabel = self.headerMessageLabel;
    
    NSDictionary *bindingsDict = NSDictionaryOfVariableBindings(topContainer, bottomContainer, headerTitleLabel, headerMessageLabel);
    
    //Container constraints
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[topContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    
    if([self.cancelActions count] <= 0) {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    } else {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(10)-[bottomContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topContainer]-(10)-[bottomContainer]-(10)-|" options:0 metrics:nil views:bindingsDict]];
    }
    
    //Top container content constraints
    __block UIScrollView *currentTopView = nil;
    __weak RMActionController *blockself = self;
    [self.doneActions enumerateObjectsUsingBlock:^(RMAction *action, NSUInteger index, BOOL *stop) {
        UIView *seperator = [UIView seperatorView];

        [self addSubview:seperator toContainer:self.topContainer];
        
        if(!currentTopView) {
            NSDictionary *bindings = @{@"actionView": action.view, @"seperator": seperator};
            
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(15)-[seperator]-(0)-|" options:0 metrics:nil views:bindings]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[seperator(seperatorHeight)]-(0)-[actionView]-(0)-|" options:0 metrics:metrics views:bindings]];
        } else {
            NSDictionary *bindings = @{@"actionView": action.view, @"seperator": seperator, @"currentTopView": currentTopView};
            
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(15)-[seperator]-(0)-|" options:0 metrics:nil views:bindings]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[seperator(seperatorHeight)]-(0)-[actionView]-(0)-[currentTopView]" options:0 metrics:metrics views:bindings]];
        }
        
        currentTopView = seperator;
    }];
    
    [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[contentView]-(0)-|" options:0 metrics:nil views:@{@"contentView": self.contentView}]];
    
    if(currentTopView) {
        [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView]-(0)-[currentTopView]" options:0 metrics:nil views:@{@"contentView": self.contentView, @"currentTopView": currentTopView}]];
    } else {
        [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[contentView]-(0)-|" options:0 metrics:nil views:@{@"contentView": self.contentView}]];
    }
    
    if([self.additionalActions count] > 0 || [self.headerMessageLabel.text length] > 0 || [self.headerTitleLabel.text length] > 0) {
        __weak RMActionController *blockself = self;
        __block UIView *currentTopView = self.contentView;
        
        [self.additionalActions enumerateObjectsUsingBlock:^(RMAction *action, NSUInteger index, BOOL *stop) {
            UIView *actionView = action.view;
            
            UIView *seperatorView = [UIView seperatorView];
            [self addSubview:seperatorView toContainer:blockself.topContainer];
            
            NSDictionary *actionBindingsDict = NSDictionaryOfVariableBindings(currentTopView, seperatorView, actionView);
            
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(15)-[seperatorView]-(0)-|" options:0 metrics:nil views:actionBindingsDict]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:actionBindingsDict]];
            [blockself.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionView]-(0)-[seperatorView(seperatorHeight)]-(0)-[currentTopView]" options:0 metrics:metrics views:actionBindingsDict]];
            
            currentTopView = actionView;
        }];
        
        if([self.headerMessageLabel.text length] > 0 || [self.headerTitleLabel.text length] > 0) {
            UIView *seperatorView = [UIView seperatorView];
            [self addSubview:seperatorView toContainer:self.topContainer];
            
            NSDictionary *bindings = NSDictionaryOfVariableBindings(seperatorView, currentTopView);
            
            [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[seperatorView]-(0)-|" options:0 metrics:nil views:bindings]];
            [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[seperatorView(seperatorHeight)]-(0)-[currentTopView]" options:0 metrics:metrics views:bindings]];
            
            currentTopView = seperatorView;
            
            if([self.headerMessageLabel.text length] > 0) {
                bindings = @{@"messageLabel": self.headerMessageLabel, @"currentTopView": currentTopView};
                
                [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(5)-[messageLabel]-(5)-|" options:0 metrics:nil views:bindings]];
                [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[messageLabel]-(10)-[currentTopView]" options:0 metrics:nil views:bindings]];
                
                currentTopView = self.headerMessageLabel;
            }
            
            if([self.headerTitleLabel.text length] > 0) {
                bindings = @{@"titleLabel": self.headerTitleLabel, @"currentTopView": currentTopView};
                NSDictionary *metrics = @{@"Margin": [currentTopView isKindOfClass:[UILabel class]] ? @(2) : @(10)};
                
                [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(5)-[titleLabel]-(5)-|" options:0 metrics:nil views:bindings]];
                [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[titleLabel]-(Margin)-[currentTopView]" options:0 metrics:metrics views:bindings]];
                
                currentTopView = self.headerTitleLabel;
            }
        }
        
        NSDictionary *metrics = @{@"Margin": (currentTopView == self.headerMessageLabel || currentTopView == self.headerTitleLabel) ? @(10) : @(0)};
        NSDictionary *bindings = NSDictionaryOfVariableBindings(currentTopView);
        
        [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(Margin)-[currentTopView]" options:0 metrics:metrics views:bindings]];
    } else  {
        [self.topContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[contentView]" options:0 metrics:nil views:@{@"contentView": self.contentView}]];
    }
    
    //Bottom container content constraints
    if([self.cancelActions count] == 1) {
        RMAction *action = [self.cancelActions lastObject];
        NSDictionary *bindings = @{@"actionView": action.view};
        
        [self.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
        [self.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
    } else if([self.cancelActions count] > 1) {
        __weak RMActionController *blockself = self;
        __block UIView *currentTopView = nil;
        
        [self.cancelActions enumerateObjectsUsingBlock:^(RMAction *action, NSUInteger index, BOOL *stop) {
            if(!currentTopView) {
                NSDictionary *bindings = @{@"actionView": action.view};
                
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
            } else {
                UIView *seperatorView = [UIView seperatorView];
                [self addSubview:seperatorView toContainer:self.bottomContainer];
                
                NSDictionary *bindings = @{@"actionView": action.view, @"currentTopView": currentTopView, @"seperator": seperatorView};
                
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[actionView]-(0)-|" options:0 metrics:nil views:bindings]];
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[seperator]-(0)-|" options:0 metrics:nil views:bindings]];
                [blockself.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionView]-(0)-[seperator(seperatorHeight)]-(0)-[currentTopView]" options:0 metrics:metrics views:bindings]];
            }
            
            currentTopView = action.view;
        }];
        
        [self.bottomContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[currentTopView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(currentTopView)]];
    }
}

- (void)setupTopContainersTopMarginConstraint {
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(10)-[topContainer]" options:0 metrics:nil views:@{@"topContainer": self.topContainer}]];
}

- (void)viewDidLoad {
    NSAssert(self.contentView != nil, @"Error: The view of an RMActionController has been loaded before a contentView has been set. You have to set the contentView before presenting a RMActionController.");
    
    [super viewDidLoad];
    
#ifdef DEBUG
    self.view.accessibilityLabel = @"ActionControllerView";
#endif
    
    self.view.translatesAutoresizingMaskIntoConstraints = YES;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.layer.masksToBounds = YES;
    
    [self setupContainerElements];
    
    if(self.modalPresentationStyle != UIModalPresentationPopover) {
        [self.view addSubview:self.backgroundView];
        _backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[BGView]-(0)-|" options:0 metrics:nil views:@{@"BGView": self.backgroundView}]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[BGView]-(0)-|" options:0 metrics:nil views:@{@"BGView": self.backgroundView}]];
    }

    [self.view addSubview:self.topContainer]; //AQUI ANTES HAY QUE AÑADIR UN SCROLLVIEW Y AÑADIR ESE
    if([self.cancelActions count] > 0) {
        [self.view addSubview:self.bottomContainer];
    }
    
    [self setupConstraints];
    if(self.modalPresentationStyle == UIModalPresentationPopover) {
        [self setupTopContainersTopMarginConstraint];
    }
    
    if(!self.disableMotionEffects) {
        UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        verticalMotionEffect.minimumRelativeValue = @(-10);
        verticalMotionEffect.maximumRelativeValue = @(10);
        
        UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        horizontalMotionEffect.minimumRelativeValue = @(-10);
        horizontalMotionEffect.maximumRelativeValue = @(10);
        
        UIMotionEffectGroup *motionEffectGroup = [UIMotionEffectGroup new];
        motionEffectGroup.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
        
        [self.view addMotionEffect:motionEffectGroup];
    }
    
    
    CGSize minimalSize = [self.view systemLayoutSizeFittingSize:CGSizeMake(999, 999)];
    self.preferredContentSize = CGSizeMake(minimalSize.width, minimalSize.height+10);
    
    if([self respondsToSelector:@selector(popoverPresentationController)]) {
        self.popoverPresentationController.delegate = self;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    DLog(@"self.fileIdToShowFiles: %f", _topContainer.bounds.size.height);
    self.hasBeenDismissed = NO;
}

#pragma mark - Helper
- (UIBlurEffectStyle)containerBlurEffectStyleForCurrentStyle {
    switch (self.style) {
        case RMActionControllerStyleWhite:
            return UIBlurEffectStyleExtraLight;
        case RMActionControllerStyleBlack:
            return UIBlurEffectStyleDark;
        default:
            return UIBlurEffectStyleExtraLight;
    }
}

- (UIBlurEffectStyle)backgroundBlurEffectStyleForCurrentStyle {
    switch (self.style) {
        case RMActionControllerStyleWhite:
            return UIBlurEffectStyleDark;
        case RMActionControllerStyleBlack:
            return UIBlurEffectStyleLight;
        default:
            return UIBlurEffectStyleDark;
    }
}

- (void)handleCancelNotAssociatedWithAnyButton {
    // Grouped Actions are stored in the doneActions array, so we'll need to check them as well
    for(RMAction *anAction in [self.cancelActions arrayByAddingObjectsFromArray:self.doneActions]) {
        if([anAction containsCancelAction]) {
            [anAction executeHandlerOfCancelActionWithController:self];
            return;
        }
    }
}

- (void)backgroundViewTapped:(UIGestureRecognizer *)sender {
    if(!self.disableBackgroundTaps) {
        [self handleCancelNotAssociatedWithAnyButton];
    }
}

- (void)addSubview:(UIView *)subview toContainer:(UIView *)container {
    if([container isKindOfClass:[UIVisualEffectView class]]) {
        [[[[[(UIVisualEffectView *)container contentView] subviews] objectAtIndex:0] contentView] addSubview:subview];
    } else {
        [container addSubview:subview];
    }
}

#pragma mark - iOS Properties
- (UIStatusBarStyle)preferredStatusBarStyle {
    switch (self.style) {
        case RMActionControllerStyleWhite:
            return UIStatusBarStyleLightContent;
        case RMActionControllerStyleBlack:
            return UIStatusBarStyleDefault;
        default:
            return UIStatusBarStyleLightContent;
    }
}

#pragma mark - Custom Properties
- (BOOL)disableBlurEffects {
    if(!NSClassFromString(@"UIBlurEffect") || !NSClassFromString(@"UIVibrancyEffect") || !NSClassFromString(@"UIVisualEffectView")) {
        return YES;
    } else if(&UIAccessibilityIsReduceTransparencyEnabled && UIAccessibilityIsReduceTransparencyEnabled()) {
        return YES;
    }
    
    return _disableBlurEffects;
}

- (BOOL)disableBlurEffectsForBackgroundView {
    if(self.disableBlurEffects) {
        return YES;
    }
    
    return _disableBlurEffectsForBackgroundView;
}

- (BOOL)disableBlurEffectsForContentView {
    if(self.disableBlurEffects) {
        return YES;
    }
    
    return _disableBlurEffectsForContentView;
}

- (BOOL)disableBouncingEffects {
    if(&UIAccessibilityIsReduceMotionEnabled && UIAccessibilityIsReduceMotionEnabled()) {
        return YES;
    }
    
    return _disableBouncingEffects;
}

- (BOOL)disableMotionEffects {
    if(&UIAccessibilityIsReduceMotionEnabled && UIAccessibilityIsReduceMotionEnabled()) {
        return YES;
    }
    
    return _disableMotionEffects;
}

- (UIView *)backgroundView {
    if(!_backgroundView) {
        
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        _backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
        if(self.disableBlurEffectsForBackgroundView) {
            self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
            _backgroundView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:1.0f];
        } else {
            UIVisualEffect *effect = [UIBlurEffect effectWithStyle:[self backgroundBlurEffectStyleForCurrentStyle]];
            self.backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
        }
        
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTapped:)];
        [_backgroundView addGestureRecognizer:tapRecognizer];
    }
    
    return _backgroundView;
}

- (NSString *)title {
    return self.headerTitleLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.headerTitleLabel.text = title;
}

- (NSString *)message {
    return self.headerMessageLabel.text;
}

- (void)setMessage:(NSString *)message {
    self.headerMessageLabel.text = message;
}

#pragma mark - Custom Transitions
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    RMActionControllerTransition *animationController = [[RMActionControllerTransition alloc] init];
    animationController.animationStyle = RMActionControllerTransitionStylePresenting;
    
    return animationController;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    RMActionControllerTransition *animationController = [[RMActionControllerTransition alloc] init];
    animationController.animationStyle = RMActionControllerTransitionStyleDismissing;
    
    return animationController;
}

#pragma mark - Actions
- (NSArray *)actions {
    return [[self.additionalActions arrayByAddingObjectsFromArray:self.doneActions] arrayByAddingObjectsFromArray:self.cancelActions];
}

- (void)addAction:(RMAction *)action {
    switch (action.style) {
        case RMActionStyleAdditional:
            [self.additionalActions addObject:action];
            break;
        case RMActionStyleDone:
            [self.doneActions addObject:action];
            break;
        case RMActionStyleCancel:
            [self.cancelActions addObject:action];
            break;
        case RMActionStyleDestructive:
            [self.doneActions addObject:action];
            break;
    }
    
    action.controller = self;
}

#pragma mark - UIpopopverPresentationController Delegates
- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    popoverPresentationController.backgroundColor = UIColor.purpleColor;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    [self handleCancelNotAssociatedWithAnyButton];
}

@end
