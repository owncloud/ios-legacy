//
//  Managers.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/3/15.
//
//

import UIKit

class Managers: NSObject {
    
    //MARK: FMDataBase
    
   class func sharedDatabase()->FMDatabaseQueue{
        
        var sharedDatabase: FMDatabaseQueue?
        
        let path = UtilsUrls.getOwnCloudFilePath().stringByAppendingPathComponent("DB.sqlite")
        
        if NSFileManager.defaultManager().fileExistsAtPath(path){
            
            if sharedDatabase == nil{
                
                let documentsDir = UtilsUrls.getOwnCloudFilePath()
                let dbPath = documentsDir.stringByAppendingPathComponent("DB.sqlite")
                
                sharedDatabase = FMDatabaseQueue(path: dbPath)
                
            }
            
        }
        
        return sharedDatabase!
    }

    
}


