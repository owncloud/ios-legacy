//
//  ShareViewController.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/8/15.
//
//

import UIKit

class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let shareFileCellIdentifier: String = "ShareFileIdentifier"
    let shareFileCellNib: String = "ShareFileCell"
    let shareLinkOptionIdentifer: String = "ShareLinkOptionIdentifier"
    let shareLinkOptionNib: String = "ShareLinkOptionCell"
    let heightOfFileDetailRow: CGFloat = 120.0
    let heightOfShareLinkOptionRow: CGFloat = 55.0
    
    @IBOutlet weak var shareTableView: UITableView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setStyleView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Style Methods
    
    func setStyleView() {
       
        self.navigationItem.title = "Share"
        
        self.setBarButtonStyle()
    }
    
    func setBarButtonStyle() {
        
        var barButton: UIBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: "didSelectCloseView")
        self.navigationItem.leftBarButtonItem = barButton
    }
    
    
    //MARK: - Action methods
    
    func didSelectCloseView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
        
    

    //MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0{
            return 1;
        }else{
            return 2;
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //ShareFileIdentifier
        
        if indexPath.section == 0 {
            var cell: ShareFileCell! = tableView.dequeueReusableCellWithIdentifier(shareFileCellIdentifier) as? ShareFileCell
            if cell == nil {
                tableView.registerNib(UINib(nibName: shareFileCellNib, bundle: nil), forCellReuseIdentifier: shareFileCellIdentifier)
                cell = tableView.dequeueReusableCellWithIdentifier(shareFileCellIdentifier) as? ShareFileCell
            }
            
            cell.fileName.text = "filename.pdf"
            cell.fileSize.text = "15,5MB"
            
            return cell
        }else{
            
            var cell: ShareLinkOptionCell! = tableView.dequeueReusableCellWithIdentifier(shareLinkOptionIdentifer) as? ShareLinkOptionCell
            if cell == nil {
                tableView.registerNib(UINib(nibName: shareLinkOptionNib, bundle: nil), forCellReuseIdentifier: shareLinkOptionIdentifer)
                cell = tableView.dequeueReusableCellWithIdentifier(shareLinkOptionIdentifer) as? ShareLinkOptionCell
            }
            
            switch (indexPath.row){
            case 0:
                cell.optionName.text = "Set expiration time"
                cell.detailTextLabel?.text = "empty"
                cell.optionSwith.setOn(false, animated: true)
            case 1:
                cell.optionName.text = "Password protect"
                cell.detailTextLabel?.text = "empty"
                cell.optionSwith.setOn(false, animated: true)
            default:
                println("Not expected")
            
            }
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat{
        
        if indexPath.section == 0{
            return heightOfFileDetailRow
        }else{
            return heightOfShareLinkOptionRow
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?{
        if section == 1{
            return "Share link"
        }else{
            return "";
        }
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        if section == 1{
            let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
            
            var backgroundView: UIView = UIView(frame: header.frame)
            backgroundView.backgroundColor = UIColor.colorOfNavigationBar()
            
            let switchFrame: CGRect = CGRect(x: header.frame.size.width - 52, y: (header.frame.size.height/2)-15, width: 31, height: 51)
            var sectionSwitch: UISwitch = UISwitch(frame: switchFrame)
            
            backgroundView.addSubview(sectionSwitch)
            
            header.backgroundView = backgroundView
            header.textLabel.textColor = UIColor.whiteColor()
            header.textLabel.frame = header.frame
            header.textLabel.textAlignment = NSTextAlignment.Left
            header.textLabel.text = "Share Link"

        }
    }
}
