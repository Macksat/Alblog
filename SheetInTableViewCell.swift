//
//  SheetInTableViewCell.swift
//  Alblog
//
//  Created by Sato Masayuki on 2021/12/09.
//

import UIKit

class SheetInTableViewCell: UITableViewCell {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var detailButtonWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tableView.register(UINib(nibName: "SheetTableViewCell", bundle: nil), forCellReuseIdentifier: "SheetTableViewCell")
        detailButton.setTitle("", for: .normal)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
