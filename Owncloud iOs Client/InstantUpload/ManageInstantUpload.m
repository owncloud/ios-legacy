//
//  ManageInstantUpload.m
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 08/01/15.
//
//

#import "ManageInstantUpload.h"
#import "AppDelegate.h"
#import "PrepareFilesToUpload.h"

@implementation ManageInstantUpload


- (void) initPrepareFiles:(NSArray *) newAsssets andRemoteFolder: (NSString *) remoteFolder{
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [app.prepareFiles addAssetsToUpload: newAsssets andRemoteFolder: remoteFolder];
    
    
    //Init loading to prepare files to upload
   // [self initLoading];
    //Set global loading screen global flag to YES (only for iPad)
   // app.isLoadingVisible = YES;
}


@end
