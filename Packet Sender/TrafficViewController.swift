//
//  TrafficViewController.swift
//  Packet Sender
//
//  Created by Dan Nagle on 12/6/14.
//  Copyright (c) 2014 Dan Nagle. All rights reserved.
//
// Licensed MIT: https://github.com/dannagle/PacketSender-iOS

import UIKit




//TODO: need to report errors.

class TrafficViewController: UITableViewController  {

    var pktArray = Packet.fetchAllFromDBFiltered(true)


    @IBAction func clearBtnClick() {
        DLog("Clear clicked")
        for pkt in pktArray {
            Packet.delete(pkt.name)
        }
        pktArray.removeAll(keepCapacity: false)
        self.tableView.reloadData()

    }


    @IBAction func saveBtnClick() {
        DLog("Save clicked")

        var indexPath = self.tableView.indexPathForSelectedRow() //get index of data for selected row

        if(indexPath == nil) {
            return;
        }
        let packetDetail = pktArray[indexPath!.item]

        var inputTextField: UITextField?
        let savePrompt = UIAlertController(title: "Save packet", message: "Name for the new packet.", preferredStyle: UIAlertControllerStyle.Alert)

        savePrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        savePrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Now do whatever you want with inputTextField (remember to unwrap the optional)

            let newname = inputTextField?.text


            if(newname != nil) {
                DLog("Need to save \(packetDetail) as \(newname!)")
                var savePacket = Packet()
                savePacket.hexString = packetDetail.hexString

                if (packetDetail.fromIP.lowercaseString == "you" || packetDetail.fromIP == "127.0.0.1"
                    || packetDetail.fromIP == "::1" || packetDetail.fromIP == "localhost"  )
                {
                    DLog("No swap")
                    savePacket.toIP = packetDetail.toIP
                    savePacket.port = packetDetail.port

                } else {

                    DLog("Do swap")
                    savePacket.toIP = packetDetail.fromIP
                    savePacket.port = packetDetail.fromPort

                }

                savePacket.name = newname!
                savePacket.tcpOrUdp = packetDetail.tcpOrUdp
                savePacket.inTrafficLog = false
                savePacket.save()

            } else {
                DLog("Cancel save")
            }

        }))
        savePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Packet Name"
            inputTextField = textField
        })

        presentViewController(savePrompt, animated: true, completion: nil);




    }


    override func viewDidLoad() {
        super.viewDidLoad()
        DLog("Traffic size is " + String(pktArray.count))

        // Do any additional setup after loading the view.
        var timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("timerTimeout"), userInfo: nil, repeats: true)

    }


    func timerTimeout() {

        if(Globals.trafficDataChanged) {
            DLog("Reloaded table")
            pktArray = Packet.fetchAllFromDBFiltered(true)
            Globals.trafficDataChanged = false
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table Headers and Footers

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Log"
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return pktArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> TrafficViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tablepktReuseID", forIndexPath: indexPath) as! TrafficViewCell

        // Configure the cell...
        //[ImageViewName setImage:[UIImage imageNamed: @"ImageName.png"]];

        cell.customImage.image = pktArray[indexPath.row].getUIImage()
        cell.customSubLabel?.text = pktArray[indexPath.row].hexString
        cell.customLabel?.text = pktArray[indexPath.row].asciiString
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        if(cell.customRightLabel != nil) {

            var str = ""

            if (pktArray[indexPath.row].isTCP()) {
                //str = "TCP: "
            } else {
                //str = "UDP: "
            }

            str = str + "\(pktArray[indexPath.row].fromIP):\(pktArray[indexPath.row].fromPort) -> "
            str = str + "\(pktArray[indexPath.row].toIP):\(pktArray[indexPath.row].port) "
            str = str + dateFormatter.stringFromDate(pktArray[indexPath.row].timestamp)

            cell.customRightLabel!.text!  = str  //"yyyy-MM-dd'T'HH:mm:ss.SSS"
        }


        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {
            // Delete the row from the data source
            DLog("Attempting delete")
            Packet.delete(pktArray[indexPath.row].name)
            pktArray = Packet.fetchAllFromDBFiltered(true)
            DLog("Did delete work?")

            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        } else if editingStyle == .Insert {

            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view

        }

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
