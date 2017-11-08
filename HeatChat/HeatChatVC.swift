//
//  ViewController.swift
//  HeatChat
//
//  Created by BAM on 2017-10-30.
//  Copyright © 2017 BAM. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

@IBDesignable
class HeatChatVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var messageView: UIScrollView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatBox: UITextView!
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    var messages = [Message]()
    var messageViews = [UIView]()
    var schools = [School]()
    var yHeight: CGFloat = 0.0
    let defaults = UserDefaults.standard
    var sideBar = UITableView()
    var selectedUni : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        loadUI()
        setupNotifications()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
//        loadMessages()
        sideBar.reloadData()
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
        
        sideBar = UITableView(frame: CGRect(x: 0 - view.bounds.width * 0.5, y: navHeight, width: view.bounds.width * 0.5, height: view.bounds.height - (navHeight)))
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
        messageView.contentSize = CGSize(width: messageView.bounds.width, height: 0)
        
        sendButton.layer.borderWidth = 1
        sendButton.layer.cornerRadius = 5
        
        self.chatBox.delegate = self
        chatBox.layer.cornerRadius = 10
        chatBox.layer.borderColor = UIColor.black.cgColor
        chatBox.layer.borderWidth = 1
        
    }
    
    @IBAction func universityIconTapped(_ sender: Any) {
        animateSideBar(sideBar)
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
        var textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.05, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125))
        textLabel.backgroundColor = UIColor(red: 0.6078, green: 1, blue: 0.7373, alpha: 1.0) /* #9bffbc */
        textLabel.text = chatMessage.text
        textLabel.font = UIFont(name: "PingFangHK-Regular", size: 12)
        textLabel.sizeToFit()
        
        if defaults.string(forKey: "userID") == chatMessage.uid {
            textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.5, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125))
            textLabel.backgroundColor = UIColor(red: 0.298, green: 0.8706, blue: 1, alpha: 1.0) /* #4cdeff */
            textLabel.font = UIFont(name: "PingFangHK-Regular", size: 12)
            textLabel.text = chatMessage.text
            textLabel.sizeToFit()
            textLabel.center.x = messageView.bounds.width*0.95 - textLabel.bounds.width * 0.5
        }
        
        textLabel.layer.cornerRadius = 10
        textLabel.layer.borderColor = UIColor.black.cgColor
        textLabel.layer.borderWidth = 1
        textLabel.isUserInteractionEnabled = false
        
        return textLabel
    }
    
    func createTimeStamp(_ textLabel: UITextView, chatMessage : Message) -> UILabel{
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d h:mm a"
        let date = Date(timeIntervalSince1970: Double(chatMessage.time))
        
        let timeLabel = UILabel(frame: CGRect(x: messageView.bounds.width * 1.02, y: yHeight, width: messageView.bounds.width * 0.2, height: messageView.bounds.height * 0.1))
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
            
            var offset = messageView.contentOffset
            offset.y = messageView.contentSize.height + messageView.contentInset.bottom - messageView.bounds.height
            messageView.setContentOffset(offset, animated: true)
            
         }
    }
    
    @objc func keyboardIsHiding(_ notification : Notification){
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardFrame.cgRectValue
            stackView.frame.origin.y += keyboardRect.height
            
            var offset = messageView.contentOffset
            offset.y = chatView.frame.height
            messageView.setContentOffset(offset, animated: true)

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
        let message = ["lat" : defaults.double(forKey: "userLat"), "lon" : defaults.double(forKey: "userLon"), "text" : chatBox.text, "time" : Int64(NSDate().timeIntervalSince1970), "uid" : defaults.string(forKey: "userID")!] as [String : Any]
        if let selectedUni = selectedUni {
            if chatBox.text != "" {
                Database.database().reference().child(selectedUni).child("messages").childByAutoId().setValue(message)
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
        
        if selectedUni != schools[indexPath.row].path {
            selectedUni = schools[indexPath.row].path 
            messages.removeAll()
            messageViews.removeAll()
            messageView.subviews.forEach({$0.removeFromSuperview()})
            
            Database.database().reference().child(selectedUni!).child("messages").queryOrdered(byChild: "time").queryLimited(toLast: 100).observe(DataEventType.childAdded) { (data) in
                guard let data = data.value as? [String : Any] else {return}
                self.createChatMessage(data: data)
            }
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
    
}

