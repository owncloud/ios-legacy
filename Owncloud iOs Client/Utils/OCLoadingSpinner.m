//
//  OCLoadingSpinner.m
//  Owncloud iOs Client
//
//  Created by María Rodríguez on 25/05/16.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "OCLoadingSpinner.h"
#import "MBProgressHUD.h"

@interface OCLoadingSpinner ()

@property(nonatomic, strong) MBProgressHUD  *HUD;
@property (nonatomic, strong) UIViewController *vc;

@end

@implementation OCLoadingSpinner


+ (id)sharedOCLoadingSpinner{
    static OCLoadingSpinner *sharedOCLoadingSpinner = nil;
    @synchronized(self) {
        if (sharedOCLoadingSpinner == nil)
            sharedOCLoadingSpinner = [[self alloc] init];
    }
    return sharedOCLoadingSpinner;
}



#pragma mark Loading view methods

/*
 * Method that launch the loading screen and block the view
 */
-(void)initLoadingForViewController:(UIViewController *)vc {
    
    self.vc = vc;
    
    if (self.HUD) {
        [self.HUD removeFromSuperview];
        self.HUD=nil;
    }
    
    
    self.HUD = [[MBProgressHUD alloc]initWithWindow:[UIApplication sharedApplication].keyWindow];
    if (IS_IPHONE) {
        [self.vc.view.window addSubview:self.HUD];
    } else {
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [app.splitViewController.view.window addSubview:self.HUD];
    }
    
    self.HUD.labelText = NSLocalizedString(@"loading", nil);
    self.HUD.dimBackground = NO;
  
    
    [self.HUD show:YES];
    
    self.vc.view.userInteractionEnabled = NO;
    self.vc.navigationController.navigationBar.userInteractionEnabled = NO;
    self.vc.tabBarController.tabBar.userInteractionEnabled = NO;
    [self.vc.view.window setUserInteractionEnabled:NO];
    
    DLog(@"init loading spinner in vc: %@", self.vc);
}


/*
 * Method that quit the loading screen and unblock the view
 */
- (void)endLoading {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //Check if the loading should be visible
    if (app.isLoadingVisible == NO) {
        // [MBProgressHUD hideAllHUDsForView:self.navigationController.view animated:YES];
        [self.HUD removeFromSuperview];
        self.vc.view.userInteractionEnabled = YES;
        self.vc.navigationController.navigationBar.userInteractionEnabled = YES;
        self.vc.tabBarController.tabBar.userInteractionEnabled = YES;
        [self.vc.view.window setUserInteractionEnabled:YES];
    }
    
    DLog(@"stop loading spinner for vc: %@", self.vc);
}

@end
