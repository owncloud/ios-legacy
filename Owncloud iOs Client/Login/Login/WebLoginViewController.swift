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
        self.webViewLogin.delegate = self
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
    
    
    // MARK: webView delegates
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        
        print("Loading login in webView")
        
        //TODO: show loading activityIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        print("Loaded url")
        
        //TODO: stop loading
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("An error happened during load: \(error)");
        
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let urlToFollow = request.url?.absoluteString
         print(urlToFollow)
        
        let oauth2RedirectUri = k_oauth2_redirect_uri
        let oauth2RedirectUriEncoded = oauth2RedirectUri.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        
        let redirectUriParam = getQueryStringParameter(url: urlToFollow!, param: "redirect_uri")
        let codeParam = getQueryStringParameter(url: urlToFollow!, param: "code")

        if let url = urlToFollow?.contains(oauth2RedirectUriEncoded!){
        print("contains url")
            //TODO: get code
           // return false;
        }
        
        return true;
    }
    
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
}
