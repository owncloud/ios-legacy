//
//  OauthAuthentication
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 29/06/2017.
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


@objc class OauthAuthentication: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
// MARK : get authData by authcode

@objc func accessTokenAuthRequest(_ url: URL, authCode: String, withCompletion completion: @escaping (_ data: Data?,_ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void) {
     
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue(UtilsUrls.getUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let authId = k_oauth2_client_id+":"+k_oauth2_client_secret
        let base64EncodedAuthId: String = UtilsFramework.afBase64EncodedString(from: authId)
        request.setValue("Basic \(base64EncodedAuthId)", forHTTPHeaderField: "Authorization")

        let body =  "grant_type=authorization_code&code=\(authCode)&redirect_uri=\(k_oauth2_redirect_uri)&client_id=\(k_oauth2_client_id)"
        let bodyEncoded = body.data(using: String.Encoding.utf8)
        request.httpBody = bodyEncoded
        
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            
            if let error = error {
                print(error.localizedDescription)
                completion(nil, nil, error)
                
            } else if let data = data {
                completion(data , response as? HTTPURLResponse, error)
                
            } else {
                completion(nil, response as? HTTPURLResponse, error)
            }
        })
        task.resume()
    }
    

@objc    func getAuthDataBy(url: URL, authCode: String, withCompletion completion: @escaping (_ userCredDto: OCCredentialsDto? ,_ error: Error?) -> Void)  {
        
        self.accessTokenAuthRequest(url, authCode: authCode, withCompletion: { (data:Data?, httpResponse:HTTPURLResponse?, error:Error?) in
            
            var returnUserCredDto: OCCredentialsDto? = nil
            var returnError: Error? = nil
            
            if (error != nil) {
                returnError = error
                
            } else if (httpResponse != nil && httpResponse!.statusCode < 200 || httpResponse!.statusCode >= 300) {
                // errored HTTP response from server
                returnError = UtilsFramework.getErrorWithCode(
                    Int(OCErrorOAuth2Error.rawValue),
                    andCustomMessageFromTheServer: ManageNetworkErrors().returnErrorMessage(
                        withHttpStatusCode:  httpResponse!.statusCode,
                        andError: nil
                    )
                );
                
            } else if (httpResponse == nil || data == nil) {
                // generic OAuth2 error, who knows what happened...
                returnError =  UtilsFramework.getErrorByCodeId(Int32(OCErrorOAuth2Error.rawValue));
                
            } else {
                do {
                    if let dictJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary  {
                        
                        if let errorElement = dictJSON["error"] {
                            if errorElement as! String == "access_denied" {
                                returnError = UtilsFramework.getErrorByCodeId(Int32(OCErrorOAuth2ErrorAccessDenied.rawValue));
                            } else {
                                returnError = UtilsFramework.getErrorByCodeId(Int32(OCErrorOAuth2Error.rawValue));
                            }
                            
                        } else {
                            
                            returnUserCredDto = OCCredentialsDto()
                            returnUserCredDto!.userName = dictJSON["user_id"] as? String
                            returnUserCredDto!.accessToken = dictJSON["access_token"] as? String
                            returnUserCredDto!.refreshToken = dictJSON["refresh_token"] as? String
                            returnUserCredDto!.expiresIn = dictJSON["expires_in"] as? String
                            returnUserCredDto!.tokenType = dictJSON["token_type"] as? String
                            returnUserCredDto!.authenticationMethod = AuthenticationMethod.BEARER_TOKEN
                            
                        }
                    } else {
                        returnError = UtilsFramework.getErrorByCodeId(Int32(OCErrorOAuth2Error.rawValue));
                    }
                    
                } catch let error {
                    print("accessTokenAuthRequest no data error:", error.localizedDescription)
                    returnError = error;
                }
            }
            
            completion(returnUserCredDto, returnError)
        })
        
    }
    
    
@objc    func oauthUrlTogetAuthCodeWith (serverPath : String) -> URL {
        
        let oauth2RedirectUri = k_oauth2_redirect_uri
        let oauth2RedirectUriEncoded = oauth2RedirectUri.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        
        let fullServerPath = serverPath + k_oauth2_authorization_endpoint
        let urlComps: NSURLComponents = NSURLComponents(string: fullServerPath)!
        
        let queryItems = [NSURLQueryItem(name: "response_type", value: "code"),
                          NSURLQueryItem(name: "redirect_uri", value: oauth2RedirectUriEncoded),
                          NSURLQueryItem(name: "client_id", value: k_oauth2_client_id)
                        ]
        urlComps.queryItems = queryItems as [URLQueryItem]
        
        let fullOauthUrl = urlComps.url
        
        return fullOauthUrl!
        
    }

@objc    func oauthUrlToGetTokenWith(serverPath : String) -> URL {
    
        var serverPathUrl = URL(string: serverPath)
        serverPathUrl = serverPathUrl?.appendingPathComponent(k_oauth2_token_endpoint)
        let urlComps = NSURLComponents(string: (serverPathUrl?.absoluteString)!)
        
        let fullOauthUrl = urlComps?.url!
        
        return fullOauthUrl!
    }
    
    
//MOVED TO OC LIBRARY
//    // MARK : get authData by refreshToken
//    
//@objc    func refreshTokenAuthRequest(_ url: URL, refreshToken: String, withCompletion completion: @escaping (_ data: Data?,_ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void) {
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        
//        request.setValue(UtilsUrls.getUserAgent(), forHTTPHeaderField: "User-Agent")
//        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        
//        let authId = k_oauth2_client_id+":"+k_oauth2_client_secret
//        let base64EncodedAuthId: String = UtilsFramework.afBase64EncodedString(from: authId)
//        request.setValue("Basic \(base64EncodedAuthId)", forHTTPHeaderField: "Authorization")
//        
//        let body =  "grant_type=refresh_token&refresh_token=\(refreshToken)&redirect_uri=\(k_oauth2_redirect_uri)&client_id=\(k_oauth2_client_id)"
//        let bodyEncoded = body.data(using: String.Encoding.utf8)
//        request.httpBody = bodyEncoded
//        
//        let configuration = URLSessionConfiguration.ephemeral
//        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
//        //        let session = URLSession(configuration: URLSessionConfiguration.default)
//        
//        let task = session.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
//            
//            if let error = error {
//                print(error.localizedDescription)
//                completion(nil, nil, error)
//                
//            } else if let data = data {
//                completion(data , response as? HTTPURLResponse, error)
//                
//            } else {
//                completion(nil, response as? HTTPURLResponse, error)
//            }
//        })
//        task.resume()
//    }
//    
//    
//@objc    func getAuthDataBy(url: URL, refreshToken: String, withCompletion completion: @escaping (_ userCredDto: OCCredentialsDto? ,_ error: String?) -> Void)  {
//        
//        self.refreshTokenAuthRequest(url, refreshToken:refreshToken, withCompletion: { (data:Data?, httpResponse:HTTPURLResponse?, error:Error?) in
//            
//            if data != nil {
//                
//                do {
//                    if let dictJSON = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary  {
//                        
//                        if let resultError = dictJSON["error"] {
//                            completion(nil, resultError as? String)
//                        } else {
//                            
//                            let userCredDto: OCCredentialsDto = OCCredentialsDto()
//                            userCredDto.userName = dictJSON["user_id"] as? String
//                            userCredDto.accessToken = dictJSON["access_token"] as? String
//                            userCredDto.refreshToken = dictJSON["refresh_token"] as? String
//                            userCredDto.expiresIn = dictJSON["expires_in"] as? String
//                            userCredDto.tokenType = dictJSON["token_type"] as? String
//                            userCredDto.authenticationMethod = AuthenticationMethod.BEARER_TOKEN
//                            
//                            completion(userCredDto, nil)
//                        }
//                    } else {
//                        completion(nil, error?.localizedDescription)
//                    }
//                    
//                } catch let error {
//                    print("accessTokenAuthRequest  no data error:", error.localizedDescription)
//                    completion(nil, error.localizedDescription)
//                }
//                
//            } else {
//                completion(nil, error?.localizedDescription)
//            }
//        })
//    }

/// MARK : methods from URLSessionDelegate
    
    // Delegate method called when the server responded with an authentication challenge.
    // Since iOS is so great, it is also called when the server certificate is not trusted, so that the client
    // can decide what to do about it.
    //
    // In this case we only expect to receive an authentication challenge if the server holds a certificate signed
    // by an authority that is not trusted by iOS system. In this case, we need to check the list of certificates
    // that were explicitly accepted by the user before, and allow the request to go on if the current one matches
    // one of them (and not in other case).
    //
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {

        // For the case that the call is due to server certificate not trusted by iOS, we compare the certificate in the
        // authentication challenge with the certificates that were previously accepted by the user in the OC app. If
        // it match any of them, we allow to go on.
        let sslCertificateManager: SSLCertificateManager = SSLCertificateManager()
        let trusted: Bool = sslCertificateManager.isTrustedServerCertificate(in: challenge)
        if (trusted) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential,credential);
            
        } else {
            // If this method was called due to an unstrusted server certificate and this was not accepted by the user before,
            // or if it was called due to a different authentication challenge, default handling will lead the task to fail.
            completionHandler(.performDefaultHandling, nil);
        }

    }
    
/// MARK : methods from URLSessionTaskDelegate

    // Delegate method called when the server responsed with a redirection
    //
    // In this case we need to grant that redirections are just followed, but not with the request proposed by the system.
    // The requests to access token endpoint are POSTs, and iOS proposes GETs for the redirections
    //
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        
        print("DetectAuthenticationMethod: redirect detected in URLSessionTaskDelegate implementation")
        
        // let's resuse the last request performed by the task (it's a POST) and set in it the redirected URL from the request proposed by the system
        if var newRequest: URLRequest = task.currentRequest {
            newRequest.url = request.url
        
            //follow
            completionHandler(newRequest)   // follow
            
        } else {
            completionHandler(nil)  // we don't know where to redirect, something was really wrong -> stop
        }
    }
    
}
