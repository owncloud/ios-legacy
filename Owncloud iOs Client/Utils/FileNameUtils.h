//
//  FileNameUtils.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 02/04/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

typedef NS_ENUM (NSInteger, kindOfFileEnum){
    imageFileType = 0,
    videoFileType = 1,
    audioFileType = 2,
    officeFileType = 3,
    otherFileType = 4,
    gifFileType = 5,
};

@interface FileNameUtils : NSObject


/*
 * Method to obtain the extension of the file in upper case
 * @fileName -> file name
 */
+ (NSString *)getExtension:(NSString*)fileName;


+ (NSInteger) checkTheTypeOfFile: (NSString*)fileName;


/*
 * Method to know if the file is an image support for the system
 * Only JPG, PNG, GIF, TIFF, TIF, BMP, and JPEG images files are supported for the moment.
 * @fileName -> file name 
 */
+ (BOOL)isImageSupportedThisFile:(NSString*)fileName;

/*
 * Method to know if the file is supported by the API of the thumbnail
 * @fileName -> file name, ex: image.JPG
 */
+ (BOOL)isRemoteThumbnailSupportThiFile:(NSString*)fileName;

/*
 * Method to know if the file is an video file support for the system
 * Only MOV, MP4, M4V and 3GP video files are supported natively for iOS.
 * @fileName -> file name 
 */
+ (BOOL)isVideoFileSupportedThisFile:(NSString*)fileName;

/*
 * Method to know if the file is an video file support for the system
 * Only MP3, AIFF, AAC, WAV and M4A audio files are supported natively for iOS.
 * @fileName -> file name 
 */
+ (BOOL)isAudioSupportedThisFile:(NSString*)fileName;

/*
 * Method to know if the file is an office file support for the system
 * Only NUMBERS.ZIP, NUMBERS, PAGES.ZIP, PAGES, KEY.ZIP, KEY, TXT, PDF, DOC, XLS, PPT, RTF, DOCX, PPTX, XLSX, XML, HTM and HTML type of files
 * are supported for the moment.
 * @fileName -> file name
 */
+ (BOOL)isOfficeSupportedThisFile:(NSString*)fileName;

/*
 * Method to know if the file is an edit file supported by the system for the moment.
 * @fileName -> file name
 */
+ (BOOL)isEditTextViewSupportedThisFile:(NSString*)fileName;

/*
 * Method to know if the image file can be scaled.
 * Only JPG, PNG, BMP and JPEG images files can be scaled for the moment.
 * @fileName -> file name 
 */
+ (BOOL)isScaledThisImageFile:(NSString*)fileName;

/*
 * Method that return the name of the preview Image file in accordance with file name.
 * @fileName -> file name 
 */
+ (NSString*)getTheNameOfTheImagePreviewOfFileName:(NSString*)fileName;


/*
 * Method that check the file name or folder name to find forbidden characters
 * This is the forbidden characters in server: "\", "/","<",">",":",""","|","?","*"
 * @fileName -> file name
 *
 * @isFCSupported -> From ownCloud 8.1 the forbidden characters are controller by the server except the '/'
 */
+ (BOOL) isForbiddenCharactersInFileName:(NSString*)fileName withForbiddenCharactersSupported:(BOOL)isFCSupported;


/*
 * This method check and url and look for a saml fragment
 * and return the bollean result
 @response -> response
 */
+ (BOOL) isURLWithSamlFragment:(NSHTTPURLResponse *)response;


///-----------------------------------
/// @name Get the Name of the Brand Image
///-----------------------------------
/**
 * This method return a string with the name of the brand image
 * Used by ownCloud and other brands
 *
 * If the day of the year is 354 or more the string return is an
 * especial image for Christmas day.
 *
 * @return image name -> NSString
 */
+ (NSString *)getTheNameOfTheBrandImage;


///-----------------------------------
/// @name Get the Name of shared path
///-----------------------------------
/**
 * This method get the name of Share Path
 * Share path is like this: /documents/example.doc
 *
 * This method must be return "example.doc"
 *
 * @param sharePath -> NSString
 *
 * @param isDirectory -> BOOL
 *
 * @return NSString
 *
 */
+ (NSString*)getTheNameOfSharedPath:(NSString*)sharedPath isDirectory:(BOOL)isDirectory;

///-----------------------------------
/// @name Get the Parent Path of the Full Shared Path
///-----------------------------------
/**
 * This method make the parent path using the full path
 *
 * @param sharedPath -> NSString (/parentPath/path)
 *
 * @param isDirectory -> BOOL
 *
 * @return output -> NSString
 *
 */
+ (NSString*)getTheParentPathOfFullSharedPath:(NSString*)sharedPath isDirectory:(BOOL)isDirectory;


///-----------------------------------
/// @name markFileNameOnAlertView
///-----------------------------------
/**
 * This method marks the text on an alert View
 *
 * @param alertView -> UIAlertView
 */
+ (void)markFileNameOnAlertView: (UITextField *) textFieldToMark;

///-----------------------------------
/// @name getComposeNameFromAsset
///-----------------------------------
/*
 Method to generate the name of the file depending if it is a video or an image
 */
+ (NSString *)getComposeNameFromAsset:(ALAsset *)asset;

///-----------------------------------
/// @name getComposeNameFromPath
///-----------------------------------
/*
 Method to generate the name of the file depending if it is a video or an image
 */
+ (NSString *)getComposeNameFromPath:(NSString *) path;

///-----------------------------------
/// @name getComposeNameFromPHAsset
///-----------------------------------
/*
 Method to generate the name of the file depending if it is a video or an image
 */
+ (NSString *)getComposeNameFromPHAsset:(PHAsset *)asset;

@end
