//
//  AddPhotoViewController.swift
//  AddPhotoViewController
//
//  Created by Sato Masayuki on 2021/09/10.
//

import UIKit
import RealmSwift
import Photos

class AddPhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate {
    
    var button = UIButton()
    let realm = try! Realm()
    let ud = UserDefaults.standard
    var imageManager = PHImageManager()
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBAction func addButton(_ sender: Any) {
        //let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
        let memos = realm.objects(Memos.self).filter("id == \(ud.integer(forKey: "memosPhoto_id"))").first!
        for i in selectedPhotos {
            let photo = realm.objects(Photo.self).filter("imageID == \(i)").first!
            var bool = false
            //for a in album.album {
                //if photo.imageID == a.imageID {
                    //bool = true
                //}
            //}
            for a in memos.photos {
                if a.imageID == photo.imageID {
                    bool = true
                }
            }
            if bool == false {
                try! realm.write {
                    //album.album.append(photo)
                    memos.photos.append(photo)
                }
            }
        }
        selectedPhotos.removeAll()
        selectedTags.removeAll()
        let index = (self.navigationController?.viewControllers.count)!
        self.navigationController?.popToViewController((navigationController?.viewControllers[index - 3])!, animated: true)
    }
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: ((self.view.frame.width)/2) - 25, height: ((self.view.frame.width)/2) - 25)
        layout.minimumLineSpacing = -20
        layout.minimumInteritemSpacing = 1
        collectionView.collectionViewLayout = layout
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapFunc() {
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: button)) {
            return false
        }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedPhotos.count
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
        let element = photoAssets.filter { $0.index == selectedPhotos[indexPath.item] }.first!
        cell.requestID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: cell.imageView.frame.width*2, height: cell.imageView.frame.height*2), contentMode: .aspectFill, options: options) { (image, info) in
            cell.imageView.image = image
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? GridCellViewController else {
            fatalError()
        }
        button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        button.setTitle("Delete", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 10
        button.tag = indexPath.item
        button.frame = CGRect(x: cell.layer.position.x-20, y: cell.layer.position.y+50, width: 80, height: 40)
        self.view.addSubview(button)
        collectionView.deselectItem(at: indexPath, animated: false)
    }
    
    @objc func buttonAction(sender: UIButton) {
        let tag  = sender.tag
        selectedPhotos.remove(at: tag)
        collectionView.reloadData()
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
    }
}
