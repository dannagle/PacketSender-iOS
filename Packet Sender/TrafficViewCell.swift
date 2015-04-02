//
//  TrafficViewCell.swift
//  Packet Sender
//
//  Created by Dan Nagle on 12/30/14.
//  Copyright (c) 2014 Dan Nagle. All rights reserved.
//
// Licensed MIT: https://github.com/dannagle/PacketSender-iOS

import Foundation
import UIKit

class TrafficViewCell: UITableViewCell {

    @IBOutlet weak var customSubLabel: UILabel!
    @IBOutlet weak var customLabel: UILabel!
    @IBOutlet weak var customRightLabel: UILabel!

    @IBOutlet weak var customImage: UIImageView!


    func forceCompile() -> Bool {
        return true;
    }

    @IBOutlet var cellLabel:UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
