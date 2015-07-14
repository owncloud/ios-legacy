//
//  DiskDataManager.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 9/7/15.
//
//

import UIKit

class DiskDataManager {
    
    class func isForbiddenPath(path: String) -> Bool {
        
        let forbiddenPaths:[String] = ["DB.sqlite",".DS_Store"]
        let forbiddenFolders: [String] = ["Certificates"]
        
        var forbidden: Bool = false
        
        for item in forbiddenPaths{
            
            if item == path{
                forbidden = true
                break
            }
        }
        
        for item in forbiddenFolders{
            
            if path.lowercaseString.rangeOfString(item) != nil{
                forbidden = true
                break
            }
            
        }
        
        return forbidden
        
    }
    
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
        let fileManager = NSFileManager.defaultManager()
        while let file:String = dirEnumerator.nextObject() as? String
        {
            let attributes:NSDictionary = fileManager.attributesOfItemAtPath(ownCloudPath.stringByAppendingPathComponent(file), error: nil)!
            
            if attributes.fileType() == NSFileTypeRegular && !self.isForbiddenPath(file){
               
                totalSize += attributes.fileSize()
            }
        }
    
        let totalSizeNumber: NSNumber = NSNumber(unsignedLongLong: totalSize)
        
        return totalSizeNumber
    }
    
    class func getOwnCloudUsedSpaceByType() -> (imageSpace: NSNumber, audioSpace: NSNumber, videoSpace: NSNumber, documentSpace: NSNumber){
        
        let ownCloudPath:String = UtilsUrls.getOwnCloudFilePath()
        let files : NSArray = NSFileManager.defaultManager().subpathsOfDirectoryAtPath(ownCloudPath, error: nil)!
        let dirEnumerator = files.objectEnumerator()
        var totalImageSize: UInt64 = 0
        var totalAudioSize: UInt64 = 0
        var totalVideoSize: UInt64 = 0
        var totalDocumentsSize: UInt64 = 0
        
        let fileManager = NSFileManager.defaultManager()
        while let file:String = dirEnumerator.nextObject() as? String
        {
            let attributes:NSDictionary = fileManager.attributesOfItemAtPath(ownCloudPath.stringByAppendingPathComponent(file), error: nil)!
            
            if attributes.fileType() == NSFileTypeRegular && !self.isForbiddenPath(file){
                if FileNameUtils.isImageSupportedThisFile(file.lastPathComponent){
                    totalImageSize += attributes.fileSize()
                }
                
                if FileNameUtils.isVideoFileSupportedThisFile(file.lastPathComponent){
                    totalVideoSize += attributes.fileSize()
                }
                
                if FileNameUtils.isAudioSupportedThisFile(file.lastPathComponent){
                    totalAudioSize += attributes.fileSize()
                }
                
                if FileNameUtils.isOfficeSupportedThisFile(file.lastPathComponent){
                    totalDocumentsSize += attributes.fileSize()
                }
            }
        }
        
        let imagesSize: NSNumber = NSNumber(unsignedLongLong: totalImageSize)
        let audioSize: NSNumber = NSNumber(unsignedLongLong: totalAudioSize)
        let videoSize: NSNumber = NSNumber(unsignedLongLong: totalVideoSize)
        let documentSize: NSNumber = NSNumber(unsignedLongLong: totalDocumentsSize)
        
        return (imagesSize, audioSize, videoSize, documentSize)
        
    }
    
    
    class func removeAllDownloadedFiles () {
        
        let ownCloudPath:String = UtilsUrls.getOwnCloudFilePath()
        let files : NSArray = NSFileManager.defaultManager().subpathsOfDirectoryAtPath(ownCloudPath, error: nil)!
        let dirEnumerator = files.objectEnumerator()
        let fileManager = NSFileManager.defaultManager()
        
        while let file:String = dirEnumerator.nextObject() as? String
        {
            let attributes:NSDictionary = fileManager.attributesOfItemAtPath(ownCloudPath.stringByAppendingPathComponent(file), error: nil)!
            
            if attributes.fileType() == NSFileTypeRegular && !self.isForbiddenPath(file){
                fileManager.removeItemAtPath(ownCloudPath + file, error: nil)
            }
        }
    }
    
    
    class func removeImageDownloadedFiles (){
        
        let ownCloudPath:String = UtilsUrls.getOwnCloudFilePath()
        let files : NSArray = NSFileManager.defaultManager().subpathsOfDirectoryAtPath(ownCloudPath, error: nil)!
        let dirEnumerator = files.objectEnumerator()
        let fileManager = NSFileManager.defaultManager()
        
        while let file:String = dirEnumerator.nextObject() as? String
        {
            let attributes:NSDictionary = fileManager.attributesOfItemAtPath(ownCloudPath.stringByAppendingPathComponent(file), error: nil)!
            
            if attributes.fileType() == NSFileTypeRegular && !self.isForbiddenPath(file){
                
                if FileNameUtils.isImageSupportedThisFile(file.lastPathComponent){
                    fileManager.removeItemAtPath(ownCloudPath + file, error: nil)
                }
            }
        }
        
    }
    
    class func removeMediaDownloadedFiles (){
        
        let ownCloudPath:String = UtilsUrls.getOwnCloudFilePath()
        let files : NSArray = NSFileManager.defaultManager().subpathsOfDirectoryAtPath(ownCloudPath, error: nil)!
        let dirEnumerator = files.objectEnumerator()
        let fileManager = NSFileManager.defaultManager()
        
        while let file:String = dirEnumerator.nextObject() as? String
        {
            let attributes:NSDictionary = fileManager.attributesOfItemAtPath(ownCloudPath.stringByAppendingPathComponent(file), error: nil)!
            
            if attributes.fileType() == NSFileTypeRegular && !self.isForbiddenPath(file){
                
                if FileNameUtils.isVideoFileSupportedThisFile(file.lastPathComponent) || FileNameUtils.isAudioSupportedThisFile(file.lastPathComponent){
                    fileManager.removeItemAtPath(ownCloudPath + file, error: nil)
                }
            }
        }
        
    }
    
    class func removeOtherDownloadedFiles (){
        
        let ownCloudPath:String = UtilsUrls.getOwnCloudFilePath()
        let files : NSArray = NSFileManager.defaultManager().subpathsOfDirectoryAtPath(ownCloudPath, error: nil)!
        let dirEnumerator = files.objectEnumerator()
        let fileManager = NSFileManager.defaultManager()
        
        while let file:String = dirEnumerator.nextObject() as? String
        {
            let attributes:NSDictionary = fileManager.attributesOfItemAtPath(ownCloudPath.stringByAppendingPathComponent(file), error: nil)!
            
            if attributes.fileType() == NSFileTypeRegular && !self.isForbiddenPath(file){
                
                if !FileNameUtils.isVideoFileSupportedThisFile(file.lastPathComponent) && !FileNameUtils.isAudioSupportedThisFile(file.lastPathComponent) && !FileNameUtils.isImageSupportedThisFile(file.lastPathComponent){
                    fileManager.removeItemAtPath(ownCloudPath + file, error: nil)
                }
            }
        }
        
    }
   
}
