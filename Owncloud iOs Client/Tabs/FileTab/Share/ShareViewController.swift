//
//  ShareViewController.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/8/15.
//

/*
Copyright (C) 2015, ownCloud, Inc.
This code is covered by the GNU Public License Version 3.
For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
You should have received a copy of this license
along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

import UIKit

class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ShareFileOrFolderDelegate, MBProgressHUDDelegate {
    
    //tools
    let standardDelay: Double = 0.2
    
    //Cells and Sections
    let shareFileCellIdentifier: String = "ShareFileIdentifier"
    let shareFileCellNib: String = "ShareFileCell"
    let shareLinkOptionIdentifer: String = "ShareLinkOptionIdentifier"
    let shareLinkOptionNib: String = "ShareLinkOptionCell"
    let shareLinkHeaderIdentifier: String = "ShareLinkHeaderIdentifier"
    let shareLinkHeaderNib: String = "ShareLinkHeaderCell"
    let shareLinkButtonIdentifier: String = "ShareLinkButtonIdentifier"
    let shareLinkButtonNib: String = "ShareLinkButtonCell"
    let heightOfFileDetailRow: CGFloat = 120.0
    let heightOfShareLinkOptionRow: CGFloat = 55.0
    let heightOfShareLinkHeader: CGFloat = 40.0
    let shareTableViewSectionsNumber: Int = 2
    
    //Nº of Rows
    let optionsShownWithShareLinkEnable: Int = 3
    let optionsShownWithShareLinkDisable: Int = 0
    
    var optionsShownWithShareLink: Int = 0
    var isShareLinkEnabled: Bool = false
    var sharedItem: FileDto!
    var shareFileOrFolder: ShareFileOrFolder!
    var loadingView: MBProgressHUD!
    
    @IBOutlet weak var shareTableView: UITableView!
    
    
     init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, fileDto: FileDto?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.sharedItem = fileDto
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setStyleView()
        
        self.updateInterfaceWithShareLinkStatus()
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
    
    func updateInterfaceWithShareLinkStatus() {
        
        if self.sharedItem.sharedFileSource > 0{
            isShareLinkEnabled = true
        }else{
            isShareLinkEnabled = false
        }
        
        self.reloadView()
        
    }
    
    func didSelectCloseView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func sharedLinkSwithValueChanged(sender: UISwitch){
        
        isShareLinkEnabled = sender.on
        
        self.getShareLinkView()
        
    }
    
    func getShareLinkView() {
        
        if isShareLinkEnabled == true{
            
            self.shareFileOrFolder = nil
            
            self.shareFileOrFolder = ShareFileOrFolder.new()
            
            self.shareFileOrFolder.delegate = self
            
            self.shareFileOrFolder.viewToShow = self.view
            
            self.shareFileOrFolder.parentViewController = self
            
            if self.sharedItem.sharedFileSource > 0{
                self.shareFileOrFolder.clickOnShareLinkFromFileDto(true)
                clickOnShareLinkFromFileDto
            }else{
                
            }
            
            self.shareFileOrFolder.showShareActionSheetForFile(self.sharedItem)
            
            
            /* if (self.mShareFileOrFolder) {
            self.mShareFileOrFolder = nil;
            }
            
            self.mShareFileOrFolder = [ShareFileOrFolder new];
            self.mShareFileOrFolder.delegate = self;
            
            //If is iPad get the selected cell
            if (!IS_IPHONE) {
            
            self.mShareFileOrFolder.viewToShow = self.splitViewController.view;
            
            //We use _selectedIndexPath to identify the position where we have to put the arrow of the popover
            if (_selectedIndexPath) {
            UITableViewCell *cell;
            cell = [_tableView cellForRowAtIndexPath:_selectedIndexPath];
            self.mShareFileOrFolder.cellFrame = cell.frame;
            self.mShareFileOrFolder.parentView = _tableView;
            self.mShareFileOrFolder.isTheParentViewACell = YES;
            }
            } else {
            
            self.mShareFileOrFolder.viewToShow=self.tabBarController.view;
            }
            
            [self.mShareFileOrFolder showShareActionSheetForFile:_selectedFileDto];*/
            
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
        return shareTableViewSectionsNumber
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0{
            return 1;
        }else{
            return optionsShownWithShareLink;
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        if indexPath.section == 0 {
            var cell: ShareFileCell! = tableView.dequeueReusableCellWithIdentifier(shareFileCellIdentifier) as? ShareFileCell
            if cell == nil {
                tableView.registerNib(UINib(nibName: shareFileCellNib, bundle: nil), forCellReuseIdentifier: shareFileCellIdentifier)
                cell = tableView.dequeueReusableCellWithIdentifier(shareFileCellIdentifier) as? ShareFileCell
            }
            
            
            if sharedItem.isDirectory{
               cell.fileImage.image = UIImage(named:"folder_icon")
               cell.fileSize.text = ""
            
            }else{
               cell.fileImage.image = UIImage(named: FileNameUtils.getTheNameOfTheImagePreviewOfFileName(sharedItem.fileName.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)))
               cell.fileSize.text = NSByteCountFormatter.stringFromByteCount(NSNumber(integer: sharedItem.size).longLongValue, countStyle: NSByteCountFormatterCountStyle.Memory)
            }
            
            cell.fileName.text = sharedItem.fileName.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
            
            return cell
            
        }else{
            
            if indexPath.row == 2 {
                
                var cell: ShareLinkButtonCell! = tableView.dequeueReusableCellWithIdentifier(shareLinkButtonIdentifier) as? ShareLinkButtonCell
                if cell == nil {
                    tableView.registerNib(UINib(nibName: shareLinkButtonNib, bundle: nil), forCellReuseIdentifier: shareLinkButtonIdentifier)
                    cell = tableView.dequeueReusableCellWithIdentifier(shareLinkButtonIdentifier) as? ShareLinkButtonCell
                }
                
                cell.titleButton.text = "Get Share Link"
                
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 2{
            
            //Get Shared Link button tapped
            self.getShareLinkView()
        }
    }
    
    //MARK: - ShareFileOrFolder Delegate Methods
    
    func initLoading() {
        
        if loadingView != nil{
            
            loadingView.removeFromSuperview()
            loadingView = nil
            
        }
        
        loadingView = MBProgressHUD(window: UIApplication.sharedApplication().keyWindow)
        loadingView.delegate = self
        
        
        if IS_IPHONE{
            self.view.window?.addSubview(loadingView)
        }else{
            appDelegate.splitViewController.view.window?.addSubview(loadingView)
        }
        
        self.view.addSubview(loadingView)
        
        loadingView.labelText = NSLocalizedString("loading", comment: "")
        loadingView.dimBackground = false
        
        loadingView.show(true)
        
        self.view.userInteractionEnabled = false
        self.navigationController?.navigationBar.userInteractionEnabled = false
        self.view.window?.userInteractionEnabled = false
        
    }
    
    func endLoading() {
        
        if appDelegate.isLoadingVisible == false{
            
            self.loadingView.removeFromSuperview()
            
            self.view.userInteractionEnabled = true
            self.navigationController?.navigationBar.userInteractionEnabled = true
            self.view.window?.userInteractionEnabled = true
            
        }
    }
    
    func errorLogin() {
        
        self.endLoading()
    }
    
    
    func presentShareOptions(activity: AnyObject){
        
        let activityView: UIActivityViewController = activity as! UIActivityViewController
        
        self.presentViewController(activityView, animated: true, completion: nil)
        
        delay(standardDelay) {
            self.reloadView()
        }
        
    }
 
    
}
