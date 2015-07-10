//
//  RootRingController.swift
//  Owncloud iOs Client WatchKit Extension
//
//  Created by Gonzalo Gonzalez on 8/7/15.
//
//

import WatchKit
import Foundation

class RootRingController: WKInterfaceController {
    
    let key:String = "RequestKey"

    @IBOutlet var progressGroup: WKInterfaceGroup!
    @IBOutlet var sizeLabel: WKInterfaceLabel!


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.setTitle("Used space")
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
        let usedSpace: NSNumber = DiskDataManager.getOwnCloudUsedSpace()
        let spaceUsedString: String = DiskDataManager.memoryFormatter(usedSpace.longLongValue)
        
        
        var watchDict:[String: AnyObject] = ["TotalDeviceSpace":totalDiskSpace, "SpaceUsed":usedSpace, "SpaceUsedString": spaceUsedString, "SpaceTotalString": "500MB"]
        
        self.calculateProgress(watchDict)
  
        
    }
    
    func calculateProgress (watchDict : [String : AnyObject]){
        
        let usedSpace = watchDict["SpaceUsed"] as! NSNumber
        let totalSpace = watchDict["TotalDeviceSpace"] as! NSNumber
        let usedSpaceString = watchDict["SpaceUsedString"] as! String
        let totalSpaceString = watchDict["SpaceTotalString"] as! String
        
        println("\(usedSpaceString)")
    
        let percent = (usedSpace.floatValue * 100.0) / totalSpace.floatValue
        
        var progress: Int = Int((percent * 30) / 100)
        
        if progress <= 5 {
            progress = 5
        }
        

        self.updateRingWithProgress(progress)
        self.updateCenterLabels(usedSpaceString, totalSize: totalSpaceString)
        
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
        
        self.progressGroup.setBackgroundImageNamed("used_disk-")
        self.progressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: duration, repeatCount: 1)
    }
    
    func updateCenterLabels(sizeUsed: String, totalSize: String){
        
        self.sizeLabel.setText(sizeUsed)
    
    }




}
