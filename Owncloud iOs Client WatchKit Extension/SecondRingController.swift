//
//  SecondRingController.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 8/7/15.
//
//

import WatchKit
import Foundation


class SecondRingController: WKInterfaceController {

    let key = "RequestKey"
    var dataCharged: Bool = false
    var progressCalculated: Int = 1
    
    @IBOutlet var progressImage: WKInterfaceImage!
  
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.getSpaceDataFromTheCoreApp()
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if dataCharged && progressCalculated > 0{
            self.updateRingWithProgress(progressCalculated)
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func getSpaceDataFromTheCoreApp() {
        var info = [key : "GetSplitOccupiedSpace"]
        
        WKInterfaceController.openParentApplication(info, reply: { (reply, error) -> Void in
            
            println("reply \(reply) error \(error)")
            if reply != nil {
                self.calculateProgress(reply as! [String: AnyObject])
                
            }
        })
        
    }
    
    func calculateProgress (watchDict : [String : AnyObject]){
        
        let occupiedSpace = watchDict["SpaceOcuppied"] as! NSNumber
        let totalSpace = watchDict["TotalDeviceSpace"] as! NSNumber
        
        let percent = (occupiedSpace.floatValue * 100.0) / totalSpace.floatValue
        
        var progress: Int =  Int((percent * 30) / 100)
        
        if progress == 0{
            progress = 1
        }
        
        progressCalculated = progress
        dataCharged = true
        
        self.updateRingWithProgress(progress)
        
    }
    
    func updateRingWithProgress (progress : Int){
        
        self.progressImage.setImageNamed("outer-120-9-")
        self.progressImage.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: 1.0, repeatCount: 1)
    }

}
