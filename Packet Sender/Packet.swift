//
//  Packet.swift
//  Packet Sender
//
//  Created by Dan Nagle on 12/6/14.
//  Copyright (c) 2014 Dan Nagle. All rights reserved.
//
// Licensed MIT: https://github.com/dannagle/PacketSender-iOS

import UIKit
import Foundation
import CoreData

extension Character {
    func intValue() -> Int {
        for s in String(self).utf8 {
            return Int(s)
        }
        return 0 as Int
    }
    func utf8Value() -> UInt8 {
        for s in String(self).utf8 {
            return s
        }
        return 0
    }

    func utf16Value() -> UInt16 {
        for s in String(self).utf16 {
            return s
        }
        return 0
    }

    func unicodeValue() -> UInt32 {
        for s in String(self).unicodeScalars {
            return s.value
        }
        return 0
    }
}


func DLog(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__, column: Int = __COLUMN__) {

    let fileArr = split(file) {$0 == "/"}
    let lastPart = fileArr.last
    println("\(lastPart!) : \(function) (\(line)): \(message)")
}


struct Globals {
    static var initialLoadFlag = false
    static var dataChanged = false
    static var trafficDataChanged = false
    static var timestamp = CACurrentMediaTime();
    static var psnetwork = PacketNetwork()

    static var tcpServerError = "TCP Success"
    static var udpServerError = "UDP Success"
}

struct Packet: Printable  {

    var name:String = ""
    var tcpOrUdp = "tcp"
    var fromIP = ""
    var toIP = ""
    var port = 5000
    var fromPort = 5000
    var hexString:String = ""
    var inTrafficLog:Bool = false;
    var timestamp:NSDate = NSDate()
    var error = ""


    static func parserUnitTest(ascii:String, hex:String) -> Bool {

        var hextest = Packet.asciiToHex(ascii)
        var asciitest = Packet.hexToASCII(hex)

        var pass1 = false
        var pass2 = false
        if(asciitest == ascii) {
            pass1 = true
        } else {
            DLog("fail ascii:\n" + asciitest + "\n" + ascii)
        }

        if(hextest == hex) {
            pass2 = true
        } else {
            DLog("fail hex:\n" + hextest + "\n" + hex)
        }

        return (pass1 && pass2)
    }

    static func asciiIsHex(val:Int) -> Bool {

        let zeroInt = Character("0").intValue()
        let nineInt = Character("9").intValue()
        let aInt = Character("a").intValue()
        let fInt = Character("f").intValue()
        let AInt = Character("A").intValue()
        let FInt = Character("F").intValue()

        if(val >= zeroInt && val <= nineInt) {
            return true
        }

        if(val >= aInt && val <= fInt) {
            return true
        }

        if(val >= AInt && val <= FInt) {
            return true
        }

        return false


    }


    static func asciiToHex(ascii:String) -> String {

        let length = ascii.lengthOfBytesUsingEncoding(NSASCIIStringEncoding)
        let characters = Array(ascii)
        var hexArray:[Int] = []
        var i = 0

        let slashInt = Character("\\").intValue()
        let rInt = Character("r").intValue()
        let nInt = Character("n").intValue()

        for (i = 0; i < length; i++) {
            var char1 = characters[i].intValue()
            //        hexArray.append(char1)
            //        continue
            if char1 == slashInt  && i + 1 < length{
                var char2 = characters[i+1].intValue()

                if(char2 == slashInt) {
                    hexArray.append(0x5C)
                    i++
                    continue
                }
                if(char2 == rInt) {
                    hexArray.append(0x0d)
                    i++
                    continue
                }
                if(char2 == nInt) {
                    hexArray.append(0x0a)
                    i++
                    continue
                }

                if(asciiIsHex(char2)) {
                    i++
                    var testString = ""
                    let charC2 = Character(UnicodeScalar(char2))
                    testString.append(charC2)
                    var result : UInt32 = 0
                    if(i + 1 < length) {
                        var char3 = characters[i+1].intValue()
                        if(asciiIsHex(char3)) {
                            i++

                            let charC3 = Character(UnicodeScalar(char3))
                            testString.append(charC3)
                            let scanner = NSScanner(string: testString)
                            if scanner.scanHexInt(&result) {
                                hexArray.append(Int(result))
                            }
                        } else {
                            let scanner = NSScanner(string: testString)
                            if scanner.scanHexInt(&result) {
                                hexArray.append(Int(result))
                            }
                        }
                    } else {
                        let scanner = NSScanner(string: testString)
                        if scanner.scanHexInt(&result) {
                            hexArray.append(Int(result))
                        }
                    }
                    continue
                }

            } else {
                hexArray.append(char1)
            }
        }

        var returnString:String = ""
        for hex in hexArray {
            var st = NSString(format:"%02X", hex) as String
            returnString += " " + st


        }
        //hexArray.join(" ")
        returnString = returnString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

        return returnString.lowercaseString
    }


    static func hexToASCII(hex:String) -> String {

        var result : UInt32 = 0
        var byteArray:[UInt32] = []
        let hexArray:[String] = split(hex) {$0 == " "}
        for val in hexArray {
            let scanner = NSScanner(string: val)
            if scanner.scanHexInt(&result) {
                byteArray.append(result)
            }
        }

        var resultString = ""
        for byte in byteArray {

            if(byte == 0x0A)
            {
                resultString = resultString + ("\\n");

            } else if (byte == 0x5C) {
                resultString = resultString + ("\\\\");

            } else if (byte == 0x0D) {
                resultString = resultString + ("\\r");

            } else if (byte >= 0x20 && byte <=  0x7E) {
                let char = Character(UnicodeScalar(byte))
                resultString.append(char)
            } else {
                var st = NSString(format:"%02X", byte) as String
                resultString = resultString + "\\" + st.lowercaseString

            }
        }

        return resultString
    }


    static func delete(thename:String) {
        DLog("deleting..." + thename)

        var appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        var newPacket:NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("PacketEntity", inManagedObjectContext: context) as NSManagedObject
        var request:NSFetchRequest = NSFetchRequest(entityName: "PacketEntity")
        request.returnsObjectsAsFaults = false

        var results:NSArray = context.executeFetchRequest(request, error:nil)!
        var didDel = false
        if(results.count > 0) {
            for result in results {
                var resCheck = result as NSManagedObject
                var nameTest = result.valueForKey("name") as String?
                if (nameTest != nil) {
                    if (nameTest == thename) {
                        context.deleteObject(resCheck)
                        didDel = true
                    }
                }
            }

        }
        if(didDel) {
            context.save(nil)
            Globals.dataChanged = true
            Globals.trafficDataChanged = true
        }


    }

    static func plainASCIItoHex(ascii:String) -> String  {

        let data = ascii.dataUsingEncoding(NSUTF8StringEncoding)
        if( data != nil) {
            return Packet.NSDataToHex(data!)
        } else {
            return ""
        }

    }


    static func NSDataToHex(data:NSData) -> String {

        let count = data.length / sizeof(UInt8)
        var array = [UInt8](count: count, repeatedValue: 0)
        // copy bytes into array
        data.getBytes(&array, length:count * sizeof(UInt8))

        var returnString:String = ""
        for hex in array {
            var st = NSString(format:"%02X", hex) as String
            returnString += " " + st

        }
        //hexArray.join(" ")
        returnString = returnString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).lowercaseString

        return returnString
    }

    static func fetchAllFromDBFiltered(traffic:Bool)  -> [Packet] {

        var pktArray =  fetchAllFromDB()


        var returnArray:[Packet] = []

        for pkt in pktArray {

            if(traffic && pkt.inTrafficLog) {
                returnArray.append(pkt)
            }
            if(!traffic && !pkt.inTrafficLog) {
                returnArray.append(pkt)
            }

        }

        if(traffic) {
            returnArray.sort({ ($0.timestamp.compare($1.timestamp)  == NSComparisonResult.OrderedDescending) })

        } else {

            returnArray.sort({ $0.name < $1.name })
        }



        return returnArray

    }

    func getUIImage() -> UIImage {

        var returnImage:UIImage
        if(isTCP()) {
            if(fromIP.lowercaseString != "you") {
                returnImage = UIImage(named: "rx_tcp30.png")!
            } else {
                returnImage = UIImage(named: "tx_tcp30.png")!
            }
        } else {
            if(fromIP.lowercaseString != "you") {
                returnImage = UIImage(named: "rx_udp30.png")!
            } else {
                returnImage = UIImage(named: "tx_udp30.png")!
            }

        }


        return returnImage

    }

    static func fetchAllFromDB() -> [Packet] {

        DLog("fetching...")

        var appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        var newPacket:NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("PacketEntity", inManagedObjectContext: context) as NSManagedObject
        var request:NSFetchRequest = NSFetchRequest(entityName: "PacketEntity")
        request.returnsObjectsAsFaults = false

        var results:NSArray = context.executeFetchRequest(request, error:nil)!
        var resultArray:[Packet] = []
        if(results.count > 0) {
            for result in results {
                var nameTest = result.valueForKey("name") as String?
                if (nameTest != nil) {
                    if(countElements(nameTest!) > 1) {
                        var pkt = Packet()
                        pkt.name = result.valueForKey("name") as String
                        pkt.hexString = result.valueForKey("hexString") as String
                        pkt.port = result.valueForKey("port") as Int
                        pkt.fromPort = result.valueForKey("fromPort") as Int
                        pkt.fromIP = result.valueForKey("fromIP") as String
                        pkt.tcpOrUdp = result.valueForKey("tcpOrUdp") as String
                        pkt.toIP = result.valueForKey("toIP") as String
                        pkt.inTrafficLog = result.valueForKey("inTrafficLog") as Bool
                        pkt.timestamp = result.valueForKey("timestamp") as NSDate
                        pkt.error = result.valueForKey("error") as String
                        resultArray.append(pkt)
                    }
                }
            }
        }


        resultArray.sort({ $0.name > $1.name })

        return resultArray

    }

    func save() {

        let namesize = countElements(self.name)
        if (namesize < 1) {
            DLog("Not saving")
            return
        }

        //delete if exists
        Packet.delete(name)

        var appDel:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        var newPacket:NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("PacketEntity", inManagedObjectContext: context) as NSManagedObject
        newPacket.setValue(self.name, forKey: "name")
        newPacket.setValue(self.hexString, forKey: "hexString")
        newPacket.setValue(self.port, forKey: "port")
        newPacket.setValue(self.fromIP, forKey: "fromIP")
        newPacket.setValue(self.fromPort, forKey: "fromPort")
        newPacket.setValue(self.tcpOrUdp, forKey: "tcpOrUdp")
        newPacket.setValue(self.toIP, forKey: "toIP")
        newPacket.setValue(self.inTrafficLog, forKey: "inTrafficLog")
        newPacket.setValue(self.timestamp, forKey: "timestamp")
        newPacket.setValue(self.error, forKey: "error")
        if(self.inTrafficLog) {
            Globals.trafficDataChanged = true
        } else {
            Globals.dataChanged = true
        }
        context.save(nil)
        println(newPacket)


    }

    func isTCP() -> Bool {
        if(tcpOrUdp.uppercaseString == "TCP") {
           return true;
        } else {
            return false;
        }
    }

    func isUDP() -> Bool {
        return !isTCP()
    }


    var description: String {
        return "name = \(name), toIP=\(toIP):\(port) data = \(hexString)"
    }

    var nsData: NSData {
        get {

            var mystring = ""
            var result : UInt32 = 0
            var byteArray:[Byte] = []
            let hexArray:[String] = split(hexString) {$0 == " "}
            for val in hexArray {
                let scanner = NSScanner(string: val)
                if scanner.scanHexInt(&result) {
                    byteArray.append(Byte(result & 0xFF))
                }
            }

            let data: NSData = NSData(bytes: byteArray, length: byteArray.count)
            return data
        }
    }


    var asciiString: String {
        get {
            return Packet.hexToASCII(hexString)
        }

        set {
            hexString = Packet.asciiToHex(newValue)
        }

    }

}
