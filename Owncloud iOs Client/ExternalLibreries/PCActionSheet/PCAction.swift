//
//  PCAction.swift
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 16/10/2017.
//

import Foundation

//
//  PCAction.swift
//  Pods
//
//  Created by Pablo Carrascal on 28/8/17.
//
//
import Foundation

@objc public enum PCActionType:Int {
    case Destructive = 1
    case NormalAction = 2
    case Cancel = 3
}

@objc public class PCAction: NSObject {
    
    var title: String
    var type: PCActionType
    var action: (() -> Void)
    
    
    public init(title: String, type: PCActionType, action: @escaping(() -> Void)) {
        self.title = title
        self.type = type
        self.action = action
    }
    
    @objc public func triggerAction() {
        self.action()
    }
}
