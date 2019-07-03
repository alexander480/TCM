//
//  ViewController.swift
//  The Connected Mailbox - Mark 8 -
//
//  Created by Alexander Lester on 12/29/16.
//  Copyright © 2016 LAGB.tech. All rights reserved.
//

import UIKit
import CoreBluetooth

var rxData = [String]()
var rxReadable = [String]()

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate
{
    var lastInqSent = String()
    
    //              //
    //    Labels    //
    //              //
    
    @IBOutlet weak var soc: UILabel!
    
    @IBOutlet weak var ma: UILabel!
    @IBOutlet weak var lux: UILabel!
    
    @IBOutlet weak var hr: UILabel!
    @IBOutlet weak var mn: UILabel!
    
    @IBOutlet weak var mth: UILabel!
    @IBOutlet weak var day: UILabel!
    
    //               //
    //    Buttons    //
    //               //
    
    @IBAction func mainButton(_ sender: Any)
    {
        self.central = CBCentralManager(delegate: self, queue: nil) // Start Bluetooth Setup
    }
    
    //                   //
    //   View Did Load   //
    //                   //
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    //                              //
    //  Bluetooth Setup Begins Here //
    //                              //
    
    let serviceID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")  // Service UUID
    
    let txID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")       // Characteristic UUID
    let rxID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")       // Characteristic UUID
    
    var central : CBCentralManager!
    var peripheral : CBPeripheral!
    
    var service : CBService! = nil
    
    var txChar : CBCharacteristic! = nil // txChar Placeholder
    var rxChar : CBCharacteristic! = nil // rxChar Placeholder
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        let serviceIDs = [serviceID]
        
        switch central.state
        {
        case .poweredOn:
            soc.text = "Scanning For Peripherals..."
            print("Bluetooth On")
            print("Scanning For Peripherals...")
            
            central.scanForPeripherals(withServices: serviceIDs, options: nil)
            
        case .poweredOff:
            soc.text = "Please Turn Bluetooth On"
            print("* Bluetooth Powered Off *")
            
        default:
            soc.text = "Unknown Bluetooth Error"
            print("* Bluetooth Could Not Be Powered On *")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        soc.text = "Attempting To Connect..."
        print("Attempting To Connect...")
        
        if peripheral.name == "TCM"
        {
            soc.text = "Found Device Named TCM"
            print("Found Device Named: TCM")
            self.central.stopScan()
            
            self.peripheral = peripheral
            self.peripheral.delegate = self
            
            self.central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheralRef: CBPeripheral)
    {
        soc.text = "Peripheral Connected!"
        print("Peripheral Connected!")
        
        self.peripheral.delegate = self // Peripheral Delegate = This View Controller
        
        central.stopScan() // Stop Searching For Peripherals
        
        peripheral.discoverServices(nil) // Discover Connected Peripheral's Services
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        soc.text = "Connection Failed"
        print("* Connection Failed *")
        print("* Retrying *")
        
        self.central = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    //                         //
    //  Did Discover Services  //
    //                         //
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        if let firstService = peripheral.services?[0] // If Services Are Available & Valid
        {
            soc.text = "Services Discovered!"
            peripheral.discoverCharacteristics(nil, for: firstService) // Discover Characteristics For First Service
        }
        else
        {
            soc.text = "No Services Discovered"
            print("* No Services Discovered *")
        }
    }
    
    
    //                                //
    //  Did Discover Characteristics  //
    //                                //
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        if let characteristics = service.characteristics // service.characteristics = characteristics
        {
            for characteristic in characteristics // Do This For All Characteristics
            {
                if characteristic.uuid == txID
                {
                    soc.text = "TX Characteristic Found!"
                    print("TX Characteristic Found!")
                    txChar = characteristic // txChar = Characteristic With TX UUID // txChar is a Global Variable
                }
                    
                else if characteristic.uuid == rxID
                {
                    soc.text = "RX Characteristic Found!"
                    print("RX Characteristic Found!")
                    rxChar = characteristic // rxChar = Characteristic With RX UUID // rxChar is a Global Variable
                    
                    self.peripheral.setNotifyValue(true, for: rxChar)
                }
            }
            
            sendInq()
        }
    }
    
    
    //                    //
    //  Did Update Value  //
    //                    //
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        soc.text = "RX Value Updated"
        
        let readable = String(bytes: rxChar.value!, encoding: String.Encoding.utf8)
        
        rxData.append(readable)
        
        print("RX Value Updated")
        
        for data in rxData
        {
            let readableData = String(bytes: data, encoding: String.Encoding.utf8)
            
            rxReadable.append(readableData!)
            print(rxReadable)
        }
    }
    
    
    //                    //
    //  Custom Functions  //
    //                    //

    func sendInq()
    {
        soc.text = "Sending Inquiry"
        
        let inq1 = "1"
        let inqData1 = inq1.data(using: String.Encoding.utf8)!
        peripheral.writeValue(inqData1, for: txChar, type: .withoutResponse)
        
        let inq2 = "2"
        let inqData2 = inq2.data(using: String.Encoding.utf8)!
        peripheral.writeValue(inqData2, for: txChar, type: .withoutResponse)
/*
        let inq3 = "3"
        let inqData3 = inq3.data(using: String.Encoding.utf8)!
        peripheral.writeValue(inqData3, for: txChar, type: .withoutResponse)
        
        let inq4 = "4"
        let inqData4 = inq4.data(using: String.Encoding.utf8)!
        peripheral.writeValue(inqData4, for: txChar, type: .withoutResponse)
        
        let inq5 = "5"
        let inqData5 = inq5.data(using: String.Encoding.utf8)!
        peripheral.writeValue(inqData5, for: txChar, type: .withoutResponse)
        
        let inq6 = "6"
        let inqData6 = inq6.data(using: String.Encoding.utf8)!
        peripheral.writeValue(inqData6, for: txChar, type: .withoutResponse)
*/
    }
    
    
    //                //
    //  Disconnected  //
    //                //
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        soc.text = "Peripheral Disconnected"
        print("* Peripheral Disconnected *")
    }
}
