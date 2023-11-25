//
//  PhotoInfoViewController.swift
//  Alblog
//
//  Created by Sato Masayuki on 2021/11/05.
//

import UIKit
import Photos

class PhotoInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var infoArray = [(title: String, content: String)]()
    let ud = UserDefaults.standard
    let imageManager = PHImageManager()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        let id = ud.integer(forKey: "photoID_value")
        let element = photoAssets.filter { $0.index == id }.first!
        if let date = element.asset.creationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            let dateInfo = (NSLocalizedString("Date", comment: ""), formatter.string(from: date))
            infoArray.append(dateInfo)
        }
        let pixelInfo = (NSLocalizedString("Image Size", comment: ""), "\(element.asset.pixelWidth)×\(element.asset.pixelHeight)")
        infoArray.append(pixelInfo)
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        element.asset.requestContentEditingInput(with: options) { input, info in
            if let url = input?.fullSizeImageURL {
                do {
                    let data = try Data(contentsOf: url)
                    let formatter = ByteCountFormatter()
                    formatter.allowedUnits = [.useKB]
                    formatter.countStyle = .file
                    let sizeInfo = (NSLocalizedString("Data Size", comment: ""), "\(formatter.string(fromByteCount: Int64(data.count)))")
                    self.infoArray.append(sizeInfo)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                } catch {
                    print("Error")
                }
            }
        }
        self.view.backgroundColor = .systemGray6
        self.tableView.backgroundColor = .systemGray6
    }
   
    static func fromStoryboard(_ storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)) -> PhotoInfoViewController {
        let controller = storyboard.instantiateViewController(withIdentifier: "PhotoInfoViewController") as! PhotoInfoViewController
        return controller
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .clear
        if let label = cell.viewWithTag(1) as? UILabel {
            label.backgroundColor = .clear
            label.text = "\(infoArray[indexPath.row].title): \(infoArray[indexPath.row].content)"
        }
        return cell
    }
}
