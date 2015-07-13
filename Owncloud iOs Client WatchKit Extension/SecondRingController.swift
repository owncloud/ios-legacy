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
    @IBOutlet var sizeDetailLabel: WKInterfaceLabel!
    @IBOutlet weak var infoTable: WKInterfaceTable!
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.setTitle("Media")
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
        
        DiskDataManager.removeMediaDownloadedFiles()
        
        self.refreshData()
    }
    
    func getSpaceData(){
        
        let usedSpace: NSNumber = DiskDataManager.getOwnCloudUsedSpace()
        let (imageSpace, audioSpace, videoSpace) = DiskDataManager.getOwnCloudUsedSpaceByType()
        
        let mediaSpace = NSNumber(unsignedLongLong: audioSpace.unsignedLongLongValue + videoSpace.unsignedLongLongValue)
        
        let mediaSpaceString: String = DiskDataManager.memoryFormatter(mediaSpace.longLongValue)
        let usedSpaceString: String = DiskDataManager.memoryFormatter(usedSpace.longLongValue)
        
        self.calculateProgress(usedSpace, mediaSpace: mediaSpace)
        self.updateInfoLabels(mediaSpaceString, totalSize: usedSpaceString)
        
    }
    
    func calculateProgress (usedSpace: NSNumber, mediaSpace: NSNumber){
        
        let mediaPercent = (mediaSpace.floatValue * 100.0) / usedSpace.floatValue
        var mediaProgress: Int = Int((mediaPercent * 30) / 100)
        self.updateRingWithProgress(mediaProgress)
        
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
        
        self.progressGroup.setBackgroundImageNamed("media_ring-")
        self.progressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: duration, repeatCount: 1)
    }
    
    func updateInfoLabels(sizeUsed: String, totalSize: String){
        
        let detail: String = "OF \(totalSize)"
        
        self.sizeLabel.setText(sizeUsed)
        self.sizeDetailLabel.setText(detail)
        
    }
    
    func loadListTable (){
        
        let (imageSpace, audioSpace, videoSpace) = DiskDataManager.getOwnCloudUsedSpaceByType()
        let freeSpace: NSNumber = DiskDataManager.getTotalFreeDiskSpace()
        
        infoTable.setNumberOfRows(3, withRowType: "InfoDataRow")
        
        let row1 = infoTable.rowControllerAtIndex(0) as! InfoDataRow
        
        row1.infoHeader.setText("VIDEO SPACE USED")
        row1.detailText.setText(DiskDataManager.memoryFormatter(videoSpace.longLongValue))
        
        let row2 = infoTable.rowControllerAtIndex(1) as! InfoDataRow
        
        row2.infoHeader.setText("MUSIC SPACE USED")
        row2.detailText.setText(DiskDataManager.memoryFormatter(audioSpace.longLongValue))

        
        let row3 = infoTable.rowControllerAtIndex(2) as! InfoDataRow
        
        row3.infoHeader.setText("SPACE FREE IN iPHONE")
        row3.detailText.setText(DiskDataManager.memoryFormatter(freeSpace.longLongValue))
        
    }


}
