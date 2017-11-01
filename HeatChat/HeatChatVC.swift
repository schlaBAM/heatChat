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
class HeatChatVC: UIViewController{

    @IBOutlet weak var messageView: UIScrollView!
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    var messages = [Message]()
    var messageViews = [UIView]()
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatBox: UITextView!
    var yHeight: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().signInAnonymously { (user, error) in
            if error != nil {
                print("Sign in error: " + (error?.localizedDescription)!)
            } else {
                let anon = User(context: (self.appDel.persistentContainer.viewContext))
                anon.uid = user?.uid
                print(user?.uid)
                self.appDel.saveContext()
            }
        }
        
        Database.database().reference().child("messages").observe(DataEventType.childAdded) { (data) in
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
    
        chatMessage.text = data["text"] as! String
        chatMessage.uid = data["uid"] as! String
        chatMessage.lat = data["lat"] as! Double
        chatMessage.lon = data["lon"] as! Double
        chatMessage.time = data["time"] as! Double
        
        self.messages.append(chatMessage)
        
        let textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.05, y: yHeight, width: view.bounds.width * 0.45, height: view.bounds.height * 0.125))
        textLabel.text = chatMessage.text
        textLabel.layer.cornerRadius = 10
        textLabel.layer.borderColor = UIColor.black.cgColor
        textLabel.layer.borderWidth = 1
        textLabel.sizeToFit()
        messageView.addSubview(textLabel)
        
        self.messageViews.append(textLabel)
        
        yHeight += textLabel.bounds.height * 1.2
        
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
        chatBox.text = "Add a message.."
    }
    
    /*
     
     //navController because obviously
     //scrollview for chat (height = ( navBarHeight - chatBarHeight ))
     //create a messageview for the chat bubble, and how long ago it was sent underneath (could pull out like unite)
     // -> user disabled textview for the bubble?
 
 
     */

}

