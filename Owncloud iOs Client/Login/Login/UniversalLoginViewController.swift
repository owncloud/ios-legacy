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

//@objc public enum LoginMode: Int {
//    case Create
//    case Update
//    case Expire
//    case Migrate
//}

@objc public enum StateCheckedURL: Int {
    case None
    case TestingConnection
    case ConnectionEstablished
    case ConnectionEstablishedSecure
    case ConnectionEstablishedNonSecure
    case ErrorServerInstanceNotFound
    case ErrorConnectionDeclined
    case ErrorNotPossibleConnectToServer
}




//TODO: check if needed use the notification relaunchErrorCredentialFilesNotification from edit account mode
//TODO: check if is needed property hidesBottomBarWhenPushed in this class to use with edit and add account modes
//TODO: check if need to call delegate #pragma mark - AddAccountDelegate- (void) refreshTable  in settings after add account
//TODO: check if need to setBarForCancelForLoadingFromModal in this class
//TODO: check if neet to use the notification LoginViewControllerRotate from login view (- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration)

/*****************/
//TODO: call manageNetworkError for all possible error after check url, not accepted certificate..



/*
 
 
 authentification_not_valid
 
 
 checkurl
 testing_connection
 -->succes
 secure_connection_established ->DONE
 
 https_non_secure_connection_established ->DONE
 
 connection_established ->DONE
 
 --> error
server_instance_not_found Server not found
 
connection_declined  Connection declined by user
 
 not_possible_connect_to_server It is not possible to connect to the server at this time
 
 error_updating_predefined_url -->migrate -->DONE
 
 */


//TODO: button , hideOrShowPassword

@objc public class UniversalLoginViewController: UIViewController, UITextFieldDelegate, SSODelegate, ManageNetworkErrorsDelegate {
 
// MARK: IBOutlets
    
    @IBOutlet var imageViewLogo: UIImageView!
    
    @IBOutlet var imageViewTopInfo: UIImageView!
    @IBOutlet var labelTopInfo: UILabel!
    
    @IBOutlet var imageViewLeftURL: UIImageView!
    @IBOutlet var textFieldURL: UITextField!
    @IBOutlet var buttonReconnection: UIButton!
    
    @IBOutlet var imageViewURLFooter: UIImageView!
    @IBOutlet var labelURLFooter: UILabel!
    @IBOutlet var activityIndicatorURLFooter: UIActivityIndicatorView!
    
    //For Basic and edit account
    @IBOutlet var imageViewUsername: UIImageView!
    @IBOutlet var textFieldUsername: UITextField!
    
    @IBOutlet var imageViewLeftPassword: UIImageView!
    @IBOutlet var textFieldPassword: UITextField!
    @IBOutlet var imageViewRightPassword: UIImageView!
    
    @IBOutlet var imageViewPasswordFooter: UIImageView!
    @IBOutlet var labelPasswordFooter: UILabel!
    
    @IBOutlet var buttonConnect: UIButton!
    @IBOutlet var buttonHelpLink: UIButton!
    
   // var urlNormalized: String!
    var validatedServerURL: String!
    var allAvailableAuthMethods = [AuthenticationMethod]()
    var authMethodToLogin: AuthenticationMethod!
    var authCodeReceived = ""
    var manageNetworkErrors: ManageNetworkErrors!
    var loginMode: LoginMode!
    public var user: UserDto?
    
    let serverURLNormalizer: ServerURLNormalizer = ServerURLNormalizer()
    let getPublicInfoFromServerJob: GetPublicInfoFromServerJob = GetPublicInfoFromServerJob()
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.manageNetworkErrors = ManageNetworkErrors()
        self.manageNetworkErrors.delegate = self
        textFieldURL.delegate = self
        textFieldUsername.delegate = self
        textFieldPassword.delegate = self
        
        self.showInitMessageCredentialsErrorIfNeeded()

        let enabledEditUrlUsernamePassword : Bool = (self.loginMode == .create || self.loginMode == .migrate)
        self.textFieldURL.isEnabled = enabledEditUrlUsernamePassword ? true : false
        self.textFieldUsername.isEnabled = enabledEditUrlUsernamePassword ? true : false
        
        //set branding styles
            //Set background company color like a comanyImageColor
            //Set background color of company image v
            //status bar k_is_text_login_status_bar_white
            self.setLabelsMessageStyle()
        
        self.initUI()
        
        
        //UtilsCookies.clear()
        
        
        
        print("Init login with loginMode: \(loginMode.rawValue) (0=Create,1=Update,2=Expire,3=Migrate)")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.loginMode == .update || self.loginMode == .migrate {
            UtilsCookies.restoreTheCookiesOfActiveUser()
//TODO: check if need to nil checkaccesstoserver sharedManager
        }
    }

    
    //MARK: Set up credentials error

    func showInitMessageCredentialsErrorIfNeeded() {
    
        if self.loginMode == .migrate {
            
            self.setTopInfo(message: "error_updating_predefined_url")

        } else if self.loginMode == .expire{
            
            self.showCredentialsError()
        }
    }
    
    func showCredentialsError() {
        if Customization.kIsSsoActive() {
            
            self.setTopInfo(message: "session_expired")
            
        } else {
            
            self.setPasswordFooterError(message: "error_login_message")
        }
    }
    

    
    //MARK: Set up image and label with error/info
    
    func setTopInfo(message: String) {
        
        self.labelTopInfo.text = NSLocalizedString(message, comment: "");
        
        self.imageViewTopInfo.image = UIImage(named: "CredentialsError.png")!
    }
    
    
    func setURLFotterSuccess(oNormalized: ServerURLNormalizer) {
        
        var type: StateCheckedURL = .TestingConnection
        type = .ConnectionEstablished         //TODO: check prefix show type of connection, if oNormalized.scheme

        
        self.setURLFooter(message: "", isType: type)
    }

    func setActivityIndicator(isVisible: Bool) {
        //TODO: add and connect with new element in UI and
//        if isVisible {
//            self.activityIndicatorURLFooter.isHidden = false
//            self.activityIndicatorURLFooter.startAnimating()
//        } else {
//            self.activityIndicatorURLFooter.isHidden = true
//            self.activityIndicatorURLFooter.stopAnimating()
//        }
    }
    
    func setURLFooter(message: String, isType type: StateCheckedURL) {
        
        var footerMessage = message
        self.setActivityIndicator(isVisible: false)
        
        switch type {
        case .TestingConnection:
            footerMessage = "testing_connection"
            self.setActivityIndicator(isVisible: true)
            break
            
        case .ConnectionEstablished:
            self.imageViewURLFooter.image = UIImage(named: "NonSecureConnectionIcon.png")!
            footerMessage = "connection_established"
            break
            
        case .ConnectionEstablishedNonSecure:
            self.imageViewURLFooter.image = UIImage(named: "NonSecureConnectionIcon.png")!
            footerMessage = "https_non_secure_connection_established"
            break
            
        case .ConnectionEstablishedSecure:
            self.imageViewURLFooter.image = UIImage(named: "SecureConnectionIcon.png")!
            footerMessage = "secure_connection_established"
            break
            
        case .ErrorServerInstanceNotFound:
            self.imageViewURLFooter.image = UIImage(named: "CredentialsError.png")!
            footerMessage = "server_instance_not_found"
            break
            
        case .ErrorConnectionDeclined:
            self.imageViewURLFooter.image = UIImage(named: "CredentialsError.png")!
            footerMessage = "connection_declined"
            break
         
        case .ErrorNotPossibleConnectToServer:
            self.imageViewURLFooter.image = UIImage(named: "CredentialsError.png")!
            footerMessage = "not_possible_connect_to_server"
            break
        case .None:
            self.imageViewURLFooter.image = nil
            footerMessage = ""
            break
        }
        
        self.labelURLFooter.text = NSLocalizedString(footerMessage, comment: "")
        
    }
    
    func setPasswordFooterError(message: String) {
        
        self.labelPasswordFooter.text = NSLocalizedString(message, comment: "");
        
        self.imageViewPasswordFooter.image = UIImage(named: "CredentialsError.png")!
    }
    

    //MARK: Set style
    
    func setLabelsMessageStyle() {
        
        self.labelTopInfo.backgroundColor = UIColor.clear
        self.labelTopInfo.textColor = UIColor.ofLoginErrorText()
        
        self.labelURLFooter.backgroundColor = UIColor.clear
        self.labelURLFooter.textColor = UIColor.ofLoginErrorText()
        
        self.labelPasswordFooter.backgroundColor = UIColor.clear
        self.labelPasswordFooter.textColor = UIColor.ofLoginErrorText()
    }
    
    func enableLoginButton() {
        self.buttonConnect.isEnabled = true
        self.setConnectButtonStyle(isEnabled: true)
    }
    
    func disableLoginButton() {
        self.buttonConnect.isEnabled = false
        self.setConnectButtonStyle(isEnabled: false)
    }
    
    private func setConnectButtonStyle(isEnabled: Bool) {
        self.buttonConnect.layer.cornerRadius = self.buttonConnect.layer.bounds.height / 4
        self.buttonConnect.setTitleColor(UIColor.ofLoginButtonText(), for: .normal)
        
      if isEnabled {
            self.buttonConnect.backgroundColor = UIColor.ofLoginButtonBackground()
        } else {
            self.buttonConnect.backgroundColor = UIColor.ofLoginButtonBackground().withAlphaComponent(0.6)
      }

    }
    
    

    
    //MARK: UI set up
    func initUI() {
       //self.checkingURLIndicator = UIActivityIndicatorView(frame: self.imageViewURLFooter.frame)
        
        //self.activityIndicatorURLFooter.frame = self.imageViewURLFooter.frame

        //init text
        self.textFieldURL.text = k_default_url_server
        
        if self.loginMode == .create {
            self.textFieldUsername.text = ""
            self.textFieldPassword.text = ""
        } else {
            
            if ( (Customization.kMultiaccountAvailable()
                    && self.loginMode != .migrate
                    && self.loginMode != .expire )
                || self.loginMode == .update) {

                self.setCancelBarButtonSystemItem()
            }
            
            self.checkCurrentUrl()

            if loginMode == .migrate {
                self.textFieldURL.text = k_default_url_server
            } else {
                self.textFieldURL.text = UtilsUrls.getFullRemoteServerPath(self.user)
            }
        
            self.textFieldUsername.text = self.user?.username
            self.textFieldPassword.text = ""
        }
        
        if Customization.kHideUrlServer() {
            //hide and trim spaces below
            
            self.imageViewLeftURL.isHidden = true
            self.textFieldURL.isHidden = true
            
            
            
        }
        
        let shouldBehiddenUserPassFields = (self.loginMode != .create) ? false : true ;
        self.updateUserAndPassFields(hiddenStatus: shouldBehiddenUserPassFields)


        self.disableLoginButton()
        
        self.buttonHelpLink.isHidden = Customization.kIsShownHelpLinkOnLogin() ?  false : true
        
    }
    
    func setCancelBarButtonSystemItem() {
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem:UIBarButtonSystemItem.cancel,
                                           target:self,
                                           action:#selector(closeLoginView))
        
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    func updateUserAndPassFields(hiddenStatus: Bool) {
        
        self.imageViewUsername.isHidden = hiddenStatus
        self.textFieldUsername.isHidden = hiddenStatus
        self.imageViewLeftPassword.isHidden = hiddenStatus
        self.textFieldPassword.isHidden = hiddenStatus
        self.imageViewRightPassword.isHidden = hiddenStatus
        
        if hiddenStatus {        //TODO: use constraints dependencies from above field instead,stack
//
//            self.buttonConnect.center = self.textFieldUsername.center
//        } else {
//            
//             self.buttonConnect.center = self.textFieldUsername.center
        }
    }
    
    func updateUIWithNormalizedData(_ oNormalized: ServerURLNormalizer) {
        self.textFieldURL.text = oNormalized.normalizedURL
        if (oNormalized.user != nil) && !(oNormalized.user?.isEmpty)! {
            self.textFieldUsername.text = oNormalized.user
        }
        if (oNormalized.password != nil) && !(oNormalized.password?.isEmpty)! {
            self.textFieldPassword.text = oNormalized.password
        }
    }

    
    
    
    // MARK: dismiss
    func closeLoginView() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
// MARK: checkUrl
    
    func checkCurrentUrl() {
        
        self.setURLFooter(message: "", isType: .TestingConnection)
        
        if let inputURL = textFieldURL.text {
            self.serverURLNormalizer.normalize(serverURL: inputURL)

            // get public infor from server
            getPublicInfoFromServerJob.start(serverURL: self.serverURLNormalizer.normalizedURL, withCompletion: { (validatedURL: String?, _ serverAuthenticationMethods: Array<Any>?, _ error: Error?, _ httpStatusCode: NSInteger) in
                
                if error != nil {
                    self.manageNetworkErrors.returnErrorMessage(withHttpStatusCode: httpStatusCode, andError: error)
                    print ("error detecting authentication methods")
                    
                } else if validatedURL != nil {
                    
                    self.updateUIWithNormalizedData(self.serverURLNormalizer)
                    
                    self.setURLFooter(message: "", isType: .None)
                    
                    self.validatedServerURL = validatedURL;
                    self.allAvailableAuthMethods = serverAuthenticationMethods as! [AuthenticationMethod]
                    
                    self.authMethodToLogin = DetectAuthenticationMethod().getAuthMethodToLoginFrom(availableAuthMethods: self.allAvailableAuthMethods)
                    
                    if (self.authMethodToLogin != .NONE) {
                        
                        if (self.authMethodToLogin == .BASIC_HTTP_AUTH) {
                            self.updateUserAndPassFields(hiddenStatus: false)
                            self.buttonConnect.isEnabled = false
                        }
                        //else { //TODO: enabledafter enter password and no empty user pass
                            self.buttonConnect.isEnabled = true
                        //}
                        
                        self.setURLFotterSuccess(oNormalized: self.serverURLNormalizer)
                        
                    } else {
                        self.buttonConnect.isEnabled = false
                        self.manageNetworkErrors.returnErrorMessage(withHttpStatusCode: httpStatusCode, andError: nil)
                    }
                    
                } else {
                    self.manageNetworkErrors.returnErrorMessage(withHttpStatusCode: httpStatusCode, andError: nil)
                }
            })
        }
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
            
            let userCredDto: CredentialsDto = CredentialsDto()
            userCredDto.userName = self.textFieldUsername.text
            userCredDto.accessToken = self.textFieldPassword.text
            userCredDto.authenticationMethod = authMethod.rawValue
            
            validateCredentialsAndAddAccount(credentials: userCredDto);
            
            break

        default:
            //TODO: show footer Error
            break
        }

    }
    
    
    func navigateToSAMLLoginView() {

        //Grant main thread
        DispatchQueue.main.async {
            print("_showSSOLoginScreen_ url: %@", self.serverURLNormalizer.normalizedURL)
            
            //New SSO WebView controller
            let ssoViewController: SSOViewController = SSOViewController(nibName: "SSOViewController", bundle: nil)
            ssoViewController.urlString = self.serverURLNormalizer.normalizedURL
            ssoViewController.delegate = self

            //present it
            ssoViewController.navigate(from: self)
        }
    }
    
    func navigateToOAuthLoginView() {
        performSegue(withIdentifier: K.segueId.segueToWebLoginView, sender: self)
    }
    

// MARK: ManageNetworkError delegate
    
    public func errorLogin() {
        
        DispatchQueue.main.async {
            
            self.showCredentialsError()
            
        }
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

    public func setCookieForSSO(_ cookieString: String?, andSamlUserName samlUserName: String?) {
        
        if self.loginMode == .update {
            ManageCookiesStorageDB.deleteCookies(byUser: self.user)
            UtilsCookies.eraseCredentials(withURL: UtilsUrls.getFullRemoteServerPath(withWebDav: self.user))
            UtilsCookies.eraseURLCache()
        }
        
        if cookieString == nil || cookieString == "" {
            // TODO: check if show other message error
            self.setPasswordFooterError(message: NSLocalizedString("authentification_not_valid", comment: "") )
            
            return;
        }
        
        if samlUserName == nil || samlUserName == "" {
            self.setPasswordFooterError(message: NSLocalizedString("saml_server_does_not_give_user_id", comment: "") )

            return
        }
        
        print("BACK with cookieString %@ and samlUserName %@", cookieString!, samlUserName!);

        
        let userCredDto: CredentialsDto = CredentialsDto()
        userCredDto.userName = samlUserName
        userCredDto.accessToken = cookieString
        userCredDto.authenticationMethod = self.authMethodToLogin.rawValue
        
        //We check if the user that we are editing is the same that we are using
        if (self.loginMode == .update  && self.user?.username == samlUserName) || (self.loginMode == .migrate){
            self.textFieldUsername.text = samlUserName
            self.textFieldPassword.text = cookieString
            
            validateCredentialsAndAddAccount(credentials: userCredDto);

        } else {
            
            self.setPasswordFooterError(message: NSLocalizedString("credentials_different_user", comment: "") )
        }
        
        
        
    }
    
//MARK: Manage network errors delegate
    public func showError(_ message: String!) {
        DispatchQueue.main.async {
            self.setURLFooter(message: message, isType: .ErrorNotPossibleConnectToServer)
        }
    }
    
    
// MARK: textField delegate
    public func textFieldDidEndEditing(_ textField: UITextField) {

       // self.checkCurrentUrl()
        
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
                
                let urlToGetAuthData = OauthAuthentication().oauthUrlToGetTokenWith(serverPath: self.serverURLNormalizer.normalizedURL)
                
                OauthAuthentication().getAuthDataBy(url: urlToGetAuthData, authCode: self.authCodeReceived, withCompletion: { ( userCredDto: CredentialsDto?, error: String?) in
                
                    if let userCredentials = userCredDto {
                        
                        self.validateCredentialsAndAddAccount(credentials: userCredentials);
                        
                    } else {
                        // TODO show error?
                    }
                })
            }
        }
    }
    

// MARK: segue
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == K.segueId.segueToWebLoginView) {
            
            let nextViewController = (segue.destination as! WebLoginViewController)
            nextViewController.serverPath = self.serverURLNormalizer.normalizedURL
        }
    }
    
    
// MARK: 'private' methods
    
    func validateCredentialsAndAddAccount(credentials: CredentialsDto) {
        //get list of files in root to check session validty, if ok store new account
        let urlToGetRootFiles = URL (string: UtilsUrls.getFullRemoteServerPathWithWebDav(byNormalizedUrl: self.serverURLNormalizer.normalizedURL) )
        
        DetectListOfFiles().getListOfFiles(url: urlToGetRootFiles!, credentials: credentials,
                                           withCompletion: { (_ errorHttp: NSInteger?,_ error: Error?, _ listOfFileDtos: [FileDto]? ) in
                                            
                                            let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
                                            
                                            if (listOfFileDtos != nil && !((listOfFileDtos?.isEmpty)!)) {
                                                
                                                if self.user == nil {
                                                    self.user = UserDto()
                                                }
                                                
                                                self.user?.url = self.serverURLNormalizer.normalizedURL
                                                self.user?.username = credentials.userName
                                                self.user?.ssl = self.serverURLNormalizer.normalizedURL.hasPrefix("https")
                                                self.user?.urlRedirected = app.urlServerRedirected
                                                self.user?.predefinedUrl = k_default_url_server
                                                
                                                if (app.activeUser == nil) {
                                                    //only set as active account the first account added
                                                    self.user?.activeaccount = true
                                                    app.activeUser = self.user
                                                }
                                                
                                                
                                                if self.loginMode == .create {
                                                    self.user?.idUser = ManageAccounts().storeAccountAndGetIdOfUser(self.user!, withCredentials: credentials)
                                                    if self.user?.idUser != 0 {
                                                        ManageFiles().storeListOfFiles(listOfFileDtos!, forFileId: 0, andUser: self.user!)
                                                        
                                                        app.generateAppInterface(fromLoginScreen: true)

                                                    } else {
                                                        //error
                                                    }
                                                    
                                                } else {
                                                    ManageAccounts().updateAccountOfUser(self.user!, withCredentials: credentials)
                                                    
                                                    self.closeLoginView()
                                                }
                                              
                                                
                                            } else {
                                                
                                                //TODO: check with https url without prefix, error unsupported URL
                                                //                                                if errorHttp == 0 {
                                                    //                                                    self.setPasswordFooterError(message: NSLocalizedString("", comment: "") )
                                                    //
                                                    //                                                } else {
                                                    self.manageNetworkErrors.manageErrorHttp((errorHttp)!, andErrorConnection: error, andUser: self.user)
                                                    //}
                                                    
                                                    
                                                }
                                            })
                                            
        }
    
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setLoginMode(loginMode: LoginMode) {
        self.loginMode = loginMode
    }
    
}
