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
            userInDB.credDto.userId = String(userInDB.idUser)
            
            //userInDB contains the userId in DB, we add the credentials and store the user in keychain
            OCKeychain.storeCredentials(userInDB.credDto)
            
            let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
            
            if (app.activeUser == nil || (userInDB.activeaccount)) {
                // only set as active account the first account added
                // OR if it is already the active user; otherwise cookies will not be correctly restored
                userInDB.activeaccount = true
                app.activeUser = userInDB
            }
            
            return userInDB;
            
        } else {
            print("Error storing account for \(user.username)")
            return nil;
        }
        
    }
    
@objc func updateAccountOfUser(_ user: UserDto, withCredentials credDto: OCCredentialsDto) {
        
        user.credDto = credDto.copy() as! OCCredentialsDto
        
        ManageUsersDB.updateUser(by: user)

        OCKeychain.updateCredentials(user.credDto)
        
        if user.activeaccount {
            UtilsCookies.eraseCredentialsAndUrlCacheOfActiveUser()
            
            CheckFeaturesSupported.updateServerFeaturesAndCapabilitiesOfActiveUser()
        }
        
        //Change the state of user uploads with credential error
        ManageUploadsDB.updateErrorCredentialFiles(user.idUser)
        
        self.restoreDownloadAndUploadsOfUser(user)
        
        
        //TODO:check relaunchErrorCredentialFilesNotification if needed
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
        app.cancelTheCurrentUploads(ofTheUser: user.idUser)
        
        let downloadManager : ManageDownloads = app.downloadManager
        downloadManager.cancelAndRefreshInterface()
        
        if user.activeaccount {
            app.launchProcessToSyncAllFavorites()
        }
    }
    
}
