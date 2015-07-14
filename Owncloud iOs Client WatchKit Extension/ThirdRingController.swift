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
    @IBOutlet var sizeDetailLabel: WKInterfaceLabel!
       @IBOutlet weak var infoTable: WKInterfaceTable!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.setTitle("Other")
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        self.refreshData()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func refreshData(){
        
        self.getSpaceData()
        self.loadListTable()
    }
    
    @IBAction func touchClearCacheButton(sender: AnyObject){
        
        DiskDataManager.removeOtherDownloadedFiles()
        
        self.refreshData()
    }
    
    func getSpaceData(){
        
        let usedSpace: NSNumber = DiskDataManager.getOwnCloudUsedSpace()
        let (imageSpace, audioSpace, videoSpace, documentSpace) = DiskDataManager.getOwnCloudUsedSpaceByType()
        let mediaSpace = NSNumber(unsignedLongLong: audioSpace.unsignedLongLongValue + videoSpace.unsignedLongLongValue)
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
        
        var progress = progress
        
        if progress > 0 && progress < 5{
            progress = 5
        }
        
        if progress == 0{
            progress = 1
        }
        
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
        
        let detail: String = "OF \(totalSize)"
        
        self.sizeLabel.setText(sizeUsed)
        self.sizeDetailLabel.setText(detail)
        
    }
    
    func loadListTable (){
        
        let (imageSpace, audioSpace, videoSpace, documentSpace) = DiskDataManager.getOwnCloudUsedSpaceByType()
        let usedSpace: NSNumber = DiskDataManager.getOwnCloudUsedSpace()
        let freeSpace: NSNumber = DiskDataManager.getTotalFreeDiskSpace()
        let mediaSpace = NSNumber(unsignedLongLong: audioSpace.unsignedLongLongValue + videoSpace.unsignedLongLongValue)
        let otherSpace = NSNumber(float: usedSpace.floatValue - (imageSpace.floatValue + mediaSpace.floatValue + documentSpace.floatValue))
        
        infoTable.setNumberOfRows(3, withRowType: "InfoDataRow")
        
        let row1 = infoTable.rowControllerAtIndex(0) as! InfoDataRow
        
        row1.infoHeader.setText("DOCUMENTS SPACE USED")
        row1.detailText.setText(DiskDataManager.memoryFormatter(documentSpace.longLongValue))
        
        let row2 = infoTable.rowControllerAtIndex(1) as! InfoDataRow
        
        row2.infoHeader.setText("OTHER SPACE USED")
        row2.detailText.setText(DiskDataManager.memoryFormatter(otherSpace.longLongValue))
        
        
        let row3 = infoTable.rowControllerAtIndex(2) as! InfoDataRow
        
        row3.infoHeader.setText("SPACE FREE IN iPHONE")
        row3.detailText.setText(DiskDataManager.memoryFormatter(freeSpace.longLongValue))
        
    }



}
