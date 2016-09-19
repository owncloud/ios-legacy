//
//  OCPortraitNavigationViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 30/09/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


#import "OCPortraitNavigationViewController.h"


@interface OCPortraitNavigationViewController ()

@end

@implementation OCPortraitNavigationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPHONE) {
        //iPhone
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    } else {
        //iPad
        return YES;
    }
    
    
}
-(NSUInteger)supportedInterfaceOrientations
{
    if (IS_IPHONE) {
        //iPhone
         return UIInterfaceOrientationMaskPortrait;
    } else {
        //iPad
         return UIInterfaceOrientationMaskAll;
    }
    
   
}

@end
