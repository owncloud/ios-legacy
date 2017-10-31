//
//  constants.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/10/12.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */


//Chunk length
#define k_lenght_chunk 1024//256

//Timeout to upload
#define k_timeout_upload 40 //seconds

//Timeout if a resource is not able to be retrieved within a given timeout
#define k_timeout_upload_resource 20 //Seconds

//Nº of times to try upload a chunk
#define k_times_upload_chunks 10

//1MB
//#define k_lenght_limit_until_chunking 1048576 //(256 x 1024)

//seconds to limit the relaunch of failed uploading files
#define k_minimun_time_to_relaunch 15

//seconds to limit the relaunch of waiting to upload files
#define k_percent_for_check_the_uploads 0.1

//Alert view tags
#define k_alertview_for_login 1
#define k_alertview_for_download_error 2

//Boolean to know when the user kill the app
#define k_app_killed_by_user @"app_killed_by_user"

//Constants to identify the different permissions of a file
#define k_permission_shared @"S"
#define k_permission_can_share @"R"
#define k_permission_mounted @"M"
#define k_permission_file_can_write @"W"
#define k_permission_can_create_file @"C"
#define k_permission_can_create_folder @"K"
#define k_permission_can_delete @"D"
#define k_permission_can_rename @"N"
#define k_permission_can_move @"V"

#define k_owncloud_folder @"cache_folder"

//WebView preview files
#define k_txt_files_font_size_iphone @"40" //examples valid formats: "30", "40", "large",...
#define k_txt_files_font_size_ipad @"20" 
#define k_txt_files_font_family @"Sans-Serif"

//Path instant upload
#define k_path_instant_upload @"InstantUpload"

//App name
#define k_app_name @"ownCloud"

//Negative etag used to force pending to update
#define k_negative_etag @"-1"

//Folder where we store
#define k_thumbnails_cache_folder_name @"thumbnails_cache"
#define k_thumbnails_height 64
#define k_thumbnails_width 64


//Menu sizes
#define k_max_number_options_plus_menu 4
#define k_max_number_options_more_menu 4
#define k_max_number_options_sort_menu 2
#define k_max_number_options_account_menu 3

//Customize top warning Messages view (TSMessage)
#define messageAlpha 0.96
#define messageDuration 3.5
