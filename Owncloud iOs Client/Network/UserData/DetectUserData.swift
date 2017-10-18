//
//  DetectUserData.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 16/10/2017.
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


@objc class DetectUserData: NSObject {
    
    
    @objc func getUserDisplayNameOfServer(path: String, credentials: OCCredentialsDto, withCompletion completion: @escaping (_ displayName: String?,_ errorHttp: NSNumber?,_ error: Error?) -> Void ) {
    
    let sharedOCCommunication : OCCommunication;
    
    #if CONTAINER_APP
        sharedOCCommunication = AppDelegate.sharedOCCommunication();
        sharedOCCommunication.setCredentials(credentials)
        sharedOCCommunication.setValueOfUserAgent(UtilsUrls.getUserAgent())
        
        sharedOCCommunication.getUserDisplayName(ofServer: path,
                                                 on: sharedOCCommunication,
                                                 success: { (response: HTTPURLResponse?, displayName: String?, redirectServer: String?) in
                                                    
                                                    let statusCode: NSNumber = (response?.statusCode == nil) ? 0: (response?.statusCode)! as NSNumber
                                                    
                                                    completion(displayName,statusCode, nil)
                                                    
        },failure: { (response: HTTPURLResponse?, error: Error?, redirectServer: String?) in
            
            let statusCode: NSNumber = (response?.statusCode == nil) ? 0: (response?.statusCode)! as NSNumber
            
            completion(nil,statusCode , error! as Error)
        })
        
    #else
        completion(nil,nil,nil)
    #endif

    }
    
    
}
