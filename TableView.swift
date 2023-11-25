//
//  TableView.swift
//  PhotoCategorizer
//
//  Created by Sato Masayuki on 2021/08/08.
//

import UIKit
import RealmSwift

var tableViewKind = [(name: String, memo: Memos)]()
var listArray = [BoolList]()
var linkArray = [Link]()
var sheetArray = [Sheet]()
var gridArray = [Grid]()
var memosArray = [Memos]()

class CustomTableView: UITableView {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesBegan(touches, with: event)
    }
}
