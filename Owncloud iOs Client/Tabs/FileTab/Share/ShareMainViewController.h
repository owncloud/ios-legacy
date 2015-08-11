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

@interface ShareMainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ShareFileOrFolderDelegate, MBProgressHUDDelegate, UIAlertViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView* shareTableView;

- (id) initWithFileDto:(FileDto *)fileDto;

@end
