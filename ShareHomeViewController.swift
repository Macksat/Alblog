//
//  ShareHomeViewController.swift
//  ShareHomeViewController
//
//  Created by Sato Masayuki on 2021/09/25.
//

import UIKit
import Firebase
import FirebaseFirestore

class ShareHomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var predictTableView = UITableView()
    var predictArray = [String]()
    var contentIDArray: [String: Any] = ["id": 0]
    var titleArray = ["For You", "Hot", "Recent"]
    let firestore = Firestore.firestore()

    @IBOutlet weak var accountButton: UIBarButtonItem!
    @IBAction func accountButton(_ sender: Any) {
        performSegue(withIdentifier: "goAccount", sender: nil)
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ContentTableViewCell", bundle: nil), forCellReuseIdentifier: "ContentTableViewCell")
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if contentIDArray.count != 0 {
            predictTableView.register(UITableViewCell.self, forCellReuseIdentifier: "predictCell")
            predictTableView.delegate = self
            predictTableView.dataSource = self
            predictTableView.backgroundColor = .systemGray6
            predictTableView.layer.cornerRadius = 10
            predictTableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            self.view.addSubview(predictTableView)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        if predictArray.count != 0 {
            predictTableView.removeFromSuperview()
        }
        self.viewDidLoad()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == predictTableView {
            return predictArray.count
        } else {
            return titleArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == self.tableView {
            guard let cell = cell as? ContentTableViewCell else { fatalError() }
            cell.setCollectionDelegateDataSource(dataSourceDelegate: self, forRow: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == predictTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "predictCell", for: indexPath)
            cell.textLabel?.text = predictArray[indexPath.row]
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            cell.backgroundColor = .systemGray6
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContentTableViewCell", for: indexPath) as? ContentTableViewCell else { fatalError() }
            cell.setUpContents(string: titleArray[indexPath.row])
            cell.moreButton.tag = indexPath.row
            cell.moreButton.addTarget(self, action: #selector(moreButtonAction(sender:)), for: .touchUpInside)
            if indexPath.row == titleArray.count - 1 {
                cell.moreButton.removeFromSuperview()
            }
            return cell
        }
    }
    
    @objc func moreButtonAction(sender: UIButton) {
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView == predictTableView {
            searchBar.text = predictArray[indexPath.row]
            predictArray.removeAll()
            predictTableView.removeFromSuperview()
            searchBar.resignFirstResponder()
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension ShareHomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contentIDArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else { fatalError() }
        let photos = firestore.collection("photos").document("url")
        photos.getDocument(completion: { (url, error) in
            if let photo = url, ((url?.exists) != nil) {
                let dataDescription = photo.data().map(String.init(describing:)) ?? "nil"
                print(dataDescription)
            }
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
