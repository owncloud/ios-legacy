//
// Copyright 2011-2012 Kosher Penguin LLC
// Created by Adar Porat (https://github.com/aporat) on 1/16/2012.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//		http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/*
 Remove the KKKeychain reference, we use ManageAppSettingsDB in order to store the pin code
 */

#import "KKPasscodeViewController.h"
// We don't use KKkeychain
//#import "KKKeychain.h"
#import "KKPasscodeSettingsViewController.h"
#import "KKPasscodeLock.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import "ManageAppSettingsDB.h"
#import "Customization.h"
#ifdef CONTAINER_APP
#import "AppDelegate.h"
#endif

@interface KKPasscodeViewController ()

@property(nonatomic,assign) BOOL isSmallLandscape;

@end

@interface KKPasscodeViewController (Private)

- (UITextField*)passcodeTextField;
- (NSArray*)boxes;
- (UIView*)headerViewForTextField:(UITextField*)textField;
- (void)moveToNextTableView;
- (void)moveToPreviousTableView;
- (void)incrementFailedAttemptsLabel;

@end


@implementation KKPasscodeViewController

@synthesize delegate = _delegate;
@synthesize mode = _mode;
@synthesize isSmallLandscape;

#pragma mark -
#pragma mark UIViewController

- (id)init
{
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    return self;
}

- (void)loadView
{
	[super loadView];
	
	self.view.backgroundColor = [UIColor whiteColor];
    
    CGRect tableViewFrame = self.view.bounds;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        // is running on device with 4" screen so add background tableView
        UITableView *backgroundTableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped];
        [self.view addSubview:backgroundTableView];
        
        //and move other tableViews down so boxes are vertically centered
#ifdef CONTAINER_APP
        if ([[UIScreen mainScreen] bounds].size.height > 480) {
            tableViewFrame.origin.y += 44.0;
        }
#else
        tableViewFrame.origin.y -= 44.0;
#endif
        
    }
	
	_enterPasscodeTableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped];
	_enterPasscodeTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_enterPasscodeTableView.delegate = self;
	_enterPasscodeTableView.dataSource = self;
	_enterPasscodeTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_enterPasscodeTableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	[self.view addSubview:_enterPasscodeTableView];
	
	_setPasscodeTableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped];
	_setPasscodeTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_setPasscodeTableView.delegate = self;
	_setPasscodeTableView.dataSource = self;
	_setPasscodeTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_setPasscodeTableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	[self.view addSubview:_setPasscodeTableView];
	
	_confirmPasscodeTableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStyleGrouped];
	_confirmPasscodeTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_confirmPasscodeTableView.delegate = self;
	_confirmPasscodeTableView.dataSource = self;
	_confirmPasscodeTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_confirmPasscodeTableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	[self.view addSubview:_confirmPasscodeTableView];
    
    _shouldReleaseFirstResponser = NO;
    
    [ManageTouchID sharedSingleton].delegate = self;
    
}

- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    //_passcodeLockOn = [[KKKeychain getStringForKey:@"passcode_on"] isEqualToString:@"YES"];
    _passcodeLockOn = [ManageAppSettingsDB isPasscode];
//	_eraseData = [[KKPasscodeLock sharedLock] eraseOption] && [[KKKeychain getStringForKey:@"erase_data_on"] isEqualToString:@"YES"];
    _eraseData = NO;
    
	_enterPasscodeTextField = [[UITextField alloc] init];
    _enterPasscodeTextField.delegate = self;
    _enterPasscodeTextField.keyboardType = UIKeyboardTypeNumberPad;
	_enterPasscodeTextField.hidden = YES;
    
    _setPasscodeTextField = [[UITextField alloc] init];
    _setPasscodeTextField.delegate = self;
    _setPasscodeTextField.keyboardType = UIKeyboardTypeNumberPad;
	_setPasscodeTextField.hidden = YES;
    
	_confirmPasscodeTextField = [[UITextField alloc] init];
    _confirmPasscodeTextField.delegate = self;
    _confirmPasscodeTextField.keyboardType = UIKeyboardTypeNumberPad;
	_confirmPasscodeTextField.hidden = YES;
	
	_tableViews = [[NSMutableArray alloc] init];
	_textFields = [[NSMutableArray alloc] init];
	_boxes = [[NSMutableArray alloc] init];
	
    // Need to make sure everything is visible in landscape mode on small devices.
    //self.isSmallLandscape = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape(self.interfaceOrientation));
    self.isSmallLandscape = NO;
    
    if (_mode == KKPasscodeModeSet) {
        self.navigationItem.title =NSLocalizedString(@"title_app_pin", nil); // KKPasscodeLockLocalizedString(@"Set Passcode", @"");
        if(!k_is_passcode_forced){
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelButtonPressed:)];
        }
    } else if (_mode == KKPasscodeModeChange) {
        self.navigationItem.title = KKPasscodeLockLocalizedString(@"Change Passcode", @"");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelButtonPressed:)];
        
    } else if (_mode == KKPasscodeModeDisabled) {
        self.navigationItem.title = NSLocalizedString(@"title_app_pin", nil); //KKPasscodeLockLocalizedString(@"Turn off Passcode", @"");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelButtonPressed:)];
        
    } else {
        self.navigationItem.title = NSLocalizedString(@"title_app_pin", nil); // KKPasscodeLockLocalizedString(@"Enter Passcode", @"");
    }
    
    CGFloat totalBoxesWidth = (71.0 * kPasscodeBoxesCount) - 10.0;
    
	if (_mode == KKPasscodeModeSet || _mode == KKPasscodeModeChange) {
		if (_passcodeLockOn) {
			_enterPasscodeTableView.tableHeaderView = [self headerViewForTextField:_enterPasscodeTextField];
			[_tableViews addObject:_enterPasscodeTableView];
			[_textFields addObject:_enterPasscodeTextField];
			[_boxes addObject:[self boxes]];
			UIView *boxesView = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - totalBoxesWidth) * 0.5, 0, totalBoxesWidth, kPasscodeBoxHeight)];
			boxesView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			for (int i = 0; i < [[_boxes lastObject] count]; i++) {
				[boxesView addSubview:[[_boxes lastObject] objectAtIndex:i]];
			}
			[_enterPasscodeTableView.tableHeaderView addSubview:boxesView];
		}
		
		_setPasscodeTableView.tableHeaderView = [self headerViewForTextField:_setPasscodeTextField];
        
		[_tableViews addObject:_setPasscodeTableView];
		[_textFields addObject:_setPasscodeTextField];
		[_boxes addObject:[self boxes]];
		UIView *boxesView = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - totalBoxesWidth) * 0.5, 0, totalBoxesWidth, kPasscodeBoxHeight)];
		boxesView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		for (int i = 0; i < [[_boxes lastObject] count]; i++) {
			[boxesView addSubview:[[_boxes lastObject] objectAtIndex:i]];
		}
		[_setPasscodeTableView.tableHeaderView addSubview:boxesView];
		
		_confirmPasscodeTableView.tableHeaderView = [self headerViewForTextField:_confirmPasscodeTextField];
		[_tableViews addObject:_confirmPasscodeTableView];
		[_textFields addObject:_confirmPasscodeTextField];
		[_boxes addObject:[self boxes]];
		UIView *boxesConfirmView = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - totalBoxesWidth) * 0.5, 0, totalBoxesWidth, kPasscodeBoxHeight)];
		boxesConfirmView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		for (int i = 0; i < [[_boxes lastObject] count]; i++) {
			[boxesConfirmView addSubview:[[_boxes lastObject] objectAtIndex:i]];
		}
		[_confirmPasscodeTableView.tableHeaderView addSubview:boxesConfirmView];
	} else {
		_enterPasscodeTableView.tableHeaderView = [self headerViewForTextField:_enterPasscodeTextField];
		[_tableViews addObject:_enterPasscodeTableView];
		[_textFields addObject:_enterPasscodeTextField];
		[_boxes addObject:[self boxes]];
		UIView *boxesView = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - totalBoxesWidth) * 0.5, 0, totalBoxesWidth, kPasscodeBoxHeight)];
		boxesView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		for (int i = 0; i < [[_boxes lastObject] count]; i++) {
			[boxesView addSubview:[[_boxes lastObject] objectAtIndex:i]];
		}
		[_enterPasscodeTableView.tableHeaderView addSubview:boxesView];
	}
	
	[self.view addSubview:[_tableViews objectAtIndex:0]];
	
	for (int i = 1; i < [_tableViews count]; i++) {
		UITableView *tableView = [_tableViews objectAtIndex:i];
		tableView.frame = CGRectMake(tableView.frame.origin.x + self.view.bounds.size.width,
                                     tableView.frame.origin.y,
                                     tableView.frame.size.width,
                                     tableView.frame.size.height);
		[self.view addSubview:tableView];
	}
	
	[[_textFields objectAtIndex:0] becomeFirstResponder];
	[[_tableViews objectAtIndex:0] reloadData];
	[[_textFields objectAtIndex:[_tableViews count] - 1] setReturnKeyType:UIReturnKeyDone];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if ([_tableViews count] > 1) {
			[self moveToNextTableView];
			[self moveToPreviousTableView];
		} else {
			UITableView *tableView = [_tableViews objectAtIndex:0];
			tableView.frame = CGRectMake(tableView.frame.origin.x,
                                         tableView.frame.origin.y,
                                         self.view.bounds.size.width,
                                         self.view.bounds.size.height);
		}
        
        if (!_dimView) {
            
#ifdef CONTAINER_APP
            id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
            _dimView = [[UIView alloc] initWithFrame:appDelegate.window.rootViewController.view.bounds];
            _dimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

           
            
            
            
            //Change the background depend of the type of passcode
            if (_mode == KKPasscodeModeSet || _mode == KKPasscodeModeDisabled) {
                _dimView.backgroundColor = [UIColor clearColor];
            }else{
                _dimView.backgroundColor = [UIColor darkGrayColor];
            }
            
            _dimView.alpha = 1.0f;
            [appDelegate.window.rootViewController.view addSubview:_dimView];
            
#endif
          /*  [UIView animateWithDuration:0.3f animations:^{
                self.dimView.alpha = 1.0f;
            }];*/
        }
	}
    
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //Set Passcode visible
    app.isPasscodeVisible = YES;
#else
    //We need to catch the rotation notifications only in iPhone.
    if (IS_IPHONE) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    }
#endif
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _shouldReleaseFirstResponser = YES;
    [_enterPasscodeTextField resignFirstResponder];
    [_setPasscodeTextField resignFirstResponder];
    [_confirmPasscodeTextField resignFirstResponder];
    
    if (self.dimView) {
        [UIView animateWithDuration:0.3f
                         animations:^{
                             self.dimView.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             [self.dimView removeFromSuperview];
                             self.dimView = nil;
                         }];
    } 
#ifdef CONTAINER_APP
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    //Set Passcode not visible
    app.isPasscodeVisible = NO;
    
#else
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
}


- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
  
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        //Change the background depend of the type of passcode
        if (_dimView) {
            [_dimView removeFromSuperview];
            _dimView=nil;
        }
        
#ifdef CONTAINER_APP
        id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
        _dimView = [[UIView alloc] initWithFrame:appDelegate.window.rootViewController.view.bounds];
        _dimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        //Change the background depend of the type of passcode
        if (_mode == KKPasscodeModeSet || _mode == KKPasscodeModeDisabled) {
            _dimView.backgroundColor = [UIColor clearColor];
        }else{
            _dimView.backgroundColor = [UIColor darkGrayColor];
        }
        
        _dimView.alpha = 1.0f;
        [appDelegate.window.rootViewController.view addSubview:self.dimView];
#endif
        
    }
    
}


#pragma mark -
#pragma mark Private methods


- (void)cancelButtonPressed:(id)sender
{
    if ([_delegate respondsToSelector:@selector(didCancelPassCodeTapped)]) {
        [_delegate didCancelPassCodeTapped];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

//We change this method in order doesn't have account failed atttempts
- (void)incrementFailedAttemptsLabel
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
	_enterPasscodeTextField.text = @"";
	for (int i = 0; i < kPasscodeBoxesCount; i++) {
		[[[_boxes objectAtIndex:_currentPanel] objectAtIndex:i] setImage:[UIImage imageNamed:@"KKPasscodeLock.bundle/box_empty.png"]];
	}
	
   // NSInteger _failedAttemptsCount = [[KKKeychain getStringForKey:@"failedAttemptsCount"] integerValue];
    
  //  _failedAttemptsCount++;
    
   // [KKKeychain setString:[NSString stringWithFormat:@"%d", _failedAttemptsCount] forKey:@"failedAttemptsCount"];

	/*if (_failedAttemptsCount == 1) {
		_failedAttemptsLabel.text = KKPasscodeLockLocalizedString(@"1 Failed Passcode Attempt", @"");
	} else {
		_failedAttemptsLabel.text = [NSString stringWithFormat:KKPasscodeLockLocalizedString(@"%i Failed Passcode Attempts", @""), _failedAttemptsCount];
	}*/
    
    //Set we message of incorrect pin
    _failedAttemptsLabel.text = NSLocalizedString(@"incorrect_pin", nil);
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:self.isSmallLandscape ? 10.0f : 14.0f]};
    CGSize size = [_failedAttemptsLabel.text sizeWithAttributes:attributes];
    
	_failedAttemptsLabel.frame = _failedAttemptsView.frame = CGRectMake((self.view.bounds.size.width - (size.width + (self.isSmallLandscape ? 20.0f : 40.0f))) / 2, self.isSmallLandscape ? 75.0f : 150.0f, size.width + (self.isSmallLandscape ? 20.0f : 40.0f), size.height + (self.isSmallLandscape ? 5.0f : 10.0f));
	
	CAGradientLayer *gradient = [CAGradientLayer layer];
	gradient.frame = _failedAttemptsView.bounds;
	gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:0.7 green:0.05 blue:0.05 alpha:1.0] CGColor],
                       (id)[[UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0] CGColor], nil];
	[_failedAttemptsView.layer insertSublayer:gradient atIndex:0];
	_failedAttemptsView.layer.masksToBounds = YES;
	
	_failedAttemptsLabel.hidden = NO;
	_failedAttemptsView.hidden = NO;
	
    //Comented this in order to doesn't support attemps
    
	/*if (_failedAttemptsCount == [[KKPasscodeLock sharedLock] attemptsAllowed]) {
		
		_enterPasscodeTextField.delegate = nil;
		
		if (_eraseData) {
			if ([_delegate respondsToSelector:@selector(shouldEraseApplicationData:)]) {
				[_delegate shouldEraseApplicationData:self];
			}
		} else {
			if ([_delegate respondsToSelector:@selector(didPasscodeEnteredIncorrectly:)]) {
				[_delegate didPasscodeEnteredIncorrectly:self];
			}
            
            [KKKeychain setString:[[KKPasscodeLock sharedLock].dateFormatter stringFromDate:[NSDate date]] forKey:@"incorrect_passcode_datetime"];
            
            if ([_delegate respondsToSelector:@selector(shouldLockApplication:)]) {
				[_delegate shouldLockApplication:self];
			}
		}
        
        [KKKeychain setString:@"0" forKey:@"failedAttemptsCount"];
	}*/
	
}

- (void)moveToNextTableView
{
	_currentPanel += 1;
    
	UITableView *oldTableView = [_tableViews objectAtIndex:_currentPanel - 1];
	UITableView *newTableView = [_tableViews objectAtIndex:_currentPanel];
    
	newTableView.frame = CGRectMake(oldTableView.frame.origin.x + self.view.bounds.size.width,
                                    oldTableView.frame.origin.y,
                                    oldTableView.frame.size.width,
                                    oldTableView.frame.size.height);
	
	for (int i = 0; i < kPasscodeBoxesCount; i++) {
		[[[_boxes objectAtIndex:_currentPanel] objectAtIndex:i] setImage:[UIImage imageNamed:@"KKPasscodeLock.bundle/box_empty.png"]];
	}
	
	[UIView beginAnimations:@"" context:nil];
	[UIView setAnimationDuration:0.25];
	oldTableView.frame = CGRectMake(oldTableView.frame.origin.x - self.view.bounds.size.width, oldTableView.frame.origin.y, oldTableView.frame.size.width, oldTableView.frame.size.height);
    
    
    CGRect newFrame = CGRectMake(self.view.frame.origin.x,oldTableView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    newTableView.frame = newFrame;
    
    
	[UIView commitAnimations];
	
	_shouldReleaseFirstResponser = YES;
	[[_textFields objectAtIndex:_currentPanel - 1] resignFirstResponder];
	_shouldReleaseFirstResponser = NO;
	[[_textFields objectAtIndex:_currentPanel] becomeFirstResponder];
}


- (void)moveToPreviousTableView
{
	_currentPanel -= 1;
    
	UITableView *oldTableView = [_tableViews objectAtIndex:_currentPanel + 1];
	UITableView *newTableView = [_tableViews objectAtIndex:_currentPanel];
	newTableView.frame = CGRectMake(oldTableView.frame.origin.x - self.view.bounds.size.width, oldTableView.frame.origin.y, oldTableView.frame.size.width, oldTableView.frame.size.height);
	
	for (int i = 0; i < kPasscodeBoxesCount; i++) {
		[[[_boxes objectAtIndex:_currentPanel] objectAtIndex:i] setImage:[UIImage imageNamed:@"KKPasscodeLock.bundle/box_empty.png"]];
	}
	
	[UIView beginAnimations:@"" context:nil];
	[UIView setAnimationDuration:0.25];
	oldTableView.frame = CGRectMake(oldTableView.frame.origin.x + self.view.bounds.size.width, oldTableView.frame.origin.y, oldTableView.frame.size.width, oldTableView.frame.size.height);
    
    CGRect newFrame = CGRectMake(self.view.frame.origin.x,oldTableView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    newTableView.frame = newFrame;
    
	//newTableView.frame = self.view.frame;
	[UIView commitAnimations];
	
    _shouldReleaseFirstResponser = YES;
	[[_textFields objectAtIndex:_currentPanel + 1] resignFirstResponder];
    _shouldReleaseFirstResponser = NO;
	[[_textFields objectAtIndex:_currentPanel] becomeFirstResponder];
}


- (void)nextDigitPressed
{
	UITextField* textField = [_textFields objectAtIndex:_currentPanel];
	
	if (![textField.text isEqualToString:@""]) {
		
		if (_mode == KKPasscodeModeSet) {
			if ([textField isEqual:_setPasscodeTextField]) {
				[self moveToNextTableView];
			} else if ([textField isEqual:_confirmPasscodeTextField]) {
				if (![_confirmPasscodeTextField.text isEqualToString:_setPasscodeTextField.text]) {
					_confirmPasscodeTextField.text = @"";
					_setPasscodeTextField.text = @"";
					_passcodeConfirmationWarningLabel.text = NSLocalizedString(@"both_pass_not_same", nil); //KKPasscodeLockLocalizedString(@"Passcodes did not match. Try again.", @"");
					[self moveToPreviousTableView];
				} else {
					/*if ([KKKeychain setString:_setPasscodeTextField.text forKey:@"passcode"]) {
						[KKKeychain setString:@"YES" forKey:@"passcode_on"];
					}*/
                    [ManageAppSettingsDB insertPasscode:_setPasscodeTextField.text];
					
					if ([_delegate respondsToSelector:@selector(didSettingsChanged:)]) {
						[_delegate performSelector:@selector(didSettingsChanged:) withObject:self];
					}
					
                    [self dismissViewControllerAnimated:YES completion:nil];
				}
			}
		} else if (_mode == KKPasscodeModeChange) {
			//NSString* passcode = [KKKeychain getStringForKey:@"passcode"];
            NSString* passcode = [ManageAppSettingsDB getPassCode];
			if ([textField isEqual:_enterPasscodeTextField]) {
				if ([passcode isEqualToString:_enterPasscodeTextField.text]) {
					[self moveToNextTableView];
				} else {
					[self incrementFailedAttemptsLabel];
				}
			} else if ([textField isEqual:_setPasscodeTextField]) {
				if ([passcode isEqualToString:_setPasscodeTextField.text]) {
					_setPasscodeTextField.text = @"";
					_passcodeConfirmationWarningLabel.text = KKPasscodeLockLocalizedString(@"Enter a different passcode. You cannot re-use the same passcode.", @"");
					_passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 132.0, self.view.bounds.size.width, 60.0);
				} else {
					_passcodeConfirmationWarningLabel.text = @"";
					_passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 146.0, self.view.bounds.size.width, 30.0);
					[self moveToNextTableView];
				}
			} else if ([textField isEqual:_confirmPasscodeTextField]) {
				if (![_confirmPasscodeTextField.text isEqualToString:_setPasscodeTextField.text]) {
					_confirmPasscodeTextField.text = @"";
					_setPasscodeTextField.text = @"";
					_passcodeConfirmationWarningLabel.text = NSLocalizedString(@"both_pass_not_same", nil); //KKPasscodeLockLocalizedString(@"Passcodes did not match. Try again.", "");
					[self moveToPreviousTableView];
				} else {
					/*if ([KKKeychain setString:_setPasscodeTextField.text forKey:@"passcode"]) {
						[KKKeychain setString:@"YES" forKey:@"passcode_on"];
					}*/
                    [ManageAppSettingsDB insertPasscode:_setPasscodeTextField.text];
					
					if ([_delegate respondsToSelector:@selector(didSettingsChanged:)]) {
						[_delegate performSelector:@selector(didSettingsChanged:) withObject:self];
					}
                    
                    [self dismissViewControllerAnimated:YES completion:nil];

				}
			}
		}
	}
}

- (void) closeKeyboards{
    
    _shouldReleaseFirstResponser = YES;
    [_enterPasscodeTextField resignFirstResponder];
    [_setPasscodeTextField resignFirstResponder];
    [_confirmPasscodeTextField resignFirstResponder];
}

- (void)vaildatePasscode:(UITextField*)textField
{
    if (_mode == KKPasscodeModeDisabled) {
       // NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
        NSString *passcode = [ManageAppSettingsDB getPassCode];
        if ([_enterPasscodeTextField.text isEqualToString:passcode]) {
            /*if ([KKKeychain setString:@"NO" forKey:@"passcode_on"]) {
                [KKKeychain setString:@"" forKey:@"passcode"];
            }*/
            [ManageAppSettingsDB removePasscode];
            
            if ([_delegate respondsToSelector:@selector(didSettingsChanged:)]) {
                [_delegate performSelector:@selector(didSettingsChanged:) withObject:self];
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];

        } else {
            [self incrementFailedAttemptsLabel];
        }
    } else if (_mode == KKPasscodeModeEnter) {
        ///NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
         NSString *passcode = [ManageAppSettingsDB getPassCode];
        if ([_enterPasscodeTextField.text isEqualToString:passcode]) {
            

            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [UIView beginAnimations:@"fadeIn" context:nil];
                [UIView setAnimationDelay:0.25];
                [UIView setAnimationDuration:0.5];
                
                [UIView commitAnimations];
            }
            if ([_delegate respondsToSelector:@selector(didPasscodeEnteredCorrectly:)]) {
                //CLose keyboards. Change for OC
                [self closeKeyboards];
                [_delegate performSelector:@selector(didPasscodeEnteredCorrectly:) withObject:self];
            }
            
            //[KKKeychain setString:@"0" forKey:@"failedAttemptsCount"];

            [self dismissViewControllerAnimated:YES completion:nil];

        } else {
            [self incrementFailedAttemptsLabel];
        }
    } else if (_mode == KKPasscodeModeChange) {
        //NSString *passcode = [KKKeychain getStringForKey:@"passcode"];
        NSString *passcode = [ManageAppSettingsDB getPassCode];
        if ([textField isEqual:_enterPasscodeTextField]) {
            if ([passcode isEqualToString:_enterPasscodeTextField.text]) {
                [self moveToNextTableView];
            } else {
                [self incrementFailedAttemptsLabel];
            }
        } else if ([textField isEqual:_setPasscodeTextField]) {
            if ([passcode isEqualToString:_setPasscodeTextField.text]) {
                _setPasscodeTextField.text = @"";
                for (int i = 0; i < kPasscodeBoxesCount; i++) {
                    [[[_boxes objectAtIndex:_currentPanel] objectAtIndex:i] setImage:[UIImage imageNamed:@"KKPasscodeLock.bundle/box_empty.png"]];
                }
                _passcodeConfirmationWarningLabel.text = KKPasscodeLockLocalizedString(@"Enter a different passcode. You cannot re-use the same passcode.", @"");
                _passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 132.0, self.view.bounds.size.width, 60.0);
            } else {
                _passcodeConfirmationWarningLabel.text = @"";
                _passcodeConfirmationWarningLabel.frame = CGRectMake(0.0, 146.0, self.view.bounds.size.width, 30.0);
                [self moveToNextTableView];
            }
        } else if ([textField isEqual:_confirmPasscodeTextField]) {
            if (![_confirmPasscodeTextField.text isEqualToString:_setPasscodeTextField.text]) {
                _confirmPasscodeTextField.text = @"";
                _setPasscodeTextField.text = @"";
                _passcodeConfirmationWarningLabel.text = NSLocalizedString(@"both_pass_not_same", nil); //KKPasscodeLockLocalizedString(@"Passcodes did not match. Try again.", @"");
                [self moveToPreviousTableView];
            } else {
                
                [ManageAppSettingsDB updatePasscode:_setPasscodeTextField.text];
                
               /* if ([KKKeychain setString:_setPasscodeTextField.text forKey:@"passcode"]) {
                    [KKKeychain setString:@"YES" forKey:@"passcode_on"];
                }*/
                
                if ([_delegate respondsToSelector:@selector(didSettingsChanged:)]) {
                    [_delegate performSelector:@selector(didSettingsChanged:) withObject:self];
                }

                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    } else if ([textField isEqual:_setPasscodeTextField]) {
        [self moveToNextTableView];
    } else if ([textField isEqual:_confirmPasscodeTextField]) {
        if (![_confirmPasscodeTextField.text isEqualToString:_setPasscodeTextField.text]) {
            _confirmPasscodeTextField.text = @"";
            _setPasscodeTextField.text = @"";
            _passcodeConfirmationWarningLabel.text = NSLocalizedString(@"both_pass_not_same", nil); //KKPasscodeLockLocalizedString(@"Passcodes did not match. Try again.", @"");
            [self moveToPreviousTableView];
        } else {
            
            [ManageAppSettingsDB insertPasscode:_setPasscodeTextField.text];
            
            /*if ([KKKeychain setString:_setPasscodeTextField.text forKey:@"passcode"]) {
                [KKKeychain setString:@"YES" forKey:@"passcode_on"];
            }*/
            
            if ([_delegate respondsToSelector:@selector(didSettingsChanged:)]) {
                [_delegate performSelector:@selector(didSettingsChanged:) withObject:self];
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}


- (void)doneButtonPressed
{
	UITextField *textField = [_textFields objectAtIndex:_currentPanel];
	[self vaildatePasscode:textField];
}


- (UIView*)headerViewForTextField:(UITextField*)textField
{
    [self.view addSubview:textField];
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, 70.0)];
    float headerLabelX = 0.0;
    float headerLabelWidth = self.view.bounds.size.width;
    if ([textField isEqual:_setPasscodeTextField] && k_is_passcode_forced) {
        headerLabelX = 25.0;
        headerLabelWidth = self.view.bounds.size.width - headerLabelX ;
    }
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(headerLabelX, self.isSmallLandscape ? 2.0f : 10.0f, headerLabelWidth, 30.0)];
	headerLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.4 alpha:1.0];
	headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
	headerLabel.font = [UIFont boldSystemFontOfSize:self.isSmallLandscape ? 12.0f : 17.0f];
	headerLabel.shadowOffset = CGSizeMake(0, 1.0);
	headerLabel.shadowColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
	
	if ([textField isEqual:_setPasscodeTextField]) {
		_passcodeConfirmationWarningLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, self.isSmallLandscape ? 73.0f : 146.0, self.view.bounds.size.width, 30.0)];
		_passcodeConfirmationWarningLabel.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.4 alpha:1.0];
		_passcodeConfirmationWarningLabel.backgroundColor = [UIColor clearColor];
		_passcodeConfirmationWarningLabel.textAlignment = NSTextAlignmentCenter;
		_passcodeConfirmationWarningLabel.font = [UIFont systemFontOfSize:14.0];
		_passcodeConfirmationWarningLabel.shadowOffset = CGSizeMake(0, 1.0);
		_passcodeConfirmationWarningLabel.shadowColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
		_passcodeConfirmationWarningLabel.text = @"";
		_passcodeConfirmationWarningLabel.numberOfLines = 0;
		_passcodeConfirmationWarningLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
		[headerView addSubview:_passcodeConfirmationWarningLabel];
	}
	
	if ([textField isEqual:_enterPasscodeTextField]) {
		_failedAttemptsView = [[UIView alloc] init];
		_failedAttemptsLabel = [[UILabel alloc] init];
		_failedAttemptsLabel.backgroundColor = [UIColor clearColor];
		_failedAttemptsLabel.textColor = [UIColor whiteColor];
		_failedAttemptsLabel.text = @"";
		_failedAttemptsLabel.font = [UIFont boldSystemFontOfSize:self.isSmallLandscape ? 10.0f : 14.0f];
		_failedAttemptsLabel.textAlignment = NSTextAlignmentCenter;
		_failedAttemptsLabel.shadowOffset = CGSizeMake(0, -1.0);
		_failedAttemptsLabel.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
		_failedAttemptsView.layer.cornerRadius = self.isSmallLandscape ? 7.0f : 14.0f;
		_failedAttemptsView.layer.borderWidth = 1.0;
		_failedAttemptsView.layer.borderColor = [[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25] CGColor];
		
		_failedAttemptsLabel.hidden = YES;
		_failedAttemptsView.hidden = YES;
        
		_failedAttemptsView.layer.masksToBounds = YES;
		
		[headerView addSubview:_failedAttemptsView];
		[headerView addSubview:_failedAttemptsLabel];
	}
	
    if (_mode == KKPasscodeModeSet) {
        if ([textField isEqual:_enterPasscodeTextField]) {
            headerLabel.text = NSLocalizedString(@"enter_app_pin_long_description", nil); // KKPasscodeLockLocalizedString(@"Enter your passcode", @"");
        } else if ([textField isEqual:_setPasscodeTextField]) {
            if (k_is_passcode_forced){
                headerLabel.text = NSLocalizedString(@"enter_app_pin_long_description_forced", nil);
                headerLabel.lineBreakMode = NSLineBreakByWordWrapping;
                headerLabel.numberOfLines = 0;
                [headerLabel sizeToFit];
            } else {
                headerLabel.text = NSLocalizedString(@"enter_app_pin_long_description", nil); //KKPasscodeLockLocalizedString(@"Enter a passcode", @"");
            }
        } else if ([textField isEqual:_confirmPasscodeTextField]) {
            headerLabel.text = NSLocalizedString(@"reenter_app_pin", nil); //KKPasscodeLockLocalizedString(@"Re-enter your passcode", @"");
        }
    } else if (_mode == KKPasscodeModeDisabled) {
        headerLabel.text = NSLocalizedString(@"remove_app_pin", nil); //KKPasscodeLockLocalizedString(@"Enter your passcode", @"");
    } else if (_mode == KKPasscodeModeChange) {
        if ([textField isEqual:_enterPasscodeTextField]) {
            headerLabel.text = KKPasscodeLockLocalizedString(@"Enter your old passcode", @"");
        } else if ([textField isEqual:_setPasscodeTextField]) {
            headerLabel.text = KKPasscodeLockLocalizedString(@"Enter your new passcode", @"");
        } else {
            headerLabel.text = NSLocalizedString(@"reenter_app_pin", nil); //KKPasscodeLockLocalizedString(@"Re-enter your new passcode", @"");
        }
    } else {
        headerLabel.text = NSLocalizedString(@"enter_app_pin", nil);//KKPasscodeLockLocalizedString(@"Enter your passcode", @"");
    }
    
    if (!k_is_passcode_forced){
        headerLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    }
    
    
#ifdef CONTAINER_APP
    [headerView addSubview:headerLabel];
#endif
	
	return headerView;
}


- (NSArray*)boxes
{
	NSMutableArray* squareViews = [NSMutableArray array];
	
	CGFloat squareX = self.isSmallLandscape ? 60.0f : 0.0f;
    
    CGFloat width = self.isSmallLandscape ? kPasscodeBoxWidth * 0.6f : kPasscodeBoxWidth;
    CGFloat height = self.isSmallLandscape ? kPasscodeBoxHeight * 0.6f : kPasscodeBoxHeight;
	
	for (int i = 0; i < kPasscodeBoxesCount; i++) {
		UIImageView *square = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"KKPasscodeLock.bundle/box_empty.png"]];
		square.frame = CGRectMake(squareX, self.isSmallLandscape ? 32.0f : 74.0, width, height);
		[squareViews addObject:square];
		squareX += self.isSmallLandscape ? 42.0f : 71.0;
	}
	return [NSArray arrayWithArray:squareViews];
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 0;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}


- (UITableViewCell*)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	static NSString* CellIdentifier = @"KKPasscodeViewControllerCell";
	
	UITableViewCell* cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	if ([aTableView isEqual:_enterPasscodeTableView]) {
		cell.accessoryView = _enterPasscodeTextField;
	} else if ([aTableView isEqual:_setPasscodeTableView]) {
		cell.accessoryView = _setPasscodeTextField;
	} else if ([aTableView isEqual:_confirmPasscodeTableView]) {
		cell.accessoryView = _confirmPasscodeTextField;
	}
	
	return cell;
}


#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
	if ([textField isEqual:[_textFields lastObject]]) {
		[self doneButtonPressed];
	} else {
		[self nextDigitPressed];
	}
	return NO;
}



- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
    textField.text = result;
    
    for (int i = 0; i < kPasscodeBoxesCount; i++) {
        UIImageView *square = [[_boxes objectAtIndex:_currentPanel] objectAtIndex:i];
        if (i < [result length]) {
            square.image = [UIImage imageNamed:@"KKPasscodeLock.bundle/box_filled.png"];
        } else {
            square.image = [UIImage imageNamed:@"KKPasscodeLock.bundle/box_empty.png"];
        }
    }
    
    if ([result length] == kPasscodeBoxesCount) {
        [self vaildatePasscode:textField];
    }
    
    return NO;
}



- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return _shouldReleaseFirstResponser;
}

#pragma mark - Rotation

- (void)orientationChange:(NSNotification*)notification {
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[[notification.userInfo objectForKey:UIApplicationStatusBarOrientationUserInfoKey] intValue];
    
    if(UIInterfaceOrientationIsPortrait(orientation)){
        [self performSelector:@selector(refreshTheInterfaceInPortrait) withObject:nil afterDelay:0.0];
    }
}

//We have to remove the status bar height in navBar and view after rotate
- (void) refreshTheInterfaceInPortrait {
    
    CGRect frameNavigationBar = self.navigationController.navigationBar.frame;
    CGRect frameView = self.view.frame;
    frameNavigationBar.origin.y -= 20;
    frameView.origin.y -= 20;
    frameView.size.height += 20;
    
    self.navigationController.navigationBar.frame = frameNavigationBar;
    self.view.frame = frameView;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:self.isSmallLandscape ? 10.0f : 14.0f]};
    CGSize size = [_failedAttemptsLabel.text sizeWithAttributes:attributes];
    _failedAttemptsLabel.frame = _failedAttemptsView.frame = CGRectMake((self.view.bounds.size.width - (size.width + (self.isSmallLandscape ? 20.0f : 40.0f))) / 2, self.isSmallLandscape ? 75.0f : 150.0f, size.width + (self.isSmallLandscape ? 20.0f : 40.0f), size.height + (self.isSmallLandscape ? 5.0f : 10.0f));
}

#pragma mark - TouchID Delegate
-(void) didBiometricAuthenticationSucceed{

    dispatch_async(dispatch_get_main_queue(), ^{
        
        DLog(@"KKPasscodeController. Biometric Succeeded");
        
        if ([_delegate respondsToSelector:@selector(didPasscodeEnteredCorrectly:)]) {
            [_delegate performSelector:@selector(didPasscodeEnteredCorrectly:) withObject:self];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    });

}


#pragma mark -
#pragma mark Memory management

@end
