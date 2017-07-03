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

@objc class UniversalLoginViewController: UIViewController, UITextFieldDelegate, CheckAccessToServerDelegate {
 
    struct K {
        struct segueId {
            static let segueWebViewLogin = "segueWebViewLogin"
        }
        
        struct vcId {
            static let vcIdWebViewLogin = "WebViewLoginViewController"
        }
        
    }
    
    
// MARK: IBOutlets
    
    @IBOutlet var imageViewLogo: UIImageView!
    @IBOutlet var textFieldURL: UITextField!
    @IBOutlet var buttonConnect: UIButton!
    @IBOutlet var buttonHelpLink: UIButton!
    @IBOutlet var buttonReconnection: UIButton!
    
    var urlNormalized: String!
    var allAvailableAuthMethods = [AuthenticationMethod]()
    var authMethodToLogin: AuthenticationMethod!

    
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
    
    
// MARK:  CheckAccessToServer delegate
    
    func connection(toTheServer isConnection: Bool) {
        if isConnection {
            print("Ok connection to the server")
            
            let urlComps = NSURLComponents(string: self.urlNormalized)!
            urlComps.path = "/\(k_url_webdav_server)"
            let fullUrl: URL = urlComps.url!
            
            DetectAuthenticationMethod().getAuthenticationMethodsAvailableBy(url: fullUrl, withCompletion: { (authMethods: Array<Any>?) in
                self.allAvailableAuthMethods = authMethods as! [AuthenticationMethod];
                //do things, open webview
                
                self.authMethodToLogin = DetectAuthenticationMethod().getAuthMethodToLoginFrom(availableAuthMethods: self.allAvailableAuthMethods)
                
                self.buttonConnect.isEnabled = true
                
            })
            
        } else {
            print("No connection to the server")
        }

    }
    
    
    
    func startAuthenticationWith(authMethod: AuthenticationMethod) {
        
        
        switch authMethod {
        case .SAML_WEB_SSO:
            //TODO
            
            break
        case .BEARER_TOKEN:
            
            performSegue(withIdentifier: K.segueId.segueWebViewLogin, sender: self)
            
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
    
    @IBAction func cancelToMainLoginView(segue:UIStoryboardSegue) {
        
    }
    
    
// MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == K.segueId.segueWebViewLogin) {
            
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
