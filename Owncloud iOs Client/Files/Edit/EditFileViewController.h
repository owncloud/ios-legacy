//
//  EditFileViewController.h
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 04/05/16.
//
//

#import <UIKit/UIKit.h>
#import "FileDto.h"

#define shareMainViewNibName @"EditFileViewController"

@interface EditFileViewController : UIViewController <ManageNetworkErrorsDelegate>

@property (nonatomic, strong) ManageNetworkErrors *manageNetworkErrors;

@property(nonatomic, strong) NSMutableArray *currentDirectoryArray;
@property(nonatomic, strong) FileDto *currentFileDto;
@property(nonatomic) UIAlertView *alert;


@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextView *bodyTextView;

- (id)initWithFileDto:(FileDto *)fileDto;
- (BOOL) checkForSameName:(NSString*)name;

@end
