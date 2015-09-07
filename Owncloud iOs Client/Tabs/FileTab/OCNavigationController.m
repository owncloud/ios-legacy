//
//  OCNavigationController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 13/09/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "OCNavigationController.h"
#import "UIColor+Constants.h"
#import "Customization.h"
#import "ImageUtils.h"

@interface OCNavigationController ()

@end

@implementation OCNavigationController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        [self applyBrandedStyle];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self applyBrandedStyle];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //NavBar color
   
    
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void) applyBrandedStyle{
    
    // Custom initialization
    
    UIFont *appFont = [UIFont fontWithName:@"HelveticaNeue" size:18];
    
    self.navigationBar.barTintColor = [UIColor colorOfNavigationBar];
    
    [self.navigationBar setBackgroundImage:[ImageUtils imageWithColor:[UIColor colorOfBackgroundNavBarImage]] forBarMetrics:UIBarMetricsDefault];
    
    //Add background view in nav bar
    [self manageBackgroundView:NO];
    
    [self.navigationBar setTintColor:[UIColor colorOfNavigationItems]];
    
    //Set the title color
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorOfNavigationTitle];
    shadow.shadowOffset = CGSizeMake(0.7, 0);
    
    
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: [UIColor colorOfNavigationTitle],
                                      NSShadowAttributeName: shadow,
                                      NSFontAttributeName: appFont};
    
    
    
    [self.navigationBar setTitleTextAttributes:titleAttributes];
    
    
}

///-----------------------------------
/// @name Manage Background View
///-----------------------------------

/**
 * This method add or hide the background view into nav bar
 *
 * @param isShow -> Indicate if the nav bar is show or not
 */
- (void)manageBackgroundView:(BOOL)isShow{
    
    if (!isShow) {
        
        CGRect bgFrame = self.navigationBar.bounds;
#ifdef SHARE_IN
        if (IS_IPHONE) {
            bgFrame.origin.y -= 20.0;
            bgFrame.size.height += 20.0;
        }
#else
        bgFrame.origin.y -= 20.0;
        bgFrame.size.height += 20.0;
#endif
        _backgroundView = [[PassthroughView alloc] initWithFrame:bgFrame];
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _backgroundView.backgroundColor = [UIColor colorOfNavigationBar];
        _backgroundView.alpha = 0.6;
        [self.navigationBar addSubview:_backgroundView];
        [self.navigationBar sendSubviewToBack:_backgroundView];
        
    } else {
        
        [_backgroundView removeFromSuperview];
        _backgroundView = nil;
        
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
#ifdef SHARE_IN
    if (IS_IPHONE && fromInterfaceOrientation != UIInterfaceOrientationPortrait) {
        
        CGRect frame = self.navigationBar.frame;
        
        self.navigationBar.frame = CGRectMake(0, 20, frame.size.width, frame.size.height);
       
    }
#endif
}



@end
