//
//  ShareLinkHeaderCell.swift
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 4/8/15.
//
//

import UIKit

class ShareLinkHeaderCell:UITableViewCell {
    
    let switchCornerRadious: CGFloat = 17.0
    
    @IBOutlet weak var titleSection: UILabel!
    @IBOutlet weak var switchSection: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    private func setup(){
        
        switchSection.backgroundColor = UIColor.whiteColor()
        switchSection.layer.cornerRadius = switchCornerRadious
        
        self.backgroundColor = UIColor.colorOfNavigationBar()
        titleSection.textColor = UIColor.whiteColor()
    }
    
}