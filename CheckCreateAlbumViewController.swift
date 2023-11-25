//
//  CheckCreateAlbumViewController.swift
//  CheckCreateAlbumViewController
//
//  Created by Sato Masayuki on 2021/09/07.
//

import UIKit
import RealmSwift
import Photos

class CheckCreateAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var imageArray = [Int]()
    let ud = UserDefaults.standard
    let realm = try! Realm()
    var imageManager = PHImageManager()

    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBAction func createButton(_ sender: Any) {
        let albums = realm.objects(Album.self)
        let photos = realm.objects(Photo.self)
        let album = Album()
        var bool = false
        album.name = ud.string(forKey: "createAlbum_name")!
        for i in albums {
            if i.name == ud.string(forKey: "createAlbum_name")! {
                bool = true
            }
        }
        if bool == true {
            let alertController = UIAlertController(title: "Do you want to add this album?", message: "There is the album the name is the same as this album in your library.", preferredStyle: .alert)
            let saveAction = UIAlertAction(title: "Save", style: .default) {
                UIAlertAction in
                for i in self.imageArray {
                    for p in photos {
                        if p.imageID == i {
                            album.album.append(p)
                        }
                    }
                }
                album.id = Album.newID()
                let udTags = self.ud.array(forKey: "createAlbum_tag")
                for i in udTags as! [String] {
                    let tag = Tag()
                    tag.tag = i
                    tag.albumID = album.id
                    album.tag.append(tag)
                }
                try! self.realm.write {
                    self.realm.add(album)
                }
                let index = self.navigationController?.viewControllers.count
                if index! < 4 {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.navigationController?.popToRootViewController(animated: true)
                }
                selectedTags.removeAll()
                selectedPhotos.removeAll()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        } else {
            for i in imageArray {
                for p in photos {
                    if p.imageID == i {
                        album.album.append(p)
                    }
                }
            }
            album.id = Album.newID()
            let udTags = ud.array(forKey: "createAlbum_tag")
            for i in udTags as! [String] {
                let tag = Tag()
                tag.tag = i
                tag.albumID = album.id
                album.tag.append(tag)
            }
            try! realm.write {
                realm.add(album)
            }
            let index = self.navigationController?.viewControllers.count
            if index! < 4 {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
            selectedTags.removeAll()
            selectedPhotos.removeAll()
        }
    }
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        
        self.navigationItem.title = ud.string(forKey: "createAlbum_name")!
        
        let array = ud.array(forKey: "createAlbum_value")!
        for i in array as! [Int] {
            imageArray.append(i)
        }
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ((self.view.frame.width)/2) - 25, height: ((self.view.frame.width)/2) - 25)
        layout.minimumLineSpacing = -20
        layout.minimumInteritemSpacing = 1
        collectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else {
            fatalError("Could not create cell.")
        }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        if let requestID = cell.requestID {
            imageManager.cancelImageRequest(requestID)
        }
        cell.imageView.image = nil
        let element = photoAssets.filter { $0.index == imageArray[indexPath.item] }.first!
        cell.requestID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: cell.imageView.frame.width*2, height: cell.imageView.frame.height*2), contentMode: .aspectFill, options: options) { (image, info) in
            cell.imageView.image = image
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        ud.set(imageArray[indexPath.item], forKey: "photoID_value")
        performSegue(withIdentifier: "checkAlbum-photo", sender: nil)
    }
}
