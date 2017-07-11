//
//  DetectListOfFiles.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 07/07/2017.
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

@objc class DetectListOfFiles: NSObject {
    
//    func readFolderRequest(_ url: URL, authType: AuthenticationMethod, username: String?, accessToken: String, withCompletion completion: @escaping (_ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void) {
//        
//    //    var sharedCommunication = AppDelegate.sharedOCCommunication()
//        
//      //  self.setCredencialsAndUserAgentWith(sharedOCCommunication: sharedCommunication!, authType: authType, username: username, accessToken: accessToken)
//        
//        //request
//        
//        
//        
//        //return
//        
//     
//    }
    
    
    func setCredencialsAndUserAgentWith(sharedOCCommunication: OCCommunication, authType: AuthenticationMethod, username: String?, accessToken: String) {
        
        sharedOCCommunication.setValueOfUserAgent(UtilsUrls.getUserAgent())

        switch authType {
        case .BEARER_TOKEN:
            sharedOCCommunication.setCredentialsOauthWithToken(accessToken)
            break
        case .SAML_WEB_SSO:
            if (Customization.kIsSsoActive()) {
                sharedOCCommunication.setCredentialsWithCookie(accessToken)
                break
            }
        default:
            sharedOCCommunication.setCredentialsWithUser(username, andPassword: accessToken)
            break
        }
    }
    
    
//    func getListOfFiles(url:URL, authType: AuthenticationMethod, accessToken: String) -> Array<Any> {
//        
////        self.readFolderRequest(url, authType: authType, username: nil, accessToken: accessToken) { (httpResponse: HTTPURLResponse?, error: Error?) in
////        
////
////        }
//        var resultArray = [""]
//        
//        return resultArray
//    }
//    
}
