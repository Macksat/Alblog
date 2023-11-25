//
//  CustomAlbumInfoViewController.swift
//  CustomAlbumInfoViewController
//
//  Created by Sato Masayuki on 2021/09/07.
//

import UIKit
import RealmSwift
import Photos

class CustomAlbumInfoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    let ud = UserDefaults.standard
    let realm = try! Realm()
    var tagArray = [String]()
    var button = UIButton()
    var albumName = String()
    var im1 = PHImageManager()
    var im2 = PHImageManager()
    var im3 = PHImageManager()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBAction func createButton(_ sender: Any) {
        let albums = realm.objects(Album.self)
        let photos = realm.objects(Photo.self)
        let album = Album()
        var bool = false
        album.id = Album.newID()
        album.name = albumName
        for i in albums {
            if i.name == albumName {
                bool = true
            }
        }
        if bool == true {
            let alertController = UIAlertController(title: "Do you want to add this album?", message: "There is the album the name is the same as this album in your library.", preferredStyle: .alert)
            let saveAction = UIAlertAction(title: "Save", style: .default) {
                UIAlertAction in
                for i in selectedTags {
                    let tag = Tag()
                    tag.tag = i
                    tag.albumID = album.id
                    album.tag.append(tag)
                }
                for i in selectedPhotos {
                    for p in photos {
                        if i == p.imageID {
                            album.album.append(p)
                        }
                    }
                }
                try! self.realm.write {
                    self.realm.add(album)
                }
                selectedTags.removeAll()
                selectedPhotos.removeAll()
                self.tagArray.removeAll()
                self.navigationController?.popToRootViewController(animated: true)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(saveAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        } else {
            if selectedTags.count != 0 {
                for i in selectedTags {
                    let tag = Tag()
                    tag.tag = i
                    tag.albumID = album.id
                    album.tag.append(tag)
                }
            }
            for i in selectedPhotos {
                for p in photos {
                    if i == p.imageID {
                        album.album.append(p)
                    }
                }
            }
            try! realm.write {
                realm.add(album)
            }
            selectedTags.removeAll()
            selectedPhotos.removeAll()
            self.tagArray.removeAll()
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        textField.delegate = self
        nameTextField.delegate = self
        
        textField.layer.cornerRadius = 10
        textField.backgroundColor = .systemGray6
        nameTextField.layer.cornerRadius = 10
        nameTextField.backgroundColor = .systemGray6
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
                
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.collectionView.collectionViewLayout = layout
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        longPressRecognizer.delegate = self
        longPressRecognizer.allowableMovement = 10
        longPressRecognizer.minimumPressDuration = 0.7
        self.collectionView.addGestureRecognizer(longPressRecognizer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        saveTagArray()
       
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        let element1 = photoAssets.filter { $0.index == selectedPhotos[0] }.first!
        if selectedPhotos.count > 2 {
            let element2 = photoAssets.filter { $0.index == selectedPhotos[1] }.first!
            let element3 = photoAssets.filter { $0.index == selectedPhotos[2] }.first!
            im1.requestImage(for: element1.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image1, info) in
                self.im2.requestImage(for: element2.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image2, info) in
                    self.im3.requestImage(for: element3.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image3, info) in
                        self.imageView1.image = image1
                        self.imageView2.image = image2
                        self.imageView3.image = image3
                    }
                }
            }
        } else if selectedPhotos.count == 2 {
            let element2 = photoAssets.filter { $0.index == selectedPhotos[1] }.first!
            im1.requestImage(for: element1.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image1, info) in
                self.im2.requestImage(for: element2.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image2, info) in
                    self.imageView1.image = image1
                    self.imageView2.image = image2
                }
            }
            imageView3.backgroundColor = .darkGray
        } else {
            im1.requestImage(for: element1.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { (image1, info) in
                self.imageView1.image = image1
            }
            imageView2.backgroundColor = .lightGray
            imageView3.backgroundColor = .darkGray
        }
        
        imageView1.layer.cornerRadius = 15
        imageView2.layer.cornerRadius = 15
        imageView3.layer.cornerRadius = 15
        imageView1.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
        imageView2.layer.maskedCorners = [.layerMaxXMinYCorner]
        imageView3.layer.maskedCorners = [.layerMaxXMaxYCorner]
        
        createButton.isEnabled = false
    }
    
    func saveTagArray() {
        let result = realm.objects(Tag.self)
        for i in result {
            tagArray.append(i.tag)
        }
        
        let orderedSet = NSOrderedSet(array: tagArray)
        tagArray = orderedSet.array as! [String]
    }
    
    @objc func tapFunc() {
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
        if textField.isEditing == true {
            textField.endEditing(true)
        } else if nameTextField.isEditing == true {
            nameTextField.endEditing(true)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: button)) {
            return false
        }
        return true
    }
    
    @objc func longPressAction(sender: UILongPressGestureRecognizer) {
        let scrollPoint: CGPoint = sender.location(in: scrollView)
        let point: CGPoint = sender.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)
        if let indexPath = indexPath {
            switch sender.state {
            case .began:
                button.frame = CGRect(x: scrollPoint.x, y: scrollPoint.y + 70, width: 80, height: 40)
                button.setTitle("Delete", for: .normal)
                button.setTitleColor(.systemRed, for: .normal)
                button.backgroundColor = .systemGray6
                button.layer.cornerRadius = 10
                button.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
                ud.set(indexPath.item, forKey: "tagIndexPath_value")
                UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                    self.view.addSubview(self.button)
                }, completion: nil)
            default:
                break
            }
        }
    }
    
    @objc func deleteButtonAction() {
        let number = ud.integer(forKey: "tagIndexPath_value")
        tagArray.remove(at: number)
        
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
        collectionView.reloadData()
    }
    
    @IBAction func imageTapAction(_ sender: Any) {
        var idArray = [Int]()
        for i in selectedPhotos {
            idArray.append(i)
        }
        var udTagArray = [String]()
        for i in selectedTags {
            udTagArray.append(i)
        }
        ud.set(idArray, forKey: "createAlbum_value")
        ud.set(udTagArray, forKey: "createAlbum_tag")
        if nameTextField.text != "" {
            ud.set(nameTextField.text, forKey: "createAlbum_name")
        } else {
            ud.set("Custom Album", forKey: "createAlbum_name")
        }
        performSegue(withIdentifier: "customAlbum-photo", sender: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if scrollView.contentOffset.y + self.view.frame.height - nameTextField.frame.size.height - nameTextField.layer.position.y < keyboardSize.height {
                if self.view.frame.origin.y == 0 {
                    self.view.frame.origin.y -= keyboardSize.height
                } else {
                    let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                    self.view.frame.origin.y -= suggestionHeight
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
            if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        createButton.isEnabled = false
        imageView1.isUserInteractionEnabled = false
        imageView2.isUserInteractionEnabled = false
        imageView3.isUserInteractionEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        createButton.isEnabled = true
        imageView1.isUserInteractionEnabled = true
        imageView2.isUserInteractionEnabled = true
        imageView3.isUserInteractionEnabled = true
        if textField == nameTextField {
            let albums = realm.objects(Album.self)
            albumName = nameTextField.text!
            if textField.text != "" {
                for i in albums {
                    if i.name == textField.text {
                        albumName = ""
                        let alert = UIAlertController(title: "Caution", message: "This name is already used.", preferredStyle: .alert)
                        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alert.addAction(ok)
                        present(alert, animated: true, completion: nil)
                    }
                }
            }
        } else {
            var boolA = false
            var boolB = false
            let id = ud.integer(forKey: "photoID_value")
            let photo = realm.objects(Photo.self).filter("imageID == \(id)")
            if textField.text != "" {
                for t in tagArray {
                    if textField.text == t {
                        boolA = true
                    }
                }
                
                for i in photo {
                    for t in i.tag {
                        if t.tag == textField.text {
                            boolB = true
                        }
                    }
                    
                    if boolA == false || boolA == true, boolB == false {
                        var tagBool = false
                        for a in tagArray {
                            if a == textField.text {
                                selectedTags.append(a)
                                tagBool = true
                            }
                        }
                        if tagBool == false {
                            selectedTags.append(textField.text!)
                            tagArray.append(textField.text!)
                        }
                    }
                }
            }
            textField.text = ""
            collectionView.reloadData()
        }
        if albumName == "" {
            createButton.isEnabled = false
        } else {
            createButton.isEnabled = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tagArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CustomCell else {
            fatalError("Could not create cell.")
        }
        cell.layer.cornerRadius = 10
        var bool = false
        for i in selectedTags {
            if i == tagArray[indexPath.item] {
                bool = true
            }
        }
        
        if bool == true {
            cell.backgroundColor = .systemRed
            cell.tagLabel.textColor = .white
        } else {
            cell.backgroundColor = .systemGray6
            cell.tagLabel.textColor = .label
        }
        
        cell.tagLabel.text = tagArray[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath)! as? CustomCell else {
            fatalError("Could not define cell.")
        }
        var bool = false
        for i in selectedTags {
            if i == tagArray[indexPath.item] {
                bool = true
            }
        }
        if bool == false {
            cell.backgroundColor = .systemRed
            cell.tagLabel.textColor = .white
            selectedTags.append(tagArray[indexPath.item])
        } else {
            cell.backgroundColor = .systemGray6
            cell.tagLabel.textColor = .label
            for (index, i) in selectedTags.enumerated() {
                if i == tagArray[indexPath.item] {
                    selectedTags.remove(at: index)
                }
            }
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 17)
        label.text = tagArray[indexPath.item]
        label.sizeToFit()
        let size = label.frame.size
        return CGSize(width: size.width + 25, height: 30)
    }
}
