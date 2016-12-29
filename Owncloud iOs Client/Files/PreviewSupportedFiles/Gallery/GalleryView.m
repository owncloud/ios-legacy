//
//  GalleryViewController.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 04/04/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "GalleryView.h"

#import "UtilsDtos.h"
#import "FileNameUtils.h"
#import "UIImage+Resize.h"
#import "AppDelegate.h"
#import "ManageFilesDB.h"
#import "UIAlertView+Blocks.h"
#import "DetailViewController.h"
#import "constants.h"
#import "Customization.h"
#import "UtilsUrls.h"
#import "SyncFolderManager.h"

@interface GalleryView ()

@end

@implementation GalleryView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _galleryIsChangingSize = NO;
    }
    return self;
}


#pragma mark - Rotation Support

/*
 * This method prepare the scroll view content before the rotation
 * This method shoud be call in the willRotateToInterfaceOrientation parent view controller method
 */
- (void)prepareScrollViewBeforeTheRotation{
    
    self.galleryIsChangingSize = YES;
    
    // First, determine which page is currently visible
     CGFloat pageWidth = self.scrollView.frame.size.width;
     NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
     
     //We set the current page before rotate to return to this page
     self.currentNumberPage = page;    
}


/*
 * This method adjust the content of the new scroll view size after the rotation
 * This method sould be call in the willAnimateRotationToInterfaceOrientation parent view controller method
 */
- (void)adjustTheScrollViewAfterTheRotation{
    
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.galleryArray.count, pagesScrollViewSize.height);
    
    
    NSInteger pageCount = self.galleryArray.count;
    
    // Set up the array to hold the views for each page
    self.pageViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < pageCount; ++i) {
        [self.pageViews addObject:[NSNull null]];
    }
    
    
    [self.scrollView setContentOffset:[self offsetForPageAtIndex:self.currentNumberPage] animated:NO];
    
    
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(self.scrollView.bounds),
                                      CGRectGetMidY(self.scrollView.bounds));
    [self view:_loadingSpinner setCenter:centerPoint];
    
    self.galleryIsChangingSize = NO;
}

#pragma mark - Init Gallery Methods

/*
 * Init the array the images for the gallery
 * @sortedArray -> Array of files with the same order that filelist
 */
- (void)initArrayOfImagesWithArrayOfFiles:(NSArray*)sortedArray{
    
    //Obtain the files of directory and store the images
    _galleryArray = [[NSMutableArray alloc]init];
    
    if (sortedArray.count > 0) {
        NSInteger sections = sortedArray.count;
        NSArray *cells;
        FileDto *file;
        for (NSInteger i = 0; i<sections; i++) {
            
            cells=[sortedArray objectAtIndex:i];
            
            for (NSInteger j = 0; j<cells.count; j++) {
                file = (FileDto *)[cells objectAtIndex:j];
                //Know if the file is image
                if (!file.isDirectory) {
                    if ([FileNameUtils isImageSupportedThisFile:file.fileName]==YES) {
                        
                        [_galleryArray addObject:file];
                        DLog(@"file %@ isDownload: %ld", file.fileName, (long)file.isDownload);
                    }
                }
            }
            
        }

    } else{
        //Empty array
        [_galleryArray addObject:_file];
        
    }
    
}

///-----------------------------------
/// @name Update Images With New Array
///-----------------------------------

/**
 * This method update the array of images with a new file
 *
 * @param sortArray -> NSArray
 */
- (void)updateImagesArrayWithNewArray:(NSArray*) sortArray {
    
    __block NSMutableArray *compareArray = [NSMutableArray new];
    
    if (sortArray.count > 0) {
        NSInteger sections = sortArray.count;
        NSArray *cells;
        FileDto *file;
        
        for (NSInteger i = 0; i<sections; i++) {
            
            cells=[sortArray objectAtIndex:i];
            
            for (NSInteger j = 0; j<cells.count; j++) {
                file = (FileDto *)[cells objectAtIndex:j];
                //Know if the file is image
                if (!file.isDirectory) {
                    if ([FileNameUtils isImageSupportedThisFile:file.fileName]==YES) {
                        [compareArray addObject:file];
                    }
                }
            }
            
        }
        
        NSMutableArray *galleryCopy = [NSMutableArray arrayWithArray:_galleryArray];
        
        [galleryCopy enumerateObjectsUsingBlock:^(id obj, NSUInteger galleryIdx, BOOL *stop) {
            __block FileDto *image = (FileDto*)obj;
            
            [compareArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                FileDto *compareImage = (FileDto*)obj;
                
                if (image.idFile == compareImage.idFile) {
                    [_galleryArray replaceObjectAtIndex:galleryIdx withObject:compareImage];
                }else if ([image.filePath isEqualToString:compareImage.filePath]){
                    if ([image.fileName isEqualToString:compareImage.fileName]) {
                        [_galleryArray replaceObjectAtIndex:galleryIdx withObject:compareImage];
                    }
                }
            }];
            
        }];
        
        //Free memory
        galleryCopy = nil;
        compareArray = nil;
    }
}

/*
 * Init the main scroll view of the galley
 * @frame -> The frame of the container gallery of the parentView.
 */
- (void)initScrollView{
    
    _scrollView= [[UIScrollView alloc]initWithFrame:self.frame];
    _scrollView.delegate=self;
    _scrollView.autoresizingMask=UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.multipleTouchEnabled=YES;
    _scrollView.scrollEnabled=YES;
    _scrollView.clipsToBounds=YES;
    _scrollView.alwaysBounceHorizontal=YES;
    _scrollView.showsVerticalScrollIndicator=NO;
    _scrollView.showsHorizontalScrollIndicator=NO;
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.hidden=NO;
    _scrollView.pagingEnabled=YES;
    _scrollView.autoresizesSubviews=YES;
    
}

/*
 * Update the currentLocalFolder with the last file selected
 */
- (void)updateTheCurrentLocalFolder{
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    _currentLocalFolder = [NSString stringWithFormat:@"%@%ld/%@", [UtilsUrls getOwnCloudFilePath],(long)app.activeUser.idUser, [UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser]];
    _currentLocalFolder = [_currentLocalFolder stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
}

- (void)initGallery{
    
    //Get the currentLocalFolder
    [self updateTheCurrentLocalFolder];
   
    _fullScreen = NO;
    _isDoubleTap = YES;
    
    _visiblePageScrollViewArray = [[NSMutableArray alloc] init];
    
    // Set up the array to hold the views for each page
    self.pageViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < [self.galleryArray count]; ++i) {
        DLog(@"Adding %ld", (long)i);
        [self.pageViews addObject:[NSNull null]];
    }
    
    //Add gestures to the main scroll view.
    
    //Double touch
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [_scrollView addGestureRecognizer:doubleTap];
    
    //Single touch only for iphone
    if (IS_IPHONE) {
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [singleTap setNumberOfTapsRequired:1];
        
        [_scrollView addGestureRecognizer:singleTap];
        
        [singleTap requireGestureRecognizerToFail:doubleTap];
    
    }
    [self setTheScrollInTheCorrectPosition];
    
}


/*
 * Depend of the select file put the scroll to the correct position
 */
-(void)setTheScrollInTheCorrectPosition{
    
    NSInteger position = 0;
    
    //Get the index of this file
    for (NSInteger i = 0 ; i < [self.galleryArray count] ; i++) {
        
        FileDto *currentFile = [self.galleryArray objectAtIndex:i];
        
        DLog(@"%ld == %ld", (long)currentFile.idFile, (long)_file.idFile);
        
        if ([currentFile.fileName isEqualToString:_file.fileName] &&
            [currentFile.filePath isEqualToString:_file.filePath]) {
            position = i;
        }
    }
    
    // Set up the content size of the scroll view
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.galleryArray.count, pagesScrollViewSize.height);
    
    [self.scrollView setContentOffset:[self offsetForPageAtIndex:position] animated:NO];
    
    if (_file.isDownload==notDownload || (_file.isNecessaryUpdate && _file.isDownload != updating)) {
        [self downloadTheFile];
    } else if (_file.isDownload == downloading || _file.isDownload == updating) {
        
        //Get download object of the current file
         Download *download = [self getDownloadOfCurrentFile];
        
        //Check to know if it's in progress
        if (download && download.downloadTask && download.downloadTask.state == NSURLSessionTaskStateRunning) {
            [self contiueDownloadIfTheFileisDownloading];
        }else{
            [self restartTheDownload];
        }
    }
    
    // Load the initial set of pages that are on screen
    [self loadVisiblePages];
}



#pragma mark - FullScreen methods


-(void)showFullScreen{
    _fullScreen = YES;
    
    if (IS_IPHONE) {
        [_delegate setFullScreenGallery:_fullScreen];
    }
    [self setupTheContentOfScrollAfterFullScreen];
}

- (void)exitFullScreen{
    _fullScreen = NO;
    
    if (IS_IPHONE) {
         [_delegate setFullScreenGallery:_fullScreen];
    }
    [self setupTheContentOfScrollAfterFullScreen];
}

- (void)setupTheContentOfScrollAfterFullScreen{
    
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.galleryArray.count, pagesScrollViewSize.height);
    
    // First, determine which page is currently visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    [self.scrollView setContentOffset:[self offsetForPageAtIndex:page] animated:NO];
}


#pragma mark - Gesture methods

/*
 * Handle a single tap gesture in gallery for the fullscreen feature.
 */

-(void)handleSingleTap: (UITapGestureRecognizer*) recognizer {
    
    if (_fullScreen)
        [self exitFullScreen];
    else
        [self showFullScreen];
}

/*
 * Handle double tap gestures in gallery for the zoom feature.
 */

-(void)handleDoubleTap: (UITapGestureRecognizer*) recognizer {
    //   DLog(@"Double tap");
    
    if (_isDoubleTap) {
        _isDoubleTap=NO;
        //Zoom in
        CGFloat pageWidth = self.scrollView.frame.size.width;
        NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
        
        DLog(@"[self.visiblePageScrollViewArray count: %lu", (unsigned long)[self.visiblePageScrollViewArray count]);
        
        for (NSInteger i = 0 ; i < [self.visiblePageScrollViewArray count] ; i++) {
            
            UIScrollView *currentScroll = [self.visiblePageScrollViewArray objectAtIndex:i];
            
            DLog(@"Page: %ld Tag: %ld", (long)page, (long)currentScroll.tag);
            
            if(page == currentScroll.tag) {
                [currentScroll setZoomScale:3.0 animated:YES];
            }
        }
        
    }else{
        _isDoubleTap=YES;
        //Zoom out
        CGFloat pageWidth = self.scrollView.frame.size.width;
        NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
        
        for (int i = 0 ; i < [self.visiblePageScrollViewArray count] ; i++) {
            
            UIScrollView *currentScroll = [self.visiblePageScrollViewArray objectAtIndex:i];
            
            if(page == currentScroll.tag) {
                [currentScroll setZoomScale:1.0 animated:YES];
            }
        }
        
    }
    
}

#pragma mark - Download Methods

/*
 * Method to know if the actual image of the gallery is downloading
 *
 */
- (BOOL)isCurrentImageDownloading{
    
    BOOL isDownloading = NO;
    
    Download *download = nil;
    
    download = [self getDownloadOfCurrentFile];
    
    if (download)
        isDownloading = YES;
    
    return isDownloading;
}

///-----------------------------------
/// @name Get Downlod of Current File
///-----------------------------------

/**
 * This method return a download object equivalent with the
 * current file selected in the main view. 
 *
 * If not exist return nil.
 *
 * @return Download
 *
 */
- (Download *)getDownloadOfCurrentFile{
    
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSArray *downloads = [NSArray arrayWithArray:[app.downloadManager getDownloads]];
    
    __block Download *download = nil;
    
    [downloads enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        download = (Download*)obj;
        
        if ([download.fileDto.localFolder isEqualToString: _file.localFolder]) {
            *stop = YES;
 
        }
        
    }];
    
    return download;
}

/*
 * Cancel download feature. Action to cancel the download of a selected file.
 */
- (void) cancelCurrentDownload{
    
    Download *download = [self getDownloadOfCurrentFile];
    
    if (download)
        [download cancelDownload];
    
    
    //Update fileDto
    _file = [ManageFilesDB getFileDtoByIdFile:_file.idFile];
    
     [_loadingSpinner setHidden:YES];
    
}


- (void)downloadTheFile{
    
    if ([_file isDownload]==notDownload || _file.isNecessaryUpdate) {
        //Phase 1.2. If the image isn't in the device, download image
        DLog(@"The image is not download");
        Download *download=[[Download alloc]init];
        download.delegate=self;
        [self updateTheCurrentLocalFolder];
        download.currentLocalFolder=_currentLocalFolder;
        
        if (_file.isNecessaryUpdate) {
            //Show the progress bar and the notification
            [self performSelector:@selector(putUpdateProgressInNavBar) withObject:nil afterDelay:0.3];
        } else {
            if (!_loadingSpinner) {
                _loadingSpinner=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                [_loadingSpinner startAnimating];
                [_scrollView addSubview:_loadingSpinner];
            }else{
                [_loadingSpinner removeFromSuperview];
                [_scrollView addSubview:_loadingSpinner];
            }
            
            CGPoint centerPoint = CGPointMake(CGRectGetMidX(self.scrollView.bounds),
                                              CGRectGetMidY(self.scrollView.bounds));
            [self view:_loadingSpinner setCenter:centerPoint];
            
            _loadingSpinner.hidden=NO;
            
            [_loadingSpinner bringSubviewToFront:self.scrollView];
        }
        [download fileToDownload:_file];
    }
}

///-----------------------------------
/// @name Put the updating progress bar in the nav bar
///-----------------------------------

/**
 * This method includes the updating progress bar in the navigation bar
 */
- (void) putUpdateProgressInNavBar {
    [_delegate putUpdateProgressInNavBar];
}


///-----------------------------------
/// @name Restart the download
///-----------------------------------

/**
 * This method restart the download of the current file
 *
 */
- (void) restartTheDownload{
    DLog(@"restartTheDownload");
    if (([_file isDownload] == downloading) || ([_file isDownload] == updating)){
        
        Download *download = [self getDownloadOfCurrentFile];
        
        if (download) {
            
            if (!k_is_sso_active) {
                
                download.delegate = self;
                
                if (_file.isNecessaryUpdate) {
                    //Show the progress bar and the notification
                    [self performSelector:@selector(putUpdateProgressInNavBar) withObject:nil afterDelay:0.3];
                } else {
                    if (!_loadingSpinner) {
                        _loadingSpinner=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                        [_loadingSpinner startAnimating];
                        [_scrollView addSubview:_loadingSpinner];
                    }else{
                        [_loadingSpinner removeFromSuperview];
                        [_scrollView addSubview:_loadingSpinner];
                    }
                    
                    CGPoint centerPoint = CGPointMake(CGRectGetMidX(self.scrollView.bounds),
                                                      CGRectGetMidY(self.scrollView.bounds));
                    [self view:_loadingSpinner setCenter:centerPoint];
                    
                    _loadingSpinner.hidden=NO;
                    
                    [_loadingSpinner bringSubviewToFront:self.scrollView];
                }
                
                [download fileToDownload:_file];
            
            } else {
                //Cancel the current download
                [self cancelCurrentDownload];
                //Download again
                [self downloadTheFile];
            }
            
 
        }
    }
}


- (void)contiueDownloadIfTheFileisDownloading{
    
    if (_file.isDownload == downloading || _file.isDownload == updating){
        
        //Get the download object of the current file
        Download *download = [self getDownloadOfCurrentFile];
        
        if (!download) {
            //If the download not is in progress, download again
            
            //Set file like a not download and download again
            [ManageFilesDB setFileIsDownloadState:_file.idFile andState:notDownload];
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
            
            [self downloadTheFile];
            
        } else {
            
            download.delegate = self;
            
            if (_file.isDownload == updating) {
                //Show the progress bar and the notification
                [self performSelector:@selector(putUpdateProgressInNavBar) withObject:nil afterDelay:0.3];
            } else {
                //If the download is in progress update de screen objects
                if (!_loadingSpinner) {
                    _loadingSpinner=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                    [_loadingSpinner startAnimating];
                    [_scrollView addSubview:_loadingSpinner];
                }else{
                    [_loadingSpinner removeFromSuperview];
                    [_scrollView addSubview:_loadingSpinner];
                }
                CGPoint centerPoint = CGPointMake(CGRectGetMidX(self.scrollView.bounds),
                                                  CGRectGetMidY(self.scrollView.bounds));
                [self view:_loadingSpinner setCenter:centerPoint];
                
                _loadingSpinner.hidden=NO;
                [_loadingSpinner bringSubviewToFront:self.scrollView];
                
                //If is downloadTask suspended
                if (download.downloadTask.state == NSURLSessionTaskStateSuspended) {
                    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
                    [app.downloadManager addDownload:download];
                }

            }
        }
    }
}



#pragma mark - Download delegate methods

/*
 * This method receive the download progress and set valor to progressView.
 */


- (void)percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto{
    
    [_delegate percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto];
    
}

/*
 * This method receive the string of download progress
 */


- (void)progressString:(NSString*)string andFileDto:(FileDto*)fileDto{
        
}

/*
 * This method tell this class to de file is in device
 */
- (void)downloadCompleted:(FileDto*)fileDto{
    
    if ([fileDto.fileName isEqualToString:_file.fileName] && [fileDto.filePath isEqualToString:_file.filePath]) {
        DLog(@"Hey, file is in device, go to preview");
        BOOL isNecessaryUpdate = fileDto.isNecessaryUpdate;
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        _file = [ManageFilesDB getFileDtoByFileName:_file.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] andUser:app.activeUser];
        
        DLog(@"file: %@", _file.fileName);
        DLog(@"_path: %@", [UtilsUrls getFilePathOnDBByFilePathOnFileDto:_file.filePath andUser:app.activeUser] );
        
        DLog(@"Count self.galleryArray: %ld", (long)[self.galleryArray count]);
        
        for(NSInteger i = 0; i < [self.galleryArray count] ; i++) {
            FileDto *currentFile = [self.galleryArray objectAtIndex:i];
            
            currentFile = [ManageFilesDB getFileDtoByFileName:currentFile.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:currentFile.filePath andUser:app.activeUser] andUser:app.activeUser];
            
            DLog(@"Compare: %ld - %ld",(long) currentFile.idFile, (long)fileDto.idFile);
            
            if(currentFile.idFile == fileDto.idFile && currentFile != nil) {
                
                DLog(@"NEW - filepath: %@, fileName: %@", fileDto.filePath, fileDto. fileName);
                [self.galleryArray replaceObjectAtIndex:i withObject:fileDto];
            }
        }
        
        if (_file.idFile == fileDto.idFile) {
            
            [_delegate stopNotificationUpdatingFile];
            
            _loadingSpinner.hidden=YES;
            
            //We update in the list that the file is download
            for(int i = 0; i < [self.galleryArray count] ; i++) {
                FileDto *currentFile = [self.galleryArray objectAtIndex:i];
                if(currentFile.idFile == _file.idFile) {
                    [self.galleryArray replaceObjectAtIndex:i withObject:_file];
                }
            }
        }
        
        //Check if the file is an updating one
        if (isNecessaryUpdate) {
            //Reload the gallery view
            if (IS_IPHONE) {
                [_delegate handleFile];
            } else {
                [app.detailViewController openGalleryFileOnUpdatingProcess:NO];
                
            }
        } else {
            [self performSelector:@selector(loadVisiblePages) withObject:nil afterDelay:0.5];
        }
    }
}

/*
 * This method tell this class that exist an error and the file doesn't down to the device
 */
- (void)downloadFailed:(NSString*)string andFile:(FileDto*)fileDto{
    
    if (_file.idFile == fileDto.idFile) {
        //Show dummy image
        fileDto.localFolder = nil;
        fileDto.isDownload = NO;
        
        //We update in the list that the file is download
        for(int i = 0; i < [self.galleryArray count] ; i++) {
            FileDto *currentFile = [self.galleryArray objectAtIndex:i];
            if(currentFile.idFile == _file.idFile) {
                [self.galleryArray replaceObjectAtIndex:i withObject:fileDto];
            }
        }
        
        _loadingSpinner.hidden=YES;
        
        [self performSelector:@selector(loadVisiblePages) withObject:nil afterDelay:0.5];
        
        if(string) {
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            
            if (!app.downloadErrorAlertView) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    app.downloadErrorAlertView = [[UIAlertView alloc] initWithTitle:string message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                    app.downloadErrorAlertView.tag = k_alertview_for_download_error;
                    [app.downloadErrorAlertView show];
                });
            }
        }
        
        [_delegate stopNotificationUpdatingFile];
    }
    [_loadingSpinner setHidden:YES];
}


#pragma mark UIScrollView center method

- (void)view:(UIView*)view setCenter:(CGPoint)centerPoint
{
    DLog(@"Set center");
    
    CGRect vf = view.frame;
    CGPoint co = self.scrollView.contentOffset;
    
    CGFloat x = centerPoint.x - vf.size.width / 2.0;
    CGFloat y = centerPoint.y - vf.size.height / 2.0;
    
    if(x < 0)
    {
        co.x = -x;
        vf.origin.x = 0.0;
    }
    else
    {
        vf.origin.x = x;
    }
    if(y < 0)
    {
        co.y = -y;
        vf.origin.y = 0.0;
    }
    else
    {
        vf.origin.y = y;
    }
    
    view.frame = vf;
    self.scrollView.contentOffset = co;
}

- (CGPoint)offsetForPageAtIndex:(NSUInteger)index {
    CGRect pagingScrollViewFrame = self.scrollView.frame;
    
    CGPoint offset;
    
    offset.x = (pagingScrollViewFrame.size.width * index);
    offset.y = 0;
    
    
    DLog(@"offset.x: %f", offset.x);
    
    return offset;
}

#pragma mark UIScrollView Delegate methods

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return  self.currentImageView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    

    if (!self.galleryIsChangingSize) {
        
        [self loadVisiblePages];
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        // First, determine which page is currently visible
        CGFloat pageWidth = self.scrollView.frame.size.width;
        
        NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
        
        FileDto *tempFile = [_galleryArray objectAtIndex:page];
        FileDto *currentFile = [ManageFilesDB getFileDtoByFileName:tempFile.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:tempFile.filePath andUser:app.activeUser] andUser:app.activeUser];
        
        
        //Check if the currentFile is nil (for example when the user has rename this file)
        if (!currentFile) {
            currentFile = [ManageFilesDB getFileDtoByIdFile:tempFile.idFile];
            if (currentFile) {
                [_galleryArray replaceObjectAtIndex:page withObject:currentFile];
            }
        }
        
        //Indicate the current file select to delegate class
        if (currentFile) {
            _file=currentFile;
        }else{
            _file=tempFile;
        }
        
        
        [_delegate selectThisFile:_file];
        
        [[AppDelegate sharedSyncFolderManager] cancelDownload:currentFile];
        currentFile = [ManageFilesDB getFileDtoByFileName:currentFile.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:currentFile.filePath andUser:app.activeUser] andUser:app.activeUser];
        
        if (_file.isDownload == updating) {
            [self putUpdateProgressInNavBar];
        }
        
        
        if (currentFile.isDownload==notDownload) {
            //Indicate the current file select to delegate class
            _file=currentFile;
            [self downloadTheFile];
        } else if (currentFile.isDownload==downloading || currentFile.isDownload == updating) {
            
            //Get download of current file
            Download *download = [self getDownloadOfCurrentFile];
            
            //Check to know if it's in progress
            if (download && download.downloadTask && download.downloadTask.state == NSURLSessionTaskStateRunning) {
                [self contiueDownloadIfTheFileisDownloading];
            }else{
                [self restartTheDownload];
            }
            
            /*  CGPoint centerPoint = CGPointMake(CGRectGetMidX(self.scrollView.bounds),
             CGRectGetMidY(self.scrollView.bounds));
             [self view:_loadingSpinner setCenter:centerPoint];
             _loadingSpinner.hidden=NO;*/
        }

    }
 
}

- (void)scrollViewDidZoom:(UIScrollView *)sv
{
    UIView* zoomView = [sv.delegate viewForZoomingInScrollView:sv];
    CGRect zvf = zoomView.frame;
    if(zvf.size.width < sv.bounds.size.width)
    {
        zvf.origin.x = (sv.bounds.size.width - zvf.size.width) / 2.0;
    }
    else
    {
        zvf.origin.x = 0.0;
    }
    if(zvf.size.height < sv.bounds.size.height)
    {
        zvf.origin.y = (sv.bounds.size.height - zvf.size.height) / 2.0;
    }
    else
    {
        zvf.origin.y = 0.0;
    }
    zoomView.frame = zvf;
    
}

#pragma mark - Scroll Gallery Methods
- (void)loadVisiblePages {
    // First, determine which page is currently visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    DLog(@"Gallery size: %ld - Page: %ld", (long)[self.galleryArray count], (long)page);
    FileDto *currentFile = [self.galleryArray objectAtIndex:page];
    DLog(@"Image: %@", currentFile.fileName);
    
    // Work out which pages we want to load
    NSInteger firstPage = page - 1;
    NSInteger lastPage = page + 1;
    
    // Purge anything before the first page
    for (NSInteger i=0; i<firstPage; i++) {
        [self purgePage:i];
    }
    for (NSInteger i=firstPage; i<=lastPage; i++) {
        
        //Remove all the zoom of all images
        if(currentFile.idFile != _file.idFile) {
            [_delegate stopNotificationUpdatingFile];
            for(int j = 0 ; j < [self.visiblePageScrollViewArray count] ; j ++) {
                UIScrollView *currentScroll = [self.visiblePageScrollViewArray objectAtIndex:j];
                @try {
                    [currentScroll setZoomScale:1.0 animated:NO];
                }
                @catch (NSException *exception) {
                    DLog(@"Image not downloading");
                }
                @finally {
                }
            }
        }
        if(i==page) {
            
            [self loadPage:i];
            
            self.currentImageView = [self.pageViews objectAtIndex:i];
            
        } else if((currentFile.isDownload || currentFile.localFolder == nil)){
            [self loadPage:i];
        }
    }
    for (NSInteger i=lastPage+1; i<self.galleryArray.count; i++) {
        [self purgePage:i];
    }
}

- (void)loadPage:(NSInteger)page {
    
    if (page < 0 || page >= self.galleryArray.count) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger currentPage = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    // Load an individual page, first seeing if we've already loaded it
    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView == [NSNull null]) {
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        
        DLog(@"File name before: %@", _file.fileName);
        
        if (page == currentPage) {
            DLog(@"PAGE: %ld", (long)page);
            _file = [self.galleryArray objectAtIndex:page];
        }
        
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        
        FileDto *theFile = [self.galleryArray objectAtIndex:page];
        theFile = [ManageFilesDB getFileDtoByFileName:theFile.fileName andFilePath:[UtilsUrls getFilePathOnDBByFilePathOnFileDto:theFile.filePath andUser:app.activeUser] andUser:app.activeUser];
        
        //  DLog(@"File name after: %@", _file.fileName);
        
        if((theFile.isDownload == downloaded) || theFile.isDownload == updating || [theFile.localFolder isEqualToString:@""]) {
            
            UIImage * myImage;
           
            if(theFile.localFolder == nil) {
                myImage = [UIImage imageNamed:@"image_fail_download.png"];
            } else {
                myImage = [UIImage imageWithContentsOfFile: theFile.localFolder];
                
                if ([FileNameUtils isScaledThisImageFile:theFile.fileName]) {
                    CGSize theSize = self.scrollView.frame.size;
                    theSize.width=theSize.width*2;
                    theSize.height=theSize.height*2;
                    
                    UIImage * scaledImage;
                    scaledImage = [myImage resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:theSize interpolationQuality:kCGInterpolationHigh];
                    
                    //check the scaled image. If with or height are <1, we use the origin image
                    if (scaledImage.size.width<1 || scaledImage.size.height<1) {
                        //nothing
                         DLog(@"Original size - Width: %f and Height: %f", myImage.size.width, myImage.size.height);
                    }else{
                        //If the image is corrected resizing, we use the scaled image.
                        myImage=scaledImage;
                        DLog(@"Resizing Image size - Width: %f and Height: %f", myImage.size.width, myImage.size.height);
                    }
                }
                
            }
            UIImageView *imageView;
            imageView = [[UIImageView alloc] initWithImage: myImage];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.frame = CGRectMake(0,0,frame.size.width, frame.size.height);
            
            UIScrollView  *subScrollView= [[UIScrollView alloc] initWithFrame:CGRectMake(frame.origin.x,frame.origin.y,frame.size.width, frame.size.height)];
            
            subScrollView.backgroundColor=[UIColor blackColor];
            subScrollView.minimumZoomScale = 1.0;
            subScrollView.maximumZoomScale = 10.0;
            subScrollView.delegate = self;
            subScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin ;
            subScrollView.contentSize = myImage.size;
            
            CGFloat scrollViewHeight = 0.0f;
            CGFloat scrollViewWidth = 0.0f;
            
            for (UIView* view in subScrollView.subviews)
            {
                scrollViewHeight += view.frame.size.height;
                scrollViewWidth += view.frame.size.width;
            }
            
            subScrollView.tag = page;
            
            [subScrollView setContentSize:(CGSizeMake(scrollViewWidth, scrollViewHeight))];
            
            [subScrollView  addSubview:imageView];
            [self.scrollView addSubview: subScrollView];
            
            //Add visibles scroll to works on double tap
            for(int j = 0 ; j < [self.visiblePageScrollViewArray count] ; j++) {
                UIScrollView *currentScroll = [self.visiblePageScrollViewArray objectAtIndex:j];
                if(page == currentScroll.tag) {
                    [self.visiblePageScrollViewArray removeObjectAtIndex:j];
                }
            }
            [self.visiblePageScrollViewArray addObject:subScrollView];
            
            [self.pageViews replaceObjectAtIndex:page withObject:imageView];
        }
    }
}

- (void)purgePage:(NSInteger)page {
    if (page < 0 || page >= self.galleryArray.count) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    // Remove a page from the scroll view and reset the container array
    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView != [NSNull null]) {
        [pageView removeFromSuperview];
        [self.pageViews replaceObjectAtIndex:page withObject:[NSNull null]];
    }
}

#pragma mark - Error login delegate method

- (void) errorLogin {
    
    [_delegate errorLogin];
    
}

#pragma mark - UIAlertViewDelegate 

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (alertView.tag) {
        case k_alertview_for_download_error: {
            //OK
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
            app.downloadErrorAlertView = nil;
    
            break;
        }
        default:
            break;
    }
    
}


@end
