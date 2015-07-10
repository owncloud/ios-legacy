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
        
        self.updateOutRingWithProgress(20)
        self.updateMiddleRingWithProgress(21)
        self.updateInnerRingWithProgress(23)
        
        self.setTitle("ownCloud")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
  
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateOutRingWithProgress (progress : Int){
        
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
