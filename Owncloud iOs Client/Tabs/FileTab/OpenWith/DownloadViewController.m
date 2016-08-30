//
//  DownloadViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 22/08/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "DownloadViewController.h"

@interface DownloadViewController ()

@end

@implementation DownloadViewController
@synthesize progressView=_progressView;
@synthesize progressLabel=_progressLabel;
@synthesize cancelButton=_cancelButton;
@synthesize delegate;

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
    [self configureView];
    _progressView.progress=0.0;  
   
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (IS_IPHONE) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

-(void)potraitView{  
    
    DLog(@"Portrait");
    
    //Progress Bar
    _heightProgressBar.constant = 2;
}

-(void)landscapeView{
    
    DLog(@"Landscape");
    
    //Progress Bar
    _heightProgressBar.constant = 2;
}


-(void)configureView{
    
    UIInterfaceOrientation currentOrientation;    
    currentOrientation=[[UIApplication sharedApplication] statusBarOrientation];           
    BOOL isPotrait = UIDeviceOrientationIsPortrait(currentOrientation);
    
    if (isPotrait==YES) {
        [self potraitView];
    } else {
        [self landscapeView];    
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
    if (toInterfaceOrientation  == UIInterfaceOrientationPortrait) {
        //Vertical
        // DLog(@"Vertical");
        [self potraitView];
    } else {
        //Horizontal
        // DLog(@"Horizontal");
        [self landscapeView];
    }
}
-(IBAction)cancelButtonPressed:(id)sender{
    DLog(@"CANCEL BUTTON PRESSED");
    [delegate cancelDownload];
}
@end
