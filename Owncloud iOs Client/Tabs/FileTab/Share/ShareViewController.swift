//
//  ShareViewController.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/8/15.
//
//

import UIKit

class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //tools
    let standardDelay: Double = 0.2
    
    //Cells and Sections
    let shareFileCellIdentifier: String = "ShareFileIdentifier"
    let shareFileCellNib: String = "ShareFileCell"
    let shareLinkOptionIdentifer: String = "ShareLinkOptionIdentifier"
    let shareLinkOptionNib: String = "ShareLinkOptionCell"
    let shareLinkHeaderIdentifier: String = "ShareLinkHeaderIdentifier"
    let shareLinkHeaderNib: String = "ShareLinkHeaderCell"
    let heightOfFileDetailRow: CGFloat = 120.0
    let heightOfShareLinkOptionRow: CGFloat = 55.0
    let heightOfShareLinkHeader: CGFloat = 40.0
    
    //Nº of Rows
    let optionsShownWithShareLinkEnable: Int = 2
    let optionsShownWithShareLinkDisable: Int = 0
    
    var optionsShownWithShareLink: Int = 0
    var isShareLinkEnabled: Bool = false
    var file: FileDto!
    
    @IBOutlet weak var shareTableView: UITableView!
    
     init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, fileDto: FileDto?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.file = fileDto
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

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
    
    func reloadView() {
        
        if isShareLinkEnabled == true{
            optionsShownWithShareLink = optionsShownWithShareLinkEnable
        }else{
            optionsShownWithShareLink = optionsShownWithShareLinkDisable
        }
        
        self.shareTableView.reloadData()
    }
    
    
    //MARK: - Action methods
    
    func didSelectCloseView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func sharedLinkSwithValueChanged(sender: UISwitch){
        
        isShareLinkEnabled = sender.on
        
        delay(standardDelay) {
            self.reloadView()
        }
        
        
    }
    
    //MARK: - Tools
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
        
    

    //MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0{
            return 1;
        }else{
            return optionsShownWithShareLink;
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
            cell.fileImage.image = UIImage(named: FileNameUtils.getTheNameOfTheImagePreviewOfFileName(file.fileName))
            cell.fileName.text = file.fileName
            cell.fileSize.text = NSByteCountFormatter.stringFromByteCount(NSNumber(integer: file.size).longLongValue, countStyle: NSByteCountFormatterCountStyle.Memory)
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
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height: CGFloat = 10.0
        
        if section == 1{
            height = heightOfShareLinkHeader
        }
        
        return height
        
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 1 {
            
            var header: ShareLinkHeaderCell! = tableView.dequeueReusableCellWithIdentifier(shareLinkHeaderIdentifier) as? ShareLinkHeaderCell
            
            if header == nil {
                tableView.registerNib(UINib(nibName: shareLinkHeaderNib, bundle: nil), forCellReuseIdentifier: shareLinkHeaderIdentifier)
                header = tableView.dequeueReusableCellWithIdentifier(shareLinkHeaderIdentifier) as? ShareLinkHeaderCell
            }
        
            header!.titleSection.text = "Share Link"
            header!.switchSection.setOn(isShareLinkEnabled, animated: false)
            header!.switchSection.addTarget(self, action: "sharedLinkSwithValueChanged:", forControlEvents: .ValueChanged)
            
            
            
            return header
        } else {
            return UIView()
        }
    }
    
}
