//
//  CreateCustomAlbumViewController.swift
//  CreateCustomAlbumViewController
//
//  Created by Sato Masayuki on 2021/09/07.
//

import UIKit
import RealmSwift
import Photos

var selectedPhotos = [Int]()
var selectedTags = [String]()

class CreateCustomAlbumViewController: UIViewController, UISearchBarDelegate,  UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    let realm = try! Realm()
    let ud = UserDefaults.standard
    var photoArray = [Int]()
    var indexArray = [Int]()
    var tagArray = [String]()
    var tableView = UITableView()
    var predictArray = [String]()
    var imageManager = PHImageManager()

    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBAction func nextButton(_ sender: Any) {
        let index = (self.navigationController?.viewControllers.count)!
        if ((self.navigationController?.viewControllers[index - 2] as? CreateTagAlbumViewController) != nil) == true {
            performSegue(withIdentifier: "goAddCustomInfo", sender: nil)
        } else {
            performSegue(withIdentifier: "addPhotos-Check", sender: nil)
        }
    }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchBar.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (self.view.frame.width-60)/3, height: (self.view.frame.width)*2/7)
        layout.minimumLineSpacing = -20
        layout.minimumInteritemSpacing = 1
        collectionView.collectionViewLayout = layout
        
        for i in photoAssets {
            photoArray.append(i.index)
        }
        let orderedSet = NSOrderedSet(array: photoArray)
        photoArray = orderedSet.array as! [Int]
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        buttonBool()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        indexArray.removeAll()
        collectionView.reloadData()
    }
    
    @objc func tapFunc() {
        if predictArray.count != 0 {
            tableView.removeFromSuperview()
        }
        searchBar.resignFirstResponder()
    }
    
    func buttonBool() {
        if selectedPhotos.count == 0 {
            nextButton.isEnabled = false
        } else {
            nextButton.isEnabled = true
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: tableView)) {
            return false
        }
        return true
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        tagArray.removeAll()
        selectedTags.removeAll()
        photoArray.removeAll()
        self.viewDidLoad()
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.collectionView.reloadData()
            self.tagCollectionView.reloadData()
        }, completion: nil)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        predictArray.removeAll()
        if predictArray.count != 0 {
            tableView.removeFromSuperview()
        }
        let tags = realm.objects(Tag.self)
        for i in tags {
            if i.tag.uppercased().contains(searchBar.text!.uppercased()) == true {
                predictArray.append(i.tag)
            }
        }
        let orderedSet = NSOrderedSet(array: predictArray)
        predictArray = orderedSet.array as! [String]
        
        tableView.frame = CGRect(x: 8, y: Int(self.searchBar.layer.position.y + self.searchBar.frame.height/2 - 15), width: Int(self.searchBar.frame.width) - 80, height: 45 * predictArray.count)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "predictCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .systemGray6
        tableView.layer.cornerRadius = 15
        tableView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        self.view.addSubview(tableView)
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        photoArray.removeAll()
        if searchBar.text != "" {
            saveTagArray()
            savePhotoArray()
        } else {
            self.viewDidLoad()
        }
        searchBar.text = ""
        collectionView.reloadData()
        tagCollectionView.reloadData()
        if predictArray.count != 0 {
            tableView.removeFromSuperview()
        }
    }
    
    func saveTagArray() {
        let tags = realm.objects(Tag.self)
        for i in tags {
            if i.tag.lowercased() == searchBar.text?.lowercased() {
                tagArray.append(i.tag)
                selectedTags.append(i.tag)
            }
        }
        let tagOrderedSet = NSOrderedSet(array: tagArray)
        tagArray = tagOrderedSet.array as! [String]
        let selectedOrderedSet = NSOrderedSet(array: selectedTags)
        selectedTags = selectedOrderedSet.array as! [String]
    }
    
    func savePhotoArray() {
        let photos = realm.objects(Photo.self)
        for i in photos {
            var count = 0
            for t in selectedTags {
                for a in i.tag {
                    if t == a.tag {
                        count += 1
                    }
                }
            }
            if count == selectedTags.count {
                photoArray.append(i.imageID)
            }
        }
        let photoOrderedSet = NSOrderedSet(array: photoArray)
        photoArray = photoOrderedSet.array as! [Int]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagCollectionView {
            return tagArray.count
        } else {
            return photoArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == tagCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCell", for: indexPath) as? CustomCell else {
                fatalError("Could not create cell.")
            }
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            }
            cell.tagLabel.text = tagArray[indexPath.item]
            cell.tagLabel.textColor = .white
            cell.layer.cornerRadius = 10
            cell.backgroundColor = .systemRed
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else {
                fatalError("Could not create cell.")
            }
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            if let requestID = cell.requestID {
                imageManager.cancelImageRequest(requestID)
            }
            cell.imageView.image = nil
            let element = photoAssets.filter { $0.index == photoArray[indexPath.item] }.first!
            cell.requestID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: cell.imageView.frame.width*2, height: cell.imageView.frame.width*2), contentMode: .aspectFill, options: options) { (image, info) in
                cell.imageView.image = image
            }
            var bool = false
            for i in selectedPhotos {
                if i == photoArray[indexPath.item] {
                    indexArray.append(indexPath.item)
                    bool = true
                }
            }
            if bool == true {
                cell.imageView.layer.borderWidth = 3
                cell.imageView.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                cell.imageView.layer.borderWidth = 0
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == tagCollectionView {
            guard let cell = collectionView.cellForItem(at: indexPath) as? CustomCell else {
                fatalError("Could not designate cell.")
            }
            var bool = false
            for (index, i) in selectedTags.enumerated() {
                if i == tagArray[indexPath.item] {
                    bool = true
                    selectedTags.remove(at: index)
                    cell.backgroundColor = .systemGray6
                    cell.tagLabel.textColor = .label
                }
            }
            if bool == false {
                selectedTags.append(tagArray[indexPath.item])
                cell.backgroundColor = .systemRed
                cell.tagLabel.textColor = .white
            }
            photoArray.removeAll()
            savePhotoArray()
            self.collectionView.reloadData()
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
            guard let cell = collectionView.cellForItem(at: indexPath) as? GridCellViewController else {
                fatalError("Could not define cell.")
            }
            var bool = false
            for i in indexArray {
                if indexPath.item == i {
                    bool = true
                }
            }
            if bool == false {
                cell.imageView.layer.borderColor = UIColor.systemBlue.cgColor
                cell.imageView.layer.borderWidth = 3
                selectedPhotos.append(photoArray[indexPath.item])
                indexArray.append(indexPath.item)
            } else {
                cell.imageView.layer.borderWidth = 0
                for (index, i) in selectedPhotos.enumerated() {
                    if i == photoArray[indexPath.item] {
                        selectedPhotos.remove(at: index)
                    }
                }
                for (index, i) in indexArray.enumerated() {
                    if i == indexPath.item {
                        indexArray.remove(at: index)
                    }
                }
            }
            buttonBool()
        }
    }
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionView == tagCollectionView {
            return CGSize.zero
        }
        return CGSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == tagCollectionView {
            let label = UILabel(frame: CGRect.zero)
            label.font = UIFont.systemFont(ofSize: 17)
            label.text = tagArray[indexPath.item]
            label.sizeToFit()
            let size = label.frame.size
            return CGSize(width: size.width + 25, height: 30)
        } else {
            return CGSize(width: (self.view.frame.width-60)/3, height: (self.view.frame.width)*2/7)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return predictArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "predictCell", for: indexPath)
        cell.backgroundColor = .systemGray6
        cell.textLabel?.text = predictArray[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.text = predictArray[indexPath.row]
        predictArray.removeAll()
        photoArray.removeAll()
        saveTagArray()
        savePhotoArray()
        tagCollectionView.reloadData()
        collectionView.reloadData()
        tableView.removeFromSuperview()
        searchBar.resignFirstResponder()
    }
}
