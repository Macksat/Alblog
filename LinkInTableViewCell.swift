//
//  TVInTableViewCell.swift
//  TVInTableViewCell
//
//  Created by Sato Masayuki on 2021/09/14.
//

import UIKit
import RealmSwift

class LinkInTableViewCell: UITableViewCell {
    
    let ud = UserDefaults.standard
    let realm = try! Realm()

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButtonHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        addButton.setTitle("Add Link", for: .normal)
        tableView.register(UINib(nibName: "LinkTableViewCell", bundle: nil), forCellReuseIdentifier: "LinkTableViewCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "blankCell")
        self.contentView.layer.cornerRadius = 15
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
