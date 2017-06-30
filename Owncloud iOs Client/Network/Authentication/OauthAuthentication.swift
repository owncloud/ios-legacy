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


class OauthAuthentication: NSObject {


    func authCodeRequest(_ urlString: String, withCompletion completion: @escaping (_ httpResponse: HTTPURLResponse?, _ error: Error?) -> Void) {
     


    }
    
    func oauthUrlTogetAuthCodeFrom (serverPath : String) -> URL {
        
        let oauth2RedirectUri = k_oauth2_redirect_uri
        let oauth2RedirectUriEncoded = oauth2RedirectUri.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        
        
        let urlComps = NSURLComponents(string: serverPath)!
        urlComps.path = k_oauth2_authorization_endpoint
        
        let queryItems = [NSURLQueryItem(name: "response_type", value: "code"),
                          NSURLQueryItem(name: "redirect_uri", value: oauth2RedirectUriEncoded),
                          NSURLQueryItem(name: "client_id", value: k_oauth2_client_id)
                        ]
        urlComps.queryItems = queryItems as [URLQueryItem]
        
        let fullOauthUrl = urlComps.url!
        
        return fullOauthUrl
        
    }
    
    

    

}
