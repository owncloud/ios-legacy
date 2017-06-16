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
    @objc func auth_request(_ urlString: String, withCompletion completion: @escaping (_ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void) {
        //Without credentials
        
        //let urlToRequest = UtilsUrls.getFullRemoteServerPath(withWebDav: user)
        
        let url = URL (string: urlString)!
        
        var request = NSMutableURLRequest(url: url)
        request.httpMethod = "PROPFIND"
        request.setValue("0", forHTTPHeaderField: "Depth")
        request.setValue(UtilsUrls.getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        let body =  "<?xml version=\"1.0\" encoding=\"UTF-8\"?><D:propfind xmlns:D=\"DAV:\"><D:prop><D:resourcetype/><D:getlastmodified/><size xmlns=\"http://owncloud.org/ns\"/><D:creationdate/><id xmlns=\"http://owncloud.org/ns\"/><D:getcontentlength/><D:displayname/><D:quota-available-bytes/><D:getetag/><permissions xmlns=\"http://owncloud.org/ns\"/><D:quota-used-bytes/><D:getcontenttype/></D:prop></D:propfind>"
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
//        let session = URLSession(configuration: URLSessionConfiguration.default)

        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
       // let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            //let text = NSString(data: data!, encoding: String.Encoding.utf8.rawValue);
//            guard let data = data else {
//                completion(nil)
//                return
//            }

            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
                
            } else if let httpResponse = response as? HTTPURLResponse {
                completion(httpResponse, error)
            }
            
            
        })
        task.resume()
        
    }
    
    
    // analyze response, return all authentication types available
    
    @objc func analyzeResponse(httpResponse: HTTPURLResponse) -> Array<Any> {
        
        let isSAML: Bool = FileNameUtils.isURL(withSamlFragment: httpResponse)
        
        var authMethod = AuthenticationMethod.UNKNOWN;
        var allAvailableAuthMethods = [AuthenticationMethod]()

        
        if let wAuth = httpResponse.allHeaderFields["Www-Authenticate"] as? String {
            
           // let allAuthenticateHeaders = httpResponse.allHeaderFields as! NSArray

           // for item in allAuthenticateHeaders {
                
              //  let itemString = item as! String
            
                if httpResponse.statusCode == NSInteger(kOCErrorServerUnauthorized) {
                    
                    
                    if wAuth.lowercased().hasPrefix("basic") {
                        
                        authMethod = AuthenticationMethod.BASIC_HTTP_AUTH;
                        
                    } else if wAuth.lowercased().hasPrefix("bearer") {
                        
                        authMethod = AuthenticationMethod.BEARER_TOKEN;
                    }
                    
                } else if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                    
                    authMethod = AuthenticationMethod.NONE;
                    
                } else if isSAML {
                    
                    authMethod = AuthenticationMethod.SAML_WEB_SSO;
                }
                
                print("Authentication method found: " + authMethod.rawValue)
                allAvailableAuthMethods.append(authMethod)
            //}
            
        }
        
        return allAvailableAuthMethods

    }
    
//    //  Delegate Handles redirection
//    //  try to access the root folder, following redirections but not SAML SSO redirections
//    func URLSession(session: URLSession,
//                    task: URLSessionTask,
//                    willPerformHTTPRedirection response: HTTPURLResponse,
//                    newRequest request: NSURLRequest,
//                    completionHandler: (NSURLRequest!) -> Void) {
//        
//        print("Redirect detected, in URLSession delegate")
//        
//        let newRequest = request
//        
//        print(newRequest.description);
//        
//        let isSAML: Bool = FileNameUtils.isURL(withSamlFragment:response)
//        
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
//    
}



