//
//  TestSwiftClass.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 18/2/15.
//
//

import Foundation
import UIKit

@objc class TestSwiftClass: NSObject {
    // define the class
    var viewForLaunching: UIViewController?
    var title: String?
    var message: String?
    var button: String?
    
    override init() {
        super.init()
        self.title = "Swift Alert View"
        self.message = "This alert view is made in Swift"
        self.button = "OK"
    }
    
    func showAlertView() {
        //Funt to show a alert view
        let alert = UIAlertView()
        alert.title = self.title!
        alert.message = self.message!
        alert.addButtonWithTitle(self.button!)
        alert.show()
    }
    
    func showAlertController(viewController: UIViewController){
        
        var alert = UIAlertController(title: self.title, message: self.message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: self.button!, style: UIAlertActionStyle.Default, handler: nil))
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func showTempFolderWithTitle(text: String){
        
        let alert = UIAlertView()
        alert.title = text
        alert.message = UtilsUrls.getTempFolderForUploadFiles()
        alert.addButtonWithTitle(self.button!)
        alert.show()
        
    }
    
    
    
    
    
    
    
    
    
}


