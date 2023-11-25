//
//  WebViewController.swift
//  PhotoCategorizer
//
//  Created by Sato Masayuki on 2021/08/21.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    
    let ud = UserDefaults.standard
    var observations = [NSKeyValueObservation]()
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBAction func backButton(_ sender: Any) {
        webView.goBack()
        self.navigationItem.title = webView.url?.absoluteString
    }
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBAction func forwardButton(_ sender: Any) {
        webView.goForward()
        self.navigationItem.title = webView.url?.absoluteString
    }
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: ud.string(forKey: "webURL_value")!)!
        let request = URLRequest(url: url)
        webView.load(request)
        webView.allowsBackForwardNavigationGestures = true
        self.navigationItem.title = webView.url?.absoluteString
        
        backButton.isEnabled = false
        forwardButton.isEnabled = false
        
        observations.append(webView.observe(\.canGoBack, options: .new) {_, change in
            if let value = change.newValue {
                DispatchQueue.main.async {
                    self.backButton.isEnabled = value
                }
            }
        })
        
        observations.append(webView.observe(\.canGoForward, options: .new) {_, change in
            if let value = change.newValue {
                DispatchQueue.main.async {
                    self.forwardButton.isEnabled = value
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
        DispatchQueue.main.async {
            self.backButton.isEnabled = webView.canGoBack
            self.forwardButton.isEnabled = webView.canGoForward
        }
    }
}
