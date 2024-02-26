//
//  ViewController.swift
//  BTLEDemo
//
//  Created by Lorenz Cunanan on 6/1/22.
//

import UIKit
import QuantumSDK

protocol ViewControllerProtocol {
    func btleScan(device: String!)
}

class ViewController: UIViewController, IPCDTDeviceDelegate, ViewControllerProtocol {
    
    @IBOutlet weak var connectionTextView: UITextView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var btleLabel: UILabel!
    @IBOutlet weak var btleDisconnectButton: UIButton!
    
    var btleDevices = [CBPeripheral]()
    var connectedDevice: CBPeripheral? = nil
    
    let lib = IPCDTDevices.sharedDevice()!
    
    // MARK: - VIEW DELEGATES
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        lib.addDelegate(self)
        lib.connect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lib.addDelegate(self)
        self.connectionState(lib.connstate)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        lib.removeDelegate(self)
        
    }

    // MARK: - BTLE HELPERS
    func btleScan(device: String!) {
        // is it already discovered?
        for btleDevice in self.btleDevices {
            if (btleDevice.name!.hasSuffix(device)){
                self.btleConnect(connectedDevice: btleDevice)
                return
            }
        }
        
        if (self.lib.btleConnectedDevices.count == 0)
        {
            print("BTLE Discover...")
            
            DispatchQueue.global(qos: .background).async {
                // Background Thread
                do {
                    self.btleDevices = try self.lib.btleDiscoverSupportedDevices(BLUETOOTH_FILTER.ALL.rawValue, stopOnFound: false)
                    
                    print("BTLE Discover...finished!")
                    
                    DispatchQueue.main.async {
                        // Run UI Updates or call completion block
                        for btleDevice in self.btleDevices {
                            print(btleDevice.name!)
                            if (btleDevice.name!.hasSuffix(device)){
                                self.btleConnect(connectedDevice: btleDevice)
                                return
                            }
                        }
                    }
                } catch let err as NSError {
                    print("Error: \(err.localizedDescription)")
                }
            }
        } else {
            self.showMessage("Please disconnect from previous device first", message: "")
        }
    }
    
    func btleConnect(connectedDevice: CBPeripheral) {
        do {
            if (lib.btleConnectedDevices.contains(connectedDevice))
            {
                try lib.btleDisconnect(connectedDevice)
                self.showMessage("Device Disconnected", message: connectedDevice.name!)
            } else {
                try lib.btleConnect(toDevice: connectedDevice)
                
                UserDefaults.standard.set(connectedDevice.name, forKey: "selectedBTLEDevice")
                UserDefaults.standard.set(connectedDevice.identifier.uuidString, forKey: "selectedBTLEUUID")
                
                btleDisconnectButton.isHidden = false
            }
        } catch let err as NSError {
            print("Error: \(err.localizedDescription)")
            self.showError("Bluetooth LE", error: err)
        }
        
    }
    
    func btleReconnect() {
        var uuid: UUID? = nil
            
        guard let btleUUIDStr = UserDefaults.standard.string(forKey: "selectedBTLEUUID") else {
            self.showMessage("BTLE Reconnect", message: "No device found")

            return
        }
        
        spinner.isHidden = false
        spinner.startAnimating()
            
        uuid = UUID.init(uuidString: btleUUIDStr)
        
        DispatchQueue.global(qos: .background).async {
            // Background Thread
            
            if(uuid != nil && self.lib.btleConnectedDevices.count != 0 && (self.lib.btleConnectedDevices[0].identifier.uuidString == btleUUIDStr)) {
                //we are already connected, disconnect
                try? self.lib.btleDisconnect(self.lib.btleConnectedDevices[0])
            } else {
                if(uuid != nil && self.lib.btleConnectedDevices.count == 0) {
                    DispatchQueue.main.async {
                        // Run UI Updates or call completion block
                        do {
                            let selectedDevice = try self.lib.btleGetKnownDevice(with: uuid)
                                
                            self.btleConnect(connectedDevice: selectedDevice)
                        } catch let err as NSError{
                            self.showError("BTLE Reconnect", error: err)
                        }
                            
                        self.spinner.isHidden = true
                        self.spinner.stopAnimating()
                    }
                }
            }
        }
    }
    
    func btleDisconnect() {
        do {
            let btleUUIDStr = UserDefaults.standard.string(forKey: "selectedBTLEUUID")
            var uuid: UUID? = nil
            if(btleUUIDStr != nil)
            {
                uuid = UUID.init(uuidString: btleUUIDStr!)
            }
            
            connectedDevice = try lib.btleGetKnownDevice(with: uuid)
            
            if (uuid != nil && lib.btleConnectedDevices.count != 0)
            {
                try lib.btleDisconnect(connectedDevice)
                self.showMessage("Device Disconnected", message: (connectedDevice?.name!)!)
            } else {
                self.showMessage("No Devices Connected", message: "")
            }
        } catch let err as NSError {
            print("Error: \(err.localizedDescription)")
        }
    }

    func btleDiscover() {
        if (self.lib.btleConnectedDevices.count == 0)
        {
            connectionTextView.isHidden = true
            spinner.isHidden = false
            spinner.startAnimating()
            
            print("BTLE Discover...")
            
            DispatchQueue.global(qos: .background).async {
                // Background Thread
                do {
                    self.btleDevices = try self.lib.btleDiscoverSupportedDevices(BLUETOOTH_FILTER.ALL.rawValue, stopOnFound: false)
                    
                    print("BTLE Discover...finished!")
                    
                    DispatchQueue.main.async {
                        // Run UI Updates or call completion block
                        let alert = UIAlertController.init(title: "BTLE Devices Found", message: "Choose device from list", preferredStyle: .alert)
                            
                        for device in self.btleDevices {
                            let action = UIAlertAction.init(title: device.name, style: .default) { UIAlertAction in
                                print("Connecting to \(device.name!)")
                                    
                                self.connectedDevice = device
                                    
                                self.btleConnect(connectedDevice: device)
                            }
                                
                            alert.addAction(action)
                        }
                            
                        let cancel = UIAlertAction.init(title: "Cancel", style: .cancel) { UIAlertAction in
                            print("Cancelled")
                        }
                            
                        alert.addAction(cancel)
                        self.present(alert, animated: true, completion: nil)
                        
                        self.connectionTextView.isHidden = false
                        self.spinner.isHidden = true
                        self.spinner.stopAnimating()
                    }
                } catch let err as NSError {
                    print("Error: \(err.localizedDescription)")
                }
            }
        } else {
            self.showMessage("Please disconnect from previous device first", message: "")
        }
    }
    
    func buildInfoString() -> String? {
        var initString = ""
        
        let dateFormat = DateFormatter()
        dateFormat.dateStyle = .long
        
        initString += "SDK: ver \(lib.sdkVersion/100).\(lib.sdkVersion%100) (\(dateFormat.string(from: lib.sdkBuildDate)))\n"
        
        if (lib.connstate == CONN_STATES.CONNECTED.rawValue)
        {
            initString += "\n\(lib.deviceName!) \(lib.deviceModel!) connected\nFirmware revision: \(lib.firmwareRevision!)\nHardware revision: \(lib.hardwareRevision!)\nSerial number: \(lib.serialNumber!)"
        } else {
            initString += "\nNo device connected"
        }
        
        return initString
    }
    
    func checkBTLE() {
        let btleDevice = UserDefaults.standard.string(forKey: "selectedBTLEDevice")
        
        if (UserDefaults.standard.string(forKey: "selectedBTLEUUID") == nil)
        {
            btleDisconnectButton.isHidden = true
            btleLabel.text = ""
        } else {
            btleDisconnectButton.isHidden = false
            btleLabel.text = "Previous device: \(btleDevice!)"
        }
        
        connectionTextView.text = buildInfoString()
        spinner.isHidden = true
        spinner.stopAnimating()
    }
    
    // MARK: - IPC DELEGATES
    func connectionState(_ state: Int32) {
        connectionTextView.text = buildInfoString()
        checkBTLE()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//            if(self.lib.getSupportedFeature(FEATURES.FEAT_BARCODE, error: nil) == FEAT_BARCODES.BARCODE_ZEBRA.rawValue) {
//                let motorolaInit: [UInt8] = [
//                    0xC6,0x00,0xFF,
//                    0xF0,0x2A,0x00, //Disable Decoding Illumination
////                    0xF0,0x2A,0x01, //Enable Decoding Illumination
////                    0xF1,0x9D,0x01,0x00, // Set Illumination Brightness
//                ]
//
//                do {
//                    try self.lib.barcodeZebraSetInitData(NSData(bytes: motorolaInit, length: motorolaInit.count) as Data?)
//                } catch {
//                    print("Error: \(error.localizedDescription)")
//                }
//            }
//        }
        
    }
    
    func barcodeData(_ barcode: String!, type: Int32) {
        self.showMessage("Barcode scanned", message: "\(lib.barcodeType2Text(type)!) (\(barcode.count)): \(barcode!)")
    }
    
    //MARK: - ACTIONS
    @IBAction func actionScanConnect(_ sender: Any) {
        if (lib.btleConnectedDevices.count > 0)
        {
            self.showMessage("Please disconnect from previous device first", message: "")
            return
        }
        
        let cameraVC: CameraViewController = self.storyboard?.instantiateViewController(withIdentifier: "cameraVC") as! CameraViewController
        cameraVC.delegate = self
        cameraVC.modalTransitionStyle = UIModalTransitionStyle.flipHorizontal
        cameraVC.modalPresentationStyle = .overFullScreen
        self.present(cameraVC, animated: true)
    }
    
    @IBAction func actionDiscover(_ sender: Any) {
        btleDiscover()
    }
    
    @IBAction func actionDisconnect(_ sender: Any) {
        btleDisconnect()
    }
    
    @IBAction func actionReconnect(_ sender: Any) {
        btleReconnect()
    }
    
}

