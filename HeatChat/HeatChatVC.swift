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
class HeatChatVC: UIViewController, UITextViewDelegate{

    @IBOutlet weak var messageView: UIScrollView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatBox: UITextView!
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    var messages = [Message]()
    var messageViews = [UIView]()
    var yHeight: CGFloat = 0.0
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsShowing(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsHiding(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
//        Database.database().reference().child("messages").observe(DataEventType.childAdded) { (data) in
//            guard let data = data.value as? [String : Any] else {return}
//            self.createChatMessage(data: data)
//        }
        
        Database.database().reference().child("messages").queryOrdered(byChild: "time").queryLimited(toLast: 100).observe(DataEventType.childAdded) { (data) in
            guard let data = data.value as? [String : Any] else {return}
            self.createChatMessage(data: data)
        }
        yHeight = self.navigationController!.navigationBar.frame.height * 1.005
        self.chatBox.delegate = self
        loadUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        loadMessages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadUI(){
        sendButton.layer.borderWidth = 1
        sendButton.layer.cornerRadius = 5
        chatBox.layer.cornerRadius = 10
        chatBox.layer.borderColor = UIColor.black.cgColor
        chatBox.layer.borderWidth = 1
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
        
        //message from other user
        var textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.05, y: yHeight, width: view.bounds.width * 0.45, height: view.bounds.height * 0.125))
        textLabel.backgroundColor = UIColor(red: 0.6078, green: 1, blue: 0.7373, alpha: 1.0) /* #9bffbc */
        textLabel.text = chatMessage.text
        textLabel.sizeToFit()

//                UIColor(red: 0, green: 0.9176, blue: 0.5176, alpha: 1.0) /* #00ea84 */

        if defaults.string(forKey: "userID") == chatMessage.uid {
            textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.5, y: yHeight, width: view.bounds.width * 0.45, height: view.bounds.height * 0.125))
            textLabel.backgroundColor = UIColor(red: 0.298, green: 0.8706, blue: 1, alpha: 1.0) /* #4cdeff */
            textLabel.text = chatMessage.text
            textLabel.sizeToFit()
            textLabel.center.x = view.bounds.width*0.95 - textLabel.bounds.width * 0.5
        }
        
        textLabel.layer.cornerRadius = 10
        textLabel.layer.borderColor = UIColor.black.cgColor
        textLabel.layer.borderWidth = 1
        textLabel.isUserInteractionEnabled = false
        messageView.addSubview(textLabel)
        
        messageViews.append(textLabel)
        
        yHeight += textLabel.bounds.height * 1.2
    
        messageView.contentSize.height = yHeight        
        messageView.scrollRectToVisible(messageView.frame, animated: true)

        messageView.scrollRectToVisible((messageViews.last?.frame)!, animated: true)

    }
    
    func loadMessages(){
        
        
//        do{
//            messages = try appDel.persistentContainer.viewContext.fetch(Message.fetchRequest())
//        }catch{
//            print(error)
//        }
    }
    
    @objc func keyboardIsShowing(_ notification : Notification){
        chatBox.text = ""
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardFrame.cgRectValue
            stackView.frame.origin.y -= keyboardRect.height
            messageView.scrollRectToVisible((messageViews.last?.frame)!, animated: true)
        }
    }
    
    @objc func keyboardIsHiding(_ notification : Notification){
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRect = keyboardFrame.cgRectValue
            stackView.frame.origin.y += keyboardRect.height
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
        Database.database().reference().child("messages").childByAutoId().setValue(message)
        
        chatBox.text = "Add a message.."
    }
    
    /*
     
     //create a messageview for the chat bubble, and how long ago it was sent underneath (could pull out like unite)
     // -> user disabled textview for the bubble?
     */
}

