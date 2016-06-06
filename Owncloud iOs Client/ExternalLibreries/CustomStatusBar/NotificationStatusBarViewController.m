//
//  NotificationStatusBarViewController.m
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 08/01/14.
//
//

#import "NotificationStatusBarViewController.h"
#import "Customization.h"

@interface NotificationStatusBarViewController ()

@end

@implementation NotificationStatusBarViewController

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

-(UIStatusBarStyle)preferredStatusBarStyle {
    
    if (k_is_text_status_bar_white) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

@end
