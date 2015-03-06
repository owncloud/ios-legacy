//
//  BlurImageView.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 5/3/15.
//
//

import UIKit

class BlurImageView: UIImageView {
    
    //MARK:- Properties
    
    let blurEffectView: UIVisualEffectView
    
    //MARK:- Init
    
    required init(coder aDecoder: NSCoder) {
        self.blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        
        super.init(coder: aDecoder)
        self.blurEffectView.frame = bounds
        addSubview(self.blurEffectView)

    }
    
    init(blurEffectStyle: UIBlurEffectStyle) {
        self.blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: blurEffectStyle))
        
        super.init(frame: CGRectZero)
        
        self.addSubview(self.blurEffectView)
    }
    
    //MARK:- Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        blurEffectView.frame = bounds
    }
    
 

}