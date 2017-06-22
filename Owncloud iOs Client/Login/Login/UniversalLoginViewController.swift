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
    
    
// MARK: IBOutlets
    
    @IBOutlet var imageViewLogo: UIImageView!
    @IBOutlet var textFieldURL: UITextField!
    @IBOutlet var buttonConnect: UIButton!
    @IBOutlet var buttonHelpLink: UIButton!
    @IBOutlet var buttonReconnection: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldURL.delegate = self;
        // Do any additional setup after loading the view.
        
        //set branding style
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
// MARK: IBActions
    
    @IBAction func reconnectionButtonTapped(_ sender: Any) {
        self.checkCurrentUrl()
    }

    
    @IBAction func connectButtonTapped(_ sender: Any) {
        self.checkCurrentUrl()
        
    }
    

    @IBAction func helpLinkButtonTapped(_ sender: Any) {
        //open web view help
    
    }

    
// MARK: checkUrl
    
    func checkCurrentUrl() {
        
        textFieldURL.resignFirstResponder()

       let stringURL = textFieldURL.text
        
        //parse url, appsfiles, user:pass, prefix
        
        
        //check status
        
                //check authentication propfind
    
        let checkAccessToServer : CheckAccessToServer = CheckAccessToServer.sharedManager() as! CheckAccessToServer
        checkAccessToServer.delegate = self
        checkAccessToServer.isConnectionToTheServer(byUrl: stringURL)
        
    }
    
// MARK:  CheckAccessToServer
    
    func connection(toTheServer isConnection: Bool) {
        if isConnection {
            print("Ok connection to the server")
            //TODO normalice url
            let stringURL = textFieldURL.text! +  (k_url_webdav_server)
            var allAvailableAuthMethods = [AuthenticationMethod]()
            
            DetectAuthenticationMethod().getAuthenticationMethodsAvailableByUrl(url: stringURL, withCompletion: { (authMethods: Array<Any>?) in
                allAvailableAuthMethods = authMethods as! [AuthenticationMethod];
                //do things
            })
            
        } else {
            print("No connection to the server")
        }

    }
    
// MARK: textField delegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {

        self.checkCurrentUrl()
        
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
