//
//  WebLoginViewController.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 23/06/2017.
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


@objc class WebLoginViewController: UIViewController, UIWebViewDelegate, UITextFieldDelegate {

    
    // MARK: IBOutlets
    @IBOutlet var webViewLogin: UIWebView!
    
    var serverPath: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //TODO: set branding style navigation bar, cancel item title
        
        //load login url in web view
        let urlToGetAuthCode = OauthAuthentication().oauthUrlTogetAuthCodeFrom(serverPath: serverPath)
        self.loadWebViewWith(url: urlToGetAuthCode)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loadWebViewWith (url : URL) {
       
        //clearAllCookies

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TimeInterval(k_timeout_upload))
        request.addValue(UtilsUrls.getUserAgent(), forHTTPHeaderField: "User-Agent")
        
        self.webViewLogin.loadRequest(request)

    }
    

}
