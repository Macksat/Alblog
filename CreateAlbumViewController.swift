//
//  CreateAlbumViewController.swift
//  Alblog
//
//  Created by Sato Masayuki on 2021/11/01.
//

import UIKit
import RealmSwift
import Photos
import SwiftUI

class CreateAlbumViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, UITextViewDelegate, UITextFieldDelegate, UIScrollViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UITableViewDragDelegate, UITableViewDropDelegate {
    
    var tagArray = [String]()
    let realm = try! Realm()
    var album: Results<Album>!
    let ud = UserDefaults.standard
    var memoCollectionView: UICollectionView!
    var buttonBool = false
    var tv1 = UITextView()
    var observation: NSKeyValueObservation?
    var deleteButton = UIButton()
    var titleButton = UIButton()
    var detailButtonBool = (Int(), false)
    var imageManager = PHImageManager()
    var doneBool = false

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
    @IBOutlet weak var addTagButton: UIBarButtonItem!
    @IBAction func addTagButton(_ sender: Any) {
        doneBool = true
        performSegue(withIdentifier: "create-tag", sender: nil)
    }
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneButton(_ sender: Any) {
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        try! realm.write {
            album.date = date
            album.dateStr = formatter.string(from: date)
        }
        doneBool = true
        self.navigationController?.popViewController(animated: true)
    }
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var memoTableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewOnScroll: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        memoTableView.delegate = self
        memoTableView.dataSource = self
        memoTableView.dragDelegate = self
        memoTableView.dropDelegate = self
        memoTableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "PhotoTableViewCell")
        memoTableView.register(UINib(nibName: "MemoTableViewCell", bundle: nil), forCellReuseIdentifier: "MemoTableViewCell")
        memoTableView.register(UINib(nibName: "GridTableViewCell", bundle: nil), forCellReuseIdentifier: "GridTableViewCell")
        memoTableView.register(UINib(nibName: "LinkInTableViewCell", bundle: nil), forCellReuseIdentifier: "LinkInTableViewCell")
        memoTableView.register(UINib(nibName: "SheetInTableViewCell", bundle: nil), forCellReuseIdentifier: "SheetInTableViewCell")
        memoTableView.register(UINib(nibName: "ListInTableViewCell", bundle: nil), forCellReuseIdentifier: "ListInTableViewCell")
        memoTableView.register(UINib(nibName: "TitleTableViewCell", bundle: nil), forCellReuseIdentifier: "TitleTableViewCell")
        memoTableView.backgroundColor = .clear
        memoTableView.layer.cornerRadius = 10
        memoTableView.dragInteractionEnabled = true
        
        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self
        
        titleTextView.delegate = self
        titleTextView.text = NSLocalizedString("Album Name", comment: "")
        let toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
        let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
        toolbar.setItems([doneButtonItem], animated: true)
        titleTextView.inputAccessoryView = toolbar
        titleTextView.textColor = .systemGray4
        
        scrollView.delegate = self
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: self.view.frame.width/6, height: 100)
        layout.minimumInteritemSpacing = 1
        layout.scrollDirection = .horizontal
        memoCollectionView = UICollectionView(frame: CGRect(x: 10, y: 40, width: self.view.frame.width - 20, height: 120), collectionViewLayout: layout)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunc))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
                
        let album = Album()
        album.id = Album.newID()
        ud.set(album.id, forKey: "view-albumContents")
        try! realm.write {
            realm.add(album)
        }
        
        ud.set(0, forKey: "inCellHeight")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tagArray.removeAll()
        doneBool = false
        let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))")
        if album.count > 0 {
            for t in album[0].tag {
                tagArray.append(t.tag)
            }
            let tagOrderedSet = NSOrderedSet(array: tagArray)
            tagArray = tagOrderedSet.array as! [String]
        } else {
            let album = Album()
            album.id = Album.newID()
            ud.set(album.id, forKey: "view-albumContents")
            try! realm.write {
                realm.add(album)
            }
        }
        
        tagCollectionView.reloadData()
        tableViewKindSave()
        memoTableView.reloadData()
        changeLayoutOfMemo()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func reloadView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.changeLayoutOfMemo()
            self.memoTableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        selectedTags.removeAll()
        selectedPhotos.removeAll()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if doneBool == false {
            titleTextView.endEditing(true)
            memoTableView.endEditing(true)
            let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
            try! realm.write {
                realm.delete(album)
            }
        }
    }
    
    func changeLayoutOfMemo() {
        textViewHeight.constant = CGFloat.greatestFiniteMagnitude
        titleTextView.layoutIfNeeded()
        textViewHeight.constant = titleTextView.contentSize.height
        
        self.tableViewHeight.constant = CGFloat.greatestFiniteMagnitude
        self.memoTableView.layoutIfNeeded()
        memoTableView.rowHeight = UITableView.automaticDimension
        self.tableViewHeight.constant = self.memoTableView.contentSize.height
        
        self.scrollViewHeight.constant = CGFloat.greatestFiniteMagnitude
        let height = textViewHeight.constant + tagCollectionView.frame.height + 45
        let viewHeight = self.view.frame.height - (self.navigationController?.navigationBar.frame.size.height)! - (self.tabBarController?.tabBar.frame.size.height)!
        if height > viewHeight - tableViewHeight.constant {
            self.scrollViewHeight.constant = height + tableViewHeight.constant
        } else {
            tableViewHeight.constant = viewHeight - height
            self.scrollViewHeight.constant = height + tableViewHeight.constant
        }
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
                let element = ("list", i)
                tableViewKind.append(element)
                let element2 = ("blank", Memos())
                tableViewKind.append(element2)
            }
            if i.sheet.count != 0 {
                if i.title != "" {
                    let element3 = ("title", i)
                    tableViewKind.append(element3)
                }
                let element = ("sheet", i)
                tableViewKind.append(element)
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
        if tableViewKind.count != 0 {
            if tableViewKind.last!.name == "blank" {
                tableViewKind.remove(at: tableViewKind.count - 1)
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
        
        if album.name == "" {
            doneButton.isEnabled = false
        } else {
            doneButton.isEnabled = true
        }
    }
   
    @objc func keyboardWillShow(notification: NSNotification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if self.ud.bool(forKey: "titleEdit-Bool") == false {
                let height = self.ud.double(forKey: "textViewPoint_index")
                let barHeight = (self.navigationController?.navigationBar.frame.size.height)! + (self.tabBarController?.tabBar.frame.size.height)!
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    let actualHeight = height + self.textViewHeight.constant + self.tagCollectionView.frame.size.height + barHeight
                    let defaultHeight = self.scrollView.contentOffset.y + self.view.frame.height - keyboardSize.height - 44
                    if actualHeight > defaultHeight {
                        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                            if self.view.frame.origin.y == 0 {
                                self.view.frame.origin.y -= (actualHeight - defaultHeight)
                            } else {
                                let suggestionHeight = self.view.frame.origin.y + (actualHeight - defaultHeight)
                                self.view.frame.origin.y -= suggestionHeight
                            }
                        }, completion: nil)
                        self.ud.set(keyboardSize.height - (actualHeight - defaultHeight), forKey: "keyboardHeight_value")
                    } else {
                        self.ud.set(keyboardSize.height, forKey: "keyboardHeight_value")
                    }
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
        if detailButtonBool.1 == true {
            titleButton.removeFromSuperview()
            deleteButton.removeFromSuperview()
            detailButtonBool.1 = false
        }
        memoTableView.endEditing(true)
        titleTextView.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view!.isDescendant(of: memoCollectionView)) {
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
        } else {
            return tableViewKind.count
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == memoTableView {
            return tableViewKind.count
        } else {
            if tableView.tag == section {
                if tableViewKind[section].name == "link" {
                    return tableViewKind[section].memo.link.count*2 - 1
                } else if tableViewKind[section].name == "list" {
                    return tableViewKind[section].memo.boolList.count + 1
                } else if tableViewKind[section].name == "sheet" {
                    return tableViewKind[section].memo.sheet.count + 1
                }
            }
            return Int()
        }
    }
    
    func moveItem(sourcePath: Int, destinationPath: Int) {
        let item = tableViewKind.remove(at: sourcePath)
        tableViewKind.insert(item, at: destinationPath)
        print(tableViewKind[destinationPath].name)
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
    
    func moveRow(sourceSection: Int, sourcePath: Int, destinationPath: Int) {
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[sourceSection].memo.id)").first!
        try! realm.write {
            if tableViewKind[sourceSection].name == "list" {
                if destinationPath < tableViewKind[sourceSection].memo.boolList.count && sourcePath < tableViewKind[sourceSection].memo.boolList.count {
                    let item = memos.boolList[sourcePath]
                    memos.boolList.remove(at: sourcePath)
                    memos.boolList.insert(item, at: destinationPath)
                    for (index, i) in memos.boolList.enumerated() {
                        i.listID = index
                    }
                }
            } else if tableViewKind[sourceSection].name == "sheet" {
                if destinationPath < tableViewKind[sourceSection].memo.sheet.count && sourcePath < tableViewKind[sourceSection].memo.sheet.count {
                    let item = memos.sheet[sourcePath]
                    memos.sheet.remove(at: sourcePath)
                    memos.sheet.insert(item, at: destinationPath)
                    for (index, i) in memos.sheet.enumerated() {
                        i.sheetID = index
                    }
                }
            } else if tableViewKind[sourceSection].name == "link" {
                let sourceNum = sourcePath % 2
                let destinationNum = destinationPath % 2
                if sourceNum == 0 {
                    let item = memos.link[sourcePath/2]
                    memos.link.remove(at: sourcePath/2)
                    if destinationNum == 0 {
                        memos.link.insert(item, at: destinationPath/2)
                    } else {
                        if sourcePath > destinationPath {
                            memos.link.insert(item, at: (destinationPath+1)/2)
                        } else if sourcePath < destinationPath {
                            memos.link.insert(item, at: (destinationPath-1)/2)
                        }
                    }
                    for (index, i) in memos.link.enumerated() {
                        i.linkID = index
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let item = coordinator.items.first,
              let destinationIndexPath = coordinator.destinationIndexPath,
              let sourceIndexPath = item.sourceIndexPath
        else { return }
        tableView.performBatchUpdates({ [weak self] in
            guard let wself = self else { return }
            if tableView == memoTableView {
                wself.moveItem(sourcePath: sourceIndexPath.row, destinationPath: destinationIndexPath.row)
                tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
                tableView.insertRows(at: [destinationIndexPath], with: .automatic)
            } else {
                wself.moveRow(sourceSection: tableView.tag, sourcePath: sourceIndexPath.row, destinationPath: destinationIndexPath.row)
                tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
                tableView.insertRows(at: [destinationIndexPath], with: .automatic)
            }
            wself.tableViewKindSave()
            tableView.reloadData()
            wself.changeLayoutOfMemo()
        }, completion: nil)
        coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == memoTableView {
            if tableViewKind[indexPath.row].name == "blank" {
                return 20
            } else if tableViewKind[indexPath.row].name == "grid" {
                var num = Int()
                num = (tableViewKind[indexPath.row].memo.grid.count + 1) % 2
                if num == 0 {
                    return ((self.view.frame.width - 40)/2 - 30)*CGFloat(tableViewKind[indexPath.row].memo.grid.count + 1)/2 + 20*(CGFloat(tableViewKind[indexPath.row].memo.grid.count + 1)/2 - 1)
                } else {
                    return ((self.view.frame.width - 40)/2 - 30)*CGFloat(tableViewKind[indexPath.row].memo.grid.count + 2)/2 + 20*(CGFloat(tableViewKind[indexPath.row].memo.grid.count + 2)/2 - 1)
                }
            } else if tableViewKind[indexPath.row].name == "link" {
                if tableViewKind[indexPath.row].memo.link.count > 0 {
                    return CGFloat(80*tableViewKind[indexPath.row].memo.link.count) + 10
                } else {
                    return 30
                }
            } else {
                return tableView.rowHeight
            }
        } else {
            if tableViewKind[indexPath.section].name == "link" {
                let num = (indexPath.row + 1) % 2
                if num != 0 {
                    return 60
                } else {
                    return 20
                }
            } else {
                tableView.rowHeight = UITableView.automaticDimension
                return tableView.rowHeight
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView == memoTableView {
            if tableViewKind[indexPath.row].name == "grid" {
                guard let cell = cell as? GridTableViewCell else {
                    return
                }
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
                cell.contentView.backgroundColor = .systemBackground
                cell.textView.backgroundColor = .systemGray6
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
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView.inputAccessoryView = toolbar
                cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                cell.detailButtonWidth.constant = 30
                cell.detailButton.isEnabled = true
                cell.textView.isUserInteractionEnabled = true
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
                cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                cell.detailButtonWidth.constant = 30
                cell.detailButton.isEnabled = true
                cell.collectionView.isUserInteractionEnabled = true
                cell.collectionView.dragInteractionEnabled = true
                cell.detailButton.tag = indexPath.row
                cell.collectionView.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                return cell
            } else if tableViewKind[indexPath.row].name == "list" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListInTableViewCell", for: indexPath) as? ListInTableViewCell else {
                    fatalError()
                }
                cell.tableView.tag = indexPath.row
                cell.tableView.delegate = self
                cell.tableView.dataSource = self
                cell.tableView.dragDelegate = self
                cell.tableView.dropDelegate = self
                cell.tableView.layer.cornerRadius = 10
                cell.tableView.backgroundColor = .systemGray6
                cell.tableView.reloadData()
                cell.tableViewHeight.constant = CGFloat.greatestFiniteMagnitude
                cell.tableView.layoutIfNeeded()
                cell.tableViewHeight.constant = cell.tableView.contentSize.height
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                cell.detailButtonWidth.constant = 30
                cell.detailButton.isEnabled = true
                cell.tableView.isUserInteractionEnabled = true
                cell.tableView.dragInteractionEnabled = true
                return cell
            } else if tableViewKind[indexPath.row].name == "sheet" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SheetInTableViewCell", for: indexPath) as? SheetInTableViewCell else {
                    fatalError()
                }
                cell.tableView.tag = indexPath.row
                cell.tableView.delegate = self
                cell.tableView.dataSource = self
                cell.tableView.dragDelegate = self
                cell.tableView.dropDelegate = self
                cell.tableView.layer.cornerRadius = 10
                cell.tableView.reloadData()
                cell.tableViewHeight.constant = CGFloat.greatestFiniteMagnitude
                cell.tableView.layoutIfNeeded()
                cell.tableViewHeight.constant = cell.tableView.contentSize.height
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
                cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                cell.detailButtonWidth.constant = 30
                cell.detailButton.isEnabled = true
                cell.tableView.isUserInteractionEnabled = true
                cell.tableView.dragInteractionEnabled = true
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
                cell.tableView.dragInteractionEnabled = true
                cell.backgroundColor = .systemBackground
                cell.addButton.setTitle(NSLocalizedString("Add Link", comment: ""), for: .normal)
                cell.addButton.isEnabled = true
                cell.addButtonHeight.constant = 30
                cell.tableView.allowsSelection = false
                cell.addButton.addTarget(self, action: #selector(addButtonAction(sender:)), for: .touchUpInside)
                cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                cell.detailButton.isEnabled = true
                cell.detailButtonWidth.constant = 30
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(detailButtonAction(sender:)), for: .touchUpInside)
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
                cell.detailButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
                cell.detailButtonWidth.constant = 30
                cell.detailButton.isEnabled = true
                cell.addButtonHeight.constant = 30
                cell.addButton.isEnabled = true
                cell.addButton.setTitle(NSLocalizedString("Add Photos", comment: ""), for: .normal)
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
                cell.isUserInteractionEnabled = true
                cell.textField.isEnabled = true
                return cell
            }
        } else {
            if tableViewKind[indexPath.section].name == "link" {
                let num = (indexPath.row + 1) % 2
                if num != 0 {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "LinkTableViewCell", for: indexPath) as? LinkTableViewCell else {
                        fatalError()
                    }
                    cell.detailButton.tag = indexPath.row
                    cell.detailButton.addTarget(self, action: #selector(contentDeleteButtonAction(sender:)), for: .touchUpInside)
                    cell.textField.tag = indexPath.row
                    cell.textField.delegate = self
                    cell.contentView.layer.cornerRadius = 10
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .systemGray6
                    let imageData = tableViewKind[indexPath.section].memo.link[indexPath.row / 2].image as Data
                    cell.setUpContents(image: UIImage(data: imageData)!, string: tableViewKind[indexPath.section].memo.link[indexPath.row / 2].title)
                    cell.detailButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
                    cell.detailButton.isEnabled = true
                    cell.detailButtonWidth.constant = 30
                    cell.textField.isEnabled = true
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "blankCell", for: indexPath)
                    cell.backgroundColor = .systemBackground
                    cell.isUserInteractionEnabled = false
                    return cell
                }
            } else if tableViewKind[indexPath.section].name == "list" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "ListTableViewCell", for: indexPath) as? ListTableViewCell else { fatalError() }
                cell.textView.delegate = self
                cell.textView.tag = indexPath.row
                cell.contentView.backgroundColor = .systemGray6
                let toolbar = UIToolbar()
                toolbar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width + 40, height: 44)
                let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(textViewDoneButton))
                toolbar.setItems([doneButtonItem], animated: true)
                cell.textView.inputAccessoryView = toolbar
                if tableViewKind[indexPath.section].memo.boolList.count > indexPath.row {
                    cell.textView.text = tableViewKind[indexPath.section].memo.boolList[indexPath.row].text
                    let height = cell.textView.sizeThatFits(CGSize(width: cell.textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cell.textViewHeight.constant = height
                    if tableViewKind[indexPath.section].memo.boolList[indexPath.row].bool == false {
                        cell.button.tintColor = .lightGray
                    } else {
                        cell.button.tintColor = .systemRed
                    }
                } else {
                    cell.textView.text = ""
                    cell.textViewHeight.constant = 35
                    cell.button.tintColor = .lightGray
                }
                cell.button.tag = indexPath.row
                cell.button.addTarget(self, action: #selector(listButtonAction(sender:)), for: .touchUpInside)
                cell.deleteButton.tag = indexPath.row
                cell.deleteButton.addTarget(self, action: #selector(contentDeleteButtonAction(sender:)), for: .touchUpInside)
                if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
                    cell.deleteButton.setImage(UIImage(), for: .normal)
                } else {
                    cell.deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
                }
                cell.deleteButtonWidth.constant = 30
                cell.deleteButton.isEnabled = true
                return cell
            } else if tableViewKind[indexPath.section].name == "sheet" {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SheetTableViewCell", for: indexPath) as? SheetTableViewCell else { fatalError() }
                cell.contentView.backgroundColor = .systemGray6
                cell.textView1.backgroundColor = .clear
                cell.textView2.backgroundColor = .clear
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
                if tableViewKind[indexPath.section].memo.sheet.count > indexPath.row {
                    cell.textView1.text = tableViewKind[indexPath.section].memo.sheet[indexPath.row].text1
                    cell.textView2.text = tableViewKind[indexPath.section].memo.sheet[indexPath.row].text2
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
                if indexPath.row == 0 {
                    cell.textView1.layer.cornerRadius = 10
                    cell.textView2.layer.cornerRadius = 10
                    cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner]
                    cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner]
                } else if indexPath.row == tableViewKind[indexPath.section].memo.sheet.count {
                    cell.textView1.layer.cornerRadius = 10
                    cell.textView2.layer.cornerRadius = 10
                    cell.textView1.layer.maskedCorners = [.layerMinXMaxYCorner]
                    cell.textView2.layer.maskedCorners = [.layerMaxXMaxYCorner]
                } else {
                    cell.textView1.layer.cornerRadius = 0
                    cell.textView2.layer.cornerRadius = 0
                }
                if tableViewKind[indexPath.section].memo.sheet.count == 0 {
                    cell.textView1.layer.cornerRadius = 10
                    cell.textView2.layer.cornerRadius = 10
                    cell.textView1.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                    cell.textView2.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                }
                if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
                    cell.detailButton.setImage(UIImage(), for: .normal)
                } else {
                    cell.detailButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
                }
                cell.detailButton.tintColor = .systemRed
                cell.detailButtonWidth.constant = 30
                cell.detailButton.isEnabled = true
                cell.detailButton.tag = indexPath.row
                cell.detailButton.addTarget(self, action: #selector(contentDeleteButtonAction(sender:)), for: .touchUpInside)
                return cell
            }
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == memoTableView {
            tableView.deselectRow(at: indexPath, animated: false)
        } else {
            ud.set(tableViewKind[indexPath.section].memo.link[indexPath.row/2].url, forKey: "webURL_value")
            performSegue(withIdentifier: "album-web", sender: nil)
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    @objc func textViewDoneButton() {
        memoTableView.endEditing(true)
        titleTextView.endEditing(true)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == titleTextView {
            if textView.textColor == .systemGray4 {
                textView.text = ""
                textView.textColor = .label
            }
            ud.set(true, forKey: "titleEdit-Bool")
        } else {
            let point = textView.convert(CGPoint.zero, to: memoTableView)
            let indexPath = memoTableView.indexPathForRow(at: point)!
            if let start = textView.selectedTextRange?.start {
                let cursorFrame = textView.caretRect(for: start)
                ud.set(Double(cursorFrame.origin.y + point.y), forKey: "textViewPoint_index")
            }
            if tableViewKind[indexPath.row].name == "sheet" {
                guard let cell = memoTableView.cellForRow(at: indexPath) as? SheetInTableViewCell else {
                    fatalError()
                }
                let cellPoint = textView.convert(CGPoint.zero, to: cell.tableView)
                let cellIndexPath = cell.tableView.indexPathForRow(at: cellPoint)!
                guard let sCell = cell.tableView.cellForRow(at: cellIndexPath) as? SheetTableViewCell else { fatalError() }
                tv1 = sCell.textView1
            }
            ud.set(false, forKey: "titleEdit-Bool")
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let keyboardHeight = CGFloat(ud.float(forKey: "keyboardHeight_value"))
        let barHeight = (self.navigationController?.navigationBar.frame.size.height)!
        if textView == titleTextView {
            textViewHeight.isActive = true
            textViewHeight.constant = textView.contentSize.height
        } else {
            let point = textView.convert(CGPoint.zero, to: memoTableView)
            if let indexPath = memoTableView.indexPathForRow(at: point) {
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
                        var heightA = cell.frame.origin.y + cell.frame.size.height + textViewHeight.constant + tagCollectionView.frame.height + barHeight
                        let heightB = scrollViewHeight.constant - 30
                        if heightA < heightB {
                            heightA += keyboardHeight
                        }
                        if heightA >= heightB {
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
                } else if let inCell = memoTableView.cellForRow(at: indexPath) as? ListInTableViewCell {
                    let cellPoint = textView.convert(CGPoint.zero, to: inCell.tableView)
                    let cellIndexPath = inCell.tableView.indexPathForRow(at: cellPoint)!
                    guard let cell = inCell.tableView.cellForRow(at: cellIndexPath) as? ListTableViewCell else { fatalError() }
                    let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cell.textViewHeight.isActive = true
                    let originalHeight = cell.frame.size.height
                    if ud.float(forKey: "inCellHeight") == 0 {
                        ud.set(inCell.frame.size.height, forKey: "inCellHeight")
                    }
                    let inCellOriginHeight = CGFloat(ud.float(forKey: "inCellHeight"))
                    var frame = textView.frame
                    frame.size.height = textView.contentSize.height
                    textView.frame = frame
                    var cellFrame = cell.frame
                    cellFrame.size.height = height + 10
                    cell.frame = cellFrame
                    if originalHeight < cell.frame.size.height {
                        if inCell.frame.size.height <= cell.frame.size.height + cell.frame.origin.y {
                            inCell.frame.size.height += 16.666666666666664
                        }
                        var heightA = inCell.frame.origin.y + inCell.frame.size.height + textViewHeight.constant + tagCollectionView.frame.height + barHeight
                        let heightB = scrollViewHeight.constant - 30
                        if heightA < heightB {
                            heightA += keyboardHeight
                        }
                        if heightA >= heightB {
                            tableViewHeight.constant += 16.666666666666664
                            scrollViewHeight.constant += 16.666666666666664
                            scrollView.contentOffset.y += 16.666666666666664
                        }
                    } else if originalHeight > cell.frame.size.height {
                        if inCell.frame.size.height > inCellOriginHeight {
                            inCell.frame.size.height -= 16.666666666666664
                        }
                        if tableViewHeight.constant > memoTableView.contentSize.height {
                            tableViewHeight.constant -= 16.666666666666664
                            scrollViewHeight.constant -= 16.666666666666664
                        }
                    }
                } else if let inCell = memoTableView.cellForRow(at: indexPath) as? SheetInTableViewCell {
                    let cellPoint = textView.convert(CGPoint(x: 10, y: 10), to: inCell.tableView)
                    let cellIndexPath = inCell.tableView.indexPathForRow(at: cellPoint)!
                    guard let cell = inCell.tableView.cellForRow(at: cellIndexPath) as? SheetTableViewCell else { fatalError() }
                    let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cell.textView1Height.isActive = true
                    cell.textView2Height.isActive = true
                    let originalHeight = cell.frame.size.height
                    if ud.float(forKey: "inCellHeight") == 0 {
                        ud.set(inCell.frame.size.height, forKey: "inCellHeight")
                    }
                    let inCellOriginHeight = CGFloat(ud.float(forKey: "inCellHeight"))
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
                        if inCell.frame.size.height <= cell.frame.size.height + cell.frame.origin.y {
                            inCell.frame.size.height += 16.666666666666664
                        }
                        var heightA = inCell.frame.origin.y + inCell.frame.size.height + textViewHeight.constant + tagCollectionView.frame.height + barHeight
                        let heightB = scrollViewHeight.constant - 30
                        if heightA < heightB {
                            heightA += keyboardHeight
                        }
                        if heightA >= heightB {
                            tableViewHeight.constant += 16.666666666666664
                            scrollViewHeight.constant += 16.666666666666664
                            scrollView.contentOffset.y += 16.666666666666664
                        }
                    } else if originalHeight > cell.frame.size.height {
                        if inCell.frame.size.height > inCellOriginHeight {
                            inCell.frame.size.height -= 16.666666666666664
                        }
                        if tableViewHeight.constant > memoTableView.contentSize.height {
                            tableViewHeight.constant -= 16.666666666666664
                            scrollViewHeight.constant -= 16.666666666666664
                        }
                    }
                }
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == titleTextView {
            let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
            try! realm.write {
                album.name = textView.text
            }
            if textView.text == "" {
                textView.text = NSLocalizedString("Album Name", comment: "")
                textView.textColor = .systemGray4
                doneButton.isEnabled = false
            }
            if album.name == "" {
                doneButton.isEnabled = false
            } else {
                doneButton.isEnabled = true
            }
            self.viewWillLayoutSubviews()
            changeLayoutOfMemo()
        } else {
            let tag = textView.tag
            let point = textView.convert(CGPoint.zero, to: memoTableView)
            let indexPath = memoTableView.indexPathForRow(at: point)!
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
                let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
                if textView.text != "" {
                    if memos.boolList.count == tag {
                        let list = BoolList()
                        list.text = textView.text
                        list.listID = tag
                        try! realm.write {
                            memos.boolList.append(list)
                        }
                    } else {
                        try! realm.write {
                            memos.boolList[tag].text = textView.text
                        }
                    }
                }
            } else if tableViewKind[indexPath.row].name == "sheet" {
                let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
                if textView.text != "" {
                    if memos.sheet.count == tag {
                        let sheet = Sheet()
                        if textView == tv1 {
                            sheet.text1 = textView.text
                            sheet.text2 = ""
                        } else {
                            sheet.text1 = ""
                            sheet.text2 = textView.text
                        }
                        sheet.sheetID = tag
                        try! realm.write {
                            memos.sheet.append(sheet)
                        }
                    } else {
                        try! realm.write {
                            if textView == tv1 {
                                memos.sheet[tag].text1 = textView.text
                            } else {
                                memos.sheet[tag].text2 = textView.text
                            }
                        }
                    }
                }
            }
            tableViewKindSave()
            memoTableView.reloadData()
            reloadView()
            ud.set(0, forKey: "inCellHeight")
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let point = textField.convert(CGPoint.zero, to: memoTableView)
        ud.set(Double(textField.frame.height + point.y), forKey: "textViewPoint_index")
        ud.set(false, forKey: "titleEdit-Bool")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
                
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let tag = textField.tag
        let point = textField.convert(CGPoint.zero, to: memoTableView)
        let indexPath = memoTableView.indexPathForRow(at: point)!
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)")
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
        reloadView()
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
        titleButton.tag = tag
        deleteButton.tag = tag
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
        reloadView()
        changeLayoutOfMemo()
        titleButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        detailButtonBool.1 = false
    }
    
    @objc func deleteButtonAction(sender: UIButton) {
        let tag = sender.tag
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        try! realm.write {
            realm.delete(memos)
        }
        tableViewKindSave()
        memoTableView.reloadData()
        reloadView()
        changeLayoutOfMemo()
        titleButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        detailButtonBool.1 = false
    }
    
    @objc func listButtonAction(sender: UIButton) {
        let tag = sender.tag
        let point = sender.convert(CGPoint.zero, to: memoTableView)
        if let indexPath = memoTableView.indexPathForRow(at: point) {
            let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[indexPath.row].memo.id)").first!
            if memos.boolList.count != tag {
                if tableViewKind[indexPath.row].memo.boolList[tag].bool == false {
                    sender.tintColor = .red
                    try! realm.write {
                        memos.boolList[tag].bool = true
                    }
                } else {
                    sender.tintColor = .lightGray
                    try! realm.write {
                        memos.boolList[tag].bool = false
                    }
                }
            } else {
                let list = BoolList()
                list.bool = true
                list.listID = tag
                try! realm.write {
                    memos.boolList.append(list)
                }
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        reloadView()
        changeLayoutOfMemo()
    }
    
    @objc func addButtonAction(sender: UIButton) {
        let tag = sender.tag
        let memos = realm.objects(Memos.self).filter("id == \(tableViewKind[tag].memo.id)").first!
        doneBool = true
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == memoCollectionView {
            return 6
        } else if collectionView == tagCollectionView {
            return tagArray.count
        } else {
            if collectionView.tag == section {
                if tableViewKind[section].name == "grid" {
                    return tableViewKind[section].memo.grid.count + 1
                } else if tableViewKind[section].name == "photo" {
                    return tableViewKind[section].memo.photos.count
                }
            }
            return Int()
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
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        return [dragItem]
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
        collectionView.reloadData()
        tableViewKindSave()
        memoTableView.reloadData()
        changeLayoutOfMemo()
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
            cell.backgroundColor = UIColor(red: 0.886, green: 0.196, blue: 0.494, alpha: 1)
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
                cell.deleteButton.addTarget(self, action: #selector(contentDeleteButtonAction(sender:)), for: .touchUpInside)
                cell.deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
                cell.deleteButton.tintColor = .systemRed
                cell.deleteButton.backgroundColor = .systemGray6
                cell.deleteButton.layer.cornerRadius = 10
                cell.deleteButton.layer.maskedCorners = [.layerMaxXMinYCorner]
                cell.title.layer.maskedCorners = [.layerMinXMinYCorner]
                cell.title.placeholder = NSLocalizedString("Title", comment: "")
                cell.deleteButtonWidth.constant = 30
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
                cell.deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
                cell.deleteButton.isUserInteractionEnabled = true
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
            try! realm.write {
                memos.link.remove(at: tag/2)
            }
        } else if tableViewKind[indexPath.row].name == "photo" {
            try! realm.write {
                memos.photos.remove(at: tag)
            }
        } else if tableViewKind[indexPath.row].name == "list" {
            if tag < memos.boolList.count {
                if memos.boolList.count == 1 {
                    try! realm.write {
                        realm.delete(memos)
                    }
                } else {
                    try! realm.write {
                        memos.boolList.remove(at: tag)
                    }
                }
            }
        } else if tableViewKind[indexPath.row].name == "sheet" {
            if tag < memos.sheet.count {
                if memos.sheet.count == 1 {
                    try! realm.write {
                        realm.delete(memos)
                    }
                } else {
                    try! realm.write {
                        memos.sheet.remove(at: tag)
                    }
                }
            }
        }
        tableViewKindSave()
        memoTableView.reloadData()
        reloadView()
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
            reloadView()
            changeLayoutOfMemo()
            scrollView.contentOffset.y = scrollViewHeight.constant - self.view.frame.height + (self.tabBarController?.tabBar.frame.height)! + (self.navigationController?.navigationBar.frame.height)! + 20
        } else if collectionView == tagCollectionView {
            collectionView.deselectItem(at: indexPath, animated: false)
        } else {
            if tableViewKind[indexPath.section].name == "photo" {
                doneBool = true
                ud.set(tableViewKind[indexPath.section].memo.photos[indexPath.row].imageID, forKey: "photoID_value")
                ud.set("photoVC", forKey: "segue_value")
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
                return CGSize(width: (self.view.frame.width - 40)/2 - 25, height: (self.view.frame.width - 40)/2 - 30)
            } else if tableViewKind[indexPath.section].name == "photo" {
                if tableViewKind[indexPath.section].memo.photos.count == 1 {
                    return CGSize(width: self.view.frame.width - 70, height: (self.view.frame.width - 40)/2 - 20)
                } else {
                    return CGSize(width: (self.view.frame.width - 40)/2 - 25, height: (self.view.frame.width - 40)/2 - 20)
                }
            }
            return CGSize()
        }
    }
}

class AttatchTagViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    var tagArray = [String]()
    let ud = UserDefaults.standard
    let realm = try! Realm()
    var button = UIButton()
    var selectedTagArray = [String]()

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneButton(_ sender: Any) {
        textField.resignFirstResponder()
        photoLibraryVCBool = false
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
        
        if photoLibraryVCBool == true {
            selectedTags.removeAll()
        }
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
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if photoLibraryVCBool == true {
            let tag = Tag()
            if textField.text != "" {
                tag.tag = textField.text!
                try! realm.write {
                    for i in selectedPhotos {
                        let photo = realm.objects(Photo.self).filter("imageID == \(i)").first!
                        tag.imageID = i
                        var bool = false
                        for t in photo.tag {
                            if t.tag == tag.tag {
                                bool = true
                            }
                        }
                        if bool == false {
                            photo.tag.append(tag)
                        }
                    }
                }
                selectedTagArray.append(textField.text!)
                let orderedSet = NSOrderedSet(array: selectedTagArray)
                selectedTagArray = orderedSet.array as! [String]
            }
        } else {
            var boolA = false
            var boolB = false
            let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
            if textField.text != "" {
                for t in tagArray {
                    if textField.text == t {
                        boolA = true
                    }
                }
                if album.tag.count != 0 {
                    for i in album.tag {
                        if i.tag == textField.text {
                            boolB = true
                        }
                    }
                        
                    if boolA == false || boolA == true, boolB == false {
                        var tagBool = false
                        for a in tagArray {
                            if a == textField.text {
                                tagBool = true
                                let tag = Tag()
                                tag.tag = a
                                tag.albumID = album.id
                                try! realm.write {
                                    album.tag.append(tag)
                                }
                            }
                        }
                        if tagBool == false {
                            let newTag = Tag()
                            newTag.tag = textField.text!
                            newTag.albumID = album.id
                            try! realm.write {
                                album.tag.append(newTag)
                            }
                        }
                    }
                } else {
                    if boolA == false {
                        let newTag = Tag()
                        newTag.tag = textField.text!
                        newTag.albumID = album.id
                        try! realm.write {
                            album.tag.append(newTag)
                        }
                    }
                }
            }
        }
            
        textField.text = ""
        tagArray.removeAll()
        saveTagArray()
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tagArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCell", for: indexPath) as? CustomCell else {
            fatalError("Could not create custom cell.")
        }
        cell.layer.cornerRadius = 10
        var bool = false
        if photoLibraryVCBool == true {
            for i in selectedTagArray {
                if i == tagArray[indexPath.item] {
                    bool = true
                }
            }
        } else {
            let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
            for  i in album.tag {
                if tagArray[indexPath.item] == i.tag {
                    bool = true
                }
            }
        }
        
        if bool == true {
            cell.backgroundColor = UIColor(red: 0.886, green: 0.196, blue: 0.494, alpha: 1)
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
        if photoLibraryVCBool == true {
            let tag = Tag()
            tag.tag = tagArray[indexPath.item]
            try! realm.write {
                for i in selectedPhotos {
                    var bool = false
                    let photo = realm.objects(Photo.self).filter("imageID == \(i)").first!
                    tag.imageID = i
                    for (index, t) in photo.tag.enumerated() {
                        if t.tag == tag.tag {
                            if cell.tagLabel.textColor == .white {
                                photo.tag.remove(at: index)
                            }
                            bool = true
                        }
                    }
                    if bool == false {
                        if cell.tagLabel.textColor == .label {
                            photo.tag.append(tag)
                        }
                    }
                }
            }
            if cell.tagLabel.textColor == .label {
                cell.backgroundColor = UIColor(red: 0.886, green: 0.196, blue: 0.494, alpha: 1)
                cell.tagLabel.textColor = .white
                selectedTagArray.append(tagArray[indexPath.item])
                let orderedSet = NSOrderedSet(array: selectedTagArray)
                selectedTagArray = orderedSet.array as! [String]
            } else {
                cell.backgroundColor = .systemGray6
                cell.tagLabel.textColor = .label
                for (index, i) in selectedTagArray.enumerated() {
                    if i == tagArray[indexPath.row] {
                        selectedTagArray.remove(at: index)
                    }
                }
            }
        } else {
            let album = realm.objects(Album.self).filter("id == \(ud.integer(forKey: "view-albumContents"))").first!
            var bool = false
            if album.tag.count != 0 {
                for i in album.tag {
                    if tagArray[indexPath.item] == i.tag {
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
                    let tag = Tag()
                    tag.tag = tagArray[indexPath.item]
                    tag.albumID = album.id
                    try! realm.write {
                        album.tag.append(tag)
                    }
                    cell.backgroundColor = UIColor(red: 0.886, green: 0.196, blue: 0.494, alpha: 1)
                    cell.tagLabel.textColor = .white
                }
            } else {
                let tag = Tag()
                tag.tag = tagArray[indexPath.item]
                tag.albumID = album.id
                try! realm.write {
                    album.tag.append(tag)
                }
                cell.backgroundColor = UIColor(red: 0.886, green: 0.196, blue: 0.494, alpha: 1)
                cell.tagLabel.textColor = .white
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
