//
//  GetPublicInfoFromServerJob.swift
//  Owncloud iOs Client
//
//  Created by David A. Velasco on 19/7/17.
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


class GetPublicInfoFromServerJob: NSObject, CheckAccessToServerDelegate {
    
    var serverURL: String
    
    var enforcedScheme: String
    
    var fullUrl: String {
        get {
            return "\(self.enforcedScheme)\(self.serverURL)"
        }
    }

    var checkAccessToServerJob: CheckAccessToServer
    
    var completion: ((_ validatedURL: String?, _ serverAuthenticationMethods: Array<Any>?, _ error: Error?, _ httpStatusCode: NSInteger) -> Void)?
    
    override init() {
        serverURL = ""
        enforcedScheme = ""
        checkAccessToServerJob = CheckAccessToServer.sharedManager() as! CheckAccessToServer
        super.init()
    }
    
    func start(serverURL: String, withCompletion completion: @escaping (_ validatedURL: String?, _ serverAuthenticationMethods: Array<Any>?, _ error: Error?, _ httpStatusCode: NSInteger) -> Void) {
        
        self.serverURL = serverURL
        self.completion = completion

        enforcedScheme = ""
        if serverURLHasNoScheme() {
            enforcedScheme = "https://"
        }
        // STEP 1: check status of the server
        checkAccessToServer()
     
        // STEP 2 will be started from connection(toTheServer: Bool), if check was fine
    }
    
    func serverURLHasNoScheme() -> Bool {
        return !(serverURL.hasPrefix("https://") || serverURL.hasPrefix("http://"))
    }
    
    func checkAccessToServer() {
        checkAccessToServerJob.delegate = self
        checkAccessToServerJob.isConnectionToTheServer(byUrl: fullUrl)
    }
    
    
    // MARK:  CheckAccessToServerDelegate implementation
    
    public func connection(toTheServerWasChecked isConnected: Bool, withHttpStatusCode statusCode: Int, andError error: Error!) {
        if !isConnected {
            print("No connection to the server")
            
            if serverURLHasNoScheme() && enforcedScheme == "https://" {
                enforcedScheme = "http://"
                // STEP 1(bis): check status of the server
                checkAccessToServer()
                
            } else {
                self.completion?(nil, nil, error, statusCode)
                
                print("No connection to the server")
            }
            
        } else {
            print("Ok connection to the server")
            
            // STEP 2: detect authentication methods accepted by the server
            let stringUrl = fullUrl + k_url_webdav_server
            let urlToCheck: URL = URL(string: stringUrl)!
            
            DetectAuthenticationMethod().getAuthenticationMethodsAvailableBy(url: urlToCheck, withCompletion: { (authMethods: Array<Any>?, error: Error?) in
                
                if error != nil {
                    self.completion?(nil, nil, error, 0)
                } else {
                    // everything ok: return validated server URL and list of available authentication methods
                    self.completion?(self.fullUrl, authMethods as! [AuthenticationMethod], nil, 0)
                }
            })
            
        }
        
    }
    
    public func repeatTheCheckToTheServer() {
        // just glue
        checkAccessToServer()
    }
    
    public func badCertificateNotAcceptedByUser() {
        let error = UtilsFramework.getErrorWithCode(Int(OCErrorSslRecoverablePeerUnverified.rawValue), andCustomMessageFromTheServer: "")
        self.completion?(nil, nil, error, 0)
    }
    
}
