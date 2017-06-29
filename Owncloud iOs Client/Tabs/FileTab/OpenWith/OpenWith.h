//
//  OpenWith.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 21/08/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "Download.h"
#import "FileDto.h"


@protocol OpenWithDelegate

@optional
- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto;
- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto;
- (void)downloadCompleted:(FileDto*)fileDto;
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto;
- (void)reloadTableFromDataBase;
- (void)errorLogin;
@end


@interface OpenWith : NSObject <UIDocumentInteractionControllerDelegate, DownloadDelegate>

@property(nonatomic, strong) FileDto *file;
@property(nonatomic,weak) __weak id<OpenWithDelegate> delegate; 
@property(nonatomic, strong) UIView *parentView;
@property(nonatomic, strong) UIDocumentInteractionController *documentInteractionController;

@property(nonatomic, strong) UIBarButtonItem *parentButton;
@property(nonatomic, strong) Download *download;
@property(nonatomic, strong) NSString *currentLocalFolder;
//this bool is to indicate if the parent view is a cell
@property(nonatomic)  BOOL isTheParentViewACell;
//this CGRect is to pass the cell frame of the file list
@property(nonatomic) CGRect cellFrame;

- (void) downloadAndOpenWithFile: (FileDto *) file;
- (void) openWithFile: (FileDto *) file;
- (void) cancelDownload;
- (void) errorLogin;

@end
