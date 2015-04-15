//
//  PacketNetwork.swift
//  Packet Sender
//
//  Created by Dan Nagle on 12/20/14.
//  Copyright (c) 2014 Dan Nagle. All rights reserved.
//
// Licensed MIT: https://github.com/dannagle/PacketSender-iOS


import Foundation
import CFNetwork
import CoreFoundation
import QuartzCore


class PacketNetwork: NSObject, Printable   {

    var udpSocket:GCDAsyncUdpSocket!
    var tcpSocket:GCDAsyncSocket!
    var connectedSockets:NSMutableArray

    //var uSocket = GCDAsyncUdpSocket(self, delegateQueue: dispatch_get_main_queue())

    override init() {
        DLog("Packe Network Init")
        connectedSockets = NSMutableArray(capacity: 1)
        super.init()

        //udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())

        //enableServerSwitch?.addTarget(self, action: Selector("stateChanged:"), forControlEvents: UIControlEvents.ValueChanged)

        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())

        let serversOn = getSavedServersOn()

        if(serversOn) {


            startServers()



        } else {

            stopServers()

        }




    }
    func getIFAddresses() -> [String] {
        var addresses = [String]()

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {

            // For each interface ...
            for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory

                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {

                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                                if let address = String.fromCString(hostname) {
                                    addresses.append(address)
                                }
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return addresses
    }

    func restartServers() {

        stopServers()
        startServers()
    }


    func stopServers() {

        udpSocket.setDelegate(nil, delegateQueue: dispatch_get_main_queue())
        udpSocket.close()
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())


        tcpSocket.setDelegate(nil, delegateQueue: dispatch_get_main_queue())
        tcpSocket.disconnect()
        tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())

    }

    func startServers() {

        var error: NSError?

        let tcpPort = UInt16(getSavedTCPport())
        let udpPort = UInt16(getSavedUDPport())


        if (udpSocket.bindToPort(udpPort, error: &error)) {
            DLog("UDP Port success. It is " + String(udpSocket.localPort()))
            if(udpSocket.beginReceiving(&error)) {
                DLog("Server started!")
                Globals.udpServerError = "Binded to \(udpSocket.localPort())"
            } else {
                DLog("NOT RECEIVING!")
                Globals.udpServerError = "Not receiving"
            }
        } else {
            DLog("Port failed. Attempted \(udpPort). Got " + String(udpSocket.localPort()))
            DLog(error!.localizedDescription)
            Globals.udpServerError =  error!.localizedDescription

        }

        if(tcpSocket.acceptOnPort(tcpPort, error: &error)) {
            DLog("TCP Port success. It is " + String(tcpSocket.localPort))
            Globals.tcpServerError = "Binded to \(tcpSocket.localPort)"

        } else {
            DLog("Port failed. Attempted \(tcpPort). It is " + String(tcpSocket.localPort))
            DLog(error!.localizedDescription)
            Globals.tcpServerError = error!.localizedDescription


        }



    }

    func storeServersOn(serversOn:Bool) {

        var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(serversOn, forKey: "serversOn")
        defaults.synchronize()

    }


    func getSavedServersOn() -> Bool {

        var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let serversOn = defaults.objectForKey("serversOn") as? Bool {
            if serversOn {
                return true
            } else {
                return false
            }
        } else {
            return true
        }

    }


    func storeUDPPort(udpPort:Int) {

        var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(udpPort, forKey: "udpPort")
        defaults.synchronize()

    }

    func storeTCPPort(tcpPort:Int) {

        var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(tcpPort, forKey: "tcpPort")
        defaults.synchronize()
    }



    func getSavedUDPport() -> Int {

        var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let tcpInt = defaults.objectForKey("udpPort") as? Int {

            if (tcpInt >= 0 && tcpInt < 65000) {
                return tcpInt
            }
        }
        return 55056;
    }


    func getSavedTCPport() -> Int {

        var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let udpPort = defaults.objectForKey("tcpPort") as? Int {

            if (udpPort >= 0 && udpPort < 65000) {
                return udpPort
            }
        }
        return 55056;
    }

    func start() {
        DLog("Starting...")
    }


    func saveTrafficPacket(pkt:Packet) {

        saveTrafficData(pkt.nsData, fromIP:pkt.fromIP, fromPort:pkt.fromPort, toIP:pkt.toIP, toPort:pkt.port, tcpOrUdp:pkt.tcpOrUdp);

    }

    func saveTrafficData(data:NSData, fromIP:String, fromPort:Int, toIP:String, toPort:Int, tcpOrUdp:String) {

        var pkt = Packet()
        pkt.tcpOrUdp = tcpOrUdp
        pkt.hexString = Packet.NSDataToHex(data)
        DLog("Data from \(fromIP), port \(fromPort) : \(pkt.asciiString)")

        let date = NSDate()
        let timestamp = date.timeIntervalSince1970
        var t:CFTimeInterval = CACurrentMediaTime() - Globals.timestamp;
        pkt.inTrafficLog = true
        pkt.name = String(t.description) + timestamp.description
        pkt.timestamp = NSDate()

        pkt.fromIP = fromIP;
        pkt.port = toPort;
        pkt.fromPort = fromPort;
        pkt.toIP = toIP;

        pkt.save()
        Globals.trafficDataChanged = true

    }


    func send(message:String){
        let data = message.dataUsingEncoding(NSUTF8StringEncoding)
        udpSocket.sendData(data, toHost: "localhost", port: 55056, withTimeout: 2, tag: 0)
        saveTrafficData(data!, fromIP: "You", fromPort: Int(udpSocket.localPort()),
            toIP: "localhost", toPort: 55056, tcpOrUdp:"udp")
    }




    func sendPacket(inout pkt:Packet) {
        DLog("Sending " + pkt.name)


        if(pkt.isUDP()) {
            udpSocket.sendData(pkt.nsData, toHost: pkt.toIP, port: UInt16(pkt.port), withTimeout: 200, tag: 0)
            pkt.fromIP = "You"
            pkt.fromPort = Int(udpSocket.localPort())
            saveTrafficPacket(pkt)

        } else {

            var inputStream: NSInputStream?
            var outputStream: NSOutputStream?

            let data = pkt.nsData
            NSStream.getStreamsToHostWithName(pkt.toIP, port: pkt.port, inputStream: &inputStream, outputStream: &outputStream)

            outputStream!.open()
            inputStream!.open()


            let startTime = NSDate()

            while (outputStream?.streamStatus == NSStreamStatus.Opening) {
                var timeCompare = startTime.dateByAddingTimeInterval(5)

                if (timeCompare.compare(NSDate()) == NSComparisonResult.OrderedAscending) {
                    DLog("Failed to open socket...")
                    break;

                }

                //DLog("Wait while opening...")
            }

            switch(outputStream!.streamStatus) {
            case NSStreamStatus.NotOpen :
                DLog("NotOpen")
            case NSStreamStatus.Opening :
                DLog("Opening")
                pkt.error = "Connection timeout."
            case NSStreamStatus.Open :
                DLog("Open")
            case NSStreamStatus.Reading :
                DLog("Reading")
            case NSStreamStatus.Writing :
                DLog("Writing")
            case NSStreamStatus.AtEnd :
                DLog("AtEnd")
            case NSStreamStatus.Closed :
                DLog("Closed")
            case NSStreamStatus.Error :
                DLog("Error")
                pkt.error = "Connection error, likely refused."

            }

            pkt.fromIP = "You"
            pkt.fromPort = Int(tcpSocket.localPort)


            if(outputStream?.streamStatus == NSStreamStatus.Open) {
                DLog("Successfully opened. Send data")
                outputStream!.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)

                outputStream!.close()
            } else {
                DLog("Did not open. Probably an error...")

                //TODO: need to report meaningful errors.


                if(pkt.error.isEmpty) {
                    pkt.error = "Send Error"
                }

            }
            if(inputStream?.streamStatus == NSStreamStatus.Open) {
                inputStream!.close()
            }

            saveTrafficPacket(pkt)


        }

    }

    func connectTestUDP() {

        let mystring = "Write this UDP!"
        let data: NSData = mystring.dataUsingEncoding(NSUTF8StringEncoding)!
        var mySocket:GCDAsyncUdpSocket = GCDAsyncUdpSocket()
        mySocket.sendData(data, toHost: "192.168.1.92", port: 55056, withTimeout: 200, tag: 0)

    }


    func socket (socketDidDisconnect: GCDAsyncSocket!, error withError: NSError!) {
        DLog("Disconnected socket")
        connectedSockets.removeObject(socketDidDisconnect)
    }


    //- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket;
    func socket (socket : GCDAsyncSocket!, didAcceptNewSocket newSocket:GCDAsyncSocket!) {

        DLog("Connected Sock count is \(connectedSockets.count)")
        DLog("Got sock from \(newSocket.connectedHost), port \(newSocket.connectedPort)")
        newSocket.setDelegate(self, delegateQueue: dispatch_get_main_queue())
        newSocket.readDataWithTimeout(-1, tag: 0)

        connectedSockets.addObject(newSocket)
        DLog("Connected Sock count is \(connectedSockets.count)")



    }

    // receiver device
    // - (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag;
    func socket(socket: GCDAsyncSocket!, didReadPartialDataOfLength partialLength: Int, withTag tag: Int) {
        DLog("Got partial")

    }

    func socket(socket : GCDAsyncSocket, didReadData data:NSData, withTag tag:UInt16)
    {
        var pkt = Packet()
        pkt.hexString = Packet.NSDataToHex(data)
        DLog("Data from \(socket.connectedHost), port \(socket.connectedPort) : \(pkt.asciiString)")

        pkt.fromIP = socket.connectedHost
        pkt.port = Int(socket.localPort)
        pkt.fromPort = Int(socket.connectedPort)
        pkt.toIP = "You"
        saveTrafficPacket(pkt)

    }



    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {

        var host: NSString?
        var port1: UInt16 = 0
        GCDAsyncUdpSocket.getHost(&host, port: &port1, fromAddress: address)
        DLog("Packet From \(host!)")

        saveTrafficData(data!, fromIP: host! as String, fromPort: Int(port1), toIP: "You", toPort: Int(sock.localPort()), tcpOrUdp: "udp")


    }



    func udpSocket(sock: GCDAsyncUdpSocket!, didNotConnect error: NSError!) {
        DLog("yes")
        DLog(error!.localizedDescription)
    }

    func udpSocket(sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!) {
        DLog("yes")
        DLog(error!.localizedDescription)

    }

    func udpSocket(sock: GCDAsyncUdpSocket!, didSendDataWithTag tag: Int) {
        DLog("sent packet")
    }

    func udpSocketDidClose(sock: GCDAsyncUdpSocket!, withError error: NSError!) {
        DLog("yes")
    }



    func connectTestTCP() {
        var inputStream: NSInputStream?
        var outputStream: NSOutputStream?

        DLog("attempting connect")
        NSStream.getStreamsToHostWithName("192.168.1.92", port: 55056, inputStream: &inputStream, outputStream: &outputStream)
        DLog("Did I connect?")

        let mystring = "Write this TCP!"
        outputStream!.open()
        inputStream!.open()
        let data: NSData = mystring.dataUsingEncoding(NSUTF8StringEncoding)!
        DLog("Did I write?")
        outputStream!.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
        outputStream!.close()
        inputStream!.close()
        DLog("Did I close?")
    }


    override var description: String {
        return "packetnetwork boom"
    }

}
