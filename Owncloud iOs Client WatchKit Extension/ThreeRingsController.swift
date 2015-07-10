//
//  ThreeRingsController.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/7/15.
//
//

import WatchKit
import Foundation

class ThreeRingsController: WKInterfaceController {
    
    @IBOutlet var outProgressGroup: WKInterfaceGroup!
    @IBOutlet var middleProgressGroup: WKInterfaceGroup!
    @IBOutlet var innerProgressGroup: WKInterfaceGroup!
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    
        self.setTitle("ownCloud")
        
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
        
        
        self.calculateProgress(usedSpace, imageSpace: imageSpace, mediaSpace: mediaSpace, otherSpace: otherSpace)
        
        
    }
    
    func calculateProgress (usedSpace: NSNumber, imageSpace: NSNumber, mediaSpace: NSNumber, otherSpace: NSNumber){
        
        let imagePercent = (imageSpace.floatValue * 100.0) / usedSpace.floatValue
        let mediaPercent = (mediaSpace.floatValue * 100.0) / usedSpace.floatValue
        let otherPercent = (otherSpace.floatValue * 100.0) / usedSpace.floatValue
        
        var imageProgress: Int = Int((imagePercent * 30) / 100)
        var mediaProgress: Int = Int((mediaPercent * 30) / 100)
        var otherProgress: Int = Int((otherPercent * 30) / 100)
        
        self.updateOutRingWithProgress(imageProgress)
        self.updateMiddleRingWithProgress(mediaProgress)
        self.updateInnerRingWithProgress(otherProgress)
        
    }
    
    func updateOutRingWithProgress (progress : Int){
        
        var progress = progress
        
        if progress > 0 && progress < 5{
            progress = 5
        }
        
        var duration: NSTimeInterval = 1.0
        
        if progress <= 10{
            
            duration = 0.25
            
        }else if progress > 11 || progress <= 20{
            
            duration = 0.5
        }else{
            
            duration = 1.0
        }
        
        outProgressGroup.setBackgroundImageNamed("out_kind_ring-")
        outProgressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: duration, repeatCount: 1)
        
    }
    
    func updateMiddleRingWithProgress (progress : Int){
        
        var progress = progress
        
        if progress > 0 && progress < 5{
            progress = 5
        }
        
        var duration: NSTimeInterval = 1.0
        
        if progress <= 10{
            
            duration = 0.25
            
        }else if progress > 11 || progress <= 20{
            
            duration = 0.5
        }else{
            
            duration = 1.0
        }
        
        middleProgressGroup.setBackgroundImageNamed("middle_kind_ring-")
        middleProgressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: duration, repeatCount: 1)
    }
    
    func updateInnerRingWithProgress (progress : Int){
        
        var progress = progress
        
        if progress > 0 && progress < 5{
            progress = 5
        }
        
        var duration: NSTimeInterval = 1.0
        
        if progress <= 10{
            
            duration = 0.25
            
        }else if progress > 11 || progress <= 20{
            
            duration = 0.5
        }else{
            
            duration = 1.0
        }
        
        innerProgressGroup.setBackgroundImageNamed("inner_kind_ring-")
        innerProgressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: duration, repeatCount: 1)
    }

}
