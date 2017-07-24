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
    
    func readFolderRequest(url: URL, credentials: CredentialsDto, withCompletion completion: @escaping (_ errorHttp: NSInteger?,_ error: Error?,_ listOfFiles: [Any]?) -> Void ) {
        
        self.setCredentialsAndUserAgentWith(credentials: credentials)
        
        AppDelegate.sharedOCCommunication().readFolder(url.absoluteString, withUserSessionToken: credentials.accessToken, on: AppDelegate.sharedOCCommunication(),
            
           successRequest: { (response: HTTPURLResponse?, items: [Any]?, redirectedServer: String?, token: String?) in
            
            if (response != nil) {
                print("Operation success response code:\(String(describing: response?.statusCode))")
            }
            
            var isSamlCredentialsError: Bool = false
            
            if Customization.kIsSsoActive() {
                isSamlCredentialsError = FileNameUtils.isURL(withSamlFragment: response)
                if isSamlCredentialsError {
    
                    //Fail as credentials error
                    completion(Int(kOCErrorServerUnauthorized), nil , nil)
                }
            }
            //TODO: chec redirectedserver in status
            if !isSamlCredentialsError {
                
                completion(nil, nil , items)
            }
            
        }, failureRequest: { (response:HTTPURLResponse?, error: Error?, token: String?, redirectedServer: String?) in
            
            completion(response?.statusCode, error, nil)
        })
    }
    
    
    func setCredentialsAndUserAgentWith(credentials: CredentialsDto) {
        
        AppDelegate.sharedOCCommunication().setValueOfUserAgent(UtilsUrls.getUserAgent())
        let authenticationMethod = AuthenticationMethod(rawValue: credentials.authenticationMethod);
        
        switch authenticationMethod! {
        case .BEARER_TOKEN:
            AppDelegate.sharedOCCommunication().setCredentialsOauthWithToken(credentials.accessToken)
        case .SAML_WEB_SSO:
            AppDelegate.sharedOCCommunication().setCredentialsWithCookie(credentials.accessToken)
        default:
            AppDelegate.sharedOCCommunication().setCredentialsWithUser(credentials.userName, andPassword: credentials.accessToken)
        }
    }
    
    
    func getListOfFiles(url:URL, credentials: CredentialsDto, withCompletion completion: @escaping (_ errorHttp: NSInteger?,_ error: Error?, _ listOfFileDtos: [FileDto]? ) -> Void) {
        
        self.readFolderRequest(url: url, credentials: credentials) { (_ errorHttp: NSInteger?,_ error: Error?,_ listOfFiles: [Any]?) in
            
            var listOfFileDtos: [FileDto]? = nil
            
            if (listOfFiles != nil && !((listOfFiles?.isEmpty)!)) {
                
                print("\(String(describing: listOfFileDtos)) files found in this folder")
                
                //Pass the listOfFiles with OCFileDto to FileDto Array
                listOfFileDtos = UtilsDtos.pass(toFileDtoArrayThisOCFileDtoArray: listOfFiles) as? [FileDto]
                
                completion(errorHttp, error, listOfFileDtos)
            } else {
                 completion(errorHttp, error, nil)
            }
        }
    }
    
}
