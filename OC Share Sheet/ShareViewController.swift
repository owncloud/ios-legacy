//
//  ShareViewController.swift
//  OC Share Sheet
//
//  Created by Gonzalo Gonzalez on 4/3/15.
//
//

import UIKit
import Social
import MobileCoreServices
import AVFoundation


@objc class ShareViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var shareTable: UITableView?
    @IBOutlet weak var numberOfImages: UILabel?
    @IBOutlet weak var destinyFolderButton: UIBarButtonItem?
    
    var filesSelected: [NSURL] = []
    var images: [UIImage] = []
    var currentRemotePath: NSString?
   
    let customRowColor = UIColor.colorOfNavigationBar()
    let customRowBorderColor = UIColor.colorOfNavigationTitle()
    
    let witdhFormSheet: CGFloat = 540.0
    let heighFormSheet: CGFloat = 620.0
    
    
    override func viewDidLoad() {
        
        self.createCustomInterface()
        
        self.shareTable!.registerClass(FileSelectedCell.self, forCellReuseIdentifier: "cell")
        
        self.loadFiles()
        
    }
    
    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad{
            
            self.navigationController?.view.bounds = CGRectMake(0, 0, witdhFormSheet, heighFormSheet)
        }
        
    }
    
    func createCustomInterface(){
        
        //TODO: Change ownCloud for the name of the branding customer
        
        let rightBarButton = UIBarButtonItem (title:"Done", style: .Plain, target: self, action:"cancelView")
        let leftBarButton = UIBarButtonItem (title:"Cancel", style: .Plain, target: self, action:"cancelView")
        
        self.navigationItem.title = "ownCloud"
        
        self.navigationItem.leftBarButtonItem = leftBarButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.navigationItem.hidesBackButton = true
        
        self.changeTheDestinyFolderWith("ownCloud")

    }
    
    func changeTheDestinyFolderWith(folder: String){
        
        let location = NSLocalizedString("location", comment: "comment")
        let destiny = "\(location) \(folder)"
        
        self.destinyFolderButton?.title = destiny
        
    }
    
    
    func cancelView() {
       
        self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
        return
       
    }
    
    @IBAction func destinyFolderButtonTapped(sender: UIBarButtonItem) {
        println("destiny folder tapped")
        
        let activeUser = ManageUsersDB.getActiveUser()
        
        let rootFileDto = ManageFilesDB.getRootFileDtoByUser(activeUser)
        
        let selectFolderViewController = SelectFolderViewController(nibName: "SelectFolderViewController", onFolder: rootFileDto)
        
        let navigation = SelectFolderNavigation(rootViewController: selectFolderViewController)
        
        navigation.delegate = self
        
        selectFolderViewController.parent = navigation;
        
        self.presentViewController(navigation, animated: true) { () -> Void in
            println("select folder presented")
        }
    }
    
    
    func loadFiles() {
        
        if let inputItems : [NSExtensionItem] = self.extensionContext?.inputItems as? [NSExtensionItem] {
            for item : NSExtensionItem in inputItems {
                if let attachments = item.attachments as? [NSItemProvider] {
                    
                    if attachments.isEmpty {
                        self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
                        return
                    }
                    
                    for (index, current) in (enumerate(attachments)){

                        //Items
                        if current.hasItemConformingToTypeIdentifier(kUTTypeItem as String){
                            
                            current.loadItemForTypeIdentifier(kUTTypeItem, options: nil, completionHandler: {(item: NSSecureCoding!, error: NSError!) -> Void in
                                
                                if error == nil {
                                    
                                    let url = item as NSURL
                                    
                                    self.filesSelected.append(url)
                                    
                                    if index+1 == attachments.count{
                                        
                                        self.showFilesSelected()
                                    }
                                    
                                } else {
                                    println("ERROR: \(error)")
                                }
                                
                            })
                        
                        } 
                    }
                }
            }
        }
    }
    
    
    func showFilesSelected (){
        
        if self.filesSelected.count > 0{
            
            for url : NSURL in self.filesSelected{
                
                //Check the type of the file
                
                let ext = FileNameUtils.getExtension(url.lastPathComponent)
                let type = FileNameUtils.checkTheTypeOfFile(ext)
                
                println("Selecte file: \(url.path)")
                
                if type == kindOfFileEnum.imageFileType.rawValue{
                    let imageData = NSData(contentsOfURL: url)
                    let image = UIImage(data: imageData!)
                    self.images.append(image!)
                } else if type == kindOfFileEnum.videoFileType.rawValue {
                    println("Video Selected")
                    
                    let asset = AVURLAsset (URL: url, options: nil)
                    let imageGenerator = AVAssetImageGenerator (asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    let time = CMTimeMakeWithSeconds(0.0, 600)
                
                    let imageRef = imageGenerator.copyCGImageAtTime(time, actualTime: nil, error: nil)
                    let image = UIImage (CGImage: imageRef)
                    
                    self.images.append(image!)
                }
            }
            
            
            // Delay 2 seconds
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.001 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                
                func reloadDatabase () {
                    self.shareTable?.reloadData()
                }
                
                reloadDatabase()
            }
            
        }else{
            //Error any file selected
        }
    }
        
    //MARK: TableView Delegate and Datasource methods
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
        return self.filesSelected.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        let identifier = "FileSelectedCell"
        var cell: FileSelectedCell! = tableView.dequeueReusableCellWithIdentifier(identifier ,forIndexPath: indexPath) as FileSelectedCell
        
        let row = indexPath.row
        let url = self.filesSelected[row] as NSURL
        
        cell.backgroundCustomView?.backgroundColor = customRowColor
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        //Custom circle image and border
        let cornerRadius = cell.imageForFile!.frame.size.width / 2
        cell.imageForFile?.layer.cornerRadius = cornerRadius
        cell.imageForFile?.clipsToBounds = true
        cell.imageForFile?.layer.borderWidth = 3.0
        cell.imageForFile?.layer.borderColor = customRowBorderColor.CGColor
        
        //Cusotm circle view in
        cell.roundCustomView?.backgroundColor = customRowColor
        cell.roundCustomView?.layer.cornerRadius = cornerRadius
        cell.roundCustomView?.clipsToBounds = true
        
        
        //Choose the correct icon if the file is not an image
        let ext = FileNameUtils.getExtension(url.lastPathComponent)
        let type = FileNameUtils.checkTheTypeOfFile(ext)
        
        if (type == kindOfFileEnum.imageFileType.rawValue || type == kindOfFileEnum.videoFileType.rawValue) && row < images.count{
           //Image
           cell.imageForFile?.image = images[indexPath.row];
            
        }else{
            //Not image
            let image = UIImage(named: FileNameUtils.getTheNameOfTheImagePreviewOfFileName(url.lastPathComponent))
            cell.imageForFile?.image = image
            cell.imageForFile?.backgroundColor = UIColor.whiteColor()
        }
        
        cell.title?.text = url.path?.lastPathComponent
        
        
        if let size = NSFileManager.defaultManager().attributesOfItemAtPath(url.path!, error: nil)![NSFileSize] as? Int{
            cell.size?.text = "\(size) bytes"
        }else{
            cell.size?.text = ""
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool
    {
        return false
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!)
    {
        println("row = %d",indexPath.row)
    }
    
    //MARK: Select Folder Selected Delegate Methods
    
    func folderSelected(folder: NSString){
        
        println("Folder selected \(folder)")
        
        self.currentRemotePath = folder
        
        let name:NSString = folder.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        self.changeTheDestinyFolderWith(name.lastPathComponent)
        
    }
    
    func cancelFolderSelected(){
        
        println("Cancel folder selected")
        
    }
    

}
