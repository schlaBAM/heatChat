//
//  ViewController.swift
//  HeatChat
//
//  Created by BAM on 2017-10-30.
//  Copyright © 2017 BAM. All rights reserved.
//

import UIKit
import FirebaseDatabase
import QuartzCore
import CoreLocation

@IBDesignable
class HeatChatVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate{

    @IBOutlet weak var messageView: UIScrollView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatBox: UITextView!
    @IBOutlet weak var chatView: UIView!
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
    
    var messages = [Message]()
    var messageViews = [UIView]()
    var schools = [School]()
    var yHeight: CGFloat = 0.0
    var sideBar = UITableView()
    var bar = SideBarView()
    var selectedUni : School?
    var locationManager = CLLocationManager()
    var ref = DatabaseReference()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 20

        ref = Database.database().reference()

        loadUI()
        setupNotifications()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func loadUI() {
        
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.3922, green: 0.5843, blue: 0.9294, alpha: 1.0) /* #6495ed */
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        
        getSchools()
        
        let navHeight = self.navigationController!.navigationBar.frame.height
        yHeight = navHeight * 1.05
        
        let bar = SideBarView(frame: CGRect(x: 0 - view.bounds.width * 0.5, y: self.navigationController!.navigationBar.frame.height * 1.45, width: view.bounds.width * 0.5, height: view.bounds.height - navHeight * 1.5), style: UITableViewStyle.plain)
        bar.delegate = self
        bar.dataSource = self
        view.addSubview(bar)
        bar.animateSideBar(view)
//
//        sideBar = UITableView(frame: CGRect(x: 0 - view.bounds.width * 0.5, y: self.navigationController!.navigationBar.frame.height * 1.45, width: view.bounds.width * 0.5, height: view.bounds.height - navHeight * 1.5))
//        sideBar.delegate = self
//        sideBar.dataSource = self
//        sideBar.layer.borderWidth = 2
//        sideBar.layer.borderColor = UIColor.black.cgColor
//        sideBar.layer.cornerRadius = 5
//        sideBar.separatorStyle = .none

//        view.addSubview(sideBar)
//        animateSideBar(sideBar)
        
        messageView.delegate = self
        messageView.contentSize = CGSize(width: view.bounds.width, height: 0)
        chatBox.delegate = self
        
    }
    
    func getSchools() {
        Database.database().reference().child("schools").observeSingleEvent(of: .value, with: { (data) in
            for item in data.children{
                let snap = item as! DataSnapshot
                self.addSchool((snap.value as? [String:Any])!)
            }
        })
    }
    
    func addSchool(_ data : [String : Any]) {
        let school = School(dict: data)
        schools.append(school!)
//        sideBar.reloadData()
        bar.reloadData()
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsShowing(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsHiding(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @IBAction func universityIconTapped(_ sender: Any) {
        bar.animateSideBar(view)
        animateSideBar(sideBar)
    }
    
    @IBAction func userTappedView(_ sender: Any) {
        if sideBar.center.x > 0 {
            animateSideBar(sideBar)
        }
    }
    
    func animateSideBar(_ sidebar: UIView) {
        
        if sidebar.center.x < 0 {
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                sidebar.center.x += self.view.bounds.width * 0.5
            })
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                sidebar.center.x -= self.view.bounds.width * 0.5
            })
        }
    }
    
    func createChatMessage(data : [String : Any]) {
        
        let message = Chat(data: data)

        let textLabel = createTextView(message!)
        let timeLabel = createTimeStamp(textLabel, chatMessage: message!)
        messageView.addSubview(textLabel)
        messageView.addSubview(timeLabel)
        messageViews.append(textLabel)
        
        yHeight += textLabel.bounds.height + 10
        messageView.contentSize.height = yHeight
        
        if let frame = messageViews.last?.frame {
            
            messageView.scrollRectToVisible(CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height + 10), animated: true)
            
        }
    }
    
    func createTextView(_ chatMessage : /*Message*/ Chat) -> UITextView {
        
        //message from other user
        var textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.025, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125))
        textLabel.backgroundColor = UIColor(red: 0.8471, green: 0.902, blue: 1, alpha: 1.0) /* #d8e6ff */
        textLabel.text = chatMessage.text
        textLabel.font = UIFont(name: "PingFangHK-Regular", size: 14)
        textLabel.sizeToFit()
        
        if defaults.string(forKey: "userID") == chatMessage.uid {
            textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.5, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125))
            textLabel.backgroundColor = UIColor(red: 0.3922, green: 0.5843, blue: 0.9294, alpha: 1.0) /* #6495ed */
//                UIColor(red: 0.6196, green: 0.7529, blue: 1, alpha: 1.0) /* #9ec0ff */
            textLabel.font = UIFont(name: "PingFangHK-Regular", size: 14)
            textLabel.textColor = .white
            textLabel.text = chatMessage.text
//            textLabel.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
            textLabel.sizeToFit()
            textLabel.center.x = messageView.bounds.width*0.975 - textLabel.bounds.width * 0.5
        }
        
        textLabel.layer.shadowColor = UIColor.black.cgColor
        textLabel.layer.shadowOffset = CGSize(width: 12, height: 12)
        textLabel.layer.shadowOpacity = 1.0
        textLabel.layer.shadowRadius = 5.0
        textLabel.layer.cornerRadius = 10
        textLabel.isUserInteractionEnabled = false
        return textLabel
    }
    
    func createTimeStamp(_ textLabel: UITextView, chatMessage : /*Message*/ Chat) -> UILabel {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d h:mm a"
        let date = Date(timeIntervalSince1970: Double(chatMessage.time / 1000))
        
        let timeLabel = UILabel(frame: CGRect(x: messageView.bounds.width * 1.005, y: yHeight, width: messageView.bounds.width * 0.2, height: messageView.bounds.height * 0.1))
        timeLabel.text = dateFormatter.string(from: date)
        timeLabel.font = UIFont(name: "PingFangHK-Regular", size: 10)
        timeLabel.sizeToFit()
        timeLabel.center.y = textLabel.center.y
        timeLabel.textColor = .black
        
        return timeLabel
    }
    
    @objc func keyboardIsShowing(_ notification : Notification) {
        chatBox.text = ""
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {

            let keyboardRect = keyboardFrame.cgRectValue
            messageView.frame.origin.y -= keyboardRect.height
            chatView.frame.origin.y -= keyboardRect.height
            
         }
    }
    
    @objc func keyboardIsHiding(_ notification : Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            
            let keyboardRect = keyboardFrame.cgRectValue
            messageView.frame.origin.y += keyboardRect.height
            chatView.frame.origin.y += keyboardRect.height
            
        }
        
        if chatBox.text == "" {
            chatBox.text = "Add a message.."
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    @IBAction func sendTapped(_ sender: Any) {
        let message = ["lat" : defaults.double(forKey: "userLat"), "lon" : defaults.double(forKey: "userLon"), "text" : chatBox.text, "time" : Int64(NSDate().timeIntervalSince1970 * 1000.0), "uid" : defaults.string(forKey: "userID")!] as [String : Any]
        if let selectedUni = selectedUni {
            if chatBox.text != "" {
                ref.child("schoolMessages").child(selectedUni.path).child("messages").childByAutoId().setValue(message)
                chatBox.text.removeAll()
                view.endEditing(true)
            }
        }
    }
    
    func setupChatBar() {
        //if selectedUni is nil, user hasn't selected a university so this setup wouldn't be needed yet.
        if let selectedUni = selectedUni {
            let userLocation = CLLocation(latitude: defaults.double(forKey: "userLat"), longitude: defaults.double(forKey: "userLon"))
            let schoolLocation = CLLocation(latitude: selectedUni.lat, longitude: selectedUni.lon)
            let distance = userLocation.distance(from: schoolLocation) // in metres
            
            if distance > 30000 {
                chatBox.layer.borderColor = UIColor.gray.cgColor
                chatBox.isEditable = false
                chatBox.text = "Too far away to post!"
                sendButton.isEnabled = false
            } else {
                chatBox.layer.borderColor = UIColor.black.cgColor
                chatBox.isEditable = true
                chatBox.text = "Add a message.."
                sendButton.isEnabled = true
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select School"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //clear messageView, load messages, dismiss sidebar
        tableView.deselectRow(at: indexPath, animated: true)
    
        if selectedUni == nil || selectedUni!.path != schools[indexPath.row].path {
            if selectedUni != nil {
                ref.child("schoolMessages").child(selectedUni!.path).child("messages").removeAllObservers()
            }
            selectedUni = schools[indexPath.row]
            messages.removeAll()
            messageViews.removeAll()
            messageView.subviews.forEach({$0.removeFromSuperview()})
            
            ref.child("schoolMessages").child(selectedUni!.path).child("messages").queryOrdered(byChild: "time").queryLimited(toLast: 100).observe(DataEventType.childAdded) { (data) in
                guard let data = data.value as? [String : Any] else {return}
                self.createChatMessage(data: data)
            }
            
        }
        
        DispatchQueue.main.async {
            self.navigationItem.title = "\(self.selectedUni!.name) Heatchat"
            self.setupChatBar()
        }
        
//        animateSideBar(sideBar)
        bar.animateSideBar(view)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schools.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.layer.cornerRadius = 5
        cell.textLabel?.font = UIFont(name: "PingFangHK-Light", size: 14)
        cell.textLabel?.text = schools[indexPath.row].name
        
        return cell
    }
    
    func checkLocation() {
        
        switch(CLLocationManager.authorizationStatus()) {
        case .denied, .notDetermined, .restricted:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if let coordinates = manager.location?.coordinate {
            print("new auth coords: \(coordinates.latitude),\(coordinates.longitude)")
            defaults.set(coordinates.latitude, forKey: "userLat")
            defaults.set(coordinates.longitude, forKey: "userLon")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordinates = manager.location?.coordinate {
            print("coords: \(coordinates.latitude),\(coordinates.longitude)")
            defaults.set(coordinates.latitude, forKey: "userLat")
            defaults.set(coordinates.longitude, forKey: "userLon")
        }
        setupChatBar()
    }
    
}

