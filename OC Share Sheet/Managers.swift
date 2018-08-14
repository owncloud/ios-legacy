//
//  Managers.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/3/15.
//

/*
Copyright (C) 2016, ownCloud GmbH.
This code is covered by the GNU Public License Version 3.
For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
You should have received a copy of this license
along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

import UIKit

@objc class Managers: NSObject {

    //MARK: FMDatabaseQueue
    @objc class var sharedDatabase: FMDatabaseQueue {
       struct Static {
        static let sharedDatabase: FMDatabaseQueue = FMDatabaseQueue(path:((UtilsUrls.getOwnCloudFilePath()).appending("DB.sqlite")), flags: SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FILEPROTECTION_NONE)
        }

        return Static.sharedDatabase
    }
}

//MARK: OCCommunication
extension OCCommunication {
	@objc static var shared: OCCommunication = {
		//Code
		let networkConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
		networkConfiguration.httpShouldUsePipelining = true
		networkConfiguration.httpMaximumConnectionsPerHost = 1
		networkConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData

		let networkSessionManager: OCURLSessionManager = OCURLSessionManager(sessionConfiguration: networkConfiguration)
		networkSessionManager.operationQueue.maxConcurrentOperationCount = 1
		networkSessionManager.responseSerializer = AFHTTPResponseSerializer()

		let sharedOCCommunication: OCCommunication = OCCommunication(uploadSessionManager: nil, andDownloadSessionManager: nil, andNetworkSessionManager: networkSessionManager)
		sharedOCCommunication.isCookiesAvailable = true

		let ocOAuth2conf: OCOAuth2Configuration = OCOAuth2Configuration(clientId: k_oauth2_client_id, clientSecret: k_oauth2_client_secret, redirectUri: k_oauth2_redirect_uri, authorizationEndpoint: k_oauth2_authorization_endpoint, tokenEndpoint: k_oauth2_token_endpoint)
		sharedOCCommunication.setValueOauth2Configuration(ocOAuth2conf)

		sharedOCCommunication.setValueOfUserAgent(UtilsUrls.getUserAgent());

		let ocKeychain = OCKeychain()
		sharedOCCommunication.setValueCredentialsStorage(ocKeychain)

		let sslCertificateManager = SSLCertificateManager()
		sharedOCCommunication.setValueTrustedCertificatesStore(sslCertificateManager)

		return sharedOCCommunication
	}()
}
