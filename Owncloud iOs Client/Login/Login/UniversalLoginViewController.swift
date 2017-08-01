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
    case TestingConnection
    case ConnectionEstablished
    case ConnectionEstablishedSecure
    case ConnectionEstablishedNonSecure
    case ErrorConnectionNoEstablished
}


//TODO: check if needed use the notification relaunchErrorCredentialFilesNotification from edit account mode
//TODO: check if is needed property hidesBottomBarWhenPushed in this class to use with edit and add account modes
//TODO: check if need to call delegate #pragma mark - AddAccountDelegate- (void) refreshTable  in settings after add account
//TODO: check if need to setBarForCancelForLoadingFromModal in this class
//TODO: check if neet to use the notification LoginViewControllerRotate from login view (- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration)

/*****************/
//TODO: call setURLFooter when checkurl success with type .connection or .connectionsecure
//TODO: call manageNetworkError for all possible error after check url, not accepted certificate..


/*
 
 
 authentification_not_valid
 
 
 checkurl
 testing_connection
 -->succes
 secure_connection_established
 
 https_non_secure_connection_established
 
 connection_established
 
 --> error
server_instance_not_found
 
 
 
connection_declined
 
 error_updating_predefined_url -->migrate -->DONE

 
 
 //    case Create
 //    case Update
 //    case Expire
 //    case Migrate ->DONE
 
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
    
    var urlNormalized: String!
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
        type = .ConnectionEstablished         //TODO: check prefix show type of connection

        
        self.setURLFooter(message: "", isType: type)
    }

    func setURLFooter(message: String, isType type: StateCheckedURL) {
        
        var footerMessage = message
        
        switch type {
        case .TestingConnection:
            footerMessage = "testing_connection"
            //TODO:set activity indicator
            
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
            
        case .ErrorConnectionNoEstablished:
            self.imageViewURLFooter.image = UIImage(named: "CredentialsError.png")!
            break
            
        }
        
        self.labelURLFooter.text = NSLocalizedString(footerMessage, comment: "")
        
        self.imageViewURLFooter.isHidden = false
        self.labelURLFooter.isHidden = false
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
    
    

    
    //MARK: UI set up
    func initUI() {
        
        //init text
        self.textFieldURL.text = k_default_url_server
        
        if self.loginMode == .update {
            self.textFieldURL.text = UtilsUrls.getFullRemoteServerPath(self.user)
            self.checkCurrentUrl()
            self.textFieldUsername.text = self.user?.username
            self.textFieldPassword.text = ""
            self.setCancelBarButtonSystemItem()
        } else {
            self.textFieldUsername.text = ""
            self.textFieldPassword.text = ""
        }
        
        if Customization.kHideUrlServer() {
            //hide and trim spaces below
            
            self.imageViewLeftURL.isHidden = true
            self.textFieldURL.isHidden = true
            
            
            
        }
        
        let shouldBehiddenUserPassFields = (self.loginMode != .create) ? false : true ;
        self.updateUserAndPassFields(hiddenStatus: shouldBehiddenUserPassFields)


        self.buttonConnect.isEnabled = false
        
        
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
    
    
    
    // MARK: dismiss
    func closeLoginView() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
// MARK: checkUrl
    
    func checkCurrentUrl() {
        
        if let inputURL = textFieldURL.text {
            self.urlNormalized = serverURLNormalizer.normalize(serverURL: inputURL)

            // get public infor from server
            getPublicInfoFromServerJob.start(serverURL: self.urlNormalized, withCompletion: { (validatedURL: String?, _ serverAuthenticationMethods: Array<Any>?, _ error: Error?, _ httpStatusCode: NSInteger) in
                
                if error != nil {
                    self.manageNetworkErrors.returnErrorMessage(withHttpStatusCode: httpStatusCode, andError: error)
                    print ("error detecting authentication methods")
                    
                } else if validatedURL != nil {

                    self.labelURLFooter.text = ""
                    self.imageViewURLFooter.isHidden = true
                    
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
            self.setURLFooter(message: message, isType: .ErrorConnectionNoEstablished)
        }
    }
    
    
// MARK: textField delegate
    public func textFieldDidEndEditing(_ textField: UITextField) {

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
            nextViewController.serverPath = self.urlNormalized
        }
    }
    
    
// MARK: 'private' methods
    
    
    
    func validateCredentialsAndAddAccount(credentials: CredentialsDto) {
        //get list of files in root to check session validty, if ok store new account
        let urlToGetRootFiles = URL (string: UtilsUrls.getFullRemoteServerPathWithWebDav(byNormalizedUrl: self.urlNormalized) )
        
        DetectListOfFiles().getListOfFiles(url: urlToGetRootFiles!, credentials: credentials,
                                           withCompletion: { (_ errorHttp: NSInteger?,_ error: Error?, _ listOfFileDtos: [FileDto]? ) in
                                            
                                            let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
                                            
                                            if (listOfFileDtos != nil && !((listOfFileDtos?.isEmpty)!)) {
                                                
                                                if self.user == nil {
                                                     self.user = UserDto()
                                                }
                                                
                                                self.user?.url = self.urlNormalized
                                                self.user?.username = credentials.userName
                                                self.user?.ssl = self.urlNormalized.hasPrefix("https")
                                                self.user?.urlRedirected = app.urlServerRedirected
                                                self.user?.predefinedUrl = k_default_url_server
                                                
                                                if (app.activeUser == nil) {
                                                    //only set as active account the first account added
                                                    self.user?.activeaccount = true
                                                    app.activeUser = self.user
                                                }

                                                
                                                if self.loginMode == .update {
                                                    ManageAccounts().updateAccountOfUser(self.user!, withCredentials: credentials)
                                                } else {
                                                    ManageAccounts().storeAccountOfUser(self.user!, withCredentials: credentials)
                                                }
                                                
                                                ManageFiles().storeListOfFiles(listOfFileDtos!, forFileId: 0, andUser: self.user!)
                                                
                                                if self.loginMode == .create {
                                                    app.generateAppInterface(fromLoginScreen: true)
                                                } else {
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
