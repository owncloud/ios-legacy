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
    
    @objc func readFolderRequest(_ url: URL, authType: String, withCompletion completion: @escaping (_ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void) {
        
        
        let occomunication = AppDelegate.sharedOCCommunication()
        
        //set credentials
        
        
        //Set user agent
        
        //request
        
        
        //return
        
     
    }
    
    
//    @objc func getListOfFiles(url:URL, authType: String) -> Array<Any> {
//        
//        
////        self.readFolderRequest(url, authType: authType) { (<#HTTPURLResponse?#>, <#Error?#>) in
////            
////        }
//    }
    
}
