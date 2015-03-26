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
    @IBOutlet weak var destinyFolderButton: UIBarButtonItem?
    @IBOutlet weak var constraintTopTableView: NSLayoutConstraint?
    
    var filesSelected: [NSURL] = []
    var images: [UIImage] = []
    var currentRemotePath: String!
   
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
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.navigationController?.view.bounds = CGRectMake(0, 0, witdhFormSheet, heighFormSheet)
            self.constraintTopTableView?.constant = -20
        }
        
    }
    
    func createCustomInterface(){
        
        let rightBarButton = UIBarButtonItem (title:NSLocalizedString("upload_label", comment: ""), style: .Plain, target: self, action:"sendTheFilesToOwnCloud")
        let leftBarButton = UIBarButtonItem (title:NSLocalizedString("cancel", comment: ""), style: .Plain, target: self, action:"cancelView")
        
        self.navigationItem.title = k_app_name

        
        self.navigationItem.leftBarButtonItem = leftBarButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.navigationItem.hidesBackButton = true
        
        self.changeTheDestinyFolderWith(k_app_name)


    }
    
    func changeTheDestinyFolderWith(folder: String){
        
        var nameFolder = folder
        let location = NSLocalizedString("location", comment: "comment")
        if folder.isEmpty {
            nameFolder = k_app_name
        }

        if (countElements(nameFolder) > 20) {
            nameFolder =  nameFolder.substringWithRange(Range<String.Index>(start:nameFolder.startIndex, end: advance(nameFolder.startIndex, 20)))
            nameFolder += "..."
        }

        println("nameFolder: \(nameFolder)")

        let destiny = "\(location) \(nameFolder)"
        
        self.destinyFolderButton?.title = destiny
    }
    
    func cancelView() {
       
        self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
        return
       
    }
    
    func sendTheFilesToOwnCloud() {
        println("sendTheFilesToOwnCloud")
        
        let user = ManageUsersDB.getActiveUser()
        
        if user != nil {
            for url : NSURL in self.filesSelected {
                
                //1º Get the future name of the file
                
                let ext = FileNameUtils.getExtension(url.lastPathComponent)
                let type = FileNameUtils.checkTheTypeOfFile(ext)
                
                var fileName:String!
                
                var urlOriginalPath :String = url.path!.stringByDeletingLastPathComponent
                var destinyMovedFilePath :String = UtilsUrls.getTempFolderForUploadFiles()
                
                fileName = url.path!.lastPathComponent
                if type == kindOfFileEnum.imageFileType.rawValue || type == kindOfFileEnum.videoFileType.rawValue {
                    
                    if  urlOriginalPath != dropLast(destinyMovedFilePath) {
                        fileName = FileNameUtils.getComposeNameFromPath(url.path)
                    }
                }
                
                //2º Copy the file to the tmp folder
                destinyMovedFilePath = destinyMovedFilePath + fileName
                if destinyMovedFilePath.stringByDeletingLastPathComponent != urlOriginalPath {
                    NSFileManager.defaultManager().copyItemAtPath(url.path!, toPath: destinyMovedFilePath, error: nil)
                }
                
                if currentRemotePath == nil {
                    currentRemotePath = ManageFilesDB.getRootFileDtoByUser(user).filePath;
                }
                
                //3º Crete the upload objects
                let remotePath = user.url + k_url_webdav_server + UtilsDtos.getDbBFilePathFromFullFilePath(currentRemotePath+fileName, andUser: user)
                println("remotePath: \(remotePath)")
                
                let fileLength = NSFileManager.defaultManager().attributesOfItemAtPath(url.path!, error: nil)![NSFileSize] as Int
                println("fileLength: \(fileLength)")
                
                var upload = UploadsOfflineDto.alloc()
                
                upload.originPath = destinyMovedFilePath
                upload.destinyFolder = remotePath
                upload.uploadFileName = fileName
                upload.kindOfError = enumKindOfError.notAnError.rawValue
                upload.estimateLength = fileLength
                upload.userId = user.idUser
                upload.isLastUploadFileOfThisArray = true
                upload.status = enumUpload.generatedByDocumentProvider.rawValue
                upload.chunksLength = Int(k_lenght_chunk)
                upload.isNotNecessaryCheckIfExist = false
                upload.isInternalUpload = false
                upload.taskIdentifier = 0
                
                ManageUploadsDB.insertUpload(upload)
            }
            
            var webView = UIWebView()
            webView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            
            let urlString = "owncloud://"
            let content = "<head><meta http-equiv='refresh' content='0; URL=\(urlString)'></head>"
            webView.loadHTMLString(content, baseURL: nil)
            self.view.addSubview(webView)
            
            // Delay 2 seconds
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                webView.removeFromSuperview()
                self.cancelView()
            }
            
        } else {
            showErrorUserNotExist()
        }
    }
    
    @IBAction func destinyFolderButtonTapped(sender: UIBarButtonItem) {
        println("destiny folder tapped")
        
        let activeUser = ManageUsersDB.getActiveUser()
        
        if activeUser != nil {
            let rootFileDto = ManageFilesDB.getRootFileDtoByUser(activeUser)
            
            let selectFolderViewController = SelectFolderViewController(nibName: "SelectFolderViewController", onFolder: rootFileDto)
            
            let navigation = SelectFolderNavigation(rootViewController: selectFolderViewController)
            
            navigation.delegate = self
            navigation.modalPresentationStyle = UIModalPresentationStyle.FormSheet
            
            selectFolderViewController.parent = navigation;
            
            self.presentViewController(navigation, animated: true) { () -> Void in
                println("select folder presented")
            }
        } else {
            showErrorUserNotExist()
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
                                    
                                    println("item: \(item)")
                                    
                                    if let url = item as? NSURL{
                                        
                                        self.filesSelected.append(url)
                                        
                                        if index+1 == attachments.count{
                                            
                                            self.showFilesSelected()
                                        }
                                    }
                                    
                                    if let image = item as? NSData{
                                        
                                        println("data")
                                        
                                        println("item: \(item)")
                                        
                                        let description = current.description
                               
                                        var fullNameArr = description.componentsSeparatedByString("\"")
                                        var fileExtArr = fullNameArr[1].componentsSeparatedByString(".")
                                        var ext = (fileExtArr[fileExtArr.count-1]).uppercaseString
                                        let dateFormatter = NSDateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                                        var fileName = "Photo_email_\(dateFormatter.stringFromDate(NSDate())).\(ext)"
                                        
                                        //2º Copy the file to the tmp folder
                                        var destinyMovedFilePath = UtilsUrls.getTempFolderForUploadFiles()
                                        destinyMovedFilePath = destinyMovedFilePath + fileName
                                        
                                        NSFileManager.defaultManager().createFileAtPath(destinyMovedFilePath,contents:image, attributes:nil)
                                        
                                        let url = NSURL(fileURLWithPath: destinyMovedFilePath)
                                        
                                        self.filesSelected.append(url!)
                                        
                                        if index+1 == attachments.count{
                                            
                                            self.showFilesSelected()
                                        }

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
        cell.imageForFile?.backgroundColor = UIColor.whiteColor()
        
        //Custom circle view in
        cell.roundCustomView?.backgroundColor = customRowColor
        cell.roundCustomView?.layer.cornerRadius = cornerRadius
        cell.roundCustomView?.clipsToBounds = true
        
        
        //Choose the correct icon if the file is not an image
        let ext = FileNameUtils.getExtension(url.lastPathComponent)
        let type = FileNameUtils.checkTheTypeOfFile(ext)
        
        
        
        
        if (type == kindOfFileEnum.imageFileType.rawValue || type == kindOfFileEnum.videoFileType.rawValue) && row < images.count{
            //Image
            var fileName: NSString = url.path!.lastPathComponent
            cell.imageForFile?.image = images[indexPath.row];
            if  !fileName.containsString("Photo_email") {
                fileName = FileNameUtils.getComposeNameFromPath(url.path)
            }
            cell.title?.text = fileName
        }else{
            //Not image
            let image = UIImage(named: FileNameUtils.getTheNameOfTheImagePreviewOfFileName(url.lastPathComponent))
            cell.imageForFile?.image = image
            cell.imageForFile?.backgroundColor = UIColor.whiteColor()
            cell.title?.text = url.path?.lastPathComponent
        }
        
        
        
        let fileSizeInBytes = NSFileManager.defaultManager().attributesOfItemAtPath(url.path!, error: nil)![NSFileSize] as? Double
        
        
        if fileSizeInBytes > 0 {
            let formattedFileSize = NSByteCountFormatter.stringFromByteCount(
                Int64(fileSizeInBytes!),
                countStyle: NSByteCountFormatterCountStyle.File
            )
            cell.size?.text = "\(formattedFileSize)"
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
        let user = ManageUsersDB.getActiveUser()
        let folderPath = UtilsDtos.getDbBFilePathFromFullFilePath(name, andUser: user)

        self.changeTheDestinyFolderWith(folderPath.lastPathComponent)
        
    }
    
    func cancelFolderSelected(){
        
        println("Cancel folder selected")
        
    }
    
    func showErrorUserNotExist() {
        var alert = UIAlertController(title: NSLocalizedString("error_login_doc_provider", comment: ""), message: "", preferredStyle: UIAlertControllerStyle.Alert)
        //alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .Default, handler: { action in
            switch action.style{
            case .Default:
                self.cancelView()
            case .Cancel:
                println("cancel")
            case .Destructive:
                println("destructive")
            }
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

}
