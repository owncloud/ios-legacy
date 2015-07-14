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
    @IBOutlet var sizeDetailLabel: WKInterfaceLabel!
    @IBOutlet weak var infoTable: WKInterfaceTable!


    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.setTitle("Images")
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
        
        DiskDataManager.removeImageDownloadedFiles()
        
        self.refreshData()
    }
    
    
    func getSpaceData(){
        
        let usedSpace: NSNumber = DiskDataManager.getOwnCloudUsedSpace()
        let (imageSpace, audioSpace, videoSpace, documentSpace) = DiskDataManager.getOwnCloudUsedSpaceByType()

        
        let imageSpaceString: String = DiskDataManager.memoryFormatter(imageSpace.longLongValue)
        let usedSpaceString: String = DiskDataManager.memoryFormatter(usedSpace.longLongValue)
        
        self.calculateProgress(usedSpace, imageSpace: imageSpace)
        self.updateInfoLabels(imageSpaceString, totalSize: usedSpaceString)
        
    }
    
    func calculateProgress (usedSpace: NSNumber, imageSpace: NSNumber){
        
        let imagePercent = (imageSpace.floatValue * 100.0) / usedSpace.floatValue
        var imageProgress: Int = Int((imagePercent * 30) / 100)
        self.updateRingWithProgress(imageProgress)
        
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
        
        self.progressGroup.setBackgroundImageNamed("images_ring-")
        self.progressGroup.startAnimatingWithImagesInRange(NSMakeRange(0, progress), duration: duration, repeatCount: 1)
    }
    
    func updateInfoLabels(sizeUsed: String, totalSize: String){
        
        let detail: String = "OF \(totalSize)"
        
        self.sizeLabel.setText(sizeUsed)
        self.sizeDetailLabel.setText(detail)
    
    }
    
    func loadListTable (){
        
        let (imageSpace, audioSpace, videoSpace, documentSpace) = DiskDataManager.getOwnCloudUsedSpaceByType()
        let freeSpace: NSNumber = DiskDataManager.getTotalFreeDiskSpace()
        
        infoTable.setNumberOfRows(2, withRowType: "InfoDataRow")
        
        let row1 = infoTable.rowControllerAtIndex(0) as! InfoDataRow
        
        row1.infoHeader.setText("IMAGE SPACE USED")
        row1.detailText.setText(DiskDataManager.memoryFormatter(imageSpace.longLongValue))
        
        let row2 = infoTable.rowControllerAtIndex(1) as! InfoDataRow
        
        row2.infoHeader.setText("SPACE FREE IN iPHONE")
        row2.detailText.setText(DiskDataManager.memoryFormatter(freeSpace.longLongValue))
        
    }

}
