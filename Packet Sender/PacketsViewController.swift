//
//  PacketsViewController.swift
//  Packet Sender
//
//  Created by Dan Nagle on 12/6/14.
//  Copyright (c) 2014 Dan Nagle. All rights reserved.
//
// Licensed MIT: https://github.com/dannagle/PacketSender-iOS


import UIKit
import CoreData

class PacketsViewController: UITableViewController, GCDAsyncUdpSocketDelegate {

    var pktArray = Packet.fetchAllFromDBFiltered(false)


    @IBAction func addBtnClick() {
        DLog("Add clicked")

        performSegueWithIdentifier("PacketDetailNewSegue",sender: self)


    }


    override func viewDidLoad() {
        super.viewDidLoad()

        let hex1 = "73 0d 20 69 0a 73 20 66 72 6f 6d 20 70 04 61 63 5c 6b 65 74"
        let ascii1 = "s\\r i\\ns from p\\04ac\\\\ket"

        Packet.parserUnitTest(ascii1, hex: hex1)

        let hex2 = "6e 61 6d 20 3d 20 2c 20 64 61 74 61 20 3d 20 99 88 aa cc"
        let ascii2 = "nam = , data = \\99\\88\\aa\\cc"

        Packet.parserUnitTest(ascii2, hex: hex2)

        let ascii3 = "test f\\rro\\nm s\\88imulator"
        let hex3 = "74 65 73 74 20 66 0d 72 6f 0a 6d 20 73 88 69 6d 75 6c 61 74 6f 72"

        Packet.parserUnitTest(ascii3, hex: hex3)

        //force load of PacketNetwork
        Globals.psnetwork.start()


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.

        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        let myIPAddress = Globals.psnetwork.getIFAddresses()

        var myIP = "Unknown"
        if (myIPAddress.count > 0) {
            myIP = myIPAddress.first!
        }

        self.view.makeToast(message: "IP Address", duration: 3, position: HRToastPositionCenter, title: myIP)



    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false);
        if(Globals.dataChanged) {
            pktArray = Packet.fetchAllFromDBFiltered(false)
            self.tableView.reloadData()
            Globals.dataChanged = false
            DLog("Reloaded table")
        } else {
            DLog("Did not reload")
        }

    }




    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table Headers and Footers

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Packets"
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

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> PacketCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("pktReuseID", forIndexPath: indexPath) as PacketCell

        pktArray[indexPath.row].fromIP = "You"

        cell.pktLabel.text  = pktArray[indexPath.row].name
        cell.detailsLabel.text = " to " + (pktArray[indexPath.row].toIP) + ":" + String(pktArray[indexPath.row].port)
        cell.pktImage.image = pktArray[indexPath.row].getUIImage()

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
            pktArray = Packet.fetchAllFromDBFiltered(false)
            DLog("Did delete work?")

            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        } else if editingStyle == .Insert {

            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view

        }

    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */

    // MARK: - Navigation




    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
        if (segue.identifier == "packetNewSegue") {

            DLog("Load the New Packet Details");

            //            var vc:PacketDetailViewController = segue.destinationViewController as PacketDetailViewController

            var vc:PacketDetailsController = segue.destinationViewController as PacketDetailsController

            vc.packetDetail = Packet()
/*
            vc.packetDetail.toIP = "192.168.1.92"
            vc.packetDetail.port = 55056
            vc.packetDetail.hexString = "74 65 73 74 20 66 0d 72 6f 0a 6d 20 73 88 69 6d 75 6c 61 74 6f 72"
*/

        } else if (segue.identifier == "packetShowSegue") {
            // pass data to next view
            DLog("Load the Packet Details");

            var indexPath = self.tableView.indexPathForSelectedRow() //get index of data for selected row
            var vc:PacketDetailsController = segue.destinationViewController as PacketDetailsController
            vc.packetDetail = pktArray[indexPath!.item]


        } else {
            DLog("ID unknown or nil");
        }

    }

}
