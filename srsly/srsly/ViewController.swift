//
//  ViewController.swift
//  srsly
//
//  Created by aang on 1/25/23.
//

import UIKit
import WebKit

struct Status: Codable {
    let lobby_size: Int
    let num_contributions: Int
    let sequencer_address: String
}

class ViewController: UIViewController {

    private var tableData = [String]()
    @IBOutlet var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // clear cache on viewDidLoad()
        WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache], modifiedSince: Date(timeIntervalSince1970: 0), completionHandler:{ })
        // Do any additional setup after loading the view.
        // set the background color to be purple in hex
        view.backgroundColor = UIColor(red: 0.92, green: 0.88, blue: 0.99, alpha: 1.0)
        title = "♢ KZG Ceremony ♢"

        
        tableView.register(StatusTableViewCell.nib(), forCellReuseIdentifier: StatusTableViewCell.identifier)
        tableView.register(ContibutionTableViewCell.nib(), forCellReuseIdentifier: ContibutionTableViewCell.identifier)
        tableView.register(VerifyTableViewCell.nib(), forCellReuseIdentifier: VerifyTableViewCell.identifier)
        
        tableView.allowsSelection = false
        self.tableView.layer.cornerRadius = 10.0

        tableView.delegate = self
        tableView.dataSource = self
        
        fetchData()
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        
    }
    
    @objc private func didPullToRefresh(){
        // refetch data here
        fetchData()
    }
    
    private func fetchData() {
        // https://eprint-sanity.com/info/status
        // {"lobby_size":0,"num_contributions":0,"sequencer_address":"0x9b1855fe5D1D3b3d91da8fdEF307161a74db0133"}
        
        tableData.removeAll()
        
        if tableView.refreshControl?.isRefreshing == true{
            print("refreshing data")
        } else {
            print("fetching first data")
        }
        
        guard let url = URL(string: "https://kzg-ceremony-sequencer-dev.fly.dev/info/status/") else {
            return
        }

        let task = URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, response, error in
            // validate data exists
            guard let strongSelf = self, let data = data, error == nil else {
                print("something went wrong")
                return
            }

            var result: Status?
            do {
                result = try JSONDecoder().decode(Status.self, from: data)
            }
            catch {
                print("failed to convert \(error.localizedDescription)")
            }

            guard let json = result else {
                return
            }
            
            print(json)
            
            strongSelf.tableData.append("Lobby Size: \(json.lobby_size)")
            strongSelf.tableData.append("Total Contributions: \(json.num_contributions)")
            strongSelf.tableData.append("Sequencer Address: \(json.sequencer_address)")
            
            DispatchQueue.main.async {
                strongSelf.tableView.refreshControl?.endRefreshing()
                strongSelf.tableView.reloadData()
            }
        })
        task.resume()
    }
    
    @objc func cancelAction() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func refreshAction() {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContibutionTableViewCell") as! ContibutionTableViewCell
        cell.webView.reload()
    }
    
    func tryContributeRequest(sessionID: String, completion: @escaping (Bool) -> Void) {
        let trycontribute = "https://kzg-ceremony-sequencer-dev.fly.dev/lobby/try_contribute"
        let requestURL: NSMutableURLRequest = NSMutableURLRequest(url: URL(string: trycontribute)!)
        requestURL.addValue("Bearer " + sessionID, forHTTPHeaderField: "Authorization")
        requestURL.httpMethod = "POST"
        let taskTryContribute = URLSession.shared.dataTask(with: requestURL as URLRequest) { data, resp, error in
            if error == nil {
                let result = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                if result!["error"] != nil {
                    print("error")
                    completion(true)
                }
                else {
                    print("NO error")
                    completion(false)
                }
            }
        }
        taskTryContribute.resume()
    }
    
    func tryContribute(sessionID: String) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ContibutionTableViewCell") as! ContibutionTableViewCell
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell

        
        cell.contributeButton.isHidden = true
        cell.contributed.isHidden = false
        cell.contributed.text = "trying to contribute..."
        var tryAgain = true
        while(tryAgain) {
            print("trying again")
            tryContributeRequest(sessionID: sessionID) { result in
                tryAgain = result
            }
            Thread.sleep(forTimeInterval: 30)
        }
        cell.contributed?.text = "ready to contribute"
        
        
    }
    
    func githubAuthVC(authWithGit: Bool) {
        // Create github Auth ViewController
        let githubVC = UIViewController()
        // Create WebView
        let webView = WKWebView()
        webView.navigationDelegate = self
        githubVC.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: githubVC.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: githubVC.view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: githubVC.view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: githubVC.view.trailingAnchor)
        ])
        
        let seqauth = "https://kzg-ceremony-sequencer-dev.fly.dev/auth/request_link"
        
        let requestURL: NSMutableURLRequest = NSMutableURLRequest(url: URL(string: seqauth)!)
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell
        fetchURL(with: requestURL as URLRequest, authWithGit: authWithGit) { result in
            let githubauthurl = URL(string: result)
            let urlRequest = URLRequest(url: githubauthurl!)
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if (authWithGit) {
                    cell.authtext = "Authorized with GitHub"
                }
                else {
                    cell.authtext = "Authorized with ETH"
                }
                cell.authType.text = cell.authtext
                cell.githubButton.isHidden = true
                cell.siweButton.isHidden = true
                webView.load(urlRequest)

                // Create Navigation Controller
                let navController = UINavigationController(rootViewController: githubVC)
                let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAction))
                githubVC.navigationItem.leftBarButtonItem = cancelButton
                let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
                githubVC.navigationItem.rightBarButtonItem = refreshButton
                let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                navController.navigationBar.titleTextAttributes = textAttributes
                githubVC.navigationItem.title = "authorization"
                navController.navigationBar.isTranslucent = false
                navController.navigationBar.tintColor = UIColor.white
                navController.navigationBar.barTintColor = UIColor.darkGray
                navController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
                navController.modalTransitionStyle = .coverVertical

                self.present(navController, animated: true, completion: nil)
                
            }
        }
    }
    
    func fetchURL(with requestURL: URLRequest, authWithGit: Bool, completion: @escaping (String) -> Void) {
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell
        let taskGetURL = URLSession.shared.dataTask(with: requestURL as URLRequest) { data, _, error in
            if error == nil {
                let result = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]

                // GitHub Auth URL
                if authWithGit {
                    let authString = (result?["github_auth_url"] as! String)
                    completion(authString)
                }
                else {
                    let authString = (result?["eth_auth_url"] as! String)
                    completion(authString)
                }
            }
        }
        taskGetURL.resume()
    }

}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.RequestForCallbackURL(request: navigationAction.request)
        decisionHandler(.allow)
    }

    func RequestForCallbackURL(request: URLRequest) {
        // Get the authorization code string after the '?code=' and before '&state='
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ContibutionTableViewCell") as! ContibutionTableViewCell
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell

        let requestURLString = (request.url?.absoluteString)! as String
        if requestURLString.contains("code=") {
            self.dismiss(animated: true)
            cell.webView.removeFromSuperview()
            let codestate = (requestURLString.components(separatedBy: "code=")[1].components(separatedBy: "&state="))
            let code = codestate[0]
            let state = codestate[1]
            print("code: " + code)
            print("state: " + state)
            githubRequestForSessionID(authCode: code, authState: state) {
                result in cell.sessionIDString = result
                DispatchQueue.main.async {
                    cell.contributeButton.isHidden = false
                    cell.sessionID!.text = result
//                    print(result)
//                    self.tableView.beginUpdates()
//                    let indexPath = IndexPath(item:  1, section: 0)
//                    self.tableView.reloadRows(at: [indexPath], with: .top)
//                    self.tableView.endUpdates()
//                    cell.updateAuthState(id: result)
                }
            }
        }
    }
    
    func githubRequestForSessionID(authCode: String, authState: String, completion: @escaping (String) -> Void) {
        // Set the GET parameters.
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell

        let rqueryItems = [URLQueryItem(name: "state", value: authState), URLQueryItem(name: "code", value: authCode)]
        var rurlComps = URLComponents(string: "")!
        if cell.authWithGit {
            rurlComps = URLComponents(string: "https://kzg-ceremony-sequencer-dev.fly.dev/auth/callback/github")!
        }
        else {
            rurlComps = URLComponents(string: "https://kzg-ceremony-sequencer-dev.fly.dev/auth/callback/eth")!
        }
        rurlComps.queryItems = rqueryItems
        let url = rurlComps.url!
        let requestURL: NSMutableURLRequest = NSMutableURLRequest(url: url)
        let task = URLSession.shared.dataTask(with: requestURL as URLRequest) { data, _, error in
            if error == nil {
                let result = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                if let value = result!["session_id"] {
                    completion(value as! String)
                }
                else {
                    if let value = result!["error"] {
                        completion(value as! String)
                    }
                }
            }
        
        }
        
        task.resume()
    }
}


extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("you tapped me \(indexPath)")
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0{
            //let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! StatusTableViewCell
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatusTableViewCell", for: indexPath) as! StatusTableViewCell
            cell.lobbySizeLabel?.text = tableData[0]
            cell.numberContrubtionsLabel?.text = tableData[1]
            cell.sequencerAddressLabel?.text = tableData[2]
            cell.center.y = tableView.center.y
            //cell.viewController = self
            cell.clipsToBounds = true
            return cell
        }
        else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContibutionTableViewCell", for: indexPath) as! ContibutionTableViewCell
            //let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell

            cell.viewController = self
            cell.clipsToBounds = true
            return cell
        } else {
            //let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! VerifyTableViewCell
            let cell = tableView.dequeueReusableCell(withIdentifier: "VerifyTableViewCell", for: indexPath) as! VerifyTableViewCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0{
            // first cell
            return CGFloat(200)
        }
        else if indexPath.row == 1{
            return CGFloat(350)
        }
        return CGFloat(250)
    }
}

