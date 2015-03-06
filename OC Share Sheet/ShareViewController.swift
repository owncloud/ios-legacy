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

class ShareViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var shareTable: UITableView?
    @IBOutlet weak var numberOfImages: UILabel?
    
    var filesSelected: [NSURL] = []
    var images: [UIImage] = []
   
    
    let customRowColor = UIColor(red: 29/255.0, green: 45/255.0, blue: 68/255.0, alpha: 1.0)
    let customRowBorderColor = UIColor.whiteColor()
    

    override func viewDidLoad() {
        
        self.createBarButtonsOfNavigationBar()
        
         self.shareTable!.registerClass(FileSelectedCell.self, forCellReuseIdentifier: "cell")
        
        let blurEffect = UIBlurEffect(style: .Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        self.shareTable?.backgroundView = blurEffectView
        
        //if you want translucent vibrant table view separator lines
        //self.shareTable?.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        
        self.loadImages()
        
    }
    
    func loadImages() {
        
        if let inputItems : [NSExtensionItem] = self.extensionContext?.inputItems as? [NSExtensionItem] {
            for item : NSExtensionItem in inputItems {
                if let attachments = item.attachments as? [NSItemProvider] {
                    
                    if attachments.isEmpty {
                        self.extensionContext?.completeRequestReturningItems(nil, completionHandler: nil)
                        return
                    }
                    
                    for (index, current) in (enumerate(attachments)){
                        
                    
                        
                        if current.hasItemConformingToTypeIdentifier(kUTTypeImage as String){
                            
                            current.loadItemForTypeIdentifier(kUTTypeImage, options: nil, completionHandler: {(item: NSSecureCoding!, error: NSError!) -> Void in
                                
                                if error == nil {
                                    
                                    let url = item as NSURL
                                    
                                    self.filesSelected.append(url)
                                    
                                    if index+1 == attachments.count{
                                        
                                        self.printFileSelected()
                                    }
                                    
                                    // let imageData = NSData(contentsOfURL: url)
                                    
                                    //   dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    //self.imageView.image = UIImage(data: imageData!)
                                    //self.numberOfImages?.text = "Did you select: \(inputItems.count) images"
                                    
                                    //   })
                                    
                                } else {
                                    println("ERROR: \(error)")
                                }
                                
                            })
                            
                        }else if current.hasItemConformingToTypeIdentifier(kUTTypeAudiovisualContent as String){
                            
                            current.loadItemForTypeIdentifier(kUTTypeAudiovisualContent, options: nil, completionHandler: {(item: NSSecureCoding!, error: NSError!) -> Void in
                                
                                if error == nil {
                                    
                                    // self.numberOfImages?.text = "Did you select: \(inputItems.count) videos"
                                    
                                }
                            })
                        }
 
                    }

                }
            }
        }
    
    
        
    }
    
    
    func printFileSelected (){
        
        if self.filesSelected.count > 0{
            
            for url : NSURL in self.filesSelected{
                
                println("Selecte file: \(url.path)")
                
                let imageData = NSData(contentsOfURL: url)
                
                let image = UIImage(data: imageData!)
                //338, 140
               // let size: CGSize = CGSize(width: 338, height: 140)
                
              //  let imgResiz: UIImage = self.imageResize(image!, sizeChange: size)
                
                self.images.append(image!)
                
                
            }
            
            self.numberOfImages?.text = "Did you select: \(self.filesSelected.count) images"
 
            self.shareTable?.reloadData()
            
        }
    }
    
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    
    func createBarButtonsOfNavigationBar(){
        
        let rightBarButton = UIBarButtonItem (title:"Done", style: .Plain, target: self, action:"cancelView:")
        let leftBarButton = UIBarButtonItem (title:"Cancel", style: .Plain, target: self, action:"cancelView:")
        let navigationItem = UINavigationItem (title: "ownCloud")
        
        navigationItem.leftBarButtonItem = leftBarButton
        navigationItem.rightBarButtonItem = rightBarButton
        navigationItem.hidesBackButton = true
        
        self.navigationBar?.pushNavigationItem(navigationItem, animated: false)
        
    }
    
    
    func cancelView((barButtonItem: UIBarButtonItem) ) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            //TODO: Delete here the temporal cache files if needed
        })
    }
    
    
    
   
    
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
        
        if row <= images.count{
            cell.imageForFile?.image = images[indexPath.row];
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

}
