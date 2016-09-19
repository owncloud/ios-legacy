//
//  SelectFolderNavigation.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 01/10/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "SelectFolderNavigation.h"


@interface SelectFolderNavigation ()

@end



@implementation SelectFolderNavigation
@synthesize delegate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)selectFolder:(NSString*)folder{
    DLog(@"Delegate select Folder");
    
    //[self popToRootViewControllerAnimated:NO];
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
    	
    
    if([delegate respondsToSelector:@selector(folderSelected:)]) {
		[delegate performSelector:@selector(folderSelected:) withObject:folder afterDelay:0.5];
    }
}


-(void)cancelSelectedFolder{
    
    //[self popToRootViewControllerAnimated:NO];
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
    
    if ([delegate respondsToSelector:@selector(cancelFolderSelected)]) {
        [delegate cancelSelectedFolder];
    }
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
   // self.presentingViewController.view.superview.frame = self.view.superview.frame;
    
       
    
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    if (IS_IPHONE) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }     
    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
   // DLog(@"SelectedFolderNavigation willRotate");
    
      
    
   // self.presentingViewController.view.superview.hidden = YES;
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];    

    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  //  self.presentingViewController.view.superview.hidden = NO;
    
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

@end
