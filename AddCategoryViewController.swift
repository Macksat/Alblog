//
//  AddCategoryViewController.swift
//  AddCategoryViewController
//
//  Created by Sato Masayuki on 2021/10/14.
//

import UIKit
import RealmSwift

class AddCategoryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var tagArray = [String]()
    let ud = UserDefaults.standard
    let realm = try! Realm()
    var button = UIButton()

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.collectionView.collectionViewLayout = layout
        
        textField.delegate = self
        textField.backgroundColor = .systemGray6
        textField.layer.cornerRadius = 10
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func tapFunc() {
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
    }
    
    @objc func longPressAction(sender: UILongPressGestureRecognizer) {
        let point: CGPoint = sender.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)
        print(point.y + self.collectionView.frame.origin.y)
        if let indexPath = indexPath {
            switch sender.state {
            case .began:
                button.frame = CGRect(x: point.x, y: point.y + self.collectionView.frame.origin.y, width: 80, height: 40)
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
        let photo = realm.objects(Photo.self).filter("imageID == \(ud.integer(forKey: "photoID_value"))")
        let result = realm.objects(Tag.self)
        for i in result {
            for p in photo {
                if i.tag == tagArray[number] {
                    if i.imageID == Int() || i.imageID == p.imageID {
                        try! realm.write {
                            realm.delete(i)
                        }
                    }
                }
            }
        }
        tagArray.removeAll()
        saveTagArray()
        UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
            self.button.removeFromSuperview()
        }, completion: nil)
        collectionView.reloadData()
    }
    
    func saveTagArray() {
        let result = realm.objects(Tag.self)
        for i in result {
            tagArray.append(i.tag)
        }
        
        let orderedSet = NSOrderedSet(array: tagArray)
        tagArray = orderedSet.array as! [String]
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.height - textField.frame.size.height - textField.layer.position.y < keyboardSize.height {
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        var boolA = false
        var boolB = false
        let category = realm.objects(Category.self)
        if textField.text != "" {
            for t in tagArray {
                if textField.text == t {
                    boolA = true
                }
            }
            if category.count != 0 {
                for i in category {
                    if i.title == textField.text {
                        boolB = true
                    }
                }
                    
                if boolA == false || boolA == true, boolB == false {
                    var tagBool = false
                    for a in tagArray {
                        if a == textField.text {
                            tagBool = true
                            let item = Category()
                            item.title = a
                            try! realm.write {
                                realm.add(item)
                            }
                        }
                    }
                    if tagBool == false {
                        let newTag = Tag()
                        newTag.tag = textField.text!
                        try! realm.write {
                            realm.add(newTag)
                        }
                        let item = Category()
                        item.title = textField.text!
                        try! realm.write {
                            realm.add(item)
                        }
                    }
                }
            } else {
                if boolA == false {
                    let newTag = Tag()
                    newTag.tag = textField.text!
                    try! realm.write {
                        realm.add(newTag)
                    }
                }
                let item = Category()
                item.title = textField.text!
                try! realm.write {
                    realm.add(item)
                }
            }
        }
            
        textField.text = ""
        tagArray.removeAll()
        saveTagArray()
        collectionView.reloadData()
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tagArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCell", for: indexPath) as? CustomCell else {
            fatalError("Could not create custom cell.")
        }
        cell.layer.cornerRadius = 10
                    
        let category = realm.objects(Category.self)
        var bool = false
        for  i in category {
            if tagArray[indexPath.item] == i.title {
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
        let category = realm.objects(Category.self)
        var bool = false
        if category.count != 0 {
            for i in category {
                if tagArray[indexPath.item] == i.title {
                    try! realm.write {
                        realm.delete(i)
                    }
                    bool = true
                }
            }
                
            if bool == true {
                cell.backgroundColor = .systemGray6
                cell.tagLabel.textColor = .label
            } else {
                let item = Category()
                item.title = tagArray[indexPath.item]
                try! realm.write {
                    realm.add(item)
                }
                cell.backgroundColor = .systemRed
                cell.tagLabel.textColor = .white
            }
        } else {
            let item = Category()
            item.title = tagArray[indexPath.item]
            try! realm.write {
                realm.add(item)
            }
            cell.backgroundColor = .systemRed
            cell.tagLabel.textColor = .white
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
