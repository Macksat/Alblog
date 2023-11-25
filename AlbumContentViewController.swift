//
//  AlbumContentViewController.swift
//  Alblog
//
//  Created by Sato Masayuki on 2021/12/06.
//

import UIKit
import RealmSwift
import Photos
import SwiftUI

class AlbumContentViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    var tagArray = [String]()
    let realm = try! Realm()
    var album: Results<Album>!
    let ud = UserDefaults.standard
    var memoCollectionView: UICollectionView!
    var buttonBool = false
    var tableView = UITableView()
    var editButtonBool = false
    var tv1 = UITextView()
    var observation: NSKeyValueObservation?
    var deleteButton = UIButton()
    var titleButton = UIButton()
    var detailButtonBool = (Int(), false)
    var memoEditBool = false
    var imageManager = PHImageManager()
    var selectBool = false
    var selectedArray = [Int]()
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBAction func selectButton(_ sender: Any) {
        if selectBool == false {
            selectButton.title = NSLocalizedString("Cancel", comment: "")
            selectBool = true
            memoTableView.dragInteractionEnabled = true
        } else {
            selectButton.title = NSLocalizedString("Select", comment: "")
            selectBool = false
            memoTableView.dragInteractionEnabled = false
        }
        UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.memoTableView.reloadData()
        }, completion: nil)
    }
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBAction func favoriteButton(_ sender: Any) {
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
        if favoriteButton.image == UIImage(systemName: "heart") {
            try! realm.write {
                album.favorite = true
            }
            favoriteButton.image = UIImage(systemName: "heart.fill")
        } else {
            try! realm.write {
                album.favorite = false
            }
            favoriteButton.image = UIImage(systemName: "heart")
        }
    }
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewOnScroll: UIView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var memoTableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBAction func addButton(_ sender: Any) {
        if buttonBool == false {
            memoCollectionView.register(UINib(nibName: "GridCellViewController", bundle: nil), forCellWithReuseIdentifier: "GridCellViewController")
            memoCollectionView.delegate = self
            memoCollectionView.dataSource = self
            memoCollectionView.frame = CGRect(x: 10, y: scrollView.contentOffset.y, width: self.view.frame.width - 20, height: 120)
            memoCollectionView.layer.cornerRadius = 10
            memoCollectionView.backgroundColor = .systemGray4
            viewOnScroll.addSubview(memoCollectionView)
            buttonBool = true
        } else if buttonBool == true {
            memoCollectionView.removeFromSuperview()
            buttonBool = false
        }
    }
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBAction func editButton(_ sender: Any) {
        if editButton.title == NSLocalizedString("Edit", comment: "") {
            if editButtonBool == false {
                tableView.register(UITableViewCell.self, forCellReuseIdentifier: "editCell")
                tableView.delegate = self
                tableView.dataSource = self
                tableView.frame = CGRect(x: self.view.frame.width - 180, y: scrollView.contentOffset.y, width: 160, height: 44*3)
                tableView.backgroundColor = .systemGray6
                tableView.isScrollEnabled = false
                tableView.layer.cornerRadius = 10
                viewOnScroll.addSubview(tableView)
                editButtonBool = true
            } else {
                tableView.removeFromSuperview()
                editButtonBool = false
            }
        } else {
            editButtonBool = false
            editButton.title = NSLocalizedString("Edit", comment: "")
            UIView.transition(with: self.view, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                self.addButton.image = UIImage()
                self.addButton.tintColor = .systemBackground
                self.addButton.isEnabled = false
            }, completion: nil)
            memoEditBool = false
            memoTableView.dragInteractionEnabled = false
            memoTableView.endEditing(true)
            refreshMemosData()
            tableViewKindSave()
            memoTableView.reloadData()
            self.viewWillLayoutSubviews()
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.changeLayoutOfMemo()
            }
        }
    }
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        memoTableView.delegate = self
        memoTableView.dataSource = self
        memoTableView.dragDelegate = self
        memoTableView.dropDelegate = self
        memoTableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "PhotoTableViewCell")
        memoTableView.register(UINib(nibName: "MemoTableViewCell", bundle: nil), forCellReuseIdentifier: "MemoTableViewCell")
        memoTableView.register(UINib(nibName: "GridTableViewCell", bundle: nil), forCellReuseIdentifier: "GridTableViewCell")
        memoTableView.register(UINib(nibName: "LinkInTableViewCell", bundle: nil), forCellReuseIdentifier: "LinkInTableViewCell")
        memoTableView.register(UINib(nibName: "SheetTableViewCell", bundle: nil), forCellReuseIdentifier: "SheetTableViewCell")
        memoTableView.register(UINib(nibName: "ListTableViewCell", bundle: nil), forCellReuseIdentifier: "ListTableViewCell")
        memoTableView.register(UINib(nibName: "TitleTableViewCell", bundle: nil), forCellReuseIdentifier: "TitleTableViewCell")
        memoTableView.backgroundColor = .clear
        memoTableView.layer.cornerRadius = 10
        memoTableView.dragInteractionEnabled = false
        
        scrollView.delegate = self
        
        titleTextView.delegate = self
        
        addButton.image = UIImage()
        addButton.tintColor = .systemBackground
        addButton.isEnabled = false
        
        selectButton.title = NSLocalizedString("Select", comment: "")
        
        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self
                
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: self.view.frame.width/6, height: 100)
        layout.minimumInteritemSpacing = 1
        layout.scrollDirection = .horizontal
        memoCollectionView = UICollectionView(frame: CGRect(x: 10, y: 40, width: self.view.frame.width - 20, height: 120), collectionViewLayout: layout)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
        if album.favorite == true {
            favoriteButton.image = UIImage(systemName: "heart.fill")
        } else {
            favoriteButton.image = UIImage(systemName: "heart")
        }
        dateLabel.text = "\(NSLocalizedString("Created Date", comment: "")): \(album.dateStr)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tagArray.removeAll()
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))")
        
        titleTextView.text = album[0].name
        textViewHeight.constant = titleTextView.contentSize.height
                
        for t in album[0].tag {
            tagArray.append(t.tag)
        }
        let tagOrderedSet = NSOrderedSet(array: tagArray)
        tagArray = tagOrderedSet.array as! [String]
        
        tagCollectionView.reloadData()
        tableViewKindSave()
        memoTableView.reloadData()
        changeLayoutOfMemo()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        changeLayoutOfMemo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        selectedTags.removeAll()
        selectedPhotos.removeAll()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func changeLayoutOfMemo() {
        self.tableViewHeight.constant = CGFloat.greatestFiniteMagnitude
        self.memoTableView.layoutIfNeeded()
        memoTableView.rowHeight = UITableView.automaticDimension
        self.tableViewHeight.constant = self.memoTableView.contentSize.height
        
        self.scrollViewHeight.constant = CGFloat.greatestFiniteMagnitude
        self.scrollViewHeight.constant = (self.navigationController?.navigationBar.frame.height)! + textViewHeight.constant + tagCollectionView.frame.height + dateLabel.frame.height + tableViewHeight.constant + 25
    }
    
    func tableViewKindSave() {
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
        tableViewKind.removeAll()
        try! realm.write {
            album.memos.sort { a, b in
                return a.number < b.number
            }
        }
        for i in album.memos {
            if i.photos.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                let element = ("photo", i)
                let element2 = ("blank", Memos())
                tableViewKind.append(element)
                tableViewKind.append(element2)
            }
            if i.memo != "" {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                let element = ("memo", i)
                let element2 = ("blank", Memos())
                tableViewKind.append(element)
                tableViewKind.append(element2)
            }
            if i.link.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                let element = ("link", i)
                tableViewKind.append(element)
                let element2 = ("blank", Memos())
                tableViewKind.append(element2)
            }
            if i.boolList.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                for _ in 1...i.boolList.count {
                    let element = ("list", i)
                    tableViewKind.append(element)
                }
                if memoEditBool == true {
                    let element = ("list", i)
                    tableViewKind.append(element)
                }
                let element2 = ("blank", Memos())
                tableViewKind.append(element2)
            }
            if i.sheet.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                for _ in 1...i.sheet.count {
                    let element = ("sheet", i)
                    tableViewKind.append(element)
                }
                if memoEditBool == true {
                    let element = ("sheet", i)
                    tableViewKind.append(element)
                }
                let element2 = ("blank", Memos())
                tableViewKind.append(element2)
            }
            if i.grid.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                let element = ("grid", i)
                let element2 = ("blank", Memos())
                tableViewKind.append(element)
                tableViewKind.append(element2)
            }
        }
        
        try! realm.write {
            album.album.removeAll()
        }
        for i in album.memos {
            if i.photos.count != 0 {
                for p in i.photos {
                    try! realm.write {
                        album.album.append(p)
                    }
                }
            }
        }
        
        if tableViewKind.count != 0 {
            if tableViewKind.last!.name == "blank" {
                tableViewKind.remove(at: tableViewKind.count - 1)
            }
        }
    }
   
    @objc func keyboardWillShow(notification: NSNotification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            let height = self.ud.double(forKey: "textViewPoint_index")
            if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                print(height)
                print(height + self.textViewHeight.constant + self.tagCollectionView.frame.size.height)
                print(self.scrollView.contentOffset.y + self.view.frame.height - keyboardSize.height - 44)
                if height + self.textViewHeight.constant + self.tagCollectionView.frame.size.height > self.scrollView.contentOffset.y + self.view.frame.height - keyboardSize.height - 44 {
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                        if self.view.frame.origin.y == 0 {
                            self.view.frame.origin.y -= keyboardSize.height
                        } else {
                            let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                            self.view.frame.origin.y -= suggestionHeight
                        }
                    }, completion: nil)
                }
            }
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != memoCollectionView {
            if buttonBool == true {
                UIView.transition(with: viewOnScroll, duration: 0.25, options: .transitionCrossDissolve, animations:  {
                    self.memoCollectionView.removeFromSuperview()
                })
                buttonBool = false
            }
            if editButtonBool == true {
                UIView.transition(with: viewOnScroll, duration: 0.25, options: .transitionCrossDissolve, animations:  {
                    self.tableView.removeFromSuperview()
                })
                editButtonBool = false
            }
            if detailButtonBool.1 == true {
                UIView.transition(with: viewOnScroll, duration: 0.25, options: .transitionCrossDissolve, animations:  {
                    self.titleButton.removeFromSuperview()
                    self.deleteButton.removeFromSuperview()
                })
                detailButtonBool.1 = false
            }
        }
    }
   
    @objc func tapFunc() {
        if buttonBool == true {
            memoCollectionView.removeFromSuperview()
            buttonBool = false
        }
        if editButtonBool == true {
            tableView.removeFromSuperview()
            editButtonBool = false
        }
        if detailButtonBool.1 == true {
            titleButton.removeFromSuperview()
            deleteButton.removeFromSuperview()
            detailButtonBool.1 = false
        }
        memoTableView.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: memoCollectionView)) {
            return false
        } else if (touch.view!.isDescendant(of: tableView)) {
            return false
        } else if (touch.view!.isDescendant(of: titleButton)) {
            return false
        } else if (touch.view!.isDescendant(of: deleteButton)) {
            return false
        }
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == memoTableView {
            return 1
        } else if tableView == self.tableView {
            return 1
        } else {
            return tableViewKind.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == memoTableView {
            return tableViewKind.count
        } else if tableView == self.tableView {
            return 3
        } else {
            if tableView.tag == section {
                if tableViewKind[section].name == "link" {
                    return tableViewKind[section].memo.link.count*2 - 1
                }
            }
            return Int()
        }
    }
    
    func dragItem(indexPathRow: Int) -> UIDragItem {
        // setting items which are added to a designated place.
        let item = String("\(tableViewKind[indexPathRow].memo.id)\(tableViewKind[indexPathRow].name)")
        let provider = NSItemProvider(object: item as NSString)
        return UIDragItem(itemProvider: provider)
    }
    
    func moveItem(sourcePath: Int, destinationPath: Int) {
        let item = tableViewKind.remove(at: sourcePath)
        tableViewKind.insert(item, at: destinationPath)
        if destinationPath > 0 {
            if tableViewKind[destinationPath - 1].name == "title" {
                if tableViewKind[destinationPath].memo.title == "" {
                    try! realm.write {
                        tableViewKind[destinationPath].memo.title = tableViewKind[destinationPath - 1].memo.title
                        tableViewKind[destinationPath - 1].memo.title = ""
                    }
                }
            }
        }
        for (index, i) in tableViewKind.enumerated() {
            if i.name != "blank" && i.name != "title" {
                try! realm.write {
                    i.memo.number = index + 1
                }
            }
        }
    }
   
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // items which are added to a designated place.
        var dragItems = [UIDragItem]()
        for i in selectedArray {
            dragItems.append(dragItem(indexPathRow: i))
        }
        return dragItems
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        //guard let item = coordinator.items.first,
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
              //let sourceIndexPath = item.sourceIndexPath
        //else { return }
        let items = coordinator.items
        var sourceIndexPaths = [IndexPath]()
        for item in items {
            sourceIndexPaths.append(item.sourceIndexPath!)
        }
        tableView.performBatchUpdates({ [weak self] in
            guard let wself = self else { return }
            for i in sourceIndexPaths {
                wself.moveItem(sourcePath: i.row, destinationPath: destinationIndexPath.row)
            }
            tableView.deleteRows(at: sourceIndexPaths, with: .automatic)
            tableView.insertRows(at: [destinationIndexPath], with: .automatic)
            wself.tableViewKindSave()
            tableView.reloadData()
            wself.changeLayoutOfMemo()
        }, completion: nil)
        for item in items {
            coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == memoTableView {
            if tableViewKind[indexPath.row].name == "blank" {
                return 20
            } else if tableViewKind[indexPath.row].name == "grid" {
                var num = Int()
                if memoEditBool == true {
                    num = (tableViewKind[indexPath.row].memo.grid.count + 1) % 2
                    if num == 0 {
                        return ((self.view.frame.width - 40)/2 - 30)*CGFloat(tableViewKind[indexPath.row].memo.grid.count + 1)/2 + 20*(CGFloat(tableViewKind[indexPath.row].memo.grid.count + 1)/2 - 1)
                    } else {
                        return ((self.view.frame.width - 40)/2 - 30)*CGFloat(tableViewKind[indexPath.row].memo.grid.count + 2)/2 + 20*(CGFloat(tableViewKind[indexPath.row].memo.grid.count + 2)/2 - 1)
                    }
                } else {
                    num = tableViewKind[indexPath.row].memo.grid.count % 2
                    if num == 0 {
                        return ((self.view.frame.width - 40)/2 - 30)*CGFloat(tableViewKind[indexPath.row].memo.grid.count)/2 + 20*(CGFloat(tableViewKind[indexPath.row].memo.grid.count)/2 - 1)
                    } else {
                        return ((self.view.frame.width - 40)/2 - 30)*CGFloat(tableViewKind[indexPath.row].memo.grid.count + 1)/2 + 20*(CGFloat(tableViewKind[indexPath.row].memo.grid.count + 1)/2 - 1)
                    }
                }
            } else if tableViewKind[indexPath.row].name == "link" {
                if memoEditBool == true {
                    return CGFloat(80*tableViewKind[indexPath.row].memo.link.count) + 10
                } else {
                    return CGFloat(80*tableViewKind[indexPath.row].memo.link.count) - 20
                }
            } else {
                return tableView.rowHeight
            }
        } else if tableView == self.tableView {
            return 44
        } else {
            if tableViewKind[indexPath.section].name == "link" {
                let num = (indexPath.row + 1) % 2
                if num != 0 {
                    return 60
                } else {
                    return 20
                }
            } else if tableViewKind[indexPath.section].name == "list" {
                return tableView.rowHeight
            } else {
                return CGFloat()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == memoTableView {
            if tableViewKind[indexPath.row].name == "grid" {
                guard let cell = cell as? GridTableViewCell else { return }
                cell.setCollectionDelegateDataSource(dataSourceDelegate: self, forRow: indexPath.row)
            } else if tableViewKind[indexPath.row].name == "photo" {
                guard let cell = cell as? PhotoTableViewCell else { return }
                cell.setCollectionDelegateDataSource(dataSourceDelegate: self, forRow: indexPath.row)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == memoTableView {
            if tableViewKind[indexPath.row].name == "memo" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "MemoTableViewCell", for: indexPath) as? MemoTableViewCell else {
                    fatalError()
                }
                cell.contentView.backgroundColor = .systemGray6
                cell.contentView.layer.cornerRadius = 10
                if tableViewKind[indexPath.row].memo.memo != "" {
                    cell.textView.text = tableViewKind[indexPath.row].memo.memo
                    let height = cell.textView.sizeThatFits(CGSize(width: cell.textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cell.textViewHeight.constant = height
                } else {
                    cell.textViewHeight.constant = 30
                }
                cell.textView.delegate = self
                cell.textView.tag = indexPath.row
                cell.selectButton.tag = indexPath.row
                cell.selectButton.addTarget(self, action: #selector(selectButtonFunc(sender:)), for: .touchUpInside)
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView.inputAccessoryView = toolbar
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.detailButton.isEnabled = true
                    cell.textView.isUserInteractionEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 0
                    cell.detailButton.isEnabled = false
                    cell.textView.isUserInteractionEnabled = false
                }
                if selectBool == true {
                    cell.selectButton.setImage(UIImage(systemName:"circle"), for: .normal)
                    cell.selectWidth.constant = 30
                    cell.selectButton.isEnabled = true
                } else {
                    cell.selectButton.setImage(UIImage(), for: .normal)
                    cell.selectWidth.constant = 0
                    cell.selectButton.isEnabled = false
                }
                cell.detailButton.tag = indexPath.row
                cell.detailButton.titleLabel?.text = ""
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "grid" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "GridTableViewCell", for: indexPath) as? GridTableViewCell else {
                    fatalError("Could not create cell.")
                }
                cell.contentView.backgroundColor = .systemBackground
                cell.contentView.layer.cornerRadius = 10
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.detailButton.isEnabled = true
                    cell.collectionView.isUserInteractionEnabled = true
                    cell.collectionView.dragInteractionEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 0
                    cell.detailButton.isEnabled = false
                    cell.collectionView.isUserInteractionEnabled = false
                    cell.collectionView.dragInteractionEnabled = false
                }
                cell.selectButton.tag = indexPath.row
                cell.selectButton.addTarget(self, action: #selector(selectButtonFunc(sender:)), for: .touchUpInside)
                if selectBool == true {
                    cell.selectButton.setImage(UIImage(systemName:"circle"), for: .normal)
                    cell.selectWidth.constant = 30
                    cell.selectButton.isEnabled = true
                } else {
                    cell.selectButton.setImage(UIImage(), for: .normal)
                    cell.selectWidth.constant = 0
                    cell.selectButton.isEnabled = false
                }
                cell.detailButton.tag = indexPath.row
                cell.collectionView.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "list" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as? ListTableViewCell else { fatalError() }
                if indexPath.row > 0 && indexPath.row < tableViewKind.count - 1 {
                    if tableViewKind[indexPath.row - 1].name != "list" {
                        cell.contentView.layer.cornerRadius = 10
                        cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    } else if tableViewKind[indexPath.row + 1].name != "list" {
                        cell.contentView.layer.cornerRadius = 10
                        cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    } else {
                        cell.contentView.layer.cornerRadius = 0
                    }
                    if tableViewKind[indexPath.row - 1].name != "list" && tableViewKind[indexPath.row + 1].name != "list" {
                        cell.contentView.layer.cornerRadius = 10
                        cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
                    }
                }
                if indexPath.row == 0 {
                    cell.contentView.layer.cornerRadius = 10
                    cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    if tableViewKind.count > 1 {
                        if tableViewKind[indexPath.row + 1].name != "list" {
                            cell.contentView.layer.cornerRadius = 10
                            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                if indexPath.row == tableViewKind.count - 1 {
                    cell.contentView.layer.cornerRadius = 10
                    cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    if tableViewKind.count > 1 {
                        if tableViewKind[indexPath.row - 1].name != "list" {
                            cell.contentView.layer.cornerRadius = 10
                            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                cell.textView.delegate = self
                cell.textView.tag = indexPath.row
                cell.contentView.backgroundColor = .systemGray6
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView.inputAccessoryView = toolbar
                var id = Int()
                if tableViewKind[0].name != "list" || tableViewKind[0].memo.id != tableViewKind[indexPath.row].memo.id {
                    if indexPath.row - 1 >= 0 {
                        var num = 1
                        while tableViewKind[indexPath.row - num].name == "list" {
                            num += 1
                        }
                        id = indexPath.row - num + 1
                    } else {
                        id = 0
                    }
                }
                if tableViewKind[indexPath.row].memo.boolList.count >= indexPath.row - id + 1 {
                    cell.textView.text = tableViewKind[indexPath.row].memo.boolList[indexPath.row - id].text
                    let height = cell.textView.sizeThatFits(CGSize(width: cell.textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cell.textViewHeight.constant = height
                    if tableViewKind[indexPath.row].memo.boolList[indexPath.row - id].bool == false {
                        cell.button.tintColor = .lightGray
                    } else {
                        cell.button.tintColor = .systemRed
                    }
                } else {
                    cell.textView.text = ""
                    cell.textViewHeight.constant = 30
                    cell.button.tintColor = .lightGray
                }
                cell.button.tag = indexPath.row
                cell.button.addTarget(self, action: #selector(listButtonAction(sender:)), for: .touchUpInside)
                
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.textView.isUserInteractionEnabled = true
                    cell.detailButton.isEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 0
                    cell.textView.isUserInteractionEnabled = false
                    cell.detailButton.isEnabled = false
                }
                cell.selectButton.tag = indexPath.row
                cell.selectButton.addTarget(self, action: #selector(selectButtonFunc(sender:)), for: .touchUpInside)
                if selectBool == true {
                    cell.selectButton.setImage(UIImage(systemName:"circle"), for: .normal)
                    cell.selectWidth.constant = 30
                    cell.selectButton.isEnabled = true
                } else {
                    cell.selectButton.setImage(UIImage(), for: .normal)
                    cell.selectWidth.constant = 0
                    cell.selectButton.isEnabled = false
                }
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "sheet" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SheetTableViewCell", for: indexPath) as? SheetTableViewCell else {
                    fatalError()
                }
                cell.contentView.backgroundColor = .systemGray6
                cell.textView1.backgroundColor = .clear
                cell.textView2.backgroundColor = .clear
                if indexPath.row > 0 && indexPath.row < tableViewKind.count - 1 {
                    if tableViewKind[indexPath.row - 1].name != "sheet" {
                        cell.contentView.layer.cornerRadius = 10
                        cell.textView1.layer.cornerRadius = 10
                        cell.textView2.layer.cornerRadius = 10
                        cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                        cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner]
                        cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner]
                    } else if tableViewKind[indexPath.row + 1].name != "sheet" {
                        cell.contentView.layer.cornerRadius = 10
                        cell.textView1.layer.cornerRadius = 10
                        cell.textView2.layer.cornerRadius = 10
                        cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                        cell.textView1.layer.maskedCorners = [.layerMinXMaxYCorner]
                        cell.textView2.layer.maskedCorners = [.layerMaxXMaxYCorner]
                    } else {
                        cell.contentView.layer.cornerRadius = 0
                        cell.textView1.layer.cornerRadius = 0
                        cell.textView2.layer.cornerRadius = 0
                    }
                    if tableViewKind[indexPath.row - 1].name != "sheet" && tableViewKind[indexPath.row + 1].name != "sheet" {
                        cell.contentView.layer.cornerRadius = 10
                        cell.textView1.layer.cornerRadius = 10
                        cell.textView2.layer.cornerRadius = 10
                        cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMinYCorner]
                        cell.textView1.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
                        cell.textView2.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
                    }
                }
                if indexPath.row == 0 {
                    cell.contentView.layer.cornerRadius = 10
                    cell.textView1.layer.cornerRadius = 10
                    cell.textView2.layer.cornerRadius = 10
                    cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner]
                    cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner]
                    if tableViewKind.count > 1 {
                        if tableViewKind[indexPath.row + 1].name != "sheet" {
                            cell.contentView.layer.cornerRadius = 10
                            cell.textView1.layer.cornerRadius = 10
                            cell.textView2.layer.cornerRadius = 10
                            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                            cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                            cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                if indexPath.row == tableViewKind.count - 1 {
                    cell.contentView.layer.cornerRadius = 10
                    cell.textView1.layer.cornerRadius = 10
                    cell.textView2.layer.cornerRadius = 10
                    cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    cell.textView1.layer.maskedCorners = [.layerMinXMaxYCorner]
                    cell.textView2.layer.maskedCorners = [.layerMaxXMaxYCorner]
                    if tableViewKind.count > 1 {
                        if tableViewKind[indexPath.row - 1].name != "sheet" {
                            cell.contentView.layer.cornerRadius = 10
                            cell.textView1.layer.cornerRadius = 10
                            cell.textView2.layer.cornerRadius = 10
                            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                            cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                            cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                        }
                    }
                }
                if tableViewKind.count == 1 {
                    cell.contentView.layer.cornerRadius = 10
                    cell.textView1.layer.cornerRadius = 10
                    cell.textView2.layer.cornerRadius = 10
                    cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                    cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                }
                cell.textView1.delegate = self
                cell.textView2.delegate = self
                cell.textView1.tag = indexPath.row
                cell.textView2.tag = indexPath.row
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView1.inputAccessoryView = toolbar
                cell.textView2.inputAccessoryView = toolbar
                var id = Int()
                if tableViewKind[0].name != "sheet" || tableViewKind[0].memo.id != tableViewKind[indexPath.row].memo.id {
                    if indexPath.row - 1 >= 0 {
                        var num = 1
                        while tableViewKind[indexPath.row - num].name == "sheet" {
                            num += 1
                        }
                        id = indexPath.row - num + 1
                    } else {
                        id = 0
                    }
                }
                if tableViewKind[indexPath.row].memo.sheet.count >= indexPath.row - id + 1 {
                    cell.textView1.text = tableViewKind[indexPath.row].memo.sheet[indexPath.row - id].text1
                    cell.textView2.text = tableViewKind[indexPath.row].memo.sheet[indexPath.row - id].text2
                    let height1 = cell.textView1.sizeThatFits(CGSize(width: cell.textView1.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    let height2 = cell.textView2.sizeThatFits(CGSize(width: cell.textView2.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    if height1 > height2 {
                        cell.textView1Height.constant = height1
                        cell.textView2Height.constant = height1
                    } else {
                        cell.textView1Height.constant = height2
                        cell.textView2Height.constant = height2
                    }
                } else {
                    cell.textView1.text = ""
                    cell.textView2.text = ""
                    cell.textView1Height.constant = 35
                    cell.textView2Height.constant = 35
                }
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.detailButton.isEnabled = true
                    cell.textView1.isUserInteractionEnabled = true
                    cell.textView2.isUserInteractionEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 0
                    cell.detailButton.isEnabled = false
                    cell.textView1.isUserInteractionEnabled = false
                    cell.textView2.isUserInteractionEnabled = false
                }
                cell.selectButton.tag = indexPath.row
                cell.selectButton.addTarget(self, action: #selector(selectButtonFunc(sender:)), for: .touchUpInside)
                if selectBool == true {
                    cell.selectButton.setImage(UIImage(systemName:"circle"), for: .normal)
                    cell.selectWidth.constant = 30
                    cell.selectButton.isEnabled = true
                } else {
                    cell.selectButton.setImage(UIImage(), for: .normal)
                    cell.selectWidth.constant = 0
                    cell.selectButton.isEnabled = false
                }
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "blank" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "blankCell", for: indexPath)
                cell.backgroundColor = .clear
                cell.isUserInteractionEnabled = false
                return cell
            } else if tableViewKind[indexPath.row].name == "link" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "LinkInTableViewCell", for: indexPath) as? LinkInTableViewCell else {
                    fatalError("Could not create cell.")
                }
                cell.addButton.tag = indexPath.row
                cell.tableView.tag = indexPath.row
                cell.tableView.delegate = self
                cell.tableView.dataSource = self
                cell.tableView.dragDelegate = self
                cell.tableView.dropDelegate = self
                cell.backgroundColor = .systemBackground
                if memoEditBool == true {
                    cell.addButton.setTitle(NSLocalizedString("Add Link", comment: ""), for: .normal)
                    cell.addButton.isEnabled = true
                    cell.addButtonHeight.constant = 30
                    cell.tableView.allowsSelection = false
                    cell.tableView.dragInteractionEnabled = true
                } else {
                    cell.addButton.setTitle("", for: .normal)
                    cell.addButton.isEnabled = false
                    cell.addButtonHeight.constant = 0
                    cell.tableView.allowsSelection = true
                    cell.tableView.dragInteractionEnabled = false
                }
                cell.addButton.addTarget(self, action: #selector(addButtonAction(sender:)), for: .touchUpInside)
                cell.tableView.reloadData()
                return cell
            } else if tableViewKind[indexPath.row].name == "photo" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoTableViewCell", for: indexPath) as? PhotoTableViewCell else { fatalError() }
                cell.collectionView.tag = indexPath.row
                cell.detailButton.tag = indexPath.row
                cell.addButton.tag = indexPath.row
                cell.backgroundColor = .clear
                cell.contentView.backgroundColor = .systemBackground
                cell.contentView.layer.cornerRadius = 10
                let layout = UICollectionViewFlowLayout()
                layout.minimumLineSpacing = -10
                layout.minimumInteritemSpacing = 1
                cell.collectionView.collectionViewLayout = layout
                cell.addButton.setTitle(NSLocalizedString("Add Photos", comment: ""), for: .normal)
                if tableViewKind[indexPath.row].memo.photos.count == 1 {
                    cell.collectionViewHeight.constant = (self.view.frame.width - 40)/2 - 40
                } else {
                    let num = tableViewKind[indexPath.row].memo.photos.count % 2
                    if num == 0 {
                        cell.collectionViewHeight.constant = ((self.view.frame.width - 40)/2 - 40) * CGFloat(tableViewKind[indexPath.row].memo.photos.count/2) + 10*(CGFloat(tableViewKind[indexPath.row].memo.photos.count/2) - 1)
                    } else {
                        cell.collectionViewHeight.constant = ((self.view.frame.width - 40)/2 - 40) * CGFloat((tableViewKind[indexPath.row].memo.photos.count + 1)/2) + 10*(CGFloat((tableViewKind[indexPath.row].memo.photos.count + 1)/2) - 1)
                    }
                }
                if memoEditBool == true {
                    cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                    cell.detailButtonWidth.constant = 30
                    cell.detailButton.isEnabled = true
                    cell.addButtonHeight.constant = 30
                    cell.addButton.isEnabled = true
                    cell.collectionView.dragInteractionEnabled = true
                } else {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                    cell.detailButtonWidth.constant = 0
                    cell.detailButton.isEnabled = false
                    cell.addButtonHeight.constant = 0
                    cell.addButton.isEnabled = false
                    cell.collectionView.dragInteractionEnabled = false
                }
                cell.selectButton.tag = indexPath.row
                cell.selectButton.addTarget(self, action: #selector(selectButtonFunc(sender:)), for: .touchUpInside)
                if selectBool == true {
                    cell.selectButton.setImage(UIImage(systemName:"circle"), for: .normal)
                    cell.selectWidth.constant = 30
                    cell.selectButton.isEnabled = true
                } else {
                    cell.selectButton.setImage(UIImage(), for: .normal)
                    cell.selectWidth.constant = 0
                    cell.selectButton.isEnabled = false
                }
                cell.addButton.addTarget(self, action: #selector(addButtonAction(sender:)), for: .touchUpInside)
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTableViewCell", for: indexPath) as? TitleTableViewCell else {
                    fatalError("Could not create cell.")
                }
                cell.textField.delegate = self
                cell.textField.tag = indexPath.row
                cell.textField.placeholder = NSLocalizedString("Title", comment: "")
                cell.textField.text = tableViewKind[indexPath.row].memo.title
                if memoEditBool == true {
                    cell.isUserInteractionEnabled = true
                    cell.textField.isEnabled = true
                } else {
                    cell.isUserInteractionEnabled = false
                    cell.textField.isEnabled = false
                }
                return cell
            }
        } else if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "editCell", for: indexPath)
            if indexPath.row == 0 {
                cell.textLabel?.text = NSLocalizedString("Edit Album", comment: "")
            } else if indexPath.row == 1 {
                cell.textLabel?.text = NSLocalizedString("Edit Album Info", comment: "")
            } else {
                cell.textLabel?.text = NSLocalizedString("Delete Album", comment: "")
                cell.textLabel?.textColor = .systemRed
            }
            cell.backgroundColor = .systemGray6
            return cell
        } else {
            if tableViewKind[indexPath.section].name == "link" {
                let num = (indexPath.row + 1) % 2
                if num != 0 {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "LinkTableViewCell", for: indexPath) as? LinkTableViewCell else {
                        fatalError()
                    }
                    cell.contentView.backgroundColor = .systemGray6
                    cell.detailButton.tag = indexPath.row
                    cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                    cell.textField.tag = indexPath.row
                    cell.textField.delegate = self
                    cell.contentView.layer.cornerRadius = 10
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .systemGray6
                    let imageData = tableViewKind[indexPath.section].memo.link[indexPath.row / 2].image as Data
                    cell.setUpContents(image: UIImage(data: imageData)!, string: tableViewKind[indexPath.section].memo.link[indexPath.row / 2].title)
                    if memoEditBool == true {
                        cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                        cell.detailButton.isEnabled = true
                        cell.detailButtonWidth.constant = 30
                        cell.textField.isEnabled = true
                    } else {
                        cell.detailButton.setImage(UIImage(), for: .normal)
                        cell.detailButtonWidth.constant = 5
                        cell.detailButton.isEnabled = false
                        cell.textField.isEnabled = false
                    }
                    cell.selectButton.tag = indexPath.row
                    cell.selectButton.addTarget(self, action: #selector(selectButtonFunc(sender:)), for: .touchUpInside)
                    if selectBool == true {
                        cell.selectButton.setImage(UIImage(systemName:"circle"), for: .normal)
                        cell.selectWidth.constant = 30
                        cell.selectButton.isEnabled = true
                    } else {
                        cell.selectButton.setImage(UIImage(), for: .normal)
                        cell.selectWidth.constant = 0
                        cell.selectButton.isEnabled = false
                    }
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "blankCell", for: indexPath)
                    cell.backgroundColor = .systemBackground
                    cell.isUserInteractionEnabled = false
                    return cell
                }
            }
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == memoTableView {
            tableView.deselectRow(at: indexPath, animated: false)
        } else if tableView == self.tableView {
            if indexPath.row == 0 {
                editButton.title = NSLocalizedString("Done", comment: "")
                UIView.transition(with: self.view, duration: 0.25, options: .transitionCrossDissolve, animations:  {
                    self.addButton.image = UIImage(systemName: "plus")
                    self.addButton.tintColor = UIColor(red: 0.886, green: 0.196, blue: 0.494, alpha: 1)
                    self.addButton.isEnabled = true
                }, completion: nil)
                memoEditBool = true
                self.tableView.removeFromSuperview()
                memoTableView.dragInteractionEnabled = true
                tableViewKindSave()
                memoTableView.reloadData()
                self.viewWillLayoutSubviews()
                changeLayoutOfMemo()
            } else if indexPath.row == 1 {
                performSegue(withIdentifier: "goAlbumEdit", sender: nil)
                self.tableView.removeFromSuperview()
                editButtonBool = false
            } else {
                let alert = UIAlertController(title: NSLocalizedString("Caution", comment: ""), message: NSLocalizedString("Do you want to delete this album?", comment: ""), preferredStyle: .alert)
                let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { UIAlertAction in
                    let album = self.realm.objects(Album.self).filter("id == \(self.ud.integer(forKey: "view-albumContents"))").first!
                    try! self.realm.write {
                        self.realm.delete(album)
                    }
                    self.navigationController?.popViewController(animated: true)
                }
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
                alert.addAction(deleteAction)
                alert.addAction(cancelAction)
                present(alert, animated: true, completion: nil)
                self.tableView.removeFromSuperview()
                editButtonBool = false
            }
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            ud.set(tableViewKind[indexPath.section].memo.link[indexPath.row/2].url, forKey: "webURL_value")
            performSegue(withIdentifier: "album-web", sender: nil)
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    @objc func textViewDoneButton() {
        memoTableView.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        let point = textView.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        if tableViewKind[indexPath.row].name == "grid" {
            guard let cell = memoTableView.cellForRow(at: indexPath) as? GridTableViewCell else {
                fatalError()
            }
            if let start = textView.selectedTextRange?.start {
                let cursorFrame = textView.caretRect(for: start)
                let gPoint = textView.convert(CGPoint.zero, to: cell.collectionView)
                ud.set(Double(cursorFrame.origin.y + point.y + gPoint.y + textView.frame.size.height), forKey: "textViewPoint_index")
            }
        } else {
            if let start = textView.selectedTextRange?.start {
                let cursorFrame = textView.caretRect(for: start)
                ud.set(Double(cursorFrame.origin.y + point.y + textView.frame.size.height), forKey: "textViewPoint_index")
            }
        }
        if tableViewKind[indexPath.row].name == "sheet" {
            guard let cell = memoTableView.cellForRow(at: indexPath) as? SheetTableViewCell else {
                fatalError()
            }
            tv1 = cell.textView1
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let point = textView.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        if let cell = memoTableView.cellForRow(at: indexPath) as? MemoTableViewCell {
            let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
            cell.textViewHeight.isActive = true
            let originalHeight = cell.frame.size.height
            var frame = textView.frame
            frame.size.height = textView.contentSize.height
            textView.frame = frame
            var cellFrame = cell.frame
            cellFrame.size.height = height + 10
            cell.frame = cellFrame
            if originalHeight < cell.frame.size.height {
                if cell.frame.origin.y + cell.frame.size.height + textViewHeight.constant + tagCollectionView.frame.height + 10 >= scrollViewHeight.constant - 30 {
                    tableViewHeight.constant += 16.666666666666664
                    scrollViewHeight.constant += 16.666666666666664
                    scrollView.contentOffset.y += 16.666666666666664
                }
            } else if originalHeight > cell.frame.size.height {
                if tableViewHeight.constant > memoTableView.contentSize.height {
                    tableViewHeight.constant -= 16.666666666666664
                    scrollViewHeight.constant -= 16.666666666666664
                }
            }
        } else if let cell = memoTableView.cellForRow(at: indexPath) as? ListTableViewCell {
            let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
            cell.textViewHeight.isActive = true
            let originalHeight = cell.frame.size.height
            var frame = textView.frame
            frame.size.height = textView.contentSize.height
            textView.frame = frame
            var cellFrame = cell.frame
            cellFrame.size.height = height + 10
            cell.frame = cellFrame
            if originalHeight < cell.frame.size.height {
                if cell.frame.origin.y + cell.frame.size.height + textViewHeight.constant + tagCollectionView.frame.height + 10 >= scrollViewHeight.constant - 30 {
                    tableViewHeight.constant += 16.666666666666664
                    scrollViewHeight.constant += 16.666666666666664
                    scrollView.contentOffset.y += 16.666666666666664
                }
            } else if originalHeight > cell.frame.size.height {
                if tableViewHeight.constant > memoTableView.contentSize.height {
                    tableViewHeight.constant -= 16.666666666666664
                    scrollViewHeight.constant -= 16.666666666666664
                }
            }
        } else if let cell = memoTableView.cellForRow(at: indexPath) as? SheetTableViewCell {
            let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
            cell.textView1Height.isActive = true
            cell.textView2Height.isActive = true
            let originalHeight = cell.frame.size.height
            var frame = textView.frame
            frame.size.height = textView.contentSize.height
            textView.frame = frame
            var cellFrame = cell.frame
            if textView == cell.textView1 {
                if height > cell.textView2Height.constant {
                    cellFrame.size.height = height + 10
                } else {
                    cellFrame.size.height = cell.textView2Height.constant
                }
            } else {
                if height > cell.textView1Height.constant {
                    cellFrame.size.height = height + 10
                } else {
                    cellFrame.size.height = cell.textView1Height.constant
                }
            }
            cell.frame = cellFrame
            if originalHeight < cell.frame.size.height {
                if cell.frame.origin.y + cell.frame.size.height + textViewHeight.constant + tagCollectionView.frame.height + 10 >= scrollViewHeight.constant - 30 {
                    tableViewHeight.constant += 16.666666666666664
                    scrollViewHeight.constant += 16.666666666666664
                    scrollView.contentOffset.y += 16.666666666666664
                }
            } else if originalHeight > cell.frame.size.height {
                if tableViewHeight.constant > memoTableView.contentSize.height {
                    tableViewHeight.constant -= 16.666666666666664
                    scrollViewHeight.constant -= 16.666666666666664
                }
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let tag = textView.tag
        let point = textView.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        var id = 0
        if tableViewKind[indexPath.row].name == "memo" {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
            if textView.text != "" {
                try! realm.write {
                    memos.memo = textView.text
                }
            }
        } else if tableViewKind[indexPath.row].name == "grid" {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
            if textView.text != "" {
                if tag == memos.grid.count {
                    let grid = Grid()
                    grid.text = textView.text
                    grid.gridID = tag
                    try! realm.write {
                        memos.grid.append(grid)
                    }
                } else {
                    try! realm.write {
                        memos.grid[tag].text = textView.text
                    }
                }
            }
        } else if tableViewKind[indexPath.row].name == "list" {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
            if tableViewKind[0].name != "list" || tableViewKind[0].memo.id != memos.id {
                if tag - 1 >= 0 {
                    var num = 1
                    while tableViewKind[tag - num].name == "list" {
                        num += 1
                    }
                    id = tag - num + 1
                } else {
                    id = 0
                }
            }
            if textView.text != "" {
                if memos.boolList.count == tag - id {
                    let list = BoolList()
                    list.text = textView.text
                    list.listID = tag - id
                    try! realm.write {
                        memos.boolList.append(list)
                    }
                } else {
                    try! realm.write {
                        memos.boolList[tag - id].text = textView.text
                    }
                }
            }
        } else if tableViewKind[indexPath.row].name == "sheet" {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
            if tableViewKind[0].name != "sheet" || tableViewKind[0].memo.id != memos.id {
                if tag - 1 >= 0 {
                    var num = 1
                    while tableViewKind[tag - num].name == "sheet" {
                        num += 1
                    }
                    id = tag - num + 1
                } else {
                    id = 0
                }
            }
            if textView.text != "" {
                if memos.sheet.count == tag - id {
                    let sheet = Sheet()
                    if textView == tv1 {
                        sheet.text1 = textView.text
                        sheet.text2 = ""
                    } else {
                        sheet.text1 = ""
                        sheet.text2 = textView.text
                    }
                    sheet.sheetID = tag - id
                    try! realm.write {
                        memos.sheet.append(sheet)
                    }
                } else {
                    try! realm.write {
                        if textView == tv1 {
                            memos.sheet[tag - id].text1 = textView.text
                        } else {
                            memos.sheet[tag - id].text2 = textView.text
                        }
                    }
                }
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.changeLayoutOfMemo()
            if self.scrollViewHeight.constant > self.view.frame.height {
                self.scrollView.contentOffset.y = self.scrollViewHeight.constant - self.view.frame.height + (self.tabBarController?.tabBar.frame.height)! + (self.navigationController?.navigationBar.frame.height)! + 20
            }
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let point = textField.convert(CGPoint.zero, to: memoTableView)
        ud.set(Double(textField.frame.height + point.y), forKey: "textViewPoint_index")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
                
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let tag = textField.tag
        let point = textField.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)")
        if textField.text != "" {
            if tableViewKind[indexPath.row].name == "title" {
                try! realm.write {
                    memos[0].title = textField.text!
                }
            } else if tableViewKind[indexPath.row].name == "grid" {
                let gridMemos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
                if tag == gridMemos.grid.count {
                    let grid = Grid()
                    grid.title = textField.text!
                    grid.gridID = tag
                    try! realm.write {
                        gridMemos.grid.append(grid)
                    }
                } else {
                    try! realm.write {
                        gridMemos.grid[tag].title = textField.text!
                    }
                }
            } else if tableViewKind[indexPath.row].name == "link" {
                let linkMemos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
                try! realm.write {
                    linkMemos.link[tag/2].title = textField.text!
                }
            }
        } else {
            if tableViewKind[tag].name == "title" {
                try! realm.write {
                    memos[0].title == ""
                }
            }
            if tableViewKind[indexPath.row].name == "link" {
                textField.text = tableViewKind[indexPath.row].memo.link[tag/2].title
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
    }
    
    @objc func detailButtonAction(sender: UIButton) {
        let tag = sender.tag
        
        let point = sender.convert(CGPoint.zero, to: viewOnScroll)
        titleButton.frame = CGRect(x: self.view.frame.width - 140, y: point.y - 22.5, width: 80, height: 45)
        deleteButton.frame = CGRect(x: self.view.frame.width - 140, y: point.y + 22.5, width: 80, height: 45)
        titleButton.layer.cornerRadius = 10
        titleButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        deleteButton.layer.cornerRadius = 10
        deleteButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        titleButton.backgroundColor = .systemGray5
        deleteButton.backgroundColor = .systemGray5
        titleButton.setTitle(NSLocalizedString("Title", comment: ""), for: .normal)
        deleteButton.setTitle(NSLocalizedString("Delete", comment: ""), for: .normal)
        titleButton.setTitleColor(.label, for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        titleButton.addTarget(self, action: #selector(titleButtonAction(sender:)), for: .touchUpInside)
        let memoPoint = sender.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: memoPoint)!
        if tableViewKind[indexPath.row].name == "link" {
            titleButton.tag = indexPath.row
            deleteButton.tag = indexPath.row
            ud.set(tag/2, forKey: "linkTag_index")
        } else {
            titleButton.tag = tag
            deleteButton.tag = tag
        }
        deleteButton.addTarget(self, action: #selector(deleteButtonAction(sender:)), for: .touchUpInside)
        if detailButtonBool.1 == false {
            viewOnScroll.addSubview(titleButton)
            viewOnScroll.addSubview(deleteButton)
            detailButtonBool = (tag, true)
        } else {
            if detailButtonBool.0 == tag {
                titleButton.removeFromSuperview()
                deleteButton.removeFromSuperview()
                detailButtonBool = (tag, false)
            } else {
                titleButton.removeFromSuperview()
                deleteButton.removeFromSuperview()
                viewOnScroll.addSubview(titleButton)
                viewOnScroll.addSubview(deleteButton)
                detailButtonBool = (tag, true)
            }
        }
    }
    
    @objc func selectButtonFunc(sender: UIButton) {
        let tag = sender.tag
        if sender.imageView?.image == UIImage(systemName: "circle") {
            sender.setImage(UIImage(systemName: "circle.fill"), for: .normal)
            selectedArray.append(tag)
        } else {
            sender.setImage(UIImage(systemName: "circle"), for: .normal)
            for (index, i) in selectedArray.enumerated() {
                if i == tag {
                    selectedArray.remove(at: index)
                }
            }
        }
    }
    
    @objc func titleButtonAction(sender: UIButton) {
        var num = 0
        let tag = sender.tag
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        if memos.title == "" {
            if tableViewKind[0].memo.id != memos.id {
                while tableViewKind[tag - num].name != "blank" {
                    num += 1
                }
                if tableViewKind[tag - num + 1].name == "title" {
                    tableViewKind.remove(at: tag - num + 1)
                }
                tableViewKind.insert(("title", memos), at: tag - num + 1)
            } else {
                tableViewKind.insert(("title", memos), at: 0)
            }
        } else {
            while tableViewKind[tag - num].name != "title" {
                num += 1
            }
            try! realm.write {
                memos.title = ""
            }
            tableViewKind.remove(at: tag - num)
        }
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
        titleButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        detailButtonBool.1 = false
    }
    
    @objc func deleteButtonAction(sender: UIButton) {
        let tag = sender.tag
        var id = 0
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        if tableViewKind[tag].name == "sheet" {
            if tableViewKind[0].name != "sheet" || tableViewKind[0].memo.id != memos.id {
                if tag - 1 >= 0 {
                    var num = 1
                    while tableViewKind[tag - num].name == "sheet" {
                        num += 1
                    }
                    id = tag - num + 1
                } else {
                    id = 0
                }
            }
            if tag - id < memos.sheet.count {
                if memos.sheet.count == 1 {
                    try! realm.write {
                        realm.delete(memos)
                    }
                } else {
                    try! realm.write {
                        memos.sheet.remove(at: tag - id)
                    }
                }
            }
        } else if tableViewKind[tag].name == "list" {
            if tableViewKind[0].name != "list" || tableViewKind[0].memo.id != memos.id {
                if tag - 1 >= 0 {
                    var num = 1
                    while tableViewKind[tag - num].name == "list" {
                        num += 1
                    }
                    id = tag - num + 1
                } else {
                    id = 0
                }
            }
            if tag - id < memos.boolList.count {
                if memos.sheet.count == 1 {
                    try! realm.write {
                        realm.delete(memos)
                    }
                } else {
                    try! realm.write {
                        memos.boolList.remove(at: tag - id)
                    }
                }
            }
        } else if tableViewKind[tag].name == "link" {
            let linkTag = ud.integer(forKey: "linkTag_index")
            try! realm.write {
                memos.link.remove(at: linkTag)
            }
        } else {
            try! realm.write {
                realm.delete(memos)
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
        titleButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        detailButtonBool.1 = false
    }
    
    @objc func listButtonAction(sender: UIButton) {
        let tag = sender.tag
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        var id = Int()
        if tableViewKind[0].name != "list" || tableViewKind[0].memo.id != memos.id {
            if tag - 1 >= 0 {
                var num = 1
                while tableViewKind[tag - num].name == "list" {
                    num += 1
                }
                id = tag - num + 1
            } else {
                id = 0
            }
        }
        if memos.boolList.count != tag - id {
            if tableViewKind[tag].memo.boolList[tag - id].bool == false {
                sender.tintColor = .red
                try! realm.write {
                    memos.boolList[tag - id].bool = true
                }
            } else {
                sender.tintColor = .lightGray
                try! realm.write {
                    memos.boolList[tag - id].bool = false
                }
            }
        } else {
            let list = BoolList()
            list.bool = true
            list.listID = tag - id
            try! realm.write {
                memos.boolList.append(list)
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
    }
    
    @objc func addButtonAction(sender: UIButton) {
        let tag = sender.tag
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        if tableViewKind[tag].name == "link" {
            ud.set(memos.id, forKey: "memosLink_id")
            performSegue(withIdentifier: "album-searchURL", sender: nil)
        } else if tableViewKind[tag].name == "photo" {
            ud.set(memos.id, forKey: "memosPhoto_id")
            performSegue(withIdentifier: "photos-addPhotos", sender: nil)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == memoCollectionView {
            return 1
        } else if collectionView == tagCollectionView {
            return 1
        } else {
            return tableViewKind.count
        }
    }
    
    func dragCollectionItem(for indexPath: IndexPath) -> [UIDragItem] {
        // setting items which are added to a designated place.
        if tableViewKind[indexPath.section].name == "photo" {
            let photoItem = String("\(tableViewKind[indexPath.section].memo.photos[indexPath.item].imageID)\(tableViewKind[indexPath.section].name)")
            let provider = NSItemProvider(object: photoItem as NSString)
            return [UIDragItem(itemProvider: provider)]
        } else {
            return [UIDragItem(itemProvider: NSItemProvider())]
        }
    }
    
    func moveCollectionItem(sourceSection: Int, sourcePath: Int, destinationSection: Int, destinationPath: Int) {
        if tableViewKind[sourceSection].name == "photo" {
            let item = tableViewKind[sourceSection].memo.photos[sourcePath]
            try! realm.write {
                tableViewKind[sourceSection].memo.photos.remove(at: sourcePath)
                tableViewKind[destinationSection].memo.photos.insert(item, at: destinationPath)
            }
        } else {
            if sourcePath < tableViewKind[sourceSection].memo.grid.count {
                let item = tableViewKind[sourceSection].memo.grid[sourcePath]
                if destinationPath < tableViewKind[sourceSection].memo.grid.count {
                    try! realm.write {
                        tableViewKind[sourceSection].memo.grid.remove(at: sourcePath)
                        tableViewKind[sourceSection].memo.grid.insert(item, at: destinationPath)
                        for (index, i) in tableViewKind[destinationSection].memo.grid.enumerated() {
                            i.gridID = index
                        }
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return dragCollectionItem(for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let destinationIndexPath = coordinator.destinationIndexPath,
              let sourceIndexPath = item.sourceIndexPath
        else { return }
        var bool = false
        if tableViewKind[sourceIndexPath.section].name == "grid" && sourceIndexPath.item == tableViewKind[sourceIndexPath.section].memo.grid.count {
            bool = true
        }
        if tableViewKind[sourceIndexPath.section].name == "grid" && destinationIndexPath.item == tableViewKind[sourceIndexPath.section].memo.grid.count {
            bool = true
        }
        collectionView.performBatchUpdates({ [weak self] in
            guard let wself = self else { return }
            wself.moveCollectionItem(sourceSection: sourceIndexPath.section, sourcePath: sourceIndexPath.item, destinationSection: destinationIndexPath.section, destinationPath: destinationIndexPath.item)
            if bool == false {
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }
        }, completion: nil)
        coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        collectionView.reloadData()
        tableViewKindSave()
        memoTableView.reloadData()
        changeLayoutOfMemo()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == memoCollectionView {
            return 6
        } else if collectionView == tagCollectionView {
            return tagArray.count
        } else {
            if collectionView.tag == section {
                if tableViewKind[section].name == "grid" {
                    if memoEditBool == true {
                        return tableViewKind[section].memo.grid.count + 1
                    } else {
                        return tableViewKind[section].memo.grid.count
                    }
                } else if tableViewKind[section].name == "photo" {
                    return tableViewKind[section].memo.photos.count
                }
            }
            return Int()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == memoCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCellViewController", for: indexPath) as? GridCellViewController else {
                fatalError("Could not create cell.")
            }
            cell.imageView.contentMode = .scaleAspectFit
            if indexPath.item == 0 {
                cell.setUpContents(image: UIImage(named: "Alblog photo")!, string: NSLocalizedString("Photo", comment: ""))
            } else if indexPath.item == 1 {
                cell.setUpContents(image: UIImage(named: "Alblog memo")!, string: NSLocalizedString("Memo", comment: ""))
            } else if indexPath.item == 2 {
                cell.setUpContents(image: UIImage(named: "Alblog grid")!, string: NSLocalizedString("Grid", comment: ""))
            } else if indexPath.item == 3 {
                cell.setUpContents(image: UIImage(named: "Alblog list")!, string: NSLocalizedString("List", comment: ""))
            } else if indexPath.item == 4 {
                cell.setUpContents(image: UIImage(named: "Alblog sheet")!, string: NSLocalizedString("Sheet", comment: ""))
            } else {
                cell.setUpContents(image: UIImage(named: "Alblog link")!, string: NSLocalizedString("Link", comment: ""))
            }
            cell.label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            
            return cell
        } else if collectionView == tagCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCell", for: indexPath) as? CustomCell else {
                fatalError("Could not create cell.")
            }
            if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            }
            cell.tagLabel.text = tagArray[indexPath.item]
            cell.tagLabel.textColor = .white
            cell.layer.cornerRadius = 10
            
            return cell
        } else {
            if tableViewKind[indexPath.section].name == "grid" {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TextCollectionViewCell", for: indexPath) as? TextCollectionViewCell else {
                    fatalError()
                }
                cell.textView.tag = indexPath.item
                cell.title.tag = indexPath.item
                cell.deleteButton.tag = indexPath.item
                cell.textView.delegate = self
                cell.title.delegate = self
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView.inputAccessoryView = toolbar
                cell.title.placeholder = NSLocalizedString("Title", comment: "")
                cell.deleteButton.addTarget(self, action: #selector(contentDeleteButtonAction(sender:)), for: .touchUpInside)
                if memoEditBool == true {
                    cell.deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
                    cell.deleteButton.tintColor = .systemRed
                    cell.deleteButton.backgroundColor = .systemGray6
                    cell.deleteButton.layer.cornerRadius = 10
                    cell.deleteButton.layer.maskedCorners = [.layerMaxXMinYCorner]
                    cell.title.layer.maskedCorners = [.layerMinXMinYCorner]
                    cell.deleteButtonWidth.constant = 30
                } else {
                    cell.deleteButton.setImage(UIImage(), for: .normal)
                    cell.deleteButton.backgroundColor = .clear
                    cell.title.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    cell.deleteButtonWidth.constant = 0
                }
                if indexPath.item <= tableViewKind[indexPath.section].memo.grid.count - 1 {
                    cell.title.text = tableViewKind[indexPath.section].memo.grid[indexPath.item].title
                    cell.textView.text = tableViewKind[indexPath.section].memo.grid[indexPath.item].text
                } else {
                    cell.title.text = ""
                    cell.textView.text = ""
                }
                return cell
            } else if tableViewKind[indexPath.section].name == "photo" {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as? ImageCollectionViewCell else { fatalError() }
                if let requestID = cell.requestID {
                    imageManager.cancelImageRequest(requestID)
                }
                cell.imageView.image = nil
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                let element = photoAssets.filter { $0.index == tableViewKind[indexPath.section].memo.photos[indexPath.row].imageID }.first!
                cell.requestID = imageManager.requestImage(for: element.asset, targetSize: CGSize(width: cell.imageView.frame.width*2, height: cell.imageView.frame.height*2), contentMode: .aspectFill, options: options, resultHandler: { image, _ in
                    cell.imageView.image = image
                })
                cell.deleteButton.tag = indexPath.item
                cell.deleteButton.addTarget(self, action: #selector(contentDeleteButtonAction(sender:)), for: .touchUpInside)
                if memoEditBool == true {
                    cell.deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
                    cell.deleteButton.isUserInteractionEnabled = true
                } else {
                    cell.deleteButton.setImage(UIImage(), for: .normal)
                    cell.deleteButton.isUserInteractionEnabled = false
                }
                return cell
            }
            return UICollectionViewCell()
        }
    }
    
    @objc func contentDeleteButtonAction(sender: UIButton) {
        let tag = sender.tag
        let point = sender.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
        if tableViewKind[indexPath.row].name == "grid" {
            if tag < memos.grid.count {
                try! realm.write {
                    memos.grid.remove(at: tag)
                }
            }
        } else if tableViewKind[indexPath.row].name == "link" {
            if tag < memos.link.count {
                try! realm.write {
                    memos.link.remove(at: tag)
                }
            }
        } else if tableViewKind[indexPath.row].name == "photo" {
            try! realm.write {
                memos.photos.remove(at: tag)
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        self.viewWillLayoutSubviews()
        changeLayoutOfMemo()
    }
    
    func refreshMemosData() {
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
        for i in album.memos {
            if i.memo == "" && i.grid.count == 0 && i.boolList.count == 0 && i.sheet.count == 0 && i.link.count == 0 && i.photos.count == 0 {
                try! realm.write {
                    realm.delete(i)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == memoCollectionView {
            refreshMemosData()
            let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
            tableViewKindSave()
            let memos = Memos()
            memos.id = Memos.newID()
            if album.memos.count != 0 {
                memos.number = album.memos.last!.number + 1
            } else {
                memos.number = 1
            }
            try! realm.write {
                album.memos.append(memos)
            }
            let blankElement = ("blank", Memos())
            tableViewKind.append(blankElement)
            if indexPath.item == 0 {
                let element = ("photo", memos)
                tableViewKind.append(element)
            } else if indexPath.item == 1 {
                let element = ("memo", memos)
                tableViewKind.append(element)
            } else if indexPath.item == 2 {
                let element = ("grid", memos)
                tableViewKind.append(element)
            } else if indexPath.item == 3 {
                let element = ("list", memos)
                tableViewKind.append(element)
            } else if indexPath.item == 4 {
                let element = ("sheet", memos)
                tableViewKind.append(element)
            } else {
                let element = ("link", memos)
                tableViewKind.append(element)
            }
            if tableViewKind.first!.name == "blank" {
                tableViewKind.remove(at: 0)
            }
            memoTableView.reloadData()
            memoCollectionView.removeFromSuperview()
            buttonBool = false
            self.viewWillLayoutSubviews()
            changeLayoutOfMemo()
            scrollView.contentOffset.y = scrollViewHeight.constant - self.view.frame.height + (self.tabBarController?.tabBar.frame.height)! + (self.navigationController?.navigationBar.frame.height)! + 20
        } else if collectionView == tagCollectionView {
            collectionView.deselectItem(at: indexPath, animated: false)
        } else {
            if tableViewKind[indexPath.section].name == "photo" {
                ud.set(tableViewKind[indexPath.section].memo.photos[indexPath.row].imageID, forKey: "photoID_value")
                ud.set("photoListVC", forKey: "segue_value")
                performSegue(withIdentifier: "photoList-fullImage", sender: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == tagCollectionView {
            let label = UILabel(frame: CGRect.zero)
            label.font = UIFont.systemFont(ofSize: 17)
            label.text = tagArray[indexPath.item]
            label.sizeToFit()
            let size = label.frame.size
            return CGSize(width: size.width + 25, height: 30)
        } else if collectionView == memoCollectionView {
            return CGSize(width: 80, height: 100)
        } else {
            if tableViewKind[indexPath.section].name == "grid" {
                if memoEditBool == true {
                    if selectBool == true {
                        return CGSize(width: (self.view.frame.width - 40)/2 - 40, height: (self.view.frame.width - 40)/2 - 30)
                    } else {
                        return CGSize(width: (self.view.frame.width - 40)/2 - 25, height: (self.view.frame.width - 40)/2 - 30)
                    }
                } else {
                    if selectBool == true {
                        return CGSize(width: (self.view.frame.width - 40)/2 - 25, height: (self.view.frame.width - 40)/2 - 30)
                    } else {
                        return CGSize(width: (self.view.frame.width - 40)/2 - 10, height: (self.view.frame.width - 40)/2 - 30)
                    }
                }
            } else if tableViewKind[indexPath.section].name == "photo" {
                if tableViewKind[indexPath.section].memo.photos.count == 1 {
                    if memoEditBool == true {
                        return CGSize(width: self.view.frame.width - 70, height: (self.view.frame.width - 40)/2 - 20)
                    } else {
                        return CGSize(width: self.view.frame.width - 40, height: (self.view.frame.width - 40)/2 - 20)
                    }
                } else {
                    if memoEditBool == true {
                        return CGSize(width: (self.view.frame.width - 40)/2 - 25, height: (self.view.frame.width - 40)/2 - 20)
                    } else {
                        return CGSize(width: (self.view.frame.width - 40)/2 - 10, height: (self.view.frame.width - 40)/2 - 20)
                    }
                }
            }
            return CGSize()
        }
    }
}
