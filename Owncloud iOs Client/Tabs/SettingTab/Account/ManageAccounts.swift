//
//  ManageAccounts.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 13/07/2017.
//
//


/*
 Copyright (C) 2017, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

import Foundation

@objc class ManageAccounts: NSObject {
    
    /*
    * @param  UserDto   -> user to store
    * @param  CredentialsDto -> credentials of user
    */
    
@objc func storeAccountOfUser(_ user: UserDto, withCredentials credDto: OCCredentialsDto) -> UserDto? {
        
        if let userInDB = ManageUsersDB.insertUser(user) {
    
            userInDB.credDto = credDto.copy() as! OCCredentialsDto
            userInDB.credDto.userId = String(userInDB.userId)
            
            //userInDB contains the userId in DB, we add the credentials and store the user in keychain
            OCKeychain.storeCredentials(userInDB.credDto)
            
            let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
            
            if (app.activeUser == nil || (userInDB.activeaccount)) {
                // only set as active account the first account added
                // OR if it is already the active user; otherwise cookies will not be correctly restored
                userInDB.activeaccount = true
                app.activeUser = userInDB
            }
            
            // grant that settings of instant uploads are the same for the new account that for the currently active account
            ManageAppSettingsDB.updateInstantUploadAllUser();
            
            return userInDB;
            
        } else {
            print("Error storing account for \(user.username)")
            return nil;
        }
        
    }
    
@objc func updateAccountOfUser(_ user: UserDto, withCredentials credDto: OCCredentialsDto) {
        
        user.credDto = credDto.copy() as! OCCredentialsDto
        user.credDto.userId = String(user.userId)
    
        ManageUsersDB.updateUser(by: user)

        OCKeychain.updateCredentials(user.credDto)
        
        if user.activeaccount {
            UtilsCookies.eraseCredentialsAndUrlCacheOfActiveUser()
            
            CheckFeaturesSupported.updateServerFeaturesAndCapabilitiesOfActiveUser()
        }
        
        //Change the state of user uploads with credential error
        ManageUploadsDB.updateErrorCredentialFiles(user.userId)
        
        self.restoreDownloadAndUploadsOfUser(user)
    
        NotificationCenter.default.post(name: NSNotification.Name.RelaunchErrorCredentialFiles, object: nil)
    }
    
@objc func migrateAccountOfUser(_ user: UserDto, withCredentials credDto: OCCredentialsDto) {
        
        //Update parameters after a force url and credentials have not been renewed
        let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)

        if Customization.kIsSsoActive() {
          //  user.username =
        }
        
        user.urlRedirected = app.urlServerRedirected
        user.predefinedUrl = k_default_url_server
        
        ManageUploadsDB.overrideAllUploads(withNewURL: UtilsUrls.getFullRemoteServerPath(user))
        
        ManageUsersDB.updateUser(by: user)
        
        
        self.updateAccountOfUser(user, withCredentials: credDto)
        
        app.updateStateAndRestoreUploadsAndDownloads()
         //[[APP_DELEGATE presentFilesViewController] initFilesView];
        let instantUploadManager: InstantUpload = InstantUpload.instantUploadManager()
        instantUploadManager.activate()
    }
    
@objc func restoreDownloadAndUploadsOfUser(_ user : UserDto) {
        let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
        app.cancelTheCurrentUploads(ofTheUser: user.userId)
        
        let downloadManager : ManageDownloads = app.downloadManager
        downloadManager.cancelAndRefreshInterface()
        
        if user.activeaccount {
            app.launchProcessToSyncAllFavorites()
        }
    }
    
    
    @objc func updateDisplayNameOfUser(user :UserDto) {
        
        DetectUserData.getUserDisplayName(ofServer: user.credDto.baseURL, credentials: user.credDto) { (displayName, error) in
            if ((displayName) != nil) {
                if (displayName != user.credDto.userDisplayName) {
                    
                    if (user.credDto.authenticationMethod == .SAML_WEB_SSO) {
                        user.username = displayName
                    }
                    
                    user.credDto.userDisplayName = displayName
                    
                    OCKeychain.updateCredentials(user.credDto)
                    
                    
                    if (user.activeaccount) {
                        let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
                        
                        app.activeUser.credDto = user.credDto.copy() as! OCCredentialsDto
                        app.activeUser.username = user.credDto.userName
                    }
                }
            } else {
                print("DisplayName not updated")
            }
            
        }
        
    }
    
}
