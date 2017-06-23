//
//  ShareUtils.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 25/1/16.
//  Edited by Noelia Alvarez
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "OCShareUser.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "Customization.h"

@interface ShareUtils : NSObject

+ (NSMutableArray *) manageTheDuplicatedUsers: (NSMutableArray*) items;

+ (NSURL *) getNormalizedURLOfShareLink:(NSString *) url;


#pragma mark - capabilities checks

+ (BOOL) isPasswordEnforcedCapabilityEnabled;

+ (BOOL) hasOptionAllowEditingToBeShownForFile:(FileDto *)file;
+ (BOOL) hasOptionShowFileListingToBeShownForFile:(FileDto *)file;
+ (BOOL) hasOptionLinkNameToBeShown;
+ (BOOL) hasMultipleShareLinkAvailable;
+ (BOOL) hasPasswordRemoveOptionAvailable;
+ (BOOL) hasExpirationRemoveOptionAvailable;
+ (BOOL) hasExpirationDefaultDateToBeShown;


#pragma mark - Get default values

+ (NSString *) getDefaultLinkNameNormalizedOfFile:(FileDto *)file withLinkShares:(NSArray *)publicLinkShared;

+ (long) getDefaultMinExpirationDateInTimeInterval;
+ (long) getDefaultMaxExpirationDateInTimeInterval;


#pragma mark - convert date

+ (NSDate *) addDays:(NSInteger)days toDate:(NSDate *)date;
+ (NSString *) convertDateInServerFormat:(NSDate *)date;
+ (NSString *) stringOfDate:(NSDate *) date;

#pragma mark - display utils

+ (NSString *) getDisplayNameForSharee:(OCShareUser *)sharee;


+ (NSString *) getPrivateLinkOfFile:(FileDto *)fileDto;

@end
