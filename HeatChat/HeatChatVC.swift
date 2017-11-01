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
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    var messages = [Message]()
    var messageViews = [UIView]()
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatBox: UITextView!
    var yHeight: CGFloat = 0.0
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        Database.database().reference().child("messages").observe(DataEventType.childAdded) { (data) in
//            guard let data = data.value as? [String : Any] else {return}
//            self.createChatMessage(data: data)
//        }
        
        Database.database().reference().child("messages").queryOrdered(byChild: "time").queryLimited(toLast: 100).observe(DataEventType.childAdded) { (data) in
            guard let data = data.value as? [String : Any] else {return}
            self.createChatMessage(data: data)
        }
        yHeight = self.navigationController!.navigationBar.frame.height * 1.005
        loadUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        loadMessages()
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
        
        DispatchQueue.main.async {
            
            let context = self.appDel.persistentContainer.viewContext
            let chatMessage = Message(context: context)
    
            chatMessage.text = (data["text"] as! String).trimmingCharacters(in: .newlines)
            chatMessage.uid = data["uid"] as! String
            chatMessage.lat = data["lat"] as! Double
            chatMessage.lon = data["lon"] as! Double
            chatMessage.time = data["time"] as! Int64
            
            self.messages.append(chatMessage)
            
            //message from other user
            var textLabel = UITextView(frame: CGRect(x: self.view.bounds.width * 0.05, y: self.yHeight, width: self.view.bounds.width * 0.45, height: self.view.bounds.height * 0.125))
            textLabel.backgroundColor = UIColor(red: 0.6078, green: 1, blue: 0.7373, alpha: 1.0) /* #9bffbc */
            textLabel.text = chatMessage.text
            textLabel.sizeToFit()

//                UIColor(red: 0, green: 0.9176, blue: 0.5176, alpha: 1.0) /* #00ea84 */

            if self.defaults.string(forKey: "userID") == chatMessage.uid {
                textLabel = UITextView(frame: CGRect(x: self.view.bounds.width * 0.5, y: self.yHeight, width: self.view.bounds.width * 0.45, height: self.view.bounds.height * 0.125))
                textLabel.textAlignment = .right
                textLabel.backgroundColor = UIColor(red: 0.298, green: 0.8706, blue: 1, alpha: 1.0) /* #4cdeff */
                textLabel.text = chatMessage.text
                textLabel.sizeToFit()
                textLabel.center.x = self.view.bounds.width*0.95 - textLabel.bounds.width * 0.5
            }
            
            textLabel.layer.cornerRadius = 10
            textLabel.layer.borderColor = UIColor.black.cgColor
            textLabel.layer.borderWidth = 1
            textLabel.isUserInteractionEnabled = false
            self.messageView.addSubview(textLabel)
            
            self.messageViews.append(textLabel)
            
            self.yHeight += textLabel.bounds.height * 1.2
        
            self.messageView.contentSize.height = self.yHeight

            self.messageView.scrollRectToVisible((self.messageViews.last?.frame)!, animated: true)
        }

    }
    
    func loadMessages(){
        
        
//        do{
//            messages = try appDel.persistentContainer.viewContext.fetch(Message.fetchRequest())
//        }catch{
//            print(error)
//        }
    }
    

    @IBAction func sendTapped(_ sender: Any) {
        print("tapped bitch")
        let message = ["lat" : defaults.double(forKey: "userLat"), "lon" : defaults.double(forKey: "userLon"), "text" : chatBox.text, "time" : Int64(NSDate().timeIntervalSince1970), "uid" : defaults.string(forKey: "userID")!] as [String : Any]
        print(Auth.auth().currentUser?.uid)
        print("message: \(message)")
        Database.database().reference().child("messages").childByAutoId().setValue(message)
        
        chatBox.text = "Add a message.."
    }
    
    /*
     
     //create a messageview for the chat bubble, and how long ago it was sent underneath (could pull out like unite)
     // -> user disabled textview for the bubble?
     */
}

