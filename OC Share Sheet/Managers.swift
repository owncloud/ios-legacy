//
//  Managers.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 10/3/15.
//

/*
Copyright (C) 2015, ownCloud, Inc.
This code is covered by the GNU Public License Version 3.
For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
You should have received a copy of this license
along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*/

import UIKit

class Managers: NSObject {
    
    class var sharedDatabase: FMDatabaseQueue {
        struct Static {
            static var sharedDatabase: FMDatabaseQueue?
            static var tokenDatabase: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.tokenDatabase) {
            Static.sharedDatabase = FMDatabaseQueue()
            
            let documentsDir = UtilsUrls.getOwnCloudFilePath()
            let dbPath = documentsDir.stringByAppendingPathComponent("DB.sqlite")
            Static.sharedDatabase = FMDatabaseQueue(path: dbPath)
            
        }
        
        return Static.sharedDatabase!
    }
    
    //MARK: FMDataBase
    
    /*class func sharedDatabase()->FMDatabaseQueue{
        
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
    }*/
    
       //MARK: OCCommunication
    
    class func sharedOCCommunication() -> OCCommunication{
        
        var communication: OCCommunication?
        
        if communication == nil{
            
            communication = OCCommunication()
            
        }
        
        return communication!
        
    }

  
    
}






