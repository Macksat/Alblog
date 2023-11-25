//
//  ListInTableViewCell.swift
//  Alblog
//
//  Created by Sato Masayuki on 2021/12/08.
//

import UIKit

class ListInTableViewCell: UITableViewCell {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var detailButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        detailButton.setTitle("", for: .normal)
        tableView.register(UINib(nibName: "ListTableViewCell", bundle: nil), forCellReuseIdentifier: "ListTableViewCell")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
