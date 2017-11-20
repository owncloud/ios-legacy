//
//  ShareUtils.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 25/1/16.
//  Edited by Noelia Alvarez
//
//

#import "ShareUtils.h"
#import "FileDto.h"
#import "UtilsUrls.h"
#import "InfoFileUtils.h"
#import "constants.h"

#define k_share_link_middle_part_url_before_version_8 @"public.php?service=files&t="
#define k_share_link_middle_part_url_after_version_8 @"index.php/s/"

#define k_server_version_with_new_shared_schema 8

#define dateServerFormat @"YYYY-MM-dd"

#define k_pathPrivateLink @"index.php/f/"


@implementation ShareUtils

+ (NSMutableArray *) manageTheDuplicatedUsers: (NSMutableArray*) items{
    
    for (OCShareUser *userOrGroup in items) {
        NSMutableArray *restOfItems = [NSMutableArray arrayWithArray:items];
        [restOfItems removeObjectIdenticalTo:userOrGroup];
        
        if(restOfItems.count == 0)
            userOrGroup.isDisplayNameDuplicated = NO;
        
        else{
            for (OCShareUser *tempItem in restOfItems) {
                if ([userOrGroup.displayName isEqualToString:tempItem.displayName] && ((!userOrGroup.server && !tempItem.server) || ([userOrGroup.server isEqualToString:tempItem.server]))){
                    userOrGroup.isDisplayNameDuplicated = YES;
                    break;
                }
            }
        }
    }
    
    return items;
}


+ (NSURL *) getNormalizedURLOfShareLink:(OCSharedDto *)sharedLink {
    
    
    NSString *urlSharedLink = sharedLink.url ? sharedLink.url : sharedLink.token;
    
    NSString *url = nil;
    // From ownCloud server 8.2 the url field is always set for public shares
    if ([urlSharedLink hasPrefix:@"http://"] || [urlSharedLink hasPrefix:@"https://"])
    {
        url = urlSharedLink;
    }else{
        //Token
        NSString *firstNumber = [[AppDelegate sharedOCCommunication].getCurrentServerVersion substringToIndex:1];
        
        if (firstNumber.integerValue >= k_server_version_with_new_shared_schema) {
            // From ownCloud server version 8 on, a different share link scheme is used.
            url = [NSString stringWithFormat:@"%@%@%@", APP_DELEGATE.activeUser.url, k_share_link_middle_part_url_after_version_8, sharedLink];
        }else{
            url = [NSString stringWithFormat:@"%@%@%@", APP_DELEGATE.activeUser.url, k_share_link_middle_part_url_before_version_8, sharedLink];
        }
    }
    
    return  [NSURL URLWithString:url];
}


#pragma mark - capabilities checks

+ (BOOL) hasOptionAllowEditingToBeShownForFile:(FileDto *)file {
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (((app.activeUser.hasCapabilitiesSupport != serverFunctionalitySupported) ||
         (app.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && app.activeUser.capabilitiesDto.isFilesSharingAllowPublicUploadsEnabled))
        && file.isDirectory){
        return YES;
    }
    
    return NO;
}

+ (BOOL) hasOptionShowFileListingToBeShownForFile:(FileDto *)file {
    
    if ([self hasOptionAllowEditingToBeShownForFile:file] && APP_DELEGATE.activeUser.hasPublicShareLinkOptionUploadOnlySupport){
        return YES;
    }
    
    
    return NO;
}

+ (BOOL) hasOptionLinkNameToBeShown {
    
    if (APP_DELEGATE.activeUser.hasPublicShareLinkOptionNameSupport) {
        return YES;
    }
    
    return NO;
}

+ (BOOL) hasMultipleShareLinkAvailable {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (app.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && app.activeUser.capabilitiesDto.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled) {
        return YES;
    }
        
    return NO;
}

+ (BOOL) hasPasswordRemoveOptionAvailable {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    if (app.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && app.activeUser.capabilitiesDto.isFilesSharingPasswordEnforcedEnabled) {
        return NO;
    }
    
    return YES;
}

+ (BOOL) hasExpirationRemoveOptionAvailable {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    if (app.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && app.activeUser.capabilitiesDto.isFilesSharingExpireDateEnforceEnabled) {
        return NO;
    }
    
    return YES;
}

+ (BOOL) hasExpirationDefaultDateToBeShown {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication]delegate];

    if (app.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && app.activeUser.capabilitiesDto.isFilesSharingExpireDateByDefaultEnabled) {
        return YES;
    }
    
    return NO;
}

+ (BOOL) isPasswordEnforcedCapabilityEnabled {
    
    
    if ((APP_DELEGATE.activeUser.hasCapabilitiesSupport != serverFunctionalitySupported) ||
        (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported && APP_DELEGATE.activeUser.capabilitiesDto && APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingPasswordEnforcedEnabled) ) {
        
        return YES;
    }
    
    return NO;
}

+ (BOOL)isAllowedReshareForFile:(FileDto *)file {
    
    BOOL fileSharedWithMe = [file.permissions rangeOfString:k_permission_shared].location != NSNotFound ;
    
    if (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported &&
        APP_DELEGATE.activeUser.capabilitiesDto &&
        !APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingReSharingEnabled &&
        fileSharedWithMe) {
        
        return NO;
    }
    
    return YES;
}

+(BOOL)hasShareOptionToBeHidden {
    
    if ((k_hide_share_options) ||
        (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported &&
         APP_DELEGATE.activeUser.capabilitiesDto &&
         !APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAPIEnabled)) {
            return YES;
        }
    
    return NO;
}

+(BOOL)hasShareOptionToBeHiddenForFile:(FileDto *)file {
    
    if ((k_hide_share_options) ||
        (APP_DELEGATE.activeUser.hasCapabilitiesSupport == serverFunctionalitySupported &&
         APP_DELEGATE.activeUser.capabilitiesDto &&
         (!APP_DELEGATE.activeUser.capabilitiesDto.isFilesSharingAPIEnabled ||
          ![ShareUtils isAllowedReshareForFile:file]) )) {
             return YES;
         }
    
    return NO;
}


#pragma mark - Default value for link name

+ (NSString *) getDefaultLinkNameNormalizedOfFile:(FileDto *)file withLinkShares:(NSArray *)publicLinkShared {
    
    NSString *fileNameNormalized = [file.fileName stringByRemovingPercentEncoding];
    if (file.isDirectory) {
        fileNameNormalized = [fileNameNormalized substringToIndex:[fileNameNormalized length]-1];
    }

    NSString *linkName = [NSLocalizedString(@"default_link_name", nil) stringByReplacingOccurrencesOfString:@"$fileName" withString:fileNameNormalized];
    NSString *linkNameNormalized = [NSString stringWithString:linkName];

    NSInteger nShared = [publicLinkShared count];

    BOOL alreadyExist = NO;
    
    NSPredicate *predicateSameFileName = [NSPredicate predicateWithFormat:@"name == %@", linkNameNormalized];
    NSArray *linksSameName = [publicLinkShared filteredArrayUsingPredicate:predicateSameFileName];

    if (linksSameName != nil && [linksSameName count] > 0) {
        
        alreadyExist = YES;
        
        //keep searching with the rest of numbers
        
        for (int i=2; i<=nShared; i++) {
            linkNameNormalized = [NSString stringWithFormat:@"%@ (%d)",linkName, i];
            
            predicateSameFileName = [NSPredicate predicateWithFormat:@"name == %@", linkNameNormalized];
            linksSameName = [publicLinkShared filteredArrayUsingPredicate:predicateSameFileName];
            
            if (linksSameName == nil || [linksSameName count] == 0) {
                alreadyExist = NO;
                break;
            }
        }
    }

    if (alreadyExist) {
        linkNameNormalized = [NSString stringWithFormat:@"%@ (%lu)",linkName,nShared+1];
    }
    
    return linkNameNormalized;
}


#pragma mark - Default Dates for datePicker

+ (long) getDefaultMinExpirationDateInTimeInterval {
    
    NSDateComponents *deltaComps = [NSDateComponents new];
    [deltaComps setDay:1];
    NSDate *tomorrow = [[NSCalendar currentCalendar] dateByAddingComponents:deltaComps toDate:[NSDate date] options:0];
    
    NSLog(@"date is %@",[self convertDateInServerFormat:tomorrow]);
              
    return [tomorrow timeIntervalSince1970];
}

+ (long) getDefaultMaxExpirationDateInTimeInterval {
    
    if ([ShareUtils hasExpirationDefaultDateToBeShown]) {
        
        NSInteger days = APP_DELEGATE.activeUser.capabilitiesDto.filesSharingExpireDateDaysNumber;
        NSDate *newDate = [ShareUtils addDays:days toDate:[NSDate date]];
        
        NSLog(@"date is %@",[self convertDateInServerFormat:newDate]);
        return [newDate timeIntervalSince1970];
        
    } else {
        
        return 0.0;
    }
}


#pragma mark - convert date

+ (NSDate *) addDays:(NSInteger)days toDate:(NSDate *)date {

    // Create and initialize date component instance
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setDay:days];
    
    // Retrieve date with increased days count
    NSDate *newDate = [[NSCalendar currentCalendar]
                       dateByAddingComponents:dateComponents
                       toDate:date options:0];
    
    return newDate;
}

+ (NSString *) convertDateInServerFormat:(NSDate *)date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateFormat:dateServerFormat];
    
    return [dateFormatter stringFromDate:date];
}


+ (NSString *) stringOfDate:(NSDate *) date {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];
    
    return [dateFormatter stringFromDate:date];
}


#pragma mark - display utils

+ (NSString *) getDisplayNameForSharee:(OCShareUser *)sharee {
    
    if (sharee.shareeType == shareTypeGroup) {
        return [NSString stringWithFormat:@"%@ (%@)", sharee.displayName, NSLocalizedString(@"share_user_group_indicator", nil)];
        
    } else if (sharee.shareeType == shareTypeRemote && sharee.server != nil) {
        
        if(sharee.isDisplayNameDuplicated) {
            return [NSString stringWithFormat:@"%@ (%@)", sharee.displayName, sharee.name];
        } else {
            return [NSString stringWithFormat:@"%@ (%@)", sharee.displayName, sharee.server];
        }
        
    } else {
        
        if (sharee.isDisplayNameDuplicated){
            return [NSString stringWithFormat:@"%@ (%@)", sharee.displayName, sharee.name];
        } else {
            return sharee.displayName;
        }
    }
    
}


#pragma mark - private link

+ (NSString *) getPrivateLinkOfFile:(FileDto *)fileDto {
    
    NSString *privateLink = @"";
    
    privateLink = [NSString stringWithFormat:@"%@%@%@", [UtilsUrls getFullRemoteServerPath:APP_DELEGATE.activeUser], k_pathPrivateLink, [InfoFileUtils getFileIdFromOcId:fileDto.ocId]];
    
    
    return privateLink;
    
}


@end
