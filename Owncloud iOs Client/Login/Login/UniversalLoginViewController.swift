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
    var nextErrorShouldBeShownAfterPasswordField = false;
    
    let serverURLNormalizer: ServerURLNormalizer = ServerURLNormalizer()
    let getPublicInfoFromServerJob: GetPublicInfoFromServerJob = GetPublicInfoFromServerJob()
    var statusBarTintSubview: UIView!
    var topTwentiConstraint: NSLayoutConstraint!

    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        topTwentiConstraint = self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0)

        topTwentiConstraint.isActive = true
        
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

        let enabledEditUrlUsernamePassword : Bool = (self.loginMode == .create || self.loginMode == .migrate)
        self.textFieldURL.isEnabled = enabledEditUrlUsernamePassword
        self.textFieldURL.isUserInteractionEnabled = enabledEditUrlUsernamePassword
        self.textFieldUsername.isEnabled = enabledEditUrlUsernamePassword
        self.textFieldUsername.isUserInteractionEnabled = enabledEditUrlUsernamePassword


        self.setBrandingStyle()
            //status bar k_is_text_login_status_bar_white
        
        self.initUI()
        
        if self.loginMode == .update {
            self.buttonReconnectionURL.isHidden = true
            self.labelURLFooter.text = nil
            self.imageViewURLFooter.image = nil
            self.checkCurrentUrl()
        }
        
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
            } else {
                self.setPasswordFooterError(errorMessage: message)
            }
            self.setConnectButton(status: true)
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
            return      // beware: return here, break in the rest
            
        case .TestingConnection:
            footerMessage = "testing_connection"
            self.setActivityIndicator(isVisible: true)
            break
            
        case .ConnectionEstablishedNonSecure:
            self.imageViewURLFooter.image = UIImage(named: "NonSecureConnectionIcon.png")!
            footerMessage = "https_non_secure_connection_established"
            break
            
        case .ConnectionEstablishedSecure:
            self.imageViewURLFooter.image = UIImage(named: "SecureConnectionIcon.png")!
            footerMessage = "secure_connection_established"
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
        
        //set user&pass status
        let shouldBehiddenUserPassFields = (self.loginMode != .create) ? false : true ;
        self.setBasicAuthLoginStackViews(hiddenStatus: shouldBehiddenUserPassFields)
        
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
        
        if self.loginMode != .create {
            
            if self.loginMode != .migrate {
                self.textFieldURL.text = UtilsUrls.getFullRemoteServerPath(self.user)
            }
            
            self.textFieldUsername.text = self.user?.username
            self.textFieldPassword.text = ""
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
    func closeLoginView() {
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
                if error != nil {
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
                    
                    self.authMethodToLogin = DetectAuthenticationMethod().getAuthMethodToLoginFrom(availableAuthMethods: self.allAvailableAuthMethods)
                    
                    if (self.authMethodToLogin != .NONE) {
                        self.setReconnectionButtons(hiddenStatus: true)
                        
                        if (self.authMethodToLogin == .BASIC_HTTP_AUTH) {
                            self.setBasicAuthLoginStackViews(hiddenStatus: false)
                            self.textFieldURL.resignFirstResponder()
                            self.textFieldUsername.becomeFirstResponder()
                            
                            if self.loginMode == .update {
                                self.textFieldUsername.text = self.user?.username
                                self.textFieldPassword.text = ""
                            }
                        } else {
                            self.setBasicAuthLoginStackViews(hiddenStatus: true)
                            self.setConnectButton(status: true)
                            self.startAuthenticationWith(authMethod: self.authMethodToLogin)
                            
                        }
                        
                        self.showURLSuccess(self.validatedServerURL.hasPrefix("https://"))
                        
                    } else {
                        self.setBasicAuthLoginStackViews(hiddenStatus: true)
                        self.setConnectButton(status: false)
                        self.showURLError(
                            self.manageNetworkErrors.returnErrorMessage(
                                withHttpStatusCode: httpStatusCode, andError: nil
                            )
                        )
                    }
                    self.updateUIWithNormalizedData(self.serverURLNormalizer)

                    
                } else {
                    self.setConnectButton(status: false)
                    self.showURLError(
                        self.manageNetworkErrors.returnErrorMessage(
                            withHttpStatusCode: httpStatusCode, andError: nil
                        )
                    )
                }
            })
        }
    }
    
    
// MARK: start log in auth
    func startAuthenticationWith(authMethod: AuthenticationMethod) {
        self.setConnectButton(status: false)
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
            nextErrorShouldBeShownAfterPasswordField = true
            
            validateCredentialsAndStoreAccount(credentials: userCredDto);
            
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
        self.setNetworkActivityIndicator(status: false)
        if self.loginMode == .update {
            ManageCookiesStorageDB.deleteCookies(byUser: self.user)
            UtilsCookies.eraseCredentials(withURL: UtilsUrls.getFullRemoteServerPath(withWebDav: self.user))
            UtilsCookies.eraseURLCache()
        }
        
        if cookieString == nil || cookieString == "" {
            self.showCredentialsError(NSLocalizedString("authentification_not_valid", comment: "") )
            
            return;
        }
        
        if samlUserName == nil || samlUserName == "" {
            self.showCredentialsError(NSLocalizedString("saml_server_does_not_give_user_id", comment: "") )

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
            
            validateCredentialsAndStoreAccount(credentials: userCredDto);

        } else {
            
            self.showCredentialsError(NSLocalizedString("credentials_different_user", comment: "") )
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
            if (self.textFieldUsername.text!.characters.count > 0) && (self.textFieldPassword.text!.characters.count > 0) {
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
            //textField.resignFirstResponder()
            self.textFieldPassword.becomeFirstResponder()
            break
        case TextfieldType.password.rawValue:
            if (self.textFieldUsername.text?.characters.count)! > 0 {
                self.setNetworkActivityIndicator(status: true)
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
        self.view.endEditing(true)
        self.setNetworkActivityIndicator(status: true)
        self.setConnectButton(status: false)
        self.startAuthenticationWith(authMethod: self.authMethodToLogin)
    }
    
    @IBAction func helpLinkButtonTapped(_ sender: Any) {
        UIApplication.shared.openURL(NSURL(string:  k_url_link_on_login)! as URL)
    }
    
    @IBAction func unwindToMainLoginView(segue:UIStoryboardSegue) {
        if let sourceViewController = segue.source as? WebLoginViewController {
            let webVC: WebLoginViewController = sourceViewController
            if !(webVC.authCode).isEmpty {
                self.setNetworkActivityIndicator(status: false)
                self.authCodeReceived = webVC.authCode
                
                let urlToGetAuthData = OauthAuthentication().oauthUrlToGetTokenWith(serverPath: self.validatedServerURL)
                
                OauthAuthentication().getAuthDataBy(url: urlToGetAuthData, authCode: self.authCodeReceived, withCompletion: { ( userCredDto: CredentialsDto?, error: String?) in
                
                    if let userCredentials = userCredDto {
                        
                        self.validateCredentialsAndStoreAccount(credentials: userCredentials);
                        
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
    func validateCredentialsAndStoreAccount(credentials: CredentialsDto) {
        //get list of files in root to check session validty, if ok store new account
        let urlToGetRootFiles = URL (string: UtilsUrls.getFullRemoteServerPathWithWebDav(byNormalizedUrl: validatedServerURL) )
        
        DetectListOfFiles().getListOfFiles(url: urlToGetRootFiles!, credentials: credentials,
                                           withCompletion: { (_ errorHttp: NSInteger?,_ error: Error?, _ listOfFileDtos: [FileDto]? ) in
                                            
                                            self.setNetworkActivityIndicator(status: false)
                                            let app: AppDelegate = (UIApplication.shared.delegate as! AppDelegate)
                                            
                                            if (listOfFileDtos != nil && !((listOfFileDtos?.isEmpty)!)) {
                                                /// credentials allowed access to root folder: well done
                                                
                                                if self.user == nil {
                                                    self.user = UserDto()
                                                }
                                                
                                                self.user?.url = self.validatedServerURL
                                                self.user?.username = credentials.userName
                                                self.user?.ssl = self.validatedServerURL.hasPrefix("https")
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
                                                        self.showURLError(NSLocalizedString("error_could_not_add_account", comment: ""))
                                                    }
                                                    
                                                } else {
                                                    ManageAccounts().updateAccountOfUser(self.user!, withCredentials: credentials)
                                                    
                                                    self.closeLoginView()
                                                }
                                              
                                                
                                            } else {
                                                if errorHttp == Int(kOCErrorServerUnauthorized) {
                                                    self.showCredentialsError(
                                                        self.manageNetworkErrors.returnErrorMessage(
                                                            withHttpStatusCode: (errorHttp)!, andError: error
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
    
    func setLoginMode(loginMode: LoginMode) {
        self.loginMode = loginMode
    }
    
}
