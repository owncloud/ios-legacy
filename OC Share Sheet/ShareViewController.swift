//
//  ShareViewController.swift
//  OC Share Sheet
//
//  Created by Gonzalo Gonzalez on 4/3/15.
//

/*
Copyright (C) 2016, ownCloud GmbH.
This code is covered by the GNU Public License Version 3.
For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
You should have received a copy of this license
along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

import UIKit
import Social
import MobileCoreServices
import AVFoundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



@objc class ShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, KKPasscodeViewControllerDelegate, CheckAccessToServerDelegate {
    
    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var shareTable: UITableView?
    @IBOutlet weak var destinyFolderButton: UIBarButtonItem?
    @IBOutlet weak var constraintTopTableView: NSLayoutConstraint?
    
    var filesSelected: [URL] = []
    var images: [UIImage] = []
    var currentRemotePath: String!
   
    let witdhFormSheet: CGFloat = 540.0
    let heighFormSheet: CGFloat = 620.0
    
    let witdhImageSize: CGFloat = 150.0
    let heighImageSize: CGFloat = 150.0
    
    
    override func viewDidLoad() {
        
        InitializeDatabase.initDataBase()
        
        var delay = 0.1
        
        if ManageAppSettingsDB.isPasscode(){
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
                self.showPasscode()
                if ManageAppSettingsDB.isTouchID(){
                    ManageTouchID.sharedSingleton().showAuth()
                }
            }
            
            delay = delay * 2
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
            self.showShareIn()
        }
 
    }

    override func viewWillLayoutSubviews() {
        
        super.viewWillLayoutSubviews()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.navigationController?.view.bounds = CGRect(x: 0, y: 0, width: witdhFormSheet, height: heighFormSheet)
            self.constraintTopTableView?.constant = -20
        }
        
    }
    
    func showPasscode() {
        
        let passcodeView = KKPasscodeViewController(nibName: nil, bundle: nil)
        passcodeView.delegate = self
        passcodeView.mode = UInt(KKPasscodeModeEnter)
        
        passcodeView.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(ShareViewController.cancelView))
        
        let ocNavController = OCNavigationController(rootViewController: passcodeView)
        ocNavController.modalPresentationStyle = UIModalPresentationStyle.formSheet
        
        self.present(ocNavController, animated: false) { () -> Void in
            print("Passcode presented")
        }
        
        
    }
    
    func showShareIn() {
        
        self.createCustomInterface()
        
        self.shareTable!.register(FileSelectedCell.self, forCellReuseIdentifier: "cell")
        
        self.loadFiles()
        
    }
    
    func createCustomInterface(){
        
        let rightBarButton = UIBarButtonItem (title:NSLocalizedString("upload_label", comment: ""), style: .plain, target: self, action:#selector(ShareViewController.uploadButtonTapped))
        let leftBarButton = UIBarButtonItem (title:NSLocalizedString("cancel", comment: ""), style: .plain, target: self, action:#selector(ShareViewController.cancelView))
        
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as! String

        self.navigationItem.title = appName

        
        self.navigationItem.leftBarButtonItem = leftBarButton
        self.navigationItem.rightBarButtonItem = rightBarButton
        self.navigationItem.hidesBackButton = true
        
        self.changeTheDestinyFolderWith(appName)


    }
    
    func changeTheDestinyFolderWith(_ folder: String){
        
        var nameFolder = folder
        let location = NSLocalizedString("location", comment: "comment")
        if folder.isEmpty {
            let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as! String
            nameFolder = appName
        }

        if (nameFolder.characters.count > 20) {
            let nameFolderNSString = nameFolder as NSString
            nameFolder = nameFolderNSString.substring(with: NSRange(location: 0, length: 20))
            nameFolder += "..."
        }

        print("nameFolder: \(nameFolder)")

        let destiny = "\(location) \(nameFolder)"
        
        self.destinyFolderButton?.title = destiny
    }
    
    func cancelView() {
       
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        return
       
    }
    
    func uploadButtonTapped() {
        
        let activeUser = ManageUsersDB.getActiveUser()
        
        if activeUser != nil {
            
            var title = ""
            
            title = NSLocalizedString("files_will_be_upload_next_time", comment: "")
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as! String
            title = title.replacingOccurrences(of: "$appname", with: appName)
            
            let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
                self.sendTheFilesToOwnCloud()
            }))
            
            self.present(alert, animated: true, completion: nil)
            
        } else {
            self.showErrorLoginView()
        }
   
    }
    
    func sendTheFilesToOwnCloud() {
        
        print("sendTheFilesToOwnCloud")
        
        let user = ManageUsersDB.getActiveUser()
        
        if user != nil {
            
            var hasSomethingToUpload: Bool = false
            
           for (index, url): (Int, URL) in (self.filesSelected.enumerated()){
                
                //1º Get the future name of the file
                
                let ext = FileNameUtils.getExtension(url.lastPathComponent)
                let type = FileNameUtils.checkTheType(ofFile: ext)
                
                var fileName:String!
                
                let urlOriginalPath :String = (url.path as NSString).deletingLastPathComponent
                var destinyMovedFilePath :String = UtilsUrls.getTempFolderForUploadFiles()
                
                fileName = (url.path as NSString).lastPathComponent
                if type == kindOfFileEnum.imageFileType.rawValue || type == kindOfFileEnum.videoFileType.rawValue {
                    
                    if  urlOriginalPath != String(destinyMovedFilePath.characters.dropLast()) {
                        fileName = FileNameUtils.getComposeName(fromPath: url.path)
                    }
                }
                
                //2º Check filename 
            
                if !FileNameUtils.isForbiddenCharacters(inFileName: fileName, withForbiddenCharactersSupported: ManageUsersDB.hasTheServerOfTheActiveUserForbiddenCharactersSupport()){
                    
                    //2º Copy the file to the tmp folder
                    destinyMovedFilePath = destinyMovedFilePath + fileName
                    if (destinyMovedFilePath as NSString).deletingLastPathComponent != urlOriginalPath {
                        do {
                            try FileManager.default.copyItem(atPath: url.path, toPath: destinyMovedFilePath)
                        } catch _ {
                        }
                    }
                    
                    if currentRemotePath == nil {
                        currentRemotePath = UtilsUrls.getFullRemoteServerPath(withWebDav: user)
                    }
                    
                    //3º Crete the upload objects
                    print("remotePath: \(currentRemotePath)")
                    
                    let fileLength = (try! FileManager.default.attributesOfItem(atPath: url.path))[FileAttributeKey.size] as! Int
                    print("fileLength: \(fileLength)")
                    
                    let upload = UploadsOfflineDto()
                    
                    upload.originPath = destinyMovedFilePath
                    upload.destinyFolder = currentRemotePath
                    upload.uploadFileName = fileName
                    upload.kindOfError = enumKindOfError.notAnError.rawValue
                    upload.estimateLength = fileLength
                    upload.userId = (user?.idUser)!
                    upload.status = enumUpload.generatedByDocumentProvider.rawValue
                    upload.chunksLength = Int(k_lenght_chunk)
                    upload.isNotNecessaryCheckIfExist = false
                    upload.isInternalUpload = false
                    upload.taskIdentifier = 0
                    
                    if index + 1 == self.filesSelected.count{
                        upload.isLastUploadFileOfThisArray = true
                        
                    }else{
                        upload.isLastUploadFileOfThisArray = false
                    }
                    

                    ManageUploadsDB.insertUpload(upload)
                    
                    hasSomethingToUpload = true
                    
                }else{
                    
                    var msg:String!
                    msg = NSLocalizedString("forbidden_characters_from_server", comment: "")
                
                    showAlertView(msg)
                }
            }
            
            if hasSomethingToUpload == true {
                self.cancelView()
            }
            
        } else {
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            showAlertView((NSLocalizedString("error_login_doc_provider", comment: "") as NSString).replacingOccurrences(of: "$appname", with: appName!))
        }
    }
    
    @IBAction func destinyFolderButtonTapped(_ sender: UIBarButtonItem) {
        print("destiny folder tapped")
        
        let activeUser = ManageUsersDB.getActiveUser()
        
        if activeUser != nil {
            let rootFileDto = ManageFilesDB.getRootFileDto(byUser: activeUser)
            
            let selectFolderViewController = SelectFolderViewController(nibName: "SelectFolderViewController", onFolder: rootFileDto)
            
            let navigation = SelectFolderNavigation(rootViewController: selectFolderViewController!)
            
            navigation.delegate = self
            navigation.modalPresentationStyle = UIModalPresentationStyle.formSheet
            
            selectFolderViewController?.parent = navigation;
            
            self.present(navigation, animated: true) { () -> Void in
                print("select folder presented")
                //We check the connection here because we need to accept the certificate on the self signed server
                (CheckAccessToServer.sharedManager() as? CheckAccessToServer)!.delegate = selectFolderViewController
                (CheckAccessToServer.sharedManager() as? CheckAccessToServer)!.viewControllerToShow = selectFolderViewController
                (CheckAccessToServer.sharedManager() as? CheckAccessToServer)!.isConnectionToTheServer(byUrl: activeUser!.url)
            }
        } else {
            self.showErrorLoginView()
        }
    }
    
    
    func loadFiles() {
        
        if let inputItems : [NSExtensionItem] = self.extensionContext?.inputItems as? [NSExtensionItem] {
            for item : NSExtensionItem in inputItems {
                if let attachments = item.attachments as? [NSItemProvider] {
                    
                    if attachments.isEmpty {
                        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                        return
                    }

                    for (index, current) in (attachments.enumerated()){

                        //Items
                        if current.hasItemConformingToTypeIdentifier(kUTTypeItem as String){
                            
                            current.loadItem(forTypeIdentifier: kUTTypeItem as String, options: nil, completionHandler: {(item, error) -> Void in
                                
                                if error == nil {
                                    if let url = item as? URL{
                                        
                                        print("item as url: \(item)")
                                        
                                        self.filesSelected.append(url)
                                        
                                        if index+1 == attachments.count{
                                            
                                            self.showFilesSelected()
                                        }
                                    }
                                    
                                    if let image = item as? Data{
                                        
                                        print("item as NSdata")
                                        
                                        let description = current.description
                               
                                        var fullNameArr = description.components(separatedBy: "\"")
                                        var fileExtArr = fullNameArr[1].components(separatedBy: ".")
                                        let ext = (fileExtArr[fileExtArr.count-1]).uppercased()
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                                        let fileName = "Photo_email_\(dateFormatter.string(from: Date())).\(ext)"
                                        
                                        //2º Copy the file to the tmp folder
                                        var destinyMovedFilePath = UtilsUrls.getTempFolderForUploadFiles()
                                        destinyMovedFilePath = destinyMovedFilePath! + fileName
                                        
                                        FileManager.default.createFile(atPath: destinyMovedFilePath!,contents:image, attributes:nil)
                                        
                                        let url = URL(fileURLWithPath: destinyMovedFilePath!)
                                        
                                        self.filesSelected.append(url)
                                        
                                        if index+1 == attachments.count{
                                            
                                            self.showFilesSelected()
                                        }

                                    }
                                    
                                } else {
                                    print("ERROR: \(error)")
                                }
                                
                            })
                        
                        } 
                    }
                }
            }
        }
    }
    
    
    func reloadListWithDelay(){
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { () -> Void in
            
            func reloadDatabase () {
                self.shareTable?.reloadData()
            }
            
            reloadDatabase()
        }
    }
    
    
    func showFilesSelected (){
        
        
        if self.filesSelected.count > 0{
            
            for (index, url): (Int, URL) in (self.filesSelected.enumerated()){
                
                //Check the type of the file
                
                let ext = FileNameUtils.getExtension(url.lastPathComponent)
                let type = FileNameUtils.checkTheType(ofFile: ext)
                
                print("Selecte file: \(url.path)")
                
                var image: UIImage?
                
                if type == kindOfFileEnum.imageFileType.rawValue{
                    image = UIImage(contentsOfFile: url.path)
                   
                } else if type == kindOfFileEnum.videoFileType.rawValue {
                    print("Video Selected")
                    
                    let asset = AVURLAsset (url: url, options: nil)
                    let imageGenerator = AVAssetImageGenerator (asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    let time = CMTimeMakeWithSeconds(0.0, 600)
                
                    let imageRef: CGImage!
                    do {
                        imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                    } catch _ {
                        imageRef = nil
                    }
                    image = UIImage (cgImage: imageRef)

                }
                
                if image != nil{
                    
                    image?.resize(CGSize(width: witdhImageSize, height: heighImageSize), completionHandler: { (resizedImage, data) -> () in
                        
                        self.images.append(resizedImage)
                        
                        if index+1 == self.filesSelected.count{
                            
                            self.reloadListWithDelay()
                        }
                        
                    })
                    
                }else{
                    
                    if index+1 == self.filesSelected.count{
                        
                     self.reloadListWithDelay()
                        
                    }
                }
 
            }
            
        }else{
            //Error any file selected
        }
    }
    
    //MARK: TableView Delegate and Datasource methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.filesSelected.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let identifier = "FileSelectedCell"
        let cell: FileSelectedCell! = tableView.dequeueReusableCell(withIdentifier: identifier ,for: indexPath) as! FileSelectedCell
        
        let row = indexPath.row
        let url = self.filesSelected[row] as URL
        
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
        //Choose the correct icon if the file is not an image
        let ext = FileNameUtils.getExtension(url.lastPathComponent)
        let type = FileNameUtils.checkTheType(ofFile: ext)
        
        if (type == kindOfFileEnum.imageFileType.rawValue || type == kindOfFileEnum.videoFileType.rawValue){
            //Image
            let fileName: NSString = ((url.path as NSString).lastPathComponent  as NSString);
            if row < images.count {
                cell.imageForFile?.image = images[indexPath.row];
            }
            if  !fileName.contains("Photo_email") {
                cell.title?.text = FileNameUtils.getComposeName(fromPath: url.path)
            } else {
                cell.title?.text = fileName as String
            }
        }else{
            //Not image
            let image = UIImage(named: FileNameUtils.getTheNameOfTheImagePreview(ofFileName: url.lastPathComponent))
            cell.imageForFile?.image = image
            cell.imageForFile?.backgroundColor = UIColor.white
            cell.title?.text = (url.path as NSString).lastPathComponent
        }
        

        let fileSizeInBytes = (try! FileManager.default.attributesOfItem(atPath: url.path))[FileAttributeKey.size] as? Double
        
        
        if fileSizeInBytes > 0 {
            let formattedFileSize = ByteCountFormatter.string(
                fromByteCount: Int64(fileSizeInBytes!),
                countStyle: ByteCountFormatter.CountStyle.file
            )
            cell.size?.text = "\(formattedFileSize)"
        }else{
            cell.size?.text = ""
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        print("row = %d",(indexPath as NSIndexPath).row)
    }
    
    //MARK: Select Folder Selected Delegate Methods
    
    func folderSelected(_ folder: NSString){
        
        print("Folder selected \(folder)")
        
        self.currentRemotePath = folder as String
        let name:NSString = (folder.replacingPercentEscapes(using: String.Encoding.utf8.rawValue)! as NSString);
        let user = ManageUsersDB.getActiveUser()
        let folderPath = UtilsUrls.getFilePathOnDB(byFullPath: name as String, andUser: user)

        self.changeTheDestinyFolderWith((folderPath! as NSString).lastPathComponent)
        
    }
    
    func cancelFolderSelected(){
        
        print("Cancel folder selected")
        
    }
    
    func showErrorLoginView () {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        showAlertView((NSLocalizedString("error_login_doc_provider", comment: "") as NSString).replacingOccurrences(of: "$appname", with: appName!))
    }
    
    func showAlertView(_ title: String) {
        
        let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { action in
            switch action.style{
            case .default:
                self.cancelView()
            case .cancel:
                print("cancel")
            case .destructive:
                print("destructive")
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: KKPasscodeViewControllerDelegate
    
    func didPasscodeEnteredCorrectly(_ viewController: KKPasscodeViewController!) {
        print("Did passcode entered correctly")
    }
    
   
    func didPasscodeEnteredIncorrectly(_ viewController: KKPasscodeViewController!) {
        print("Did passcode entered incorrectly")
    }

}


