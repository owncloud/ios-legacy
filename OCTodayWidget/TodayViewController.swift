//
//  TodayViewController.swift
//  OCTodayWidget
//
//  Created by Javier Gonzalez on 9/7/15.
//
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var filesLabel: UILabel?
    @IBOutlet weak var recentsLabel: UILabel?
    @IBOutlet weak var sharedLabel: UILabel?
    @IBOutlet weak var settingsLabel: UILabel?
    
    @IBAction func openFilesTab(sender: AnyObject) {
        var url: NSURL = NSURL(string:"owncloud://"+k_widget_parameter+"="+k_widget_parameter_files)!
        self.extensionContext?.openURL(url, completionHandler: nil)}
    
    @IBAction func openRecentsTab(sender: AnyObject) {
        var url: NSURL = NSURL(string:"owncloud://"+k_widget_parameter+"="+k_widget_parameter_recents)!
        self.extensionContext?.openURL(url, completionHandler: nil)}
    
    @IBAction func openSharedTab(sender: AnyObject) {
        var url: NSURL = NSURL(string:"owncloud://"+k_widget_parameter+"="+k_widget_parameter_shared)!
        self.extensionContext?.openURL(url, completionHandler: nil)}
    
    @IBAction func openSettingsTab(sender: AnyObject) {
        var url: NSURL = NSURL(string:"owncloud://"+k_widget_parameter+"="+k_widget_parameter_settings)!
        self.extensionContext?.openURL(url, completionHandler: nil)}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        filesLabel?.text = NSLocalizedString("files_tab", comment: "")
        recentsLabel?.text = NSLocalizedString("uploads_tab", comment: "")
        //sharedLabel?.text = NSLocalizedString("shared_tab", comment: "")
        settingsLabel?.text = NSLocalizedString("settings", comment: "")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
}
