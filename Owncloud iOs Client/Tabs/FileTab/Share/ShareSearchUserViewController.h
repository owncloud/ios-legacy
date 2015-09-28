//
//  ShareSearchUserViewController.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 28/9/15.
//
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"


@interface ShareSearchUserViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate, UISearchDisplayDelegate>

@property (weak, nonatomic) IBOutlet UITableView* searchTableView;
@property(nonatomic,strong) IBOutlet UISearchBar *itemSearchBar;

@end
