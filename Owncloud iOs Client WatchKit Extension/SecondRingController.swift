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
    
    @IBOutlet var progressGroup: WKInterfaceGroup!
    @IBOutlet var sizeLabel: WKInterfaceLabel!
    @IBOutlet var detailLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.setTitle("ownCloud")
        self.detailLabel.setText("Free space")
        
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
        var info = [key : "GetFreeSpace"]
        
        WKInterfaceController.openParentApplication(info, reply: { (reply, error) -> Void in
            
            println("reply \(reply) error \(error)")
            if reply != nil {
                self.calculateProgress(reply as! [String: AnyObject])
                
            }
        })
        
    }
    
    func calculateProgress (watchDict : [String : AnyObject]){
        
        let totalSpace = watchDict["TotalDeviceSpace"] as! NSNumber
        let freeSpace = watchDict["FreeDeviceSpace"] as! NSNumber
        let freeSpaceString = watchDict["SpaceFreeString"] as! String
        let totalSpaceString = watchDict["SpaceTotalString"] as! String
        
        let percent = (freeSpace.floatValue * 100.0) / totalSpace.floatValue
        
        var progress: Int =  Int((percent * 30) / 100)
        
        if progress == 0{
            progress = 2
        }
        
        progressCalculated = progress
        dataCharged = true
        
        self.updateRingWithProgress(progress)
        self.updateCenterLabels(freeSpaceString, totalSize: totalSpaceString)
        
    }
    
    func updateRingWithProgress (progress : Int){
        
        self.progressGroup.setBackgroundImageNamed("outer-120-9-")
        self.progressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: 1.0, repeatCount: 1)
    }
    
    func updateCenterLabels(sizeUsed: String, totalSize: String){
        
        self.sizeLabel.setText(sizeUsed)
        
    }

}
