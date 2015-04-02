//
//  PacketDetailsController.swift
//  Packet Sender
//
//  Created by Dan Nagle on 1/29/15.
//  Copyright (c) 2015 Dan Nagle. All rights reserved.
//
// Licensed MIT: https://github.com/dannagle/PacketSender-iOS


import Foundation

import UIKit
import QuartzCore

class PacketDetailsController: UITableViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var nameEdit: UITextField!
    @IBOutlet weak var ipEdit: UITextField!
    @IBOutlet weak var portEdit: UITextField!
    @IBOutlet weak var tcpOrUdpSwitch: UISegmentedControl!
    @IBOutlet weak var asciiTextView: UITextView!
    @IBOutlet weak var hexTextView: UITextView!

    var packetDetail:Packet = Packet();


    //TODO: put back in the edit hooks to auto-translate the hex/ascii changes!


    @IBAction func saveBtnClick() {
        DLog("Save clicked")

        var pkt = buildPacket()
        pkt.save()

        //[self.navigationController popViewControllerAnimated:TRUE];

        self.navigationController?.popViewControllerAnimated(true)


    }

    @IBAction func sendBtnClick() {
        DLog("Send clicked")

        var pkt = buildPacket()
        DLog("Need to send " + pkt.description)
        Globals.psnetwork.sendPacket(&pkt)

        var msgBuild = pkt.tcpOrUdp.uppercaseString + " "
        msgBuild = msgBuild + pkt.toIP + ":" + String(pkt.port)

        if(pkt.error.isEmpty) {
            self.view.makeToast(message: msgBuild, duration: 2, position: HRToastPositionCenter, title: "Sent")
        } else {
            self.view.makeToast(message: pkt.error, duration: 4, position: HRToastPositionCenter, title: "Error")
        }



    }




    func buildPacket() -> Packet {

        var pkt = Packet()
        pkt.name = nameEdit!.text
        pkt.toIP = ipEdit!.text
        let intTest = portEdit!.text.toInt()
        if(intTest == nil) {
            pkt.port = 1
        } else {
            pkt.port = intTest!
        }

        pkt.hexString = hexTextView!.text

        if(tcpOrUdpSwitch?.selectedSegmentIndex == 0) {
            pkt.tcpOrUdp = "tcp"
        } else {
            pkt.tcpOrUdp = "udp"
        }


        return pkt
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        DLog("loaded packet...")

        // Do any additional setup after loading the view.
        DLog("Loaded Packet Details")
        nameEdit.text = packetDetail.name
        ipEdit.text = packetDetail.toIP
        portEdit.text = String(packetDetail.port)
        hexTextView.text = packetDetail.hexString
        asciiTextView.text = packetDetail.asciiString

        if(packetDetail.isTCP()) {
            tcpOrUdpSwitch.selectedSegmentIndex = 0;
        } else {
            tcpOrUdpSwitch.selectedSegmentIndex = 1;
        }


    }




    func textViewDidChange(textView: UITextView!) { //Handle the text changes

        if(textView.restorationIdentifier! != "hexEditID") {
            textViewDidEndEditing(textView)
        }

    }

    func textFieldDidEndEditing(textField: UITextField!) {

        if(textField.restorationIdentifier! == "nameID") {
            DLog("Verification of name field")
        }
        if(textField.restorationIdentifier! == "ipID") {
            DLog("Verification of ip field")
        }
        if(textField.restorationIdentifier! == "portID") {
            DLog("Verification of port field")

            let intTest = portEdit!.text.toInt()
            if(intTest == nil) {
                DLog("Verification of port field FAILED")
                portEdit?.textColor = UIColor.redColor()
            } else {
                portEdit?.textColor = UIColor.blackColor()
            }
        }
    }

    func textViewDidEndEditing(textView: UITextView!) {

        if(textView.restorationIdentifier! == "hexEditID") {
            DLog("Text Changed Finished Hex")
            asciiTextView.text = Packet.hexToASCII(textView.text)
            hexTextView.text = Packet.asciiToHex(asciiTextView.text)

        } else {
            DLog("Text Changed Finished Ascii")

            hexTextView.text = Packet.asciiToHex(textView.text)

        }
    }





    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false);
        DLog("Reloaded table")

    }



}
