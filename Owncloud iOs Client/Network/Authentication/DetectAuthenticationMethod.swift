//
//  DetectAuthenticationMethod.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 13/06/17.
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


/**
 * Operation to find out what authentication method requires
 * the server to access files.
 *
 * Basically, tries to access to the root folder without authorization
 * and analyzes the response.
 *
 * When successful, returns array of AuthenticationMethod available.
 */

enum AuthenticationMethod: String {
    case UNKNOWN = "UNKNOWN"
    case NONE = "NONE"
    case BASIC_HTTP_AUTH = "BASIC_HTTP_AUTH"
    case BEARER_TOKEN = "BEARER_TOKEN"
    case SAML_WEB_SSO = "SAML_WEB_SSO"
}

@objc class DetectAuthenticationMethod: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    
    let user = ManageUsersDB.getActiveUser()
    
    
 //   func auth_request(_ urlString: String, withCompletion completion: @escaping ([Any]?) -> Void) {
    @objc func auth_request(_ urlString: String, withCompletion completion: @escaping (_ result: String) -> Void) {
        //Without credentials
        
        //let urlToRequest = UtilsUrls.getFullRemoteServerPath(withWebDav: user)
        
        let url = URL (string: urlString)!
        
//        var request = URLRequest(url: url)
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
//        let session = URLSession(configuration: URLSessionConfiguration.default)

        
        let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            let text = NSString(data: data!, encoding: String.Encoding.utf8.rawValue);
//            guard let data = data else {
//                completion(nil)
//                return
//            }

//            if let error = error {
//                print(error.localizedDescription)
//                
//                
//            } else if let httpResponse = response as? HTTPURLResponse {
//                if httpResponse.statusCode == 200 {
//                    
//                } else if httpRespose.
//            }
            
            
            completion("David")
        })
        task.resume()
        
    }
    
    // analyze response, return all authentication types available
    
    func analyzeResponse(response: HTTPURLResponse) -> Array<Any> {
        
        //var authMethod = AuthenticationMethod.UNKNOWN;
        //
        
        var availableAuth = [AuthenticationMethod]()
        
        return availableAuth

    }
    
    // Delegate Handles redirection        
    // try to access the root folder, following redirections but not SAML SSO redirections
//    func URLSession(session: URLSession,
//                    task: URLSessionTask,
//                    willPerformHTTPRedirection response: HTTPURLResponse,
//                    newRequest request: NSURLRequest,
//                    completionHandler: (NSURLRequest!) -> Void) {
//        
//        print("in URLSession delegate")
//        
//        let newRequest = request
//        
//        print(newRequest.description);
//        
//        let isSAML = false
//        if (isSAML) {
//            //stop
//            completionHandler(nil)
//
//        } else {
//            //follow
//            completionHandler(newRequest)
//        }
//        
//    }
    
    
    
    
}
