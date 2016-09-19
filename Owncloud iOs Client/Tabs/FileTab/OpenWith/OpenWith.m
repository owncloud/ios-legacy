//
//  OpenWith.m
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

#import "OpenWith.h"
#import "FileDto.h"
#import "UserDto.h"
#import "ManageFilesDB.h"
#import "FileNameUtils.h"
#import "AppDelegate.h"
#import "DetailViewController.h"
#import "TTOpenInAppActivity.h"



@implementation OpenWith



-(id)init
{
    if (self = [super init])
    {
        // Set the constant
        _isTheParentViewACell = NO;
    }
    return self;
}

/*
 * This method download a file, update file info and then call  openWithFile.
 */

- (void)downloadAndOpenWithFile: (FileDto *) file{
    
    self.file=file;
    
    
    //Phase 1. Check if this file is in the device
    if ([self.file isDownload] == notDownload) {
        //File is not in the device
        
        //Phase 1.1. Download the file
        DLog(@"Download the file");
        self.download = [[Download alloc]init];
        self.download.delegate = self;
        self.download.currentLocalFolder = self.currentLocalFolder;
      
        [self.download fileToDownload:_file];
        
    }else {
        //This file is in the device
        DLog(@"The file is in the device");
        //Phase 2. Open the file with "Open with" class
        [self openWithFile:file];
        
    }
    
}

-(void) cancelDownload{
    
    if (self.download) {
        [self.download cancelDownload];
        self.file=[ManageFilesDB getFileDtoByIdFile:_file.idFile];
    }
    
}

/*
 * This method open a file in other app if it's posibble
 */

- (void)openWithFile: (FileDto *) file{
    
    //Check if the localFolder is null. 
    if (file.localFolder) {
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
         DLog(@"File path is %@", file.localFolder);
        
        //Pass path to url
        NSURL *url = [NSURL fileURLWithPath:file.localFolder];
        
        TTOpenInAppActivity *openInAppActivity;
        
        if (_isTheParentViewACell) {
            openInAppActivity = [[TTOpenInAppActivity alloc] initWithView:self.parentView andRect:_cellFrame];
            
        }else{
            openInAppActivity = [[TTOpenInAppActivity alloc] initWithView:self.parentView andBarButtonItem:self.parentButton];
        }

        
        if (self.activityView) {
            [self.activityView dismissViewControllerAnimated:YES completion:nil];
            self.activityView = nil;
        }
        
        if (self.activityPopoverController) {
            [self.activityPopoverController dismissPopoverAnimated:YES];
            self.activityPopoverController = nil;
        }
        
        self.activityView = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:@[openInAppActivity]];
        
        if (IS_IPHONE) {
            
            openInAppActivity.superViewController = self.activityView;
            
            [app.ocTabBarController presentViewController:self.activityView animated:YES completion:nil];
        } else {
            
            if (self.activityPopoverController) {
                [self.activityPopoverController setContentViewController:self.activityView];
            } else {
                self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.activityView];
            }
            
            openInAppActivity.superViewController = self.activityPopoverController;
            
            if (_isTheParentViewACell && IS_PORTRAIT && (IS_IOS8 || IS_IOS9)) {
              
                [self.activityPopoverController presentPopoverFromRect:CGRectMake(app.detailViewController.view.frame.size.width/2, app.detailViewController.view.frame.size.width/2, 100, 100) inView:app.detailViewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                
            }else{
                
                if (_isTheParentViewACell) {
                    //Present view from cell from file list
                    [self.activityPopoverController presentPopoverFromRect:_cellFrame inView:_parentView permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                    
                } else if (_parentButton) {
                    //Present view from bar button item
                    [self.activityPopoverController presentPopoverFromBarButtonItem:_parentButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                    
                } else {
                    //Present  view from rect
                    [self.activityPopoverController presentPopoverFromRect:CGRectMake(100, 100, 200, 400) inView:_parentView permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
                }
            }
        }
    }
}


#pragma mark - DownloadInBackGround delegate methods


//The same method fot ipad

- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto{
    
    [self.delegate percentageTransfer:percent andFileDto:fileDto];
}
/*
 * This method tell this class to de file is in device
 */
- (void)downloadCompleted:(FileDto*)fileDto{
    
    //Actualizar fileDto
    self.file=[ManageFilesDB getFileDtoByIdFile:self.file.idFile];
    
    [self.delegate downloadCompleted:fileDto];

    [self openWithFile:self.file];
}
- (void)reloadTableFromDataBaseAfterFileNotFound{
    [self.delegate reloadTableFromDataBase];
}


/*
 * This method tell this class that exist an error and the file doesn't down to the device
 */
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto{
    
    [self.delegate downloadFailed:string andFile:fileDto];
}

/*
 * This method receive the string of download progress
 */

- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto{
    [self.delegate progressString:string andFileDto:fileDto];
    
}

- (void)errorLogin {
    [self.delegate errorLogin];
}


@end
