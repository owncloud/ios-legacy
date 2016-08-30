//
//  FileListDocumentProviderViewController.h
//  Owncloud iOs Client
//
//  Created by Javier Gonzalez on 24/11/14.
//
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import "SimpleFileListTableViewController.h"
#import "DPDownload.h"

@protocol FileListDocumentProviderViewControllerDelegate

@optional
- (void) openFile:(FileDto*)fileDto;
- (void) selectFolder:(FileDto*)fileDto;
- (void) closeDocumentPicker;
@end

@interface FileListDocumentProviderViewController : SimpleFileListTableViewController <DPDownloadDelegate>

//Notification to notify that the user has change
extern NSString *userHasChangeNotification;
extern NSString *userHasCloseDocumentPicker;

@property (nonatomic) BOOL isLockedApperance;
@property (nonatomic, strong) FileDto *selectedFile;
@property (nonatomic, strong) NSOperation *downloadOperation;
@property (nonatomic, strong) DPDownload *download;
@property(nonatomic,weak) __weak id<FileListDocumentProviderViewControllerDelegate> delegate;
@property BOOL isNecessaryAdjustThePositionAndTheSizeOfTheNavigationBar;
@property (nonatomic, strong) FileListDocumentProviderViewController *filesViewController;

//For Export and Move
@property (nonatomic) UIDocumentPickerMode mode;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *moveToThisLocationButton;

- (void) showErrorMessage:(NSString *)string;

- (IBAction)moveToThisLocationButtonTapped:(id)sender;

@end
