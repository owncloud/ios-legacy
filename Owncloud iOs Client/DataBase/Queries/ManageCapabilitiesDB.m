//
//  ManageCapabilitiesDB.m
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/11/15.
//
//

/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import "ManageCapabilitiesDB.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "UserDto.h"
#import "OCCapabilities.h"

#ifdef CONTAINER_APP
#import "AppDelegate.h"
#import "Owncloud_iOs_Client-Swift.h"
#elif FILE_PICKER
#import "ownCloudExtApp-Swift.h"
#elif SHARE_IN
#import "OC_Share_Sheet-Swift.h"
#else
#import "ownCloudExtAppFileProvider-Swift.h"
#endif

@implementation ManageCapabilitiesDB

+(void) insertCapabilities:(OCCapabilities *)capabilities ofUserId:(NSInteger)userId{
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"INSERT INTO capabilities(id_user, version_major, version_minor, version_micro, version_string, version_edition, core_poll_intervall, is_files_sharing_api_enabled, is_files_sharing_share_link_enabled, is_files_sharing_password_enforced_enabled, is_files_sharing_expire_date_by_default_enabled, is_files_sharing_expire_date_enforce_enabled, files_sharing_expire_date_days_number, is_files_sharing_allow_user_send_mail_notification_about_share_link_enabled, is_files_sharing_allow_public_uploads_enabled, is_files_sharing_allow_user_send_mail_notification_about_other_users_enabled, is_files_sharing_re_sharing_enabled, is_files_sharing_allow_user_send_shares_to_other_servers_enabled, is_files_sharing_allow_user_receive_shares_to_other_servers_enabled, is_file_big_file_chunking_enabled, is_file_undelete_enabled, is_file_versioning_enabled, is_files_sharing_allow_user_create_multiple_public_links_enabled, 'is_files_sharing_supports_upload_only_enabled') Values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        [NSNumber numberWithInteger:userId],
                        [NSNumber numberWithInteger:capabilities.versionMajor],
                        [NSNumber numberWithInteger:capabilities.versionMinor],
                        [NSNumber numberWithInteger:capabilities.versionMicro],
                        capabilities.versionString,
                        capabilities.versionEdition,
                        [NSNumber numberWithInteger:capabilities.corePollInterval],
                        [NSNumber numberWithBool:capabilities.isFilesSharingAPIEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingShareLinkEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingPasswordEnforcedEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingExpireDateByDefaultEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingExpireDateEnforceEnabled],
                        [NSNumber numberWithInteger:capabilities.filesSharingExpireDateDaysNumber],
                        [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingAllowPublicUploadsEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingReSharingEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserSendSharesToOtherServersEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserReceiveSharesToOtherServersEnabled],
                        [NSNumber numberWithBool:capabilities.isFileBigFileChunkingEnabled],
                        [NSNumber numberWithBool:capabilities.isFileUndeleteEnabled],
                        [NSNumber numberWithBool:capabilities.isFileVersioningEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled],
                        [NSNumber numberWithBool:capabilities.isFilesSharingSupportsUploadOnlyEnabled]];
        
        if (!correctQuery) {
            DLog(@"Error in insert capabilities");
        }
    }];
}

+(OCCapabilities *) getCapabilitiesOfUserId:(NSInteger) userId{
    
    __block OCCapabilities *output = nil;
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM capabilities WHERE id_user = ?", [NSNumber numberWithInteger:userId]];
        
        while ([rs next]) {
            
            output = [OCCapabilities new];

            output.versionMajor = [rs intForColumn:@"version_major"];
            output.versionMinor = [rs intForColumn:@"version_minor"];
            output.versionMicro = [rs intForColumn:@"version_micro"];
            output.versionString = [rs stringForColumn:@"version_string"];
            output.versionEdition = [rs stringForColumn:@"version_edition"];
            
            output.corePollInterval = [rs intForColumn:@"core_poll_intervall"];
            
            output.isFilesSharingAPIEnabled = [rs boolForColumn:@"is_files_sharing_api_enabled"];
            
            output.isFilesSharingShareLinkEnabled = [rs boolForColumn:@"is_files_sharing_share_link_enabled"];
            output.isFilesSharingPasswordEnforcedEnabled = [rs boolForColumn:@"is_files_sharing_password_enforced_enabled"];
            output.isFilesSharingExpireDateByDefaultEnabled = [rs boolForColumn:@"is_files_sharing_expire_date_by_default_enabled"];
            output.isFilesSharingExpireDateEnforceEnabled = [rs boolForColumn:@"is_files_sharing_expire_date_enforce_enabled"];
            output.filesSharingExpireDateDaysNumber = [rs intForColumn:@"files_sharing_expire_date_days_number"];
            
            output.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled = [rs boolForColumn:@"is_files_sharing_allow_user_send_mail_notification_about_share_link_enabled"];
            output.isFilesSharingAllowPublicUploadsEnabled = [rs boolForColumn:@"is_files_sharing_allow_public_uploads_enabled"];
            output.isFilesSharingSupportsUploadOnlyEnabled = [rs boolForColumn:@"is_files_sharing_supports_upload_only_enabled"];
            output.isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled = [rs boolForColumn:@"is_files_sharing_allow_user_send_mail_notification_about_other_users_enabled"];
            output.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled = [rs boolForColumn:@"is_files_sharing_allow_user_create_multiple_public_links_enabled"];
            
            output.isFilesSharingReSharingEnabled = [rs boolForColumn:@"is_files_sharing_re_sharing_enabled"];
            output.isFilesSharingAllowUserSendSharesToOtherServersEnabled = [rs boolForColumn:@"is_files_sharing_allow_user_send_shares_to_other_servers_enabled"];
            output.isFilesSharingAllowUserReceiveSharesToOtherServersEnabled = [rs boolForColumn:@"is_files_sharing_allow_user_receive_shares_to_other_servers_enabled"];
            
            output.isFileBigFileChunkingEnabled = [rs boolForColumn:@"is_file_big_file_chunking_enabled"];
            output.isFileUndeleteEnabled = [rs boolForColumn:@"is_file_undelete_enabled"];
            output.isFileVersioningEnabled = [rs boolForColumn:@"is_file_versioning_enabled"];
        }
        
        [rs close];
        
    }];
    
    return output;

}

+(void) updateCapabilitiesWith:(OCCapabilities *)capabilities ofUserId:(NSInteger)userId {
    
    FMDatabaseQueue *queue = Managers.sharedDatabase;
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL correctQuery=NO;
        
        correctQuery = [db executeUpdate:@"UPDATE capabilities SET version_major=?, version_minor=?, version_micro=?, version_string=?, version_edition=?, core_poll_intervall=?, is_files_sharing_api_enabled=?, is_files_sharing_share_link_enabled=?, is_files_sharing_password_enforced_enabled=?, is_files_sharing_expire_date_by_default_enabled=?, is_files_sharing_expire_date_enforce_enabled=?, files_sharing_expire_date_days_number=?, is_files_sharing_allow_user_send_mail_notification_about_share_link_enabled=?, is_files_sharing_allow_public_uploads_enabled=?, is_files_sharing_allow_user_send_mail_notification_about_other_users_enabled=?, is_files_sharing_re_sharing_enabled=?, is_files_sharing_allow_user_send_shares_to_other_servers_enabled=?, is_files_sharing_allow_user_receive_shares_to_other_servers_enabled=?, is_file_big_file_chunking_enabled=?, is_file_undelete_enabled=?, is_file_versioning_enabled=?, is_files_sharing_allow_user_create_multiple_public_links_enabled=?, is_files_sharing_supports_upload_only_enabled=? WHERE id_user = ?",[NSNumber numberWithInteger:capabilities.versionMajor], [NSNumber numberWithInteger:capabilities.versionMinor], [NSNumber numberWithInteger:capabilities.versionMicro], capabilities.versionString, capabilities.versionEdition, [NSNumber numberWithInteger:capabilities.corePollInterval], [NSNumber numberWithBool:capabilities.isFilesSharingAPIEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingShareLinkEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingPasswordEnforcedEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingExpireDateByDefaultEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingExpireDateEnforceEnabled], [NSNumber numberWithInteger:capabilities.filesSharingExpireDateDaysNumber], [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserSendMailNotificationAboutShareLinkEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingAllowPublicUploadsEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserSendMailNotificationAboutOtherUsersEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingReSharingEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserSendSharesToOtherServersEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingAllowUserReceiveSharesToOtherServersEnabled], [NSNumber numberWithBool:capabilities.isFileBigFileChunkingEnabled], [NSNumber numberWithBool:capabilities.isFileUndeleteEnabled], [NSNumber numberWithBool:capabilities.isFileVersioningEnabled],[NSNumber numberWithBool:capabilities.isFilesSharingAllowUserCreateMultiplePublicLinksEnabled], [NSNumber numberWithBool:capabilities.isFilesSharingSupportsUploadOnlyEnabled], [NSNumber numberWithInteger:userId]];
        
        if (!correctQuery) {
            DLog(@"Error updating capabilities");
        }
    }];
}


@end
