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
    
    func getUserDisplayNameOfServer(path: String, credentials: OCCredentialsDto,
                                    withCompletion completion:(@escaping (_ displayName: String?,_ errorHttp: NSInteger?,_ error: NSError?) -> Void ) ){
        
        AppDelegate.sharedOCCommunication().setCredentials(credentials)
        AppDelegate.sharedOCCommunication().setValueOfUserAgent(UtilsUrls.getUserAgent())
        
        AppDelegate.sharedOCCommunication().getUserDisplayName(ofServer: path,
                                                               on: AppDelegate.sharedOCCommunication(),
                                                               success: { (response: HTTPURLResponse?, displayName: String?, redirectServer: String?) in
                                                                
                                                                completion(displayName, response?.statusCode, nil)
                                                                
        },failure: { (response: HTTPURLResponse?, error: Error?, redirectServer: String?) in
            
            let statusCode: NSInteger = (response?.statusCode == nil) ? 0: (response?.statusCode)!
            
            completion(nil, statusCode, error! as NSError)
        })
    }
    
    
}
