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
    
    
    func storeAccountOfUser(_ user: UserDto, withCredentials credDto: CredentialsDto) {
        
        
        if let userInDB = ManageUsersDB.insertUser(user) {
            
            userInDB.credDto = credDto.copy() as! CredentialsDto
            
            //userInDB contains the userId in DB, we add the credentials and store the user in keychain
            OCKeychain.setCredentialsOfUser(userInDB)
            
            (UIApplication.shared.delegate as! AppDelegate).activeUser = user
            
        } else {
            //error storing account
            print("Error storing account for \(user.username)")
        }
    }
    
    func updateAccountOfUser(_ user: UserDto, withCredentials credDto: CredentialsDto) {
        
        
        OCKeychain.updateCredentials(ofUser: user)
        
        if user.activeaccount {
            UtilsCookies.eraseCredentialsAndUrlCacheOfActiveUser()
            
            CheckFeaturesSupported.updateServerFeaturesAndCapabilitiesOfActiveUser()
        }
        
        //Change the state of user uploads with credential error
        ManageUploadsDB.updateErrorCredentialFiles(user.idUser)
        
        self.restoreDownloadAndUploadsOfUser(user)
        
        
        //TODO:check relaunchErrorCredentialFilesNotification if needed
    }
    
    func migrateAccountOfUser(_ user: UserDto, withCredentials credDto: CredentialsDto) {
        
        //Update parameters after a force url and credentials have not been renewed
        
        if Customization.kIsSsoActive() {
          //  user.username =
        }
        
        user.urlRedirected = (UIApplication.shared.delegate as! AppDelegate).urlServerRedirected
        user.predefinedUrl = k_default_url_server
        
        ManageUploadsDB.overrideAllUploads(withNewURL: UtilsUrls.getFullRemoteServerPath(user))
        
        ManageUsersDB.updateUser(by: user)
        
        
        self.updateAccountOfUser(user, withCredentials: credDto)
        
        (UIApplication.shared.delegate as! AppDelegate).updateStateAndRestoreUploadsAndDownloads()
        let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
         //[[APP_DELEGATE presentFilesViewController] initFilesView];
        let instantUploadManager: InstantUpload = InstantUpload.instantUploadManager()
        instantUploadManager.activate()
    }
    
    func restoreDownloadAndUploadsOfUser(_ user : UserDto) {
        
        (UIApplication.shared.delegate as! AppDelegate).cancelTheCurrentUploads(ofTheUser: user.idUser)
        
        let downloadManager : ManageDownloads = (UIApplication.shared.delegate as! AppDelegate).downloadManager
        downloadManager.cancelAndRefreshInterface()
        
        (UIApplication.shared.delegate as! AppDelegate).launchProcessToSyncAllFavorites()
    }
    
}
