//
//  GalleryViewController.h
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

#import <UIKit/UIKit.h>
#import "FileDto.h"
#import "Download.h"



@protocol GalleryViewDelegate

@optional
- (void) selectThisFile:(FileDto*)file;
- (void) putUpdateProgressInNavBar;
- (void) stopNotificationUpdatingFile;
- (void) percentageTransfer:(float)percent andFileDto:(FileDto*)fileDto;
- (void) handleFile;
- (void) setFullScreenGallery:(BOOL)isFullScreen;
- (void) errorLogin;
- (void) contiueDownloadIfTheFileisDownloading;
@end

@interface GalleryView : UIView<UIScrollViewDelegate, DownloadDelegate, UIAlertViewDelegate>

@property (nonatomic,strong) FileDto *file;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) UIImageView *currentImageView;
@property (nonatomic,strong) UIActivityIndicatorView *loadingSpinner;
@property (nonatomic,strong) NSMutableArray *galleryArray;
@property (nonatomic,strong) NSMutableArray *pageViews;
@property (nonatomic,strong) NSMutableArray *visiblePageScrollViewArray;
@property (nonatomic,strong) NSString *currentLocalFolder;

@property NSInteger currentNumberPage;
@property (nonatomic)BOOL isDoubleTap;
@property (nonatomic)BOOL fullScreen;
@property (nonatomic)BOOL galleryIsChangingSize;
@property(nonatomic,strong) id<GalleryViewDelegate> delegate;


/*
 * Init the array the images for the gallery
 * @sortedArray -> Array of files with the same order that filelist
 */
- (void)initArrayOfImagesWithArrayOfFiles:(NSArray*)sortedArray;

/*
 * Init the main scroll view of the galley
 */
- (void)initScrollView;

/*
 * Init the gallery with the array of images in the scroll
 */
- (void)initGallery;

/*
 * Method to know if the actual image of the gallery is downloading
 *
 */
- (BOOL)isCurrentImageDownloading;


/*
 * This method prepare the scroll view content before the rotation
 * This method shoud be call in the willRotateToInterfaceOrientation parent view controller method
 */
- (void)prepareScrollViewBeforeTheRotation;


/*
 * This method adjust the content of the new scroll view size after the rotation
 * This method sould be call in the willAnimateRotationToInterfaceOrientation parent view controller method
 */
- (void)adjustTheScrollViewAfterTheRotation;


///-----------------------------------
/// @name Update Images With New Array
///-----------------------------------

/**
 * This method update the array of images with a new file
 *
 * @param sortArray -> NSArray
 */
- (void)updateImagesArrayWithNewArray:(NSArray*) sortArray;

-(void)showFullScreen;
- (void)exitFullScreen;


@end
