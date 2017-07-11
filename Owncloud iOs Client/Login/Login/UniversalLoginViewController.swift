//
//  UniversalLoginViewController.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 21/06/2017.
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

struct K {
    struct segueId {
        static let segueToWebLoginView = "segueToWebLoginView"
    }
    
    struct unwindId {
        static let unwindToMainLoginView = "unwindToMainLoginView"
    }
    
    struct vcId {
        static let vcIdWebViewLogin = "WebViewLoginViewController"
    }
    
}

@objc class UniversalLoginViewController: UIViewController, UITextFieldDelegate, CheckAccessToServerDelegate {
 
// MARK: IBOutlets
    
    @IBOutlet var imageViewLogo: UIImageView!
    @IBOutlet var textFieldURL: UITextField!
    @IBOutlet var buttonConnect: UIButton!
    @IBOutlet var buttonHelpLink: UIButton!
    @IBOutlet var buttonReconnection: UIButton!
    
    var urlNormalized: String!
    var allAvailableAuthMethods = [AuthenticationMethod]()
    var authMethodToLogin: AuthenticationMethod!
    var authCodeReceived = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldURL.delegate = self;
        self.buttonConnect.isEnabled = false
        // Do any additional setup after loading the view.
        
        //set branding style
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
// MARK: checkUrl
    
    func checkCurrentUrl() {
        
        textFieldURL.resignFirstResponder()

       //let stringURL = textFieldURL.text
    
        self.urlNormalized = textFieldURL.text //TODO: normalize url
        //parse url, appsfiles, user:pass, prefix
        
        
        //check status and get authmethods available
        
        let checkAccessToServer : CheckAccessToServer = CheckAccessToServer.sharedManager() as! CheckAccessToServer
        checkAccessToServer.delegate = self
        checkAccessToServer.isConnectionToTheServer(byUrl: self.urlNormalized)
        
    }
    
    
// MARK: start log in auth
    
    func startAuthenticationWith(authMethod: AuthenticationMethod) {
        
        switch authMethod {
        case .SAML_WEB_SSO:

            LoginViewController().showSSOLoginScreen(withUrl: self.urlNormalized, inVC: self)
            
            break
        case .BEARER_TOKEN:
            
            performSegue(withIdentifier: K.segueId.segueToWebLoginView, sender: self)
            
            break
        case .BASIC_HTTP_AUTH:
            //TODO
            break
        default:
            //TODO: show footer Error

            break
        }
    }
    
    func openWebViewLogin() {
        
    }
    
    
// MARK:  CheckAccessToServer delegate
    
    func connection(toTheServer isConnection: Bool) {
        if isConnection {
            print("Ok connection to the server")
            
            let stringUrl = self.urlNormalized + k_url_webdav_server
            let urlToCheck: URL = URL(string: stringUrl)!
            
            DetectAuthenticationMethod().getAuthenticationMethodsAvailableBy(url: urlToCheck, withCompletion: { (authMethods: Array<Any>?, error: Error?) in
                
                if authMethods != nil {
                    self.allAvailableAuthMethods = authMethods as! [AuthenticationMethod];
                    //do things, open webview
                    
                    self.authMethodToLogin = DetectAuthenticationMethod().getAuthMethodToLoginFrom(availableAuthMethods: self.allAvailableAuthMethods)
                    
                    if (self.authMethodToLogin != .NONE) {
                        self.buttonConnect.isEnabled = true
                    } else {
                        self.buttonConnect.isEnabled = false
                        //TODO show error
                    }
                    
                } else if error != nil{
                    //TODO: show error
                    print ("error detecting authentication methods")
                }
                
                
            })
            
        } else {
            print("No connection to the server")
        }
        
    }
    
    func repeatTheCheckToTheServer() {
        
    }
    
// MARK: textField delegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {

        self.checkCurrentUrl()
        
    }


// MARK: IBActions
    
    @IBAction func reconnectionButtonTapped(_ sender: Any) {
        self.checkCurrentUrl()
    }
    
    
    @IBAction func connectButtonTapped(_ sender: Any) {
        
        self.startAuthenticationWith(authMethod: self.authMethodToLogin)
        
    }
    
    
    @IBAction func helpLinkButtonTapped(_ sender: Any) {
        //open web view help
        
    }
    
    @IBAction func unwindToMainLoginView(segue:UIStoryboardSegue) {
        if let sourceViewController = segue.source as? WebLoginViewController {
            let webVC: WebLoginViewController = sourceViewController
            if !(webVC.authCode).isEmpty {
                self.authCodeReceived = webVC.authCode
                
                let urlToGetAuthData = OauthAuthentication().oauthUrlToGetTokenWith(serverPath: self.urlNormalized)
                OauthAuthentication().getAuthDataBy(url: urlToGetAuthData, authCode: authCodeReceived, withCompletion: { (dataDict: Dictionary<String, String>?, error: String?) in
                
                    if (dataDict != nil) {
                        //getfiles, if ok store new account
                       // DetectListOfFiles().getListOfFiles(url: URL, authType: AuthenticationMethod, accessToken: String)
                    }

                })
            }
        }
    }
    

// MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == K.segueId.segueToWebLoginView) {
            
            let nextViewController = (segue.destination as! WebLoginViewController)
            nextViewController.serverPath = self.urlNormalized
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
