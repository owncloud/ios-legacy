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
