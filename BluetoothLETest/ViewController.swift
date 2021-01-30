import UIKit
import CoreLocation
import CoreBluetooth


class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, CLLocationManagerDelegate {

    var timerA: Timer!
    let appDel = UIApplication.shared.delegate as! AppDelegate
    let serviceUUID: String = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
    let rxUUID: String = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" // Send with rxUUID WIFI SSID and PASS
    let txUUID: String = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" // Read with txUUID Sensor Data
    @IBOutlet weak var scanBTN: UIButton!
    
    var centralM: CBCentralManager!
    var peripherals = Array<CBPeripheral>()
    
    var periDic = [Int:NSNumber]()
    var periSet = Set<CBPeripheral>()
    
    var bleDevice: CBPeripheral?
    var writeChar: CBCharacteristic!
    var actV: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.actV.frame.origin = CGPoint(x:self.view.frame.width/2, y:self.view.frame.height/2)
        self.centralM = CBCentralManager(delegate: self, queue: nil)
        self.view.addSubview(actV)
        actV.isHidden = true
        
    }
    
    @IBAction func showList() {
        let listVC = BLEListVC(nibName: nil, bundle: nil)
        listVC.peripherals = self.peripherals
        listVC.periDic = self.periDic
        listVC.centralM = self.centralM
        listVC.vc = self
        self.present(listVC, animated: true)
        print("showList")
    }
        
    @IBAction func startBLEScan(_ sender: UIBarButtonItem) {
        switch centralM.state {
            case .poweredOn:
                self.periDic.removeAll()
                self.periSet.removeAll()
                self.peripherals.removeAll()
                self.view.isUserInteractionEnabled = false
                actV.isHidden = false
                // Start Scan
                //centralM.scanForPeripherals(withServices: [CBUUID(nsuuid: UUID(uuidString: serviceUUID)!)], options: nil)
                centralM.scanForPeripherals(withServices: nil, options: nil)
                
                self.actV.startAnimating()
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (timerA) in
                    self.centralM.stopScan()
                    self.actV.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                    self.peripherals = Array(self.periSet)
                    self.showList()
                }
            case .poweredOff:
                let alertA = UIAlertController(title: "알림", message: "설정에서 블루투스를 켜주세요.", preferredStyle: .alert)
                alertA.addAction(UIAlertAction(title: "확인", style: .default, handler: { (alert) in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }))
                self.present(alertA, animated: true)
                print("poweredOff")
            case .unauthorized:
                let alertA = UIAlertController(title: "알림", message: "설정에서 블루투스 사용을 허락해주세요.", preferredStyle: .alert)
                alertA.addAction(UIAlertAction(title: "확인", style: .default, handler: { (alert) in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }))
                self.present(alertA, animated: true)
                print("unauthorized")
            case .unknown:
                print("unknown")
            case .resetting:
                print("resetting")
            case .unsupported:
                print("unsupported")
            @unknown default:
                fatalError()
        }
        actV.isHidden = true
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral.name ?? "No Name")
        print(RSSI)
        if peripheral.name != nil {
            self.periSet.insert(peripheral)
            self.periDic[peripheral.hash] = RSSI
            print(peripheral.identifier)
            //print(peripheral.hash)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("Connected.")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        self.centralM.connect(self.bleDevice!)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for ser: CBService in peripheral.services! {
            print("Service : \(ser.uuid.uuidString)")
            if ser.uuid.uuidString == serviceUUID {
                peripheral.discoverCharacteristics(nil, for: ser)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for ch in service.characteristics! {
            print("Char : \(ch)")
            if ch.uuid.uuidString == txUUID {
                peripheral.setNotifyValue(true, for: ch)
            } else if ch.uuid.uuidString == rxUUID {
                self.writeChar = ch
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("\(error)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let error = error {
            print("\(error)")
        } else {
            // how many byte? -> characteristic.value
            //print(characteristic.value ?? "characterstic value is nil")
            if let value = characteristic.value {
                var str = String(data: value, encoding: String.Encoding.utf8)
                str = str != nil ? str:"nil"
                print(str!)
                print("\r\n")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("centralManagerDidUpdateState - power on")
        case .poweredOff:
            let alertA = UIAlertController(title: "알림", message: "설정에서 블루투스를 켜주세요.", preferredStyle: .alert)
            alertA.addAction(UIAlertAction(title: "확인", style: .default, handler: { (alert) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            self.present(alertA, animated: true) {
            }
        case .resetting:
            print("resetting")
        case .unauthorized:
            print("unauthorized")
        case .unsupported:
            print("unsupported")
        case .unknown:
            print("unknown")
        @unknown default:
            fatalError()
        }
    }
    
}



/*
 
 
 @IBAction func editProfile(_ sender: Any) {
     
     if centralM.state == .poweredOn && bleDevice != nil {
 
     } else if centralM.state == .poweredOff {
         let alertA = UIAlertController(title: "알림", message: "설정에서 블루투스를 켜주세요.", preferredStyle: .alert)
         alertA.addAction(UIAlertAction(title: "확인", style: .default, handler: { (alert) in
             UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
         }))
         self.present(alertA, animated: true)
     } else if bleDevice == nil {
         let alertA = UIAlertController(title: "알림", message: "장치와 블루투스 연결을 해주세요.", preferredStyle: .alert)
         alertA.addAction(UIAlertAction(title: "확인", style: .default, handler: { (alert) in
         }))
         self.present(alertA, animated: true)
     }
 }
 
 
 if str!.hasPrefix("H") {            // Humidity
//                    appDel.humidity = (String(str!.split(separator: ":")[1]) as NSString).floatValue
 } else if str!.hasPrefix("Te") {    // Temperature
//                    appDel.temperature = (String(str!.split(separator: ":")[1]) as NSString).floatValue
//                    self.dataArr[3] = String(format: "%.2f", (String(str!.split(separator: ":")[1]) as NSString).floatValue)
 } else if str!.hasPrefix("P") {     // Pressure
//                    appDel.pressure = (String(str!.split(separator: ":")[1]) as NSString).floatValue
 } else if str!.hasPrefix("Tap") {   // Step
 }

 
 */
