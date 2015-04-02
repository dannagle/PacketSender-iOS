//
//  PacketCell.swift
//  Packet Sender
//
//  Created by Dan Nagle on 1/29/15.
//  Copyright (c) 2015 Dan Nagle. All rights reserved.
//


import Foundation
import UIKit

class PacketCell: UITableViewCell {
    
    @IBOutlet weak var pktLabel: UILabel!
    @IBOutlet weak var pktImage: UIImageView!
    
    @IBOutlet weak var detailsLabel: UILabel!
    func forceCompile() -> Bool {
        return true;
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
