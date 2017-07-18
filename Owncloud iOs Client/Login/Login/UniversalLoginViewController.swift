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

@objc class UniversalLoginViewController: UIViewController, UITextFieldDelegate, CheckAccessToServerDelegate, SSODelegate, ManageNetworkErrorsDelegate {
 
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
    var manageNetworkErrors: ManageNetworkErrors!
    var loginMode: LoginMode!
    
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        
//
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.manageNetworkErrors = ManageNetworkErrors()
        self.manageNetworkErrors.delegate = self
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
            navigateToSAMLLoginView();
            break

        case .BEARER_TOKEN:
            navigateToOAuthLoginView();
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
    
    func navigateToSAMLLoginView() {

        //Grant main thread
        DispatchQueue.main.async {
            print("_showSSOLoginScreen_ url: %@", self.urlNormalized);
            
            //New SSO WebView controller
            let ssoViewController: SSOViewController = SSOViewController(nibName: "SSOViewController", bundle: nil);
            ssoViewController.urlString = self.urlNormalized;
            ssoViewController.delegate = self;

            //present it
            ssoViewController.navigate(from: self);
        }
    }
    
    func navigateToOAuthLoginView() {
        performSegue(withIdentifier: K.segueId.segueToWebLoginView, sender: self)
    }
    
// MARK:  CheckAccessToServerDelegate implementation
    
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
        // just glue
        checkCurrentUrl()
    }
  
// MARK: ManageNetworkError delegate
    
    func errorLogin() {
        //TOOD: SHow error in url footer
    }
    
// MARK: SSODelegate implementation
    
    
    /**
     * This delegate method is called from SSOViewController when the user
     * successfully logs-in.
     *
     * @param cookieString -> NSString      Cookies in last state of the SSO WebView , including SSO cookie & OC session cookie.
     * @param samlUserName -> NSString      Username.
     *
     */
    func setCookieForSSO(_ cookieString: String!, andSamlUserName samlUserName: String!) {

        print("BACK with cookieString %@ and samlUserName %@", cookieString, samlUserName);
        
        if cookieString == nil || cookieString == "" {
            // TODO show error
            return;
        }
        
        if samlUserName == nil || samlUserName == "" {
            // TODO show error NSLocalizedString(@"saml_server_does_not_give_user_id", nil)
            return
        }
        
        let userCredDto: CredentialsDto = CredentialsDto()
        userCredDto.userName = samlUserName
        userCredDto.accessToken = cookieString
        userCredDto.authenticationMethod = self.authMethodToLogin.rawValue
        
        validateCredentialsAndCreateNewAccount(credentials: userCredDto);
        
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
                OauthAuthentication().getAuthDataBy(url: urlToGetAuthData, authCode: self.authCodeReceived, withCompletion: { ( userCredDto: CredentialsDto?, error: String?) in
                
                    if let userCredentials = userCredDto {
                        
                        self.validateCredentialsAndCreateNewAccount(credentials: userCredentials);
                        
                    } else {
                        // TODO show error?
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
    
    
// MARK: 'private' methods
    
    func validateCredentialsAndCreateNewAccount(credentials: CredentialsDto) {
        //get list of files in root to check session validty, if ok store new account
        let urlToGetRootFiles = URL (string: UtilsUrls.getFullRemoteServerPathWithWebDav(byNormalizedUrl: self.urlNormalized) )
        
        DetectListOfFiles().getListOfFiles(url: urlToGetRootFiles!, credentials: credentials,
                                           withCompletion: { (_ errorHttp: NSInteger?,_ error: Error?, _ listOfFileDtos: [FileDto]? ) in
                                            
                                            if (listOfFileDtos != nil && !((listOfFileDtos?.isEmpty)!)) {
                                                
                                                let user: UserDto = UserDto()
                                                user.url = self.urlNormalized
                                                user.username = credentials.userName
                                                
                                                user.ssl = self.urlNormalized.hasPrefix("https")
                                                user.activeaccount = true
                                                user.urlRedirected = (UIApplication.shared.delegate as! AppDelegate).urlServerRedirected
                                                user.predefinedUrl = k_default_url_server
                                                
                                                ManageAccounts().storeAccountOfUser(user, withCredentials: credentials)
                                                
                                                ManageFiles().storeListOfFiles(listOfFileDtos!, forFileId: 0)
                                                
                                                //Generate the app interface
                                                (UIApplication.shared.delegate as! AppDelegate).generateAppInterface(fromLoginScreen: true)
                                                
                                            } else {
                                                
                                                self.manageNetworkErrors.returnErrorMessage(withHttpStatusCode: errorHttp!, andError: error)
                                            }
        })
        
    }
    
}
