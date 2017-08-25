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
    
    func readFolderRetryingNumberOfTimes(ntimes:NSInteger, url: NSURL, credentials: OCCredentialsDto,
                           success: ( @escaping (_ listOfFiles: [Any]?) -> Void ),
                            failure: (@escaping (_ errorHttp: NSInteger?,_ error: NSError?) -> Void) ) {
        
        AppDelegate.sharedOCCommunication().setCredentials(credentials)
        AppDelegate.sharedOCCommunication().setValueOfUserAgent(UtilsUrls.getUserAgent())
        
        AppDelegate.sharedOCCommunication().readFolder(url.absoluteString, withUserSessionToken: credentials.accessToken, on: AppDelegate.sharedOCCommunication(),
            
           successRequest: { (response: HTTPURLResponse?, items: [Any]?, redirectedServer: String?, token: String? ) in
            
            if (response != nil) {
                print("Operation success response code:\(String(describing: response?.statusCode))")
            }
            
            var isSamlCredentialsError: Bool = false
            
            if Customization.kIsSsoActive() {
                isSamlCredentialsError = FileNameUtils.isURL(withSamlFragment: response)
                if isSamlCredentialsError {
    
                    //Fail as credentials error
                    failure(Int(kOCErrorServerUnauthorized),
                            UtilsFramework.getErrorWithCode(Int(kOCErrorServerUnauthorized), andCustomMessageFromTheServer: "")! as NSError)
                    return;
                }
            }
            //TODO: chec redirectedserver in status
            if (items?.isEmpty)! {
                let statusCode: NSInteger = (response?.statusCode == nil) ? 0: (response?.statusCode)!
               failure(statusCode, UtilsFramework.getErrorWithCode(Int(kOCErrorServerUnauthorized), andCustomMessageFromTheServer: "")! as NSError)
            } else {
                success(items)
            }
            
        }, failureRequest: { (response:HTTPURLResponse?, error: Error?, token: String?, redirectedServer: String?) in
            
            if (ntimes <= 0) {
                let statusCode: NSInteger = (response?.statusCode == nil) ? 0: (response?.statusCode)!
                
                failure(statusCode, error! as NSError)

            } else {
                
                self.readFolderRetryingNumberOfTimes(ntimes: ntimes - 1, url: url, credentials: credentials, success: success, failure: failure)
            }
            
       })
    }
    
    

 func getListOfFiles(url:NSURL, credentials: OCCredentialsDto, withCompletion completion: @escaping (_ errorHttp: NSInteger?,_ error: NSError?, _ listOfFileDtos: [FileDto]? ) -> Void) {
        
        self.readFolderRetryingNumberOfTimes(ntimes: 2, url: url, credentials: credentials, success: { (_ listOfFiles: [Any]?) in
            var listOfFileDtos: [FileDto]? = nil
            
            if (listOfFiles != nil && !((listOfFiles?.isEmpty)!)) {
                
                print("\(String(describing: listOfFiles)) files found in this folder")
                
                //Pass the listOfFiles with OCFileDto to FileDto Array
                listOfFileDtos = UtilsDtos.pass(toFileDtoArrayThisOCFileDtoArray: listOfFiles) as? [FileDto]
                
                completion(nil, nil, listOfFileDtos)
            }
            
        }) { (_ errorHttp: NSInteger?,_ error: NSError?) in
            
            completion(errorHttp, error, nil)
        }

    }
    
    func aaa(){
    
    }
}
