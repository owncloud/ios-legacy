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


@objc class WebLoginViewController: UIViewController, UIWebViewDelegate, UITextFieldDelegate, NSURLConnectionDelegate {


    var authCode = ""
    var error: Error? = nil
    
    private let sslCertificateManager: SSLCertificateManager = SSLCertificateManager();

    private var currentRequest: URLRequest? = nil;
    
    private var loadInterrupted: Bool = false;

    private let oAuth2Manager: OCOAuth2Manager = OCOAuth2Manager()
    
    // MARK: IBOutlets
    @IBOutlet var webViewLogin: UIWebView!
    @IBOutlet var cancelButton: UIBarButtonItem!

    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.closeLoginViewController()

    }

    func closeLoginViewController() {
        self.performSegue(withIdentifier: K.unwindId.unwindToMainLoginView, sender: self)
    }

    var serverPath: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webViewLogin.delegate = self
        self.webViewLogin.backgroundColor = UIColor.ofWebViewBackground()
    
        // Do any additional setup after loading the view.
                
        //load login url in web view
        let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
        self.oAuth2Manager.trustedCertificatesStore = self.sslCertificateManager
        let urlToGetAuthCode = self.oAuth2Manager.getOAuth2URLToGetAuthCode(by: app.oauth2Configuration, withServerPath: serverPath)
        self.loadWebViewWith(url: urlToGetAuthCode!)
        
        self.loadInterrupted = false;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadWebViewWith (url : URL) {
       
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TimeInterval(k_timeout_upload))
        request.addValue(UtilsUrls.getUserAgent(), forHTTPHeaderField: "User-Agent")
        //request.setValue("", forHTTPHeaderField: "Cookie")
        
        self.webViewLogin.loadRequest(request)

    }
    
    
    // MARK: webView delegates
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        
        print("Loading login in webView with url:\(String(describing: webView.request?.mainDocumentURL))")
        //TODO: show loading activityIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        print("Loaded url:\(String(describing: webView.request?.mainDocumentURL))")
        
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("An error happened during load: \(error)");
        
        if sslCertificateManager.isUntrustedServerCertificate(error) {
            self.retryIfCertificateInCurrentRequestWasAcceptedByUser()
            return;
            
        } else if !self.loadInterrupted {
            self.error = error

        } //else, let the error set in webView(webView, shouldStartLoadWith, navigationType), if any
        
        self.closeLoginViewController()
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let urlToFollow: String = (request.url?.absoluteString)!

        // We store the request to inspect the server certificate and retry it in case of SSL error
        self.currentRequest = request;

        if urlToFollow.hasPrefix(k_oauth2_redirect_uri){
            processFinalRedirect(urlToFollow);
            self.loadInterrupted = true;
            return false;      // will trigger webView(webView, didFailLoadWithError), with error due to cancellation
            
        } else if urlToFollow.hasPrefix(serverPath + k_url_path_list_of_files_in_web) {
            self.error = UtilsFramework.getErrorByCodeId(Int32(OCErrorOAuth2Error.rawValue))
            self.loadInterrupted = true;
            // for some reason, this time "return false" will NOT trigger webView(webView, didFailLoadWithError), with error due to cancellation
            // so, let's solve it here:
            self.closeLoginViewController()
            return false;
        }
        
        return true;
    }
    
    func processFinalRedirect(_ urlToFollow: String) -> Void {
        if let code = getQueryStringParameter(url: urlToFollow, param: "code") {
            self.authCode = code
            self.error = nil;
            print("contains url and code auth \(self.authCode)")
            
        } else if let errorString = getQueryStringParameter(url: urlToFollow, param: "error") {
            if errorString == "access_denied" {
                self.error = UtilsFramework.getErrorByCodeId(Int32(OCErrorOAuth2ErrorAccessDenied.rawValue))
            } else {
                self.error = UtilsFramework.getErrorByCodeId(Int32(OCErrorOAuth2Error.rawValue))
            }
            
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
 

    // MARK - HACK on UIWebView to allow access to servers with insecure certificates that were already accepted by the user
    
    func retryIfCertificateInCurrentRequestWasAcceptedByUser() -> Void {
        // Start an NSURLConnection with the current request to receive an authentication challenge that we can accept or not
        NSURLConnection.init(request: currentRequest!, delegate: self)
            // TODO - check if hack works also with NSURLSession
    }
    
    // MARK NSURLConnection Delegate Method, part of the HACK on UIWebView
    
    public func connection(_ connection: NSURLConnection, willSendRequestFor challenge: URLAuthenticationChallenge) {
        var trusted: Bool = false
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
            if sslCertificateManager.isTrustedServerCertificate(in: challenge) {
                print("trusting connection to host %@", challenge.protectionSpace.host)
    
                trusted = true;
    
                challenge.sender?.use(URLCredential.init(trust: challenge.protectionSpace.serverTrust!), for: challenge)
    
            } else {
                print("Not trusting connection to host %@", challenge.protectionSpace.host);
            }
    
        } else {
            print("WARNING: expecting NSURLAuthenticationMethodServerTrust, received %@ instead, will continue without credentials", challenge);
        }
    
        if (!trusted) {
            challenge.sender?.continueWithoutCredential(for: challenge)
        }
    
        connection.cancel()
            // nothing else is needed from the connection once that challenge.sender is "instructed";
            // ir will cache the response for future uses, what allows to load the request again in the webview successfully
        
        if (trusted) {
            // retry it; should work now!
            self.webViewLogin.loadRequest(currentRequest!)
            
        } else {
            // TODO askToAcceptCertificate()
            print("TODO: askToAcceptCertificate() or direct error");
        }
    }
    
}
