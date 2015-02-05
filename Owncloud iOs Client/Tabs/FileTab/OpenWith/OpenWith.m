//
//  OpenWith.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 21/08/12.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
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


@implementation OpenWith

@synthesize file = _file;
@synthesize delegate;
@synthesize parentView=_parentView;
@synthesize documentInteractionController=_documentInteractionController;
@synthesize download=_download;
@synthesize currentLocalFolder=_currentLocalFolder;
@synthesize parentButton=_parentButton;



-(id)init
{
    if (self = [super init])
    {
        // Set the constant
        _isTheParentViewACell=NO;
    }
    return self;
}

/*
 * This method download a file, update file info and then call  openWithFile.
 */

- (void)downloadAndOpenWithFile: (FileDto *) file{
    
    _file=file;
    
    
    //Phase 1. Check if this file is in the device
    if ([_file isDownload] == notDownload) {        
        //File is not in the device
        
        //Phase 1.1. Download the file
        DLog(@"Download the file");
        _download = [[Download alloc]init];
        _download.delegate=self;
        _download.currentLocalFolder=_currentLocalFolder;       
      
        [_download fileToDownload:_file];
        
    }else {
        //This file is in the device
        DLog(@"The file is in the device");
        //Phase 2. Open the file with "Open with" class
        [self openWithFile:file];
        
    }
    
}

-(void) cancelDownload{
    
    if (_download) {
        [_download cancelDownload];        
        _file=[ManageFilesDB getFileDtoByIdFile:_file.idFile];
    }
    
}

/*
 * This method open a file in other app if it's posibble
 */

- (void)openWithFile: (FileDto *) file{
    
    //Check if the localFolder is null. 
    if (file.localFolder) {
        
         BOOL canOpen = FALSE;
        
         DLog(@"File path is %@", file.localFolder);
        
        //Pass path to url
        NSURL *url = [NSURL fileURLWithPath:file.localFolder];
        
        //If exist the object dismiss the view
        if (_documentInteractionController) {
            [_documentInteractionController dismissMenuAnimated:YES];
        }
        
        //Create object
        _documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL: url];
        _documentInteractionController.delegate=self;
        
    
        if (IS_IPHONE) {
            //Present  view from rect
            canOpen = [_documentInteractionController presentOptionsMenuFromRect:CGRectMake(100, 100, 200, 400) inView:_parentView animated:YES];
            
           // canOpen = [_documentInteractionController presentOpenInMenuFromRect:CGRectMake(100, 100, 200, 400) inView:_parentView animated:YES];
        }else{
            
            if (_isTheParentViewACell) {
                //Present view from cell from file list
                canOpen = [_documentInteractionController presentOptionsMenuFromRect:_cellFrame inView:_parentView animated:YES];
                
            }else if (_parentButton){
                //Present view from bar button item
                canOpen = [_documentInteractionController presentOptionsMenuFromBarButtonItem:_parentButton animated:YES];
            }else{
                //Present  view from rect
                canOpen = [_documentInteractionController presentOptionsMenuFromRect:CGRectMake(100, 100, 200, 400) inView:_parentView animated:YES];
            }
        }
    
            
        if (!canOpen) {
            DLog(@"Problems with the interface");
        }

        
        
    }
        
}


#pragma mark - UIDocumentInteractoionController delegate methods


- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
   
    DLog(@"Document interaction Controller Did Dimiss Open in Menu");
}


- (void) documentInteractionControllerDidDismissOptionsMenu: (UIDocumentInteractionController *) controller
{
    DLog(@"Document interaction Controller Did Dimiss options menu");
}


- (void) documentInteractionController: (UIDocumentInteractionController *) controller willBeginSendingToApplication: (NSString *) application{
    
    DLog(@"The document is begin sending to Application: %@", application);
    
}

- (void) documentInteractionController: (UIDocumentInteractionController *) controller didEndSendingToApplication: (NSString *) application{
    
    DLog(@"The document was sent to Application: %@", application);
}

- (void) documentInteractionControllerWillBeginPreview: (UIDocumentInteractionController *) controller{
    
    DLog(@"The document interaction controller begin preview");
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller{
    
    DLog(@"The document interaction controller end preview");
}

- (void) documentInteractionControllerWillPresentOpenInMenu: (UIDocumentInteractionController *) controller{
    
    DLog(@"The document iteration will present open in menu");
}

- (void) documentInteractionControllerWillPresentOptionsMenu: (UIDocumentInteractionController *) controller{
    
    DLog(@"The document iteration will present options menu");
}


#pragma mark - DownloadInBackGround delegate methods


//The same method fot ipad

- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto{
    
    [delegate percentageTransfer:percent andFileDto:fileDto];
}
/*
 * This method tell this class to de file is in device
 */
- (void)downloadCompleted:(FileDto*)fileDto{
    
    //Actualizar fileDto
    _file=[ManageFilesDB getFileDtoByIdFile:_file.idFile];
    
    [delegate downloadCompleted:fileDto];

    [self openWithFile:_file];
}
- (void)reloadTableFromDataBaseAfterFileNotFound{
    [delegate reloadTableFromDataBase];    
}


/*
 * This method tell this class that exist an error and the file doesn't down to the device
 */
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto{
    
    [delegate downloadFailed:string andFile:fileDto];
}

/*
 * This method receive the string of download progress
 */

- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto{
    [delegate progressString:string andFileDto:fileDto];
    
}

- (void)errorLogin {
    [self.delegate errorLogin];
}


@end
