//
//  DiskDataManager.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 9/7/15.
//
//

import UIKit

class DiskDataManager {
    
    class func memoryFormatter(diskSpace: Int64) -> String {
        
        var formatter = NSByteCountFormatter()

        formatter.allowedUnits = NSByteCountFormatterUnits.UseDefault
        formatter.countStyle = NSByteCountFormatterCountStyle.Decimal
        formatter.includesUnit = true
        
        return formatter.stringFromByteCount(diskSpace) as String
    }
    
   class func getTotalDiskSpace() -> NSNumber{
       
        let systemAttributes = NSFileManager.defaultManager().attributesOfFileSystemForPath(NSHomeDirectory() as String, error: nil)
        let space = (systemAttributes?[NSFileSystemSize] as? NSNumber)?.longLongValue
        
        let totalSpace: NSNumber = NSNumber(longLong: space!)
        
        return totalSpace
       
    }
    
    class func getTotalFreeDiskSpace() -> NSNumber{
        
        let systemAttributes = NSFileManager.defaultManager().attributesOfFileSystemForPath(NSHomeDirectory() as String, error: nil)
        let freeSpace = (systemAttributes?[NSFileSystemFreeSize] as? NSNumber)?.longLongValue
        
        let totalFreeSpace: NSNumber = NSNumber(longLong: freeSpace!)
        
        return totalFreeSpace
    }
    
    class func getOwnCloudUsedSpace() -> NSNumber{
        
        let ownCloudPath:String = UtilsUrls.getOwnCloudFilePath()
        let files : NSArray = NSFileManager.defaultManager().subpathsOfDirectoryAtPath(ownCloudPath, error: nil)!
        let dirEnumerator = files.objectEnumerator()
        var totalSize: UInt64 = 0
        let fileManager = NSFileManager.defaultManager();
        while let file:String = dirEnumerator.nextObject() as? String
        {
            let attributes:NSDictionary = fileManager.attributesOfItemAtPath(ownCloudPath.stringByAppendingPathComponent(file), error: nil)!
            totalSize += attributes.fileSize();
        }
    
        let totalSizeNumber: NSNumber = NSNumber(unsignedLongLong: totalSize)
        
        return totalSizeNumber
    }
    
 
   
}
