//
//  ContibutionTableViewCell.swift
//  srsly
//
//  Created by aang on 1/28/23.
//

import UIKit
import WebKit



class ContibutionTableViewCell: UITableViewCell {
    
    
    
    @IBOutlet public weak var githubButton: UIButton!
    @IBOutlet public weak var siweButton: UIButton!
    @IBOutlet public weak var authType: UILabel!
    @IBOutlet public weak var sessionID: UILabel!
    @IBOutlet public weak var contributeButton: UIButton!
    @IBOutlet public weak var contributed: UILabel!
    
    public var authtext = ""
    public var githubauthurl = URL(string: "")
    public var authWithGit = false
    public var sessionIDString = ""
    public var webView = WKWebView()
    
    public weak var viewController : ViewController?
    
    
    @IBAction func githubButtonPressed(_ sender: Any) {
        print("github")
        self.authWithGit = true
        print("self.authWithGit: ", self.authWithGit)
        self.viewController?.githubAuthVC(authWithGit: self.authWithGit)
    }
    
    @IBAction func siweButtonPressed(_ sender: Any) {
        print("eth")
        self.authWithGit = false
        self.viewController?.githubAuthVC(authWithGit: self.authWithGit)
    }
    
    @IBAction func contributeButtonTapped(_ sender: Any) {
//        viewController?.tryContribute(sessionID: self.sessionIDString)
        DispatchQueue.main.async {
            self.contributeButton.isEnabled = false
            self.contributeButton.backgroundColor = UIColor.red
            self.viewController?.tableView.reloadData()
            //self.contributeButton.isHidden = true
            self.contributed.isHidden = false
            self.contributed.text = "trying to contribute..."
        }
        
        DispatchQueue.global().async {
            var tryAgain = true
            while(tryAgain) {
                print("trying again")
                self.viewController?.tryContributeRequest(sessionID: self.sessionIDString) { result in
                    tryAgain = result
                }
                Thread.sleep(forTimeInterval: 30)
            }
            DispatchQueue.main.async {
                self.contributed?.text = "ready to contribute"
                self.contributeButton.isEnabled = true
                self.contributeButton.backgroundColor = UIColor.green
            }
        }
    }

    static let identifier = "ContibutionTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "ContibutionTableViewCell", bundle: nil)
    }
    
    func updateAuthState(id: String){
        print("here")
        self.sessionIDString = id
        self.sessionID.text = id
        self.contributeButton.isHidden = false
        self.githubButton.isHidden = true
        self.siweButton.isHidden = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        githubButton.layer.cornerRadius = 5
        githubButton.layer.borderWidth = 1
        githubButton.layer.borderColor = UIColor.black.cgColor

        siweButton.layer.cornerRadius = 5
        siweButton.layer.borderWidth = 1
        siweButton.layer.borderColor = UIColor.black.cgColor
        
        contributeButton.isHidden = true
        contributed.isHidden = true

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
