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
    var filesSelected: [NSURL] = []
   //@IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var numberOfImages: UILabel?
    

    override func viewDidLoad() {
        
        self.createBarButtonsOfNavigationBar()
        
         self.shareTable!.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
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
                    
                    for current: NSItemProvider in attachments{
                       
                        if current.hasItemConformingToTypeIdentifier(kUTTypeImage as String){
                            
                            current.loadItemForTypeIdentifier(kUTTypeImage, options: nil, completionHandler: {(item: NSSecureCoding!, error: NSError!) -> Void in
                               
                                if error == nil {
                                    
                                    let url = item as NSURL
                    
                                    self.filesSelected.append(url)
                                    
                                    self.printFileSelected()
                                    
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
                
            }
            
            self.numberOfImages?.text = "Did you select: \(self.filesSelected.count) images"
            
            self.shareTable?.reloadData()
            
        }
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
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        
        let url = self.filesSelected[indexPath.row] as NSURL
        
        cell.textLabel?.text = url.path
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
