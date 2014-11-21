//
//  ELCImagePickerController.m
//  ELCImagePickerDemo
//
//  Created by ELC on 9/9/10.
//  Copyright 2010 ELC Technologies. All rights reserved.
//

#import "AppDelegate.h"
#import "ELCImagePickerController.h"
#import "ELCAsset.h"
#import "ELCAssetCell.h"
#import "OCELCAssetTablePicker.h"
#import "ELCAlbumPickerController.h"

@implementation ELCImagePickerController

@synthesize delegate = _myDelegate;

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.currentViewVisible = self;
    
}

- (void)cancelImagePicker
{
	if([_myDelegate respondsToSelector:@selector(elcImagePickerControllerDidCancel:)]) {
		[_myDelegate performSelector:@selector(elcImagePickerControllerDidCancel:) withObject:self];
	}
}

-(void)selectedAssets:(NSArray*)assets andURL:(NSString*)urlToUpload {
	DLog(@"selectedAssets");
    
    NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
    [args setObject:assets forKey:@"assets"];
    [args setObject:urlToUpload forKey:@"urlToUpload"];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self performSelector:@selector(initThredInABackgroundThread:) withObject:args afterDelay:0.2];
    
    [args release];
}

-(void) initThredInABackgroundThread:(NSMutableDictionary*)args{
    [self performSelectorInBackground:@selector(initInOtherThread:) withObject:args];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
    }
}

-(void)initInOtherThread:(NSMutableDictionary*)args{
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    
    NSArray *_assets = [args objectForKey:@"assets"];
    NSString *urlToUpload = [args objectForKey:@"urlToUpload"];
    
    NSMutableDictionary *workingDictionary;
    
	for(ALAsset *asset in _assets) {
        
       // workingDictionary = nil;
		workingDictionary = [[NSMutableDictionary alloc] init];
		[workingDictionary setObject:[asset valueForProperty:ALAssetPropertyType] forKey:@"UIImagePickerControllerMediaType"];
		[workingDictionary setObject:[[asset valueForProperty:ALAssetPropertyURLs] valueForKey:[[[asset valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]] forKey:@"UIImagePickerControllerReferenceURL"];
        
            
		[returnArray addObject:workingDictionary];
        
        [workingDictionary release];
        
        //Code to implemente the change of name
        // NSString *fileName = asset.defaultRepresentation.filename;
       // DLog(@"filename is: %@", fileName);
        
        DLog(@"Doing something");

	}
    
	if([_myDelegate respondsToSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:inURL:)]) {
        /*[delegate performSelector:@selector(elcImagePickerController:didFinishPickingMediaWithInfo:inURL:) withObject:self withObject:[NSArray arrayWithArray:returnArray] withObject:urlToUpload];*/
        [_myDelegate elcImagePickerController:self didFinishPickingMediaWithInfo:[NSArray arrayWithArray:returnArray] inURL:urlToUpload];
	}
    
    [returnArray release];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    NSLog(@"ELC Image Picker received memory warning.");
    
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)dealloc
{
    NSLog(@"deallocing ELCImagePickerController");
    [super dealloc];
}

@end
