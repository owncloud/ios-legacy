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
        }
        
        
    }
    
}
