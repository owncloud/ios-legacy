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

    @IBOutlet var progressGroup: WKInterfaceGroup!
    @IBOutlet var sizeLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.setTitle("Free space")
  
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        self.getSpaceData()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func getSpaceData(){
        
        let totalDiskSpace: NSNumber = DiskDataManager.getTotalDiskSpace()
        let freeSpace: NSNumber = DiskDataManager.getTotalFreeDiskSpace()
        let freeSpaceString = DiskDataManager.memoryFormatter(freeSpace.longLongValue)
        
        var watchDict:[String: AnyObject] = ["TotalDeviceSpace":totalDiskSpace, "FreeDeviceSpace":freeSpace, "SpaceFreeString": freeSpaceString, "SpaceTotalString": "500MB"]
        
        self.calculateProgress(watchDict)
        
    }
    
    
    func calculateProgress (watchDict : [String : AnyObject]){
        
        let totalSpace = watchDict["TotalDeviceSpace"] as! NSNumber
        let freeSpace = watchDict["FreeDeviceSpace"] as! NSNumber
        let freeSpaceString = watchDict["SpaceFreeString"] as! String
        let totalSpaceString = watchDict["SpaceTotalString"] as! String
        
        let percent = (freeSpace.floatValue * 100.0) / totalSpace.floatValue
        
        var progress: Int =  Int((percent * 30) / 100)
        
        if progress <= 5 {
            progress = 5
        }
        

        self.updateRingWithProgress(progress)
        self.updateCenterLabels(freeSpaceString, totalSize: totalSpaceString)
        
    }
    
    func updateRingWithProgress (progress : Int){
        
        var duration: NSTimeInterval = 1.0
        
        if progress <= 10{
            
            duration = 0.25
            
        }else if progress > 11 || progress <= 20{
            
            duration = 0.5
        }else{
            
            duration = 1.0
        }
        
        self.progressGroup.setBackgroundImageNamed("free_disk-")
        self.progressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: duration, repeatCount: 1)
    }
    
    func updateCenterLabels(sizeUsed: String, totalSize: String){
        
        self.sizeLabel.setText(sizeUsed)
        
    }

}
