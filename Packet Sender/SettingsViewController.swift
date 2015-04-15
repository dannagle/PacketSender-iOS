//
//  SettingsViewController.swift
//  Packet Sender
//
//  Created by Dan Nagle on 12/6/14.
//  Copyright (c) 2014 Dan Nagle. All rights reserved.
//
// Licensed MIT: https://github.com/dannagle/PacketSender-iOS


import UIKit

class SettingsViewController: UITableViewController, UITextViewDelegate, UITextFieldDelegate {


    @IBOutlet var tcpPortEdit: UITextField?


    @IBOutlet var udpPortEdit: UITextField?

    @IBOutlet var enableServerSwitch: UISwitch?


    @IBOutlet var udpResultsLabel: UILabel!
    @IBOutlet var tcpResultsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        DLog("loading settings...")



        //[yourSwitchObject addTarget:self action:@selector(setState:) forControlEvents:UIControlEventValueChanged];

        enableServerSwitch?.addTarget(self, action: Selector("stateChanged:"), forControlEvents: UIControlEvents.ValueChanged)

        tcpPortEdit?.addTarget(self, action: Selector("textFieldDidChange:"), forControlEvents: UIControlEvents.EditingChanged)
        udpPortEdit?.addTarget(self, action: Selector("textFieldDidChange:"), forControlEvents: UIControlEvents.EditingChanged)


        doReload()
    }

    func restart() {

        Globals.psnetwork.restartServers()
        doReload()

    }

    func doReload() {

        DLog("Do reload")

        udpPortEdit?.text = String(Globals.psnetwork.getSavedUDPport())

        var l = udpPortEdit?.text.lengthOfBytesUsingEncoding(NSASCIIStringEncoding);

        if (l != nil ) {
            var i = l!
            while i < 5 {
                udpPortEdit!.text = "   " + udpPortEdit!.text
                i = i + 1
            }
        }

        tcpPortEdit?.text = String(Globals.psnetwork.getSavedTCPport())

        l = tcpPortEdit?.text.lengthOfBytesUsingEncoding(NSASCIIStringEncoding);

        if (l != nil ) {
            var i = l!
            while i < 5 {
                tcpPortEdit!.text = "   " + tcpPortEdit!.text
                i = i + 1
            }
        }


        enableServerSwitch?.setOn(Globals.psnetwork.getSavedServersOn(), animated: false)
        udpResultsLabel.text = "UDP Status: " + Globals.udpServerError
        tcpResultsLabel.text = "TCP Status: " + Globals.tcpServerError


    }

    func stateChanged(switchState: UISwitch) {
        var toggle = false
        if switchState.on {
            DLog("Is ON")
            toggle = true
        } else {
            DLog("Is Off")
            toggle = false
        }

        Globals.psnetwork.storeServersOn(toggle)
        restart()


    }

    func textFieldDidChange(textField: UITextField!) {

        //DLog("Resize tests...")


    }

    func textFieldDidEndEditing(textField: UITextField) {

        let intTest = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).toInt()
        DLog("Verification of port field: \(intTest)")
        if(intTest == nil) {
            DLog("Verification of port field FAILED")
            textField.textColor = UIColor.redColor()
        } else {
            textField.textColor = UIColor.blackColor()
        }

        let tcpInt = tcpPortEdit!.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).toInt()
        let udpInt = udpPortEdit!.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).toInt()

        if (tcpInt != nil && udpInt != nil) {

            DLog("TCP port is " + String(tcpInt!))
            DLog("UDP port is " + String(udpInt!))

            Globals.psnetwork.storeTCPPort(tcpInt!)
            Globals.psnetwork.storeUDPPort(udpInt!)
            restart()
            doReload()


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
