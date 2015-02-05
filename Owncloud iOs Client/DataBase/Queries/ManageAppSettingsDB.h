//
//  ManageAppSettingsDB.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 24/06/13.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
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
 * Methods manage instant uploads photos
 */
+(BOOL)isInstantUpload;
+(void)updateInstantUploadTo:(BOOL)instantUpload;
+(void)updatePathInstantUpload:(NSString *)newValue;
+(void)updateDateInstantUpload:(long )newValue;
+(void)updateInstantUploadAllUser;
+(long)getDateInstantUpload;
+(void)updateOnlyWifiInstantUpload:(BOOL)newValue;


@end
