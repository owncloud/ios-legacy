//
//  UniversalLoginViewController.swift
//  Owncloud iOs Client
//
//  Created by Noelia Alvarez on 21/06/2017.
//
//

/*
 Copyright (C) 2018, ownCloud GmbH.
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

public enum TextfieldType: String {
    case url = "url"
    case username = "username"
    case password = "password"
}

@objc public enum StateCheckedURL: Int {
    case None
    case TestingConnection
    case ConnectionEstablishedSecure
    case ConnectionEstablishedNonSecure
    case Error
}


@objc public class UniversalLoginViewController: UIViewController, UITextFieldDelegate, SSODelegate {
 
// MARK: IBOutlets
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var imageViewLogo: UIImageView!
    
    @IBOutlet weak var viewTopLogo: UIView!
    @IBOutlet var imageViewTopInfo: UIImageView!
    @IBOutlet var labelTopInfo: UILabel!
    
    @IBOutlet var imageViewLeftURL: UIImageView!
    @IBOutlet var textFieldURL: UITextField!
    @IBOutlet var buttonReconnection: UIButton!
    
    @IBOutlet var buttonReconnectionURL: UIButton!
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
    
    
    var validatedServerURL: String!
    var allAvailableAuthMethods = [AuthenticationMethod]()
    var authMethodToLogin: AuthenticationMethod! = .UNKNOWN
    var authCodeReceived = ""
    var manageNetworkErrors: ManageNetworkErrors!
    private var loginMode: LoginMode!
    private var user: UserDto?
    var userNewCredentials:OCCredentialsDto = OCCredentialsDto()
    var activeField: UITextField!
    var nextErrorShouldBeShownAfterPasswordField = false;
    
    let serverURLNormalizer: ServerURLNormalizer = ServerURLNormalizer()
    let getPublicInfoFromServerJob: GetPublicInfoFromServerJob = GetPublicInfoFromServerJob()
    var statusBarTintSubview: UIView!
    var topTwentiConstraint: NSLayoutConstraint!
    var forceAccountMigration: Bool = false
    
    private let oAuth2Manager: OCOAuth2Manager = OCOAuth2Manager()

    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.topTwentiConstraint = self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0)
        self.topTwentiConstraint.isActive = true
        
        self.forceAccountMigration = false
        self.userNewCredentials = OCCredentialsDto()
        
        viewDidLayoutSubviews()
        
        self.listenNotificationsAboutKeyboard()
        self.manageNetworkErrors = ManageNetworkErrors()
            // using ManageNetworkErrors() without delegate; UniversalLoginViewController will call
            // ManageNetworkErrors.returnErrorMessageWithHttpStatusCode when appropriate, and will show
            // the message without a callback to a delegate method
        
        textFieldURL.delegate = self
        textFieldUsername.delegate = self
        textFieldPassword.delegate = self
        
        
        self.showInitMessageCredentialsErrorIfNeeded()

        self.setBrandingStyle()
        
        self.initUI()
        
        self.oAuth2Manager.trustedCertificatesStore = SSLCertificateManager()
        
        if self.loginMode == .update {
            self.setReconnectionButtons(hiddenStatus: true)
            self.setURLFooter(isType: .None)
            self.checkCurrentUrl()
        }
                
        UtilsCookies.saveCurrentOfActiveUserAndClean()    // network requests from log-in view need to be independent of existing sessions
        
        print("Init login with loginMode: \(loginMode.rawValue) (0=Create,1=Update,2=Expire,3=Migrate)")
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.removeNotificationsAboutKeyboard()
        
    }
    
    public override func viewDidLayoutSubviews() {
        if self.navigationController == nil {
            if  !UIApplication.shared.isStatusBarHidden {
                topTwentiConstraint.constant = 0
            } else {
                topTwentiConstraint.constant = -64
            }
        } else {
            topTwentiConstraint.constant = -10
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
            
            self.setTopInfo(message: "session_expired")
            
        }
    }
    
    //MARK: Set up image and label with error/info
    
    func setTopInfo(message: String) {
        
        self.labelTopInfo.text = NSLocalizedString(message, comment: "");
        
        self.imageViewTopInfo.image = UIImage(named: "CredentialsError.png")!
    }
    
    func setActivityIndicator(isVisible: Bool) {
        self.imageViewURLFooter.isHidden = isVisible
        if isVisible {
            self.activityIndicatorURLFooter.startAnimating()
        } else {
            self.activityIndicatorURLFooter.stopAnimating()
        }
    }
    
    private func showURLError(_ message: String!) {
        DispatchQueue.main.async {
            self.setURLFooter(isType: .Error, errorMessage: message)
        }
    }
    
    private func showURLSuccess(_ serverIsSecure: Bool) {
        DispatchQueue.main.async {
            if serverIsSecure {
                self.setURLFooter(isType: .ConnectionEstablishedSecure)
            } else {
                self.setURLFooter(isType: .ConnectionEstablishedNonSecure)
            }
        }
    }
    
    private func showCredentialsError(_ message: String!) {
        DispatchQueue.main.async {
            if (self.basicAuthInfoStackView.isHidden) {
                self.setURLFooter(isType: .Error, errorMessage: message)
                self.setConnectButton(status: false)

            } else {
                self.setPasswordFooterError(errorMessage: message)
                self.setConnectButton(status: true)
            }
        }
    }
    
    private func setURLFooter(isType type: StateCheckedURL, errorMessage: String = "") {
        
        var footerMessage = ""
        self.setActivityIndicator(isVisible: false)
        
        switch type {

        case .Error:
            self.imageViewURLFooter.image = UIImage(named: "CredentialsError.png")!
            self.labelURLFooter.text = errorMessage
            self.setReconnectionButtons(hiddenStatus: false)
            self.setConnectButton(status: false)
            return      // beware: return here, break in the rest
            
        case .TestingConnection:
            footerMessage = "testing_connection"
            self.setActivityIndicator(isVisible: true)
            self.setConnectButton(status: false)

            break
            
        case .ConnectionEstablishedNonSecure:
            self.imageViewURLFooter.image = UIImage(named: "NonSecureConnectionIcon.png")!
            footerMessage = "connection_established"
            self.setConnectButton(status: true)

            break
            
        case .ConnectionEstablishedSecure:
            self.imageViewURLFooter.image = UIImage(named: "SecureConnectionIcon.png")!
            footerMessage = "secure_connection_established"
            self.setConnectButton(status: true)

            break
            
        case .None:
            self.imageViewURLFooter.image = nil
            footerMessage = ""
            break
        }
        
        self.labelURLFooter.text = NSLocalizedString(footerMessage, comment: "")
    }
    
    
    func setPasswordFooterError(errorMessage: String) {
        
        self.labelPasswordFooter.text = errorMessage;
        
        self.imageViewPasswordFooter.image = UIImage(named: "CredentialsError.png")!
    }
    

    //MARK: Set style
    
    func setBrandingStyle() {
        
        //labels messages
        self.labelTopInfo.backgroundColor = UIColor.clear
        self.labelTopInfo.textColor = UIColor.ofLoginErrorText()
        
        self.labelURLFooter.backgroundColor = UIColor.clear
        self.labelURLFooter.textColor = UIColor.ofLoginErrorText()
        
        self.labelPasswordFooter.backgroundColor = UIColor.clear
        self.labelPasswordFooter.textColor = UIColor.ofLoginErrorText()
        
        //text in text fields
        textFieldURL.textColor = UIColor.ofURLUserPassword()
        textFieldUsername.textColor = UIColor.ofURLUserPassword()
        textFieldPassword.textColor = UIColor.ofURLUserPassword()
        
        //background
        self.scrollView.backgroundColor = UIColor.ofLoginBackground()
        self.imageViewLogo.backgroundColor = UIColor.ofLoginTopBackground()
        self.viewTopLogo.backgroundColor = UIColor.ofLoginTopBackground()
        
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
        
        let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
        
        self.hideKeyboardWhenTappedAround()
        
        //set cancel button in navigation bar
        if (  self.loginMode == .update
            || (self.loginMode == .create && (app.activeUser != nil))
            || (Customization.kMultiaccountAvailable() && (self.loginMode == .migrate || self.loginMode == .expire))
            ) {
            
            self.setCancelBarButtonSystemItem()
        }
        
        //set URL status
        if Customization.kHideUrlServer() {
            self.setURLStackView(hiddenStatus: true)
        }
        
        //set username and password fields status (enabled/disabled)
        let enabledEditUrlUsernamePassword : Bool = (self.loginMode == .create || self.loginMode == .migrate)
        self.textFieldURL.isEnabled = enabledEditUrlUsernamePassword
        self.textFieldURL.isUserInteractionEnabled = enabledEditUrlUsernamePassword
        self.textFieldUsername.isEnabled = true
        self.textFieldUsername.isUserInteractionEnabled = true
        
        self.textFieldUsername.autocorrectionType = .no
        self.textFieldURL.autocorrectionType = .no
        
        //set username and password fields visibility
        self.updateInputFieldsFromCurrentAuthMethodToLogin()
        
        //set login button status
        self.setConnectButton(status: false)
        
        //init help link button status
        self.buttonHelpLink.isHidden = Customization.kIsShownHelpLinkOnLogin() ?  false : true
        let buttonHelpTitleWithoutAppName = NSLocalizedString("help_link_login", comment: "")
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
        let buttonHelpTitle = buttonHelpTitleWithoutAppName.replacingOccurrences(of: "$appname", with: appName)
        self.buttonHelpLink.setTitle(buttonHelpTitle, for: .normal)
        
        //Placeholders for the login textfields
        self.textFieldURL.placeholder = NSLocalizedString("url_sample", comment: "")
        self.textFieldUsername.placeholder = NSLocalizedString("username", comment: "")
        self.textFieldPassword.placeholder = NSLocalizedString("password", comment: "")
        
        
        //init textField values
        
        self.textFieldURL.text = k_default_url_server
        
        //test
//        self.loginMode = .expire
//        self.user?.username = ""
        ////
        
        if self.loginMode != .create {
            
            let noCredentialsAvailable = (self.loginMode == .expire && (self.user?.username == nil || self.user?.username == ""))
            
            if (noCredentialsAvailable) {
                
                //TODO:show OCLoadingSpinner
                print("Migrating keychain from login view")
                OCKeychain.updateAllKeychainItemsFromDBVersion21or22To23ToStoreCredentialsDtoAsValueAndAuthenticationType()
                sleep(5)
                self.user = ManageUsersDB.getActiveUser()
                
                if (self.user?.credDto != nil && self.user?.credDto.userName != nil
                    && self.user?.credDto.userName != "") {
                    print("New credentials, update active user")
                    let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
                    app.activeUser = self.user;
                } else {
                    print("Can not get credentials from keychain in login view")
                    OCKeychain.removeCredentials(ofUser: self.user)
                    //TODO:expire all accounts and force migration
                    self.forceAccountMigration = true
                }
            }
            
            self.textFieldUsername.text = self.user?.username
            self.textFieldPassword.text = ""
            
            if self.loginMode != .migrate {
                self.textFieldURL.text = UtilsUrls.getFullRemoteServerPath(self.user)
            }
        }
        
        //auto launch check of URL
        if self.textFieldURL.text != nil && self.textFieldURL.text != "" {
            self.checkCurrentUrl()
        }

    }
    
    func setCancelBarButtonSystemItem() {
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem:UIBarButtonSystemItem.cancel,
                                           target:self,
                                           action:#selector(closeLoginView))
        
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    func updateInputFieldsFromCurrentAuthMethodToLogin() {
        let shouldBehiddenUserPassFields = (self.authMethodToLogin == nil || self.authMethodToLogin != AuthenticationMethod.BASIC_HTTP_AUTH);
        self.setBasicAuthLoginStackViews(hiddenStatus: shouldBehiddenUserPassFields)
    }
    
    func setBasicAuthLoginStackViews(hiddenStatus: Bool) {
        
        self.revealPasswordButton.setBackgroundImage(UIImage(named: "RevealPasswordIcon.png"), for: .normal)
        
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
        self.textFieldURL.text = self.validatedServerURL
        if (oNormalized.user != nil) && !(oNormalized.user?.isEmpty)! {
            self.textFieldUsername.text = oNormalized.user
        }
        if (oNormalized.password != nil) && !(oNormalized.password?.isEmpty)! {
            self.textFieldPassword.text = oNormalized.password
            self.textFieldPassword.becomeFirstResponder()
            self.setConnectButton(status: true)
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
    @objc func closeLoginView() {
        UtilsCookies.deleteCurrentSystemCookieStorageAndRestoreTheCookiesOfActiveUser()
        self.setNetworkActivityIndicator(status: false)
        self.dismiss(animated: true, completion: nil)
    }
    
    
// MARK: checkUrl
    func checkCurrentUrl() {
        self.setConnectButton(status: false)
        self.setURLFooter(isType: .TestingConnection)
        
        if let inputURL = textFieldURL.text {
            self.serverURLNormalizer.normalize(serverURL: inputURL)
            self.setNetworkActivityIndicator(status: true)
            // get public infor from server
            getPublicInfoFromServerJob.start(serverURL: self.serverURLNormalizer.normalizedURL, withCompletion: { (validatedURL: String?, _ serverAuthenticationMethods: Array<Any>?, _ error: Error?, _ httpStatusCode: NSInteger) in
            
                self.setNetworkActivityIndicator(status: false)
                if (error != nil || validatedURL == nil) {
                    
                    self.setConnectButton(status: false)
                    self.showURLError(
                        self.manageNetworkErrors.returnErrorMessage(
                            withHttpStatusCode: httpStatusCode, andError: error
                        )
                    )
                    print ("error getting information from URL")
                    
                } else if validatedURL != nil {
                    
                    self.setURLFooter(isType: .None)
                    
                    self.validatedServerURL = validatedURL;
                    self.allAvailableAuthMethods = serverAuthenticationMethods as! [AuthenticationMethod]
                    
                    self.authMethodToLogin = DetectAuthenticationMethod.getAuthMethodToLoginFrom(availableAuthMethods: self.allAvailableAuthMethods)
                    
                    if (self.authMethodToLogin != .NONE) {
                        self.setReconnectionButtons(hiddenStatus: true)

                        if (self.authMethodToLogin == .BASIC_HTTP_AUTH) {
                            self.textFieldURL.resignFirstResponder()
                            self.textFieldUsername.becomeFirstResponder()
                            
                            if self.loginMode == .update {
                                self.textFieldUsername.text = self.user?.username
                                self.textFieldPassword.text = ""
                            }
                        } else {
                            self.setConnectButton(status: false)
                            self.startAuthenticationWith(authMethod: self.authMethodToLogin)
                        }
                        
                        self.showURLSuccess(self.validatedServerURL.hasPrefix("https://"))
                        
                    } else {
                        self.setConnectButton(status: false)
                        self.showURLError(NSLocalizedString("authentification_not_valid", comment: ""))
                    }
                    self.updateUIWithNormalizedData(self.serverURLNormalizer)
                }
                
                self.updateInputFieldsFromCurrentAuthMethodToLogin()
            })
        }
    }
    
    
// MARK: start log in auth
    func startAuthenticationWith(authMethod: AuthenticationMethod) {
        switch authMethod {

        case .SAML_WEB_SSO:
            navigateToSAMLLoginView();
            self.setConnectButton(status: true) // work of the buttong was already done
            break

        case .BEARER_TOKEN:
            navigateToOAuthLoginView();
            self.setConnectButton(status: true) // work of the buttong was already done
            break

        case .BASIC_HTTP_AUTH:
            self.resetPasswordFooterMessage()
            let userCredDto: OCCredentialsDto = OCCredentialsDto()
            userCredDto.userName = self.textFieldUsername.text
            userCredDto.accessToken = self.textFieldPassword.text
            userCredDto.authenticationMethod = authMethod
            nextErrorShouldBeShownAfterPasswordField = true
            
            self.userNewCredentials = (userCredDto.copy() as? OCCredentialsDto)!
            
            self.detectUserDataAndValidate(serverPath: self.validatedServerURL)
            
            break

        default:
            showURLError(NSLocalizedString("authentification_not_valid", comment: ""))
            
        }

    }
    
    func navigateToSAMLLoginView() {

        //Grant main thread
        DispatchQueue.main.async {
            print("_showSSOLoginScreen_ url: %@", self.validatedServerURL)
            
            //New SSO WebView controller
            let ssoViewController: SSOViewController = SSOViewController(nibName: "SSOViewController", bundle: nil)
            ssoViewController.urlString = self.validatedServerURL
            ssoViewController.delegate = self

            //present it
            ssoViewController.navigate(from: self)
        }
    }
    
    func navigateToOAuthLoginView() {
        performSegue(withIdentifier: K.segueId.segueToWebLoginView, sender: self)
    }
    
// MARK: SSODelegate implementation
    
    /**
     * This delegate method is called from SSOViewController when the user successfully logs-in.
     *
     * @param cookieString -> NSString Cookies in last state of the SSO WebView , including SSO cookie & OC session cookie.
     *
     */
    
    public func setCookieForSSO(_ cookieString: String?, serverPath: String?) {
        
        self.setNetworkActivityIndicator(status: false)
        
        let userCredDto :OCCredentialsDto =  OCCredentialsDto()
        userCredDto.accessToken = cookieString;
        userCredDto.authenticationMethod = .SAML_WEB_SSO;
        
        if self.loginMode == .expire {
            let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
            userCredDto.userName = app.activeUser.username
        }
        
        
        if cookieString == nil || cookieString == "" {
            self.showCredentialsError(NSLocalizedString("authentification_not_valid", comment: "") )
            
            return;
        }
        
        self.userNewCredentials = (userCredDto.copy() as? OCCredentialsDto)!
        self.detectUserDataAndValidate(serverPath: serverPath!)
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
            }
            break
        default:
            break
        }
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeField = textField
        if textField.restorationIdentifier! == TextfieldType.password.rawValue {
            self.setPasswordEyeOnPasswordStackView(hiddenStatus: false)
        }
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if self.authMethodToLogin != nil && self.authMethodToLogin == .BASIC_HTTP_AUTH {
            if (!self.textFieldUsername.text!.isEmpty) && (!self.textFieldPassword.text!.isEmpty) {
                self.setConnectButton(status: true)
            } else {
                self.setConnectButton(status: false)
            }
        }
        
        self.activeField = nil
        switch textField.restorationIdentifier! {
        case TextfieldType.url.rawValue:
            textField.resignFirstResponder()
            return true
        case TextfieldType.username.rawValue:
            self.textFieldPassword.becomeFirstResponder()
            break
        case TextfieldType.password.rawValue:
            if (!self.textFieldUsername.text!.isEmpty) {
                self.setNetworkActivityIndicator(status: true)
                self.setConnectButton(status: false)
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
    
    @objc func dismissKeyboard() {
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
    
    @objc func keyboardDidShow(_ notification: Notification) {
        if let activeField = self.activeField, let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height + 20, right: 0.0)
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            var aRect = self.view.frame
            aRect.size.height -= keyboardSize.size.height
            if (!aRect.contains(activeField.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    @objc func keyboardWillBeHidden(_ notification: Notification) {
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
        self.view.endEditing(true)
        self.setNetworkActivityIndicator(status: true)
        self.setConnectButton(status: false)    // prevent multiple taps
        self.startAuthenticationWith(authMethod: self.authMethodToLogin)
    }
    
    @IBAction func helpLinkButtonTapped(_ sender: Any) {
        UIApplication.shared.openURL(NSURL(string:  k_url_link_on_login)! as URL)
    }
    
    @IBAction func unwindToMainLoginView(segue:UIStoryboardSegue) {
        if let sourceViewController = segue.source as? WebLoginViewController {
            /// back from web view getting OAuth2 authorization code
            
            let webVC: WebLoginViewController = sourceViewController
            if !(webVC.authCode).isEmpty {
                self.setNetworkActivityIndicator(status: false)
                self.authCodeReceived = webVC.authCode
                
                let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
                
                self.oAuth2Manager.authData(by: app.oauth2Configuration,
                                withBaseURL: self.validatedServerURL,
                                   authCode: self.authCodeReceived ,
                                  userAgent: UtilsUrls.getUserAgent(),
                             withCompletion: { (userCredDto: OCCredentialsDto?, error: Error?) in
                                
                                if let userCredentials = userCredDto {
                                    self.userNewCredentials = (userCredentials.copy() as? OCCredentialsDto)!
                                    self.detectUserDataAndValidate(serverPath: self.validatedServerURL)
                                    
                                 } else {
                                    
                                    self.showURLError(
                                        self.manageNetworkErrors.returnErrorMessage(withHttpStatusCode: -1, andError: error)
                                    )
                                 }
                                    
                })
            } else if let error = webVC.error {
                self.showURLError(
                    self.manageNetworkErrors.returnErrorMessage(
                        withHttpStatusCode: -1, andError: error
                    )
                )
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
            self.setConnectButton(status: !(sender.text!).isEmpty)
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
    
    func detectUserDataAndValidate(serverPath: String) {
        if loginMode == .migrate || self.forceAccountMigration{
            //credentials may have changed, remove cookies
            UtilsCookies.deleteAllCookiesOfActiveUser()
        }
        
        DetectUserData .getUserDisplayName(ofServer: serverPath, credentials: self.userNewCredentials) { (serverUserID, displayName, error) in
            
            if (serverUserID != nil && displayName != nil) {
                
                if self.userNewCredentials.authenticationMethod == .SAML_WEB_SSO {
                    if self.userNewCredentials.userName == nil {
                        self.userNewCredentials.userName = serverUserID
                        self.userNewCredentials.userDisplayName = displayName
                    } 
                } else {

                    if (serverUserID == self.userNewCredentials.userName) {
                        
                        if (displayName != self.userNewCredentials.userDisplayName){
                            self.userNewCredentials.userDisplayName = displayName
                        }
                    }
                }
            }
            self.validateCredentialsAndStoreAccount()
        }
    }
    
    func validateCredentialsAndStoreAccount() {
        //get list of files in root to check session validty, if ok store new account
        let urlToGetRootFiles = NSURL (string: UtilsUrls.getFullRemoteServerPathWithWebDav(byNormalizedUrl: validatedServerURL) )
        
        DetectListOfFiles().getListOfFiles(url: urlToGetRootFiles!, credentials: self.userNewCredentials,
           withCompletion: { (_ errorHttp: NSInteger?,_ error: NSError?, _ listOfFileDtos: [FileDto]? ) in
            
            self.setNetworkActivityIndicator(status: false)
            let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
            
            if (listOfFileDtos != nil && !((listOfFileDtos?.isEmpty)!)) {
                /// credentials allowed access to root folder: well done
                if self.forceAccountMigration {
                    OCKeychain.storeCredentials(self.userNewCredentials)
                }
                
                let tryingToUpdateDifferentUser = (self.user != nil &&
                    (self.loginMode == .update || self.loginMode == .expire)
                    && self.user?.username != nil
                    && self.user?.username != ""
                    && self.userNewCredentials.userName != self.user?.username)
                
                if (tryingToUpdateDifferentUser) {
                    //Delete current wrong cookies
                    UtilsFramework.deleteAllCookies()
                    self.showCredentialsError(NSLocalizedString("credentials_different_user", comment: "") )
                    
                } else {

                    if self.loginMode == .create || self.loginMode == .migrate || self.forceAccountMigration {
                        let newUser = UserDto()
                        if self.loginMode != .create {
                            newUser.userId = self.user!.userId
                            if self.loginMode == .migrate {
                                newUser.predefinedUrl = k_default_url_server
                            }
                        }
                        newUser.url = self.validatedServerURL
                        newUser.username = self.userNewCredentials.userName
                        newUser.ssl = self.validatedServerURL.hasPrefix("https")
                        newUser.urlRedirected = app.urlServerRedirected
                        
                        self.user = newUser.copy() as? UserDto
                    }

                    self.userNewCredentials.baseURL = UtilsUrls.getFullRemoteServerPath(self.user)

                    if self.loginMode == .create {
                        
                        if (ManageUsersDB.isExistUser(self.user)) {
                            //Delete current wrong cookies and relaunch check url to get correct ones
                            UtilsFramework.deleteAllCookies()
                            self.showURLError(NSLocalizedString("account_not_new", comment: ""))
                            
                        } else {

                            self.user = ManageAccounts().storeAccountOfUser(self.user!, withCredentials: self.userNewCredentials)
                            
                            if self.user != nil {
                                ManageFiles().storeListOfFiles(listOfFileDtos!, forFileId: 0, andUser: self.user!)
                            
                                app.switchActiveUser(to: self.user, isNewAccount: true)
                                app.generateAppInterface(fromLoginScreen: true)
                                
                            } else {
                                self.showURLError(NSLocalizedString("error_could_not_add_account", comment: ""))
                            }
                        }
                        
                     } else {
                        
                        if ( (self.user?.username == nil || self.user?.username == "")
                            && self.userNewCredentials.userName != nil ){
                            self.user?.username = self.userNewCredentials.userName
                            self.user?.credDto = (self.userNewCredentials.copy() as? OCCredentialsDto)!
                        }
                        
                        if (app.activeUser != nil && app.activeUser.userId == self.user?.userId) {
                            app.activeUser = self.user;
                        }
                        
                        ManageAccounts().updateAccountOfUser(self.user!, withCredentials: self.userNewCredentials)
                        
                        if self.loginMode == .migrate || self.forceAccountMigration {
                            // migration mode needs to start a fresh list of files, so that it is updated with the new URL
                            app.generateAppInterface(fromLoginScreen: true)
                              
                        } else {
                            self.closeLoginView()
                        }
                    }
                }

            } else {
                if errorHttp == Int(kOCErrorServerUnauthorized) {
                    self.showCredentialsError(
                        self.manageNetworkErrors.returnErrorMessage(
                            withHttpStatusCode: (errorHttp)!, andError: nil
                        )
                    )
                    
                } else {
                    self.showURLError(
                        self.manageNetworkErrors.returnErrorMessage(
                            withHttpStatusCode: (errorHttp)!, andError: error
                        )
                    )
                }
            }
            
        })
        
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func setLoginMode(loginMode: LoginMode, user: UserDto) {
        self.loginMode = loginMode
        self.user = user
    }
    
}
