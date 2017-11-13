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
    @IBOutlet weak var stackView: UIStackView!
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard

    var messages = [Message]()
    var messageViews = [UIView]()
    var schools = [School]()
    var yHeight: CGFloat = 0.0
    var sideBar = UITableView()
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
        
//        loadMessages()
        sideBar.reloadData()
        checkLocation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsShowing(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsHiding(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func loadUI(){
      
        getSchools()
            
        let navHeight = self.navigationController!.navigationBar.frame.height
        
        yHeight = navHeight * 1.05
        
        sideBar = UITableView(frame: CGRect(x: 0 - view.bounds.width * 0.5, y: self.navigationController!.navigationBar.frame.height * 1.49, width: view.bounds.width * 0.5, height: view.bounds.height - navHeight * 1.5 ))
        sideBar.delegate = self
        sideBar.dataSource = self
        sideBar.isHidden = false
        sideBar.layer.borderWidth = 2
        sideBar.layer.borderColor = UIColor.black.cgColor
        sideBar.layer.cornerRadius = 5
        sideBar.separatorStyle = .none

        sideBar.reloadData()
        view.addSubview(sideBar)
        animateSideBar(sideBar)
        
        messageView.delegate = self
        messageView.contentSize = CGSize(width: view.bounds.width, height: 0)
        
        sendButton.layer.borderWidth = 1
        sendButton.layer.cornerRadius = 5
        
        self.chatBox.delegate = self
        chatBox.layer.cornerRadius = 10
        chatBox.layer.borderWidth = 1
    }
    
    @IBAction func universityIconTapped(_ sender: Any) {
        animateSideBar(sideBar)
    }
    
    func setupChatBar(){
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

            }else{
                chatBox.layer.borderColor = UIColor.black.cgColor
                chatBox.isEditable = true
                chatBox.text = "Add a message.."
                sendButton.isEnabled = true
            }
        }
    }
    
    func animateSideBar(_ sidebar: UIView){
        
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
    
    @IBAction func userSwipedRight(_ sender: Any) {
        if sideBar.center.x < 0 {
            animateSideBar(sideBar)
        }
    }
    
    @IBAction func userTappedView(_ sender: Any) {
        if sideBar.center.x > 0 {
            animateSideBar(sideBar)
        }
    }
    
    func getSchools(){
        Database.database().reference().child("schools").observeSingleEvent(of: .value, with: { (data) in
            for item in data.children{
                let snap = item as! DataSnapshot
                self.addSchool((snap.value as? [String:Any])!)
            }
        })
    }
    
    func addSchool(_ data : [String : Any]){
        
        let school = School(dict: data)
        schools.append(school!)
        sideBar.reloadData()
    }
    
    func createChatMessage(data : [String : Any]){
        
        let context = appDel.persistentContainer.viewContext
        let chatMessage = Message(context: context)

        chatMessage.text = (data["text"] as! String).trimmingCharacters(in: .newlines)
        chatMessage.uid = data["uid"] as! String
        chatMessage.lat = data["lat"] as! Double
        chatMessage.lon = data["lon"] as! Double
        chatMessage.time = data["time"] as! Int64
        messages.append(chatMessage)
        
        let textLabel = createTextView(chatMessage)
        let timeLabel = createTimeStamp(textLabel, chatMessage: chatMessage)
        messageView.addSubview(textLabel)
        messageView.addSubview(timeLabel)
        messageViews.append(textLabel)
        
        yHeight += textLabel.bounds.height * 1.2
        messageView.contentSize.height = yHeight
        messageView.scrollRectToVisible((messageViews.last?.frame)!, animated: true)

    }
    
    func createTextView(_ chatMessage : Message) -> UITextView {
        
        //message from other user
        var textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.025, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125))
        textLabel.backgroundColor = .white
//            UIColor(red: 0.9255, green: 0.9255, blue: 0.9882, alpha: 1.0) /* #ececfc */
    
//            UIColor(red: 0.6078, green: 1, blue: 0.7373, alpha: 1.0) /* #9bffbc */
        textLabel.text = chatMessage.text
        textLabel.font = UIFont(name: "PingFangHK-Regular", size: 14)
//        textLabel.font = UIFont.systemFont(ofSize: 14)
        
//        textLabel.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        textLabel.sizeToFit()
        
        if defaults.string(forKey: "userID") == chatMessage.uid {
            textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.5, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125))
            textLabel.backgroundColor = UIColor(red: 0.298, green: 0.8706, blue: 1, alpha: 1.0) /* #4cdeff */

//                UIColor(red: 0.2275, green: 0.3255, blue: 0.3961, alpha: 1.0) /* #3a5365 */
//                UIColor(red: 12/255, green: 64/255, blue: 117/255, alpha: 1.0) /* #0c4075 */
//                UIColor(red: 10/255, green: 58/255, blue: 110/255, alpha: 1.0) /* #0a3a6e */
//                UIColor(red: 0.298, green: 0.8706, blue: 1, alpha: 1.0) /* #4cdeff */
//            textLabel.font = UIFont(name: "PingFangHK-Regular", size: 14)
            textLabel.font = UIFont.systemFont(ofSize: 14)
            textLabel.textColor = .black
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
//        textLabel.layer.borderColor = UIColor.black.cgColor
//        textLabel.layer.borderWidth = 1
        textLabel.isUserInteractionEnabled = false
        return textLabel
    }
    
    func createTimeStamp(_ textLabel: UITextView, chatMessage : Message) -> UILabel{
        
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
    
    //core data for later.
//    func loadMessages(){
//        do{
//            messages = try appDel.persistentContainer.viewContext.fetch(Message.fetchRequest())
//        }catch{
//            print(error)
//        }
//    }
    
    @objc func keyboardIsShowing(_ notification : Notification){
        chatBox.text = ""
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardFrame.cgRectValue
            stackView.frame.origin.y -= keyboardRect.height
//
//            let insets = UIEdgeInsetsMake(0,0,messageView.contentSize.height + messageView.contentInset.bottom - messageView.bounds.height,0)
//            messageView.contentInset = insets
//            messageView.scrollIndicatorInsets = insets

//            messageView.contentOffset.y = messageView.contentSize.height - keyboardRect.height - chatView.frame.height
            
            
//            messageView.scrollRectToVisible((messageViews.last?.frame)!, animated: true)

            var offset = messageView.contentOffset
            offset.y = messageView.contentSize.height + messageView.contentInset.bottom - messageView.bounds.height
            messageView.setContentOffset(offset, animated: true)
//
         }
    }
    
    @objc func keyboardIsHiding(_ notification : Notification){
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardFrame.cgRectValue
            stackView.frame.origin.y += keyboardRect.height
//
//            messageView.contentSize.height = yHeight
//            messageView.scrollRectToVisible((messageViews.last?.frame)!, animated: true)
            
        }
        if chatBox.text == ""{
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
        animateSideBar(sideBar)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schools.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.layer.cornerRadius = 5
        cell.textLabel?.font = UIFont(name: "PingFangHK-Light", size: 14)
//        cell.textLabel?
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

