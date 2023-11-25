//
//  CreateTagAlbumViewController.swift
//  CreateTagAlbumViewController
//
//  Created by Sato Masayuki on 2021/09/07.
//

import UIKit
import RealmSwift
import Photos

class CreateTagAlbumViewController: UIViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    let realm = try! Realm()
    let ud = UserDefaults.standard
    var albumArray = [Album]()
    var tagArray = [String]()
    var selectedTags = [String]()
    var predictArray = [String]()
    var tableView = UITableView()
    var indicator = UIActivityIndicatorView()
    var im1 = PHImageManager()
    var im2 = PHImageManager()
    var im3 = PHImageManager()

    @IBOutlet weak var locationButton: UIButton!
    @IBAction func locationButton(_ sender: Any) {
        performSegue(withIdentifier: "goLocationAlbum", sender: nil)
    }
    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var customButton: UIBarButtonItem!
    @IBAction func customButton(_ sender: Any) {
        performSegue(withIdentifier: "goCustomAlbum", sender: nil)
    }
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBAction func createButton(_ sender: Any) {
        for i in albumArray {
            i.id = Album.newID()
            for t in i.tag {
                t.albumID = i.id
            }
            try! realm.write {
                realm.add(i)
            }
        }
        albumArray.removeAll()
        selectedTags.removeAll()
        selectedPhotos.removeAll()
        self.navigationController?.popViewController(animated: true)
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
        
        collectionView.register(UINib(nibName: "AlbumCellViewController", bundle: nil), forCellWithReuseIdentifier: "AlbumCellViewController")
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ((self.view.frame.width)/2) - 25, height: ((self.view.frame.width)/2) - 25)
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = -10
        collectionView.collectionViewLayout = layout
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        indicator.center = self.view.center
        indicator.style = .large
        indicator.color = .gray
        self.view.addSubview(indicator)
        
        albumArray.removeAll()
        let result = realm.objects(Tag.self)
        var tagArray = [String]()
        let photos = realm.objects(Photo.self)
        indicator.startAnimating()
        DispatchQueue.main.async {
            for i in result {
                tagArray.append(i.tag)
            }
            let orderedSet = NSOrderedSet(array: tagArray)
            tagArray = orderedSet.array as! [String]
            for i in tagArray {
                autoreleasepool {
                    let album = Album()
                    album.name = i
                    let tag = Tag()
                    tag.tag = i
                    album.tag.append(tag)
                    var photoArray = [Photo]()
                    for p in photos {
                        if p.tag.count != 0 {
                            for t in p.tag {
                                if t.tag == i {
                                    photoArray.append(p)
                                }
                            }
                        }
                    }
                    let orderedSet = NSOrderedSet(array: photoArray)
                    photoArray = orderedSet.array as! [Photo]
                    for p in photoArray {
                        album.album.append(p)
                    }
                    self.albumArray.append(album)
                }
            }
            self.albumArrayCheck()
            self.indicator.stopAnimating()
            self.collectionView.reloadData()
        }
    }
    
    @objc func tapFunc() {
        if predictArray.count != 0 {
            tableView.removeFromSuperview()
        }
        searchBar.resignFirstResponder()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: tableView)) {
            return false
        }
        return true
    }
    
    func albumArrayCheck() {
        let albums = realm.objects(Album.self)
        if albums.count != 0 {
            if albumArray.count != 0 {
                for i in albumArray {
                    for a in albums {
                        if i.name == a.name, i.album.count == a.album.count {
                            albumArray.remove(at: albumArray.firstIndex(of: i)!)
                        }
                    }
                }
            }
        }
        for i in albumArray {
            if i.album.count == 0 {
                albumArray.remove(at: albumArray.firstIndex(of: i)!)
            }
        }
    }
  
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        tagArray.removeAll()
        albumArray.removeAll()
        self.tagArray.removeAll()
        self.selectedTags.removeAll()
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
        
        albumArray.removeAll()
        if searchBar.text != "" {
            saveTagArray()
            saveAlbumArray()
            albumArrayCheck()
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
        let photos = realm.objects(Photo.self)
        for i in photos {
            for t in i.tag {
                if t.tag.lowercased() == searchBar.text?.lowercased() {
                    tagArray.append(t.tag)
                    self.selectedTags.append(t.tag)
                }
            }
        }
        let tagOrderedSet = NSOrderedSet(array: tagArray)
        tagArray = tagOrderedSet.array as! [String]
        let selectedOrderedSet = NSOrderedSet(array: self.selectedTags)
        self.selectedTags = selectedOrderedSet.array as! [String]
    }
    
    func saveAlbumArray() {
        let photos = realm.objects(Photo.self)
        if selectedTags.count != 0 {
            for i in self.selectedTags {
                let album = Album()
                album.name = i
                for p in photos {
                    for t in p.tag {
                        if t.tag == i {
                            album.album.append(p)
                        }
                    }
                }
                let tag = Tag()
                tag.tag = i
                album.tag.append(tag)
                albumArray.append(album)
            }
            let albumOrderedSet = NSOrderedSet(array: albumArray)
            albumArray = albumOrderedSet.array as! [Album]
        } else {
            self.viewDidLoad()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagCollectionView {
            return tagArray.count
        } else {
            return albumArray.count
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
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumCellViewController", for: indexPath) as? AlbumCellViewController else {
                fatalError("Could not create cell.")
            }
            cell.imageView1Width.constant = cell.frame.width*2/3
            cell.imageView2Width.constant = cell.frame.width/3
            cell.imageView3Width.constant = cell.frame.width/3
            cell.imageView1Height.constant = cell.frame.height - 20
            cell.imageView2Height.constant = (cell.frame.height-20)/2
            cell.imageView3Height.constant = (cell.frame.height-20)/2
            
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            if let req1 = cell.req1 {
                im1.cancelImageRequest(req1)
            }
            if let req2 = cell.req2 {
                im2.cancelImageRequest(req2)
            }
            if let req3 = cell.req3 {
                im3.cancelImageRequest(req3)
            }
            cell.imageView1.image = nil
            cell.imageView2.image = nil
            cell.imageView3.image = nil
            if albumArray[indexPath.item].album.count != 0 {
                let element1 = photoAssets.filter { $0.index == albumArray[indexPath.item].album[0].imageID }.first!
                if albumArray[indexPath.item].album.count > 2 {
                    let element2 = photoAssets.filter { $0.index == albumArray[indexPath.item].album[1].imageID }.first!
                    let element3 = photoAssets.filter { $0.index == albumArray[indexPath.item].album[2].imageID }.first!
                    cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width*2, height: cell.imageView1.frame.height*2), contentMode: .aspectFill, options: options) { (image1, info) in
                        cell.req2 = self.im2.requestImage(for: element2.asset, targetSize: CGSize(width: cell.imageView2.frame.width, height: cell.imageView2.frame.height), contentMode: .aspectFill, options: options) { (image2, info) in
                            cell.req3 = self.im3.requestImage(for: element3.asset, targetSize: CGSize(width: cell.imageView3.frame.width, height: cell.imageView3.frame.height), contentMode: .aspectFill, options: options) { (image3, info) in
                                cell.imageView1.image = image1
                                cell.imageView2.image = image2
                                cell.imageView3.image = image3
                                cell.label.text = self.albumArray[indexPath.item].name
                            }
                        }
                    }
                } else if albumArray[indexPath.item].album.count == 2 {
                    let element2 = photoAssets.filter { $0.index == albumArray[indexPath.item].album[1].imageID }.first!
                    cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width*2, height: cell.imageView1.frame.height*2), contentMode: .aspectFill, options: options) { (image1, info) in
                        cell.req2 = self.im2.requestImage(for: element2.asset, targetSize: CGSize(width: cell.imageView2.frame.width, height: cell.imageView2.frame.height), contentMode: .aspectFill, options: options) { (image2, info) in
                            cell.imageView1.image = image1
                            cell.imageView2.image = image2
                            cell.imageView3.backgroundColor = .darkGray
                            cell.label.text = self.albumArray[indexPath.item].name
                        }
                    }
                } else {
                    cell.req1 = im1.requestImage(for: element1.asset, targetSize: CGSize(width: cell.imageView1.frame.width*2, height: cell.imageView1.frame.height*2), contentMode: .aspectFill, options: options) { (image1, info) in
                        cell.imageView1.image = image1
                        cell.imageView2.backgroundColor = .lightGray
                        cell.imageView3.backgroundColor = .darkGray
                        cell.label.text = self.albumArray[indexPath.item].name
                    }
                }
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
            for (index, i) in self.selectedTags.enumerated() {
                if i == tagArray[indexPath.item] {
                    bool = true
                    self.selectedTags.remove(at: index)
                    cell.backgroundColor = .systemGray6
                    cell.tagLabel.textColor = .label
                }
            }
            if bool == false {
                self.selectedTags.append(tagArray[indexPath.item])
                cell.backgroundColor = .systemRed
                cell.tagLabel.textColor = .white
            }
            albumArray.removeAll()
            saveAlbumArray()
            albumArrayCheck()
            self.collectionView.reloadData()
            collectionView.deselectItem(at: indexPath, animated: true)
        } else {
            var idArray = [Int]()
            for i in albumArray[indexPath.item].album {
                idArray.append(i.imageID)
            }
            var udTagArray = [String]()
            for i in albumArray[indexPath.item].album {
                for t in i.tag {
                    udTagArray.append(t.tag)
                }
            }
            ud.set(idArray, forKey: "createAlbum_value")
            ud.set(udTagArray, forKey: "createAlbum_tag")
            ud.set(albumArray[indexPath.item].name, forKey: "createAlbum_name")
            ud.set("", forKey: "createAlbum_memo")
            performSegue(withIdentifier: "tagAlbum-photo", sender: nil)
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
        albumArray.removeAll()
        saveTagArray()
        saveAlbumArray()
        albumArrayCheck()
        tagCollectionView.reloadData()
        collectionView.reloadData()
        tableView.removeFromSuperview()
        searchBar.resignFirstResponder()
    }
}
