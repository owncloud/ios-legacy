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

@objc class DetectAuthenticationMethod: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    @objc func auth_request(_ url: URL, withCompletion completion: @escaping (_ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void) {
        
        var request = URLRequest(url: url)
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

            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
                
            } else if let httpResponse = response as? HTTPURLResponse {
                completion(httpResponse, error)
            }
        })
        task.resume()
        
    }
    
    
    // analyze response, return all authentication methods available
    
    func analyzeResponse(httpResponse: HTTPURLResponse) -> Array<Any> {
        
        var allAvailableAuthMethods = [AuthenticationMethod]()

        let isSAML: Bool = FileNameUtils.isURL(withSamlFragment: httpResponse)

            
        if httpResponse.statusCode == NSInteger(kOCErrorServerUnauthorized) {
            
            let wwwAuthenticate = httpResponse.allHeaderFields["Www-Authenticate"] as? String
            
            if let allAuthMethodsResponse = wwwAuthenticate?.components(separatedBy: ",")  {
                
                for wAuth in allAuthMethodsResponse {
                    
                    if wAuth.lowercased().range(of:"basic") != nil {
                        allAvailableAuthMethods.append(AuthenticationMethod.BASIC_HTTP_AUTH)
                        
                    } else if wAuth.lowercased().range(of:"bearer") != nil {
                        
                        allAvailableAuthMethods.append(AuthenticationMethod.BEARER_TOKEN)
                    }
                    
                }
            }
        } else {
            
            if isSAML {
                
                allAvailableAuthMethods.append(AuthenticationMethod.SAML_WEB_SSO)
                
            } else if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300){
                
                allAvailableAuthMethods.append(AuthenticationMethod.NONE)
            }
            
        }
        
    
        if allAvailableAuthMethods.isEmpty {
            print("Authentication method not found")
            allAvailableAuthMethods.append(AuthenticationMethod.UNKNOWN)

        } else {
            print("Authentication methods found:")
            for element in allAvailableAuthMethods {
                print(" \(element.rawValue)" )
            }
            print("0=UNKNOWN, 1=NONE, 2=BASIC_HTTP_AUTH, 3=BEARER_TOKEN, 4=SAML_WEB_SSO");
        }
        
        return allAvailableAuthMethods
    }
    


    
    func getAuthenticationMethodsAvailableBy(url: URL,  withCompletion completion: @escaping (_ authMethods: Array<Any>? ,_ error: Error?) -> Void)  {
        
        self.auth_request(url, withCompletion: { (httpResponse: HTTPURLResponse?,error: Error?) in
            
            if (httpResponse != nil) {
                completion(self.analyzeResponse(httpResponse: httpResponse!) , nil )
            } else {
                completion(nil, error)
            }

        })
        
    }
    
    
    func getAuthMethodToLoginFrom(availableAuthMethods: [AuthenticationMethod]) -> AuthenticationMethod {
        
        var authMethod: AuthenticationMethod? = .NONE
        
        if Customization.kIsSsoActive() {
            
            if availableAuthMethods.contains(.SAML_WEB_SSO) {
                authMethod = .SAML_WEB_SSO
            }
            
        } else if availableAuthMethods.contains(.BEARER_TOKEN){
            authMethod = .BEARER_TOKEN
            
        } else if availableAuthMethods.contains(.BASIC_HTTP_AUTH) {
            authMethod = .BASIC_HTTP_AUTH
        }
        
        return authMethod!
    }
    
    
// MARK: UrlSession delegates
    
    func urlSession(_ session: URLSession,
                             task: URLSessionTask,
                             didReceive challenge: URLAuthenticationChallenge,
                             completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        
        let checkAccessToServer: CheckAccessToServer = CheckAccessToServer.sharedManager() as! CheckAccessToServer
        let trusted: Bool = checkAccessToServer.isTrustedServer(with: challenge)
        if (trusted) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential,credential);
        } else {
            completionHandler(.performDefaultHandling, nil);
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Swift.Void) {
        
        print("Redirect detected, in URLSession delegate")
        let newRequest = request
        
        print(newRequest.description);
        
        let isSAML: Bool = FileNameUtils.isURL(withSamlFragment:response)
        
        if (isSAML) {
            //stop
            completionHandler(nil)
            
        } else {
            //follow
            completionHandler(newRequest)
        }
    }
    
    
}



