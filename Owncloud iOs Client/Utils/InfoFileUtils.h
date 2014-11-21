//
//  InfoFileUtils.h
//  Owncloud iOs Client
//
//  Created by Rebeca Martín de León on 06/03/14.
//

/*
 Copyright (C) 2014, ownCloud, Inc.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>

@interface InfoFileUtils : NSObject

///-----------------------------------
/// @name getTheDifferenceBetweenDateOfUploadAndNow
///-----------------------------------

/**
 * This method obtains the difference between the upload date and the received date doing
 * a custom string like a:
 * seconds ago
 * minutes ago
 * hours ago
 * days ago
 * the date of upload (When the days > 30)
 *
 * @param NSDate -> date
 *
 * @return NSString -> The searched date
 */
+ (NSString *)getTheDifferenceBetweenDateOfUploadAndNow:(NSDate *)date;

@end
