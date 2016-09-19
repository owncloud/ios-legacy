//
//  ManageAppSettingsDB.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 24/06/13.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@interface ManageAppSettingsDB : NSObject

/*
 * Method that return if exist pass code or not
 */
+(BOOL)isPasscode;


/*
 * Method that insert pin code
 * @passcode -> pin code
 */
+(void) insertPasscode: (NSString *) passcode;

/*
 * Method that return the pin code
 */
+(NSString *) getPassCode;

/*
 * Method that remove the pin code
 */
+(void) removePasscode;


/*
 * Method that insert certificate
 * @certificateLocation -> path of certificate
 */
+(void) insertCertificate: (NSString *) certificateLocation;


/*
 * Method that return an array with all of certifications
 */
+(NSMutableArray*) getAllCertificatesLocation;


/*
 * Methods that manage Touh ID
 */
+(BOOL) isTouchID;
+(void) updateTouchIDTo:(BOOL)newValue;


/*
 * Methods manage instant uploads photos
 */
+(BOOL)isInstantUpload;
+(BOOL)isBackgroundInstantUpload;
+(void)updateInstantUploadTo:(BOOL)instantUpload;
+(void)updateBackgroundInstantUploadTo:(BOOL)newValue;
+(void)updatePathInstantUpload:(NSString *)newValue;
+(void)updateInstantUploadAllUser;
+(NSTimeInterval)getTimestampInstantUpload;
+(void)updateTimestampInstantUpload:(NSTimeInterval)newValue;
+(void)updateOnlyWifiInstantUpload:(BOOL)newValue;

@end
