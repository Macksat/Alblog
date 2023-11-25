//
//  Realm.swift
//  PhotoCategorizer
//
//  Created by Masayuki Sato on 2021/07/03.
//

import UIKit
import RealmSwift

class Album: Object {
    @objc dynamic var id = 0
    @objc dynamic var name = String()
    @objc dynamic var favorite = Bool()
    var album = List<Photo>()
    var tag = List<Tag>()
    var memos = List<Memos>()
    
    static func newID() -> Int {
        let realm = try! Realm()
        if let item = realm.objects(Album.self).sorted(byKeyPath: "id").last {
            return item.id + 1
        } else {
            return 1
        }
    }
}

class Photo: Object {
    @objc dynamic var imageID = Int()
    @objc dynamic var url = String()
    @objc dynamic var favorite = Bool()
    var tag = List<Tag>()
    var memos = List<Memos>()
}

class Tag: Object {
    @objc dynamic var tag = String()
    @objc dynamic var imageID = Int()
    @objc dynamic var albumID = 0
}

class Memos: Object {
    @objc dynamic var id = 0
    @objc dynamic var number = 0
    @objc dynamic var title = ""
    var link = List<Link>()
    @objc dynamic var memo = ""
    var boolList = List<BoolList>()
    var sheet = List<Sheet>()
    var grid = List<Grid>()
    var photos = List<Photo>()
    
    static func newID() -> Int {
        let realm = try! Realm()
        if let item = realm.objects(Memos.self).sorted(byKeyPath: "id").last {
            return item.id + 1
        } else {
            return 1
        }
    }
}

class Link: Object {
    @objc dynamic var linkID = 0
    @objc dynamic var url = String()
    @objc dynamic var image = NSData()
    @objc dynamic var title = ""
}

class BoolList: Object {
    @objc dynamic var listID = 0
    @objc dynamic var text = ""
    @objc dynamic var bool = false
}

class Sheet: Object {
    @objc dynamic var sheetID = 0
    @objc dynamic var text1 = ""
    @objc dynamic var text2 = ""
}

class Grid: Object {
    @objc dynamic var gridID = 0
    @objc dynamic var title = ""
    @objc dynamic var text = ""
}

class Category: Object {
    @objc dynamic var title = ""
}
