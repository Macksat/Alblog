//
//  AddLinkViewController.swift
//  AddLinkViewController
//
//  Created by Sato Masayuki on 2021/09/26.
//

import UIKit
import WebKit
import RealmSwift

class AddLinkViewController: UIViewController, WKNavigationDelegate, UITextFieldDelegate {
    
    let ud = UserDefaults.standard
    let realm = try! Realm()
    var observations = [NSKeyValueObservation]()

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBAction func addButton(_ sender: Any) {
        let alert = UIAlertController(title: "Edit Link Name", message: "", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.delegate = self
            textField.layer.cornerRadius = 10
            textField.backgroundColor = .systemGray6
            textField.text = self.webView.title!
            textField.placeholder = "Type link name"
            textField.borderStyle = .none
        }
        let doneAction = UIAlertAction(title: "Done", style: .default) { UIAlertAction in
            let id = self.ud.integer(forKey: "memosLink_id")
            let memos = self.realm.objects(Memos.self).filter("id == \(id)").first!
            let link = Link()
            link.linkID = memos.link.count
            link.title = alert.textFields![0].text!
            link.url = self.webView.url!.absoluteString
            link.image = self.getScreenShot().jpegData(compressionQuality: 0.1)! as NSData
            try! self.realm.write {
                memos.link.append(link)
            }
            self.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(doneAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBAction func forwardButton(_ sender: Any) {
        webView.goForward()
        self.navigationItem.title = webView.url?.absoluteString
    }
    @IBAction func backwardButton(_ sender: Any) {
        webView.goBack()
        self.navigationItem.title = webView.url?.absoluteString
    }
    @IBOutlet weak var backwardButton: UIBarButtonItem!
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let url = URL(string: "https://www.google.com/search?")!
        let request = URLRequest(url: url)
        webView.load(request)
        webView.allowsBackForwardNavigationGestures = true
        self.navigationItem.title = webView.url?.absoluteString
        
        backwardButton.isEnabled = false
        forwardButton.isEnabled = false
        
        observations.append(webView.observe(\ .canGoBack, options: .new) { _, change in
            if let value = change.newValue {
                DispatchQueue.main.async {
                    self.backwardButton.isEnabled = value
                }
            }
        })
    }
   
    override func loadView() {
        super.loadView()
        
        webView.navigationDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.backwardButton.isEnabled = webView.canGoBack
        self.forwardButton.isEnabled = webView.canGoForward
    }
    
    func getScreenShot() -> UIImage {
        let rect = self.view.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        self.view.layer.render(in: context)
        let capturedImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return capturedImage
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField.text == "" {
            textField.text = self.webView.title!
        }
        return true
    }
}
