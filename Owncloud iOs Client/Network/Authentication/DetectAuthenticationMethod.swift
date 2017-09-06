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
        configuration.urlCredentialStorage = nil;   // enforce that no credential is proposed for the auhtentication challenge
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)

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
    
    
    // Analyze server response and return all authentication methods accepted by it.
    //
    // Returns {AuthenticationMethod.UNKNOWN} if no method known by the client is supported,
    // or if an HTTP error was returned.
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
    
    // Delegate method called when the server responded with an authentication challenge.
    // Since iOS is so great, it is also called when the server certificate is not trusted, so that the client
    // can decide what to do about it.
    //
    // In this case an authentication challenge from the server is an expected response, since we made an
    // unauthenticated request to analyse the authentication challenge. 
    //
    func urlSession(_ session: URLSession,
                             task: URLSessionTask,
                             didReceive challenge: URLAuthenticationChallenge,
                             completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        
        // For the case that the call is due to server certificate not trusted, first we compare it with the server that
        // could have been trusted by CheckAccessToServer in a previous call. Please, notice that DetectAuthenticationMethod is
        // only used in the app as part of GetPublicInfoFromServerJob, and a successful call to CheckAccessToServer must have been
        // finished before. That successful call could include the acceptance by the user of self-signed server certificates, and
        // those are cached in CheckAccessToServer and considered in the call to CheckAccessToServer.isTrustedServer
        let sslCertificateManager: SSLCertificateManager = SSLCertificateManager();
        let trusted: Bool = sslCertificateManager.isTrustedServerCertificate(in: challenge)
        if (trusted) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential,credential);
            
        } else if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust ){
            // If this method was called due to an unstrusted server certificate and this was not accepted by the user in
            // CheckAccessToServer, .performDefaultHandling should be good enought to make the request fail due to the untrusted 
            // certificate.
            completionHandler(.performDefaultHandling, nil);
            
        } else {
            // If this method was called due to a real authentication challenge from the server, .performDefaultHandling with nil
            // will repeat again the network request, wich is pretty unconvenient, but allows to handle the HTTP status code and 
            // response in the analyzeResponse(...) as part of the request completion handler.
            
            // The only way to prevent that the request was repeated would be using .cancelAuthenticationChallenge instead of 
            // .performDefaultHandling, but in that case I see no way to get the status code and the response headers in the completion
            // handler, and since this callback itself cannot recognize Bearer authentication challenges, we cannot use it either to
            // determine the list of authentication methods supported in the server.
            
            // "Deal with it" -- somebody in Apple.
            //
            completionHandler(.performDefaultHandling, nil);
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Swift.Void) {
        
        print("DetectAuthenticationMethod: redirect detected in URLSessionTaskDelegate implementation")
        let newRequest = request
        
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



