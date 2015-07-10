//
//  ThirdRingController.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/7/15.
//
//

import WatchKit
import Foundation

class ThirdRingController: WKInterfaceController {
    
    @IBOutlet var progressGroup: WKInterfaceGroup!
    @IBOutlet var sizeLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.setTitle("Other")
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
        
        let usedSpace: NSNumber = DiskDataManager.getOwnCloudUsedSpace()
        let (imageSpace, mediaSpace) = DiskDataManager.getOwnCloudUsedSpaceByType()
        let otherSpace = NSNumber(float: usedSpace.floatValue - (imageSpace.floatValue + mediaSpace.floatValue))
        
        let otherSpaceString: String = DiskDataManager.memoryFormatter(otherSpace.longLongValue)
        let usedSpaceString: String = DiskDataManager.memoryFormatter(usedSpace.longLongValue)
        
        self.calculateProgress(usedSpace, otherSpace: otherSpace)
        self.updateInfoLabels(otherSpaceString, totalSize: usedSpaceString)
        
    }
    
    func calculateProgress (usedSpace: NSNumber, otherSpace: NSNumber){
        
        let otherPercent = (otherSpace.floatValue * 100.0) / usedSpace.floatValue
        var otherProgress: Int = Int((otherPercent * 30) / 100)
        self.updateRingWithProgress(otherProgress)
        
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
        
        self.progressGroup.setBackgroundImageNamed("other_ring-")
        self.progressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: duration, repeatCount: 1)
    }
    
    func updateInfoLabels(sizeUsed: String, totalSize: String){
        
        self.sizeLabel.setText(sizeUsed)
        
    }


}
