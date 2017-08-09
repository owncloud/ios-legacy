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

public enum TextfieldType: String {
    case url = "url"
    case username = "username"
    case password = "password"
}

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
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var imageViewLogo: UIImageView!
    
    @IBOutlet var imageViewTopInfo: UIImageView!
    @IBOutlet var labelTopInfo: UILabel!
    
    @IBOutlet var imageViewLeftURL: UIImageView!
    @IBOutlet var textFieldURL: UITextField!
    @IBOutlet var buttonReconnection: UIButton!
    
    @IBOutlet weak var buttonReconnectionURL: UIButton!
    @IBOutlet var imageViewURLFooter: UIImageView!
    @IBOutlet var labelURLFooter: UILabel!
    @IBOutlet var activityIndicatorURLFooter: UIActivityIndicatorView!
    
    //For Basic and edit account
    @IBOutlet var imageViewUsername: UIImageView!
    @IBOutlet var textFieldUsername: UITextField!
    
    @IBOutlet var imageViewLeftPassword: UIImageView!
    @IBOutlet var textFieldPassword: UITextField!
    @IBOutlet var revealPasswordButton: UIButton!
    
    @IBOutlet var imageViewPasswordFooter: UIImageView!
    @IBOutlet var labelPasswordFooter: UILabel!
    
    @IBOutlet var buttonConnect: UIButton!
    @IBOutlet var buttonHelpLink: UIButton!
    
    
    //StackViews
    @IBOutlet weak var topInfoStackView: UIStackView!
    @IBOutlet weak var urlStackView: UIStackView!
    @IBOutlet weak var urlInfoStackView: UIStackView!
    @IBOutlet weak var usernameStackView: UIStackView!
    @IBOutlet weak var passwordStackView: UIStackView!
    @IBOutlet weak var basicAuthInfoStackView: UIStackView!
    @IBOutlet weak var connectButtonStackView: UIStackView!
    @IBOutlet weak var helpButtonStackView: UIStackView!
    
    
    //var urlNormalized: String!
    var validatedServerURL: String!
    var allAvailableAuthMethods = [AuthenticationMethod]()
    var authMethodToLogin: AuthenticationMethod!
    var authCodeReceived = ""
    var manageNetworkErrors: ManageNetworkErrors!
    var loginMode: LoginMode!
    public var user: UserDto?
    var activeField: UITextField!
    
    let serverURLNormalizer: ServerURLNormalizer = ServerURLNormalizer()
    let getPublicInfoFromServerJob: GetPublicInfoFromServerJob = GetPublicInfoFromServerJob()
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listenNotificationsAboutKeyboard()
        self.manageNetworkErrors = ManageNetworkErrors()
        self.manageNetworkErrors.delegate = self
        textFieldURL.delegate = self
        textFieldUsername.delegate = self
        textFieldPassword.delegate = self
        
        textFieldURL.textColor = UIColor.ofURLUserPassword()
        textFieldUsername.textColor = UIColor.ofURLUserPassword()
        textFieldPassword.textColor = UIColor.ofURLUserPassword()
        
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
        
        self.removeNotificationsAboutKeyboard()
        if self.loginMode == .update || self.loginMode == .migrate {
            UtilsCookies.restoreTheCookiesOfActiveUser()
//TODO: check if need to nil checkaccesstoserver sharedManager
        }
    }

    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if Customization.kIsTextLoginStatusBarWhite() {
            return .lightContent
        }
        return .default
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
        self.imageViewURLFooter.isHidden = isVisible
        if isVisible {
            self.activityIndicatorURLFooter.startAnimating()
        } else {
            self.activityIndicatorURLFooter.stopAnimating()
        }
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
            self.setReconnectionButtons(hiddenStatus: false)
            break
            
        case .ErrorConnectionDeclined:
            self.imageViewURLFooter.image = UIImage(named: "CredentialsError.png")!
            footerMessage = "connection_declined"
            self.setReconnectionButtons(hiddenStatus: false)
            break
         
        case .ErrorNotPossibleConnectToServer:
            self.imageViewURLFooter.image = UIImage(named: "CredentialsError.png")!
            footerMessage = "not_possible_connect_to_server"
            self.setReconnectionButtons(hiddenStatus: false)
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
    
    func setConnectButton(status: Bool) {
        self.buttonConnect.isEnabled = status
        self.setConnectButtonStyle(isEnabled: status)
    }
    
    private func setConnectButtonStyle(isEnabled: Bool) {
        self.buttonConnect.layer.cornerRadius = self.buttonConnect.layer.bounds.height / 2
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
        self.hideKeyboardWhenTappedAround()
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
            self.setURLStackView(hiddenStatus: true)
            
        }
        
        let shouldBehiddenUserPassFields = (self.loginMode != .create) ? false : true ;
        self.setBasicAuthLoginStackViews(hiddenStatus: shouldBehiddenUserPassFields)
        self.scrollView.backgroundColor = UIColor.ofLoginBackground()
        self.imageViewLogo.backgroundColor = UIColor.ofLoginTopBackground()

        self.setConnectButton(status: false)
        
        self.buttonHelpLink.isHidden = Customization.kIsShownHelpLinkOnLogin() ?  false : true

    }
    
    func setCancelBarButtonSystemItem() {
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem:UIBarButtonSystemItem.cancel,
                                           target:self,
                                           action:#selector(closeLoginView))
        
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    func setBasicAuthLoginStackViews(hiddenStatus: Bool) {
        
        self.textFieldUsername.text = ""
        self.textFieldPassword.text = ""
        self.revealPasswordButton.setBackgroundImage(UIImage(named: "RevealPasswordIcon.png"), for: .normal)
        self.labelPasswordFooter.text = ""
        self.imageViewPasswordFooter.image = nil
        
        UIView.animate(withDuration: 0.5, animations: {
            self.usernameStackView.isHidden = hiddenStatus
            self.passwordStackView.isHidden = hiddenStatus
            self.basicAuthInfoStackView.isHidden = hiddenStatus
        }, completion: {(_) in
            self.usernameStackView.isHidden = hiddenStatus
            self.passwordStackView.isHidden = hiddenStatus
            self.basicAuthInfoStackView.isHidden = hiddenStatus
        })
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

    func setURLStackView(hiddenStatus: Bool) {
        self.urlStackView.isHidden = hiddenStatus
    }
    
    func setReconnectionButtonOnURLInfoStackView(hiddenStatus: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            self.buttonReconnection.isHidden = hiddenStatus
        }, completion: {(_) in })
    }
    
    func setReconnectionButtonOnURLStackView(hiddenStatus: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            self.buttonReconnectionURL.isHidden = hiddenStatus
        }, completion: { (_) in
            self.buttonReconnectionURL.isHidden = hiddenStatus
        })
    }
    
    func setPasswordEyeOnPasswordStackView(hiddenStatus: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            self.revealPasswordButton.isHidden = hiddenStatus
        }, completion: {(_) in })
    }
    
    func setReconnectionButtons(hiddenStatus: Bool) {
        if Customization.kHideUrlServer() {
            self.setReconnectionButtonOnURLInfoStackView(hiddenStatus: hiddenStatus)
        } else {
            self.setReconnectionButtonOnURLStackView(hiddenStatus: hiddenStatus)
        }
    }
    
    func setNetworkActivityIndicator(status: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = status
    }
    
    func resetPasswordFooterMessage() {
        self.imageViewPasswordFooter.image = nil
        self.labelPasswordFooter.text = ""
    }
    
    // MARK: dismiss
    func closeLoginView() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
// MARK: checkUrl
    func checkCurrentUrl() {
        self.setConnectButton(status: false)
        print("LOG ---> \(self.buttonReconnectionURL.isHidden)")
        self.setURLFooter(message: "", isType: .TestingConnection)
        
        if let inputURL = textFieldURL.text {
            self.serverURLNormalizer.normalize(serverURL: inputURL)
            self.setNetworkActivityIndicator(status: true)
            // get public infor from server
            getPublicInfoFromServerJob.start(serverURL: self.serverURLNormalizer.normalizedURL, withCompletion: { (validatedURL: String?, _ serverAuthenticationMethods: Array<Any>?, _ error: Error?, _ httpStatusCode: NSInteger) in
            
                self.setNetworkActivityIndicator(status: false)
                if error != nil {
                    self.setConnectButton(status: false)
                    self.manageNetworkErrors.returnErrorMessage(withHttpStatusCode: httpStatusCode, andError: error)
                    print ("error detecting authentication methods")
                    
                } else if validatedURL != nil {
                    
                    self.setURLFooter(message: "", isType: .None)
                    
                    self.validatedServerURL = validatedURL;
                    self.allAvailableAuthMethods = serverAuthenticationMethods as! [AuthenticationMethod]
                    
                    self.authMethodToLogin = DetectAuthenticationMethod().getAuthMethodToLoginFrom(availableAuthMethods: self.allAvailableAuthMethods)
                    
                    if (self.authMethodToLogin != .NONE) {
                        self.setReconnectionButtons(hiddenStatus: true)
                        
                        if (self.authMethodToLogin == .BASIC_HTTP_AUTH) {
                            self.setBasicAuthLoginStackViews(hiddenStatus: false)
                            self.textFieldURL.resignFirstResponder()
                            self.textFieldUsername.becomeFirstResponder()
                        } else {
                            self.setBasicAuthLoginStackViews(hiddenStatus: true)
                            self.setConnectButton(status: true)
                            self.startAuthenticationWith(authMethod: self.authMethodToLogin)
                            
                        }
                        
                        self.setURLFotterSuccess(oNormalized: self.serverURLNormalizer)
                        
                    } else {
                        self.setBasicAuthLoginStackViews(hiddenStatus: true)
                        self.setConnectButton(status: false)
                        self.manageNetworkErrors.returnErrorMessage(withHttpStatusCode: httpStatusCode, andError: nil)
                    }
                    self.updateUIWithNormalizedData(self.serverURLNormalizer)

                    
                } else {
                    self.setConnectButton(status: false)
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
            self.resetPasswordFooterMessage()
            let userCredDto: CredentialsDto = CredentialsDto()
            userCredDto.userName = self.textFieldUsername.text
            userCredDto.accessToken = self.textFieldPassword.text
            userCredDto.authenticationMethod = authMethod
            
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
        userCredDto.authenticationMethod = self.authMethodToLogin
        
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
            if !self.basicAuthInfoStackView.isHidden {
                self.setBasicAuthLoginStackViews(hiddenStatus: true)
            }
        }
    }
    
    
// MARK: textField delegate
    public func textFieldDidEndEditing(_ textField: UITextField) {
        
        self.activeField = nil
        switch textField.restorationIdentifier! {
        case TextfieldType.password.rawValue:
            if textField.text == "" {
                self.setPasswordEyeOnPasswordStackView(hiddenStatus: true)
            }
            break
        case TextfieldType.url.rawValue:
            if textField.text != "" {
                self.checkCurrentUrl()
            }else{
                self.setBasicAuthLoginStackViews(hiddenStatus: true)
            }
            break
        case TextfieldType.username.rawValue:
            break
        default:
            break
        }
        
        if self.authMethodToLogin != nil && self.authMethodToLogin == .BASIC_HTTP_AUTH {
            if (self.textFieldUsername.text!.characters.count > 0) && (self.textFieldPassword.text!.characters.count > 0) {
                self.setConnectButton(status: true)
            } else {
                self.setConnectButton(status: false)
            }
        }
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeField = textField
        if textField.restorationIdentifier! == TextfieldType.password.rawValue {
            self.setPasswordEyeOnPasswordStackView(hiddenStatus: false)
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.activeField = nil
        switch textField.restorationIdentifier! {
        case TextfieldType.url.rawValue:
            textField.resignFirstResponder()
            return true
            break
        case TextfieldType.username.rawValue:
            textField.resignFirstResponder()
            self.textFieldPassword.becomeFirstResponder()
            break
        case TextfieldType.password.rawValue:
            if (self.textFieldUsername.text?.characters.count)! > 0 {
                startAuthenticationWith(authMethod: .BASIC_HTTP_AUTH)
            }
            textField.resignFirstResponder()
            break
        default:
            break
        }
        return false
    }

    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

// MARK: Keyboard
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UniversalLoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    //MARK: Keyboard Notifications
    
    func listenNotificationsAboutKeyboard () {
        NotificationCenter.default.addObserver(self, selector: #selector(UniversalLoginViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UniversalLoginViewController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeNotificationsAboutKeyboard () {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardDidShow(_ notification: Notification) {
        if let activeField = self.activeField, let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            var aRect = self.view.frame
            aRect.size.height -= keyboardSize.size.height
            if (!aRect.contains(activeField.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    func keyboardWillBeHidden(_ notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
    
// MARK: IBActions
    @IBAction func reconnectionButtonTapped(_ sender: Any) {
        self.dismissKeyboard()
        self.checkCurrentUrl()
    }
    
    @IBAction func connectButtonTapped(_ sender: Any) {
        self.setNetworkActivityIndicator(status: true)
        self.startAuthenticationWith(authMethod: self.authMethodToLogin)
    }
    
    @IBAction func helpLinkButtonTapped(_ sender: Any) {
        UIApplication.shared.openURL(NSURL(string:  k_url_link_on_login)! as URL)
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
    
    @IBAction func revealPasswordButtonTapped(_ sender: UIButton) {
        
        if self.textFieldPassword.isSecureTextEntry {
            self.textFieldPassword.isSecureTextEntry = false
            self.revealPasswordButton.setBackgroundImage(UIImage(named: "NonRevealPasswordIcon.png"), for: .normal)
        } else {
            self.textFieldPassword.isSecureTextEntry = true
            self.revealPasswordButton.setBackgroundImage(UIImage(named: "RevealPasswordIcon.png"), for: .normal)
        }
    }
    
    @IBAction func editingChanged(_ sender: UITextField) {
        
        if self.textFieldUsername.text != ""{
            self.setConnectButton(status: (sender.text?.characters.count)! > 0)
        }
    }
// MARK: segue
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == K.segueId.segueToWebLoginView) {
            
            let destinationNavigationController = segue.destination as! UINavigationController
            let targetController = destinationNavigationController.topViewController as! WebLoginViewController
            targetController.serverPath = self.validatedServerURL
        }
    }
    
    
// MARK: 'private' methods
    func validateCredentialsAndAddAccount(credentials: CredentialsDto) {
        //get list of files in root to check session validty, if ok store new account
        let urlToGetRootFiles = URL (string: UtilsUrls.getFullRemoteServerPathWithWebDav(byNormalizedUrl: self.serverURLNormalizer.normalizedURL) )
        
        DetectListOfFiles().getListOfFiles(url: urlToGetRootFiles!, credentials: credentials,
                                           withCompletion: { (_ errorHttp: NSInteger?,_ error: Error?, _ listOfFileDtos: [FileDto]? ) in
                                            self.setNetworkActivityIndicator(status: false)
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
                                                
                                                self.setNetworkActivityIndicator(status: false)
                                                
                                                //TODO: check with https url without prefix, error unsupported URL
                                                if errorHttp == 0 {
                                                    //self.setPasswordFooterError(message: NSLocalizedString("", comment: "") )
                                                    self.setPasswordFooterError(message: "Error with the credentials" )
                                                } else {
                                                    self.manageNetworkErrors.manageErrorHttp((errorHttp)!, andErrorConnection: error, andUser: self.user)
                                                }
                                                
                                                    
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
    
    private func showURLError() {}
}
