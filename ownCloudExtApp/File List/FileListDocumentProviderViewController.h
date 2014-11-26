//
//  FileListDocumentProviderViewController.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 24/11/14.
//
//

#import <UIKit/UIKit.h>
#import "SimpleFileListTableViewController.h"

@interface FileListDocumentProviderViewController : SimpleFileListTableViewController

//Notification to notify that the user has change
extern NSString * userHasChangeNotification;

@end
