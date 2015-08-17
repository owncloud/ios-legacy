//
//  ShareMainViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/8/15.
//
//

#import <UIKit/UIKit.h>
#import "ShareFileOrFolder.h"
#import "MBProgressHUD.h"
#import "FileDto.h"

@interface ShareMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ShareFileOrFolderDelegate, MBProgressHUDDelegate, UIAlertViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView* shareTableView;
@property (strong, nonatomic) UIView* datePickerContainerView;
@property (strong, nonatomic) UIDatePicker *datePickerView;
@property (strong, nonatomic) UIView* pickerView;

- (id) initWithFileDto:(FileDto *)fileDto;

@end
