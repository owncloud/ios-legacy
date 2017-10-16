//
//  PCTransitioningDelegate.swift
//  Owncloud iOs Client
//
//  Created by Pablo Carrascal on 26/09/2017.
//
//

import UIKit

@objc public class PCTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PCPresentationAnimator()
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PCDismissalAnimator()
    }
}
