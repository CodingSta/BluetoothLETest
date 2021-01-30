
import UIKit
import CoreBluetooth

class BLEListVC: UIViewController,UITableViewDataSource,UITableViewDelegate {

    var peripherals: [CBPeripheral]!
    var periDic: [Int:NSNumber]!    // peripheral's hash value

    var tableV: UITableView!
    var centralM: CBCentralManager!
    var toolBar: UIToolbar!

    weak var vc: ViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white

        self.toolBar = UIToolbar(frame: CGRect(x: 0, y: 20, width: self.view.frame.width, height: 44))
        let bItems = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeVC))]
        self.toolBar.items = bItems
        self.toolBar.barStyle = UIBarStyle.default
        self.view.addSubview(self.toolBar)

        self.tableV = UITableView(frame: CGRect(x: 0, y: 64, width: self.view.frame.width, height: self.view.frame.height-64), style: .plain)
        self.tableV.dataSource = self
        self.tableV.delegate = self
        self.tableV.register(UITableViewCell.self, forCellReuseIdentifier: "cellA")
        self.view.addSubview(self.tableV)
    }

    @objc func closeVC() {
        self.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cellA", for: indexPath)
        if let name = peripherals[indexPath.row].name {
            cell.textLabel?.text = "\(name)     - rssi: \(periDic[peripherals[indexPath.row].hash]!.stringValue)"
        } else {
            cell.textLabel?.text = "No Name"
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.vc.bleDevice = peripherals[indexPath.row]
        centralM.connect(peripherals[indexPath.row], options: nil)
        self.dismiss(animated: true) {}
    }

}


