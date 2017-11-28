//
//  HeatChatVC.swift
//  HeatChat
//
//  Created by BAM on 2017-10-30.
//  Copyright © 2017 BAM. All rights reserved.
//

import UIKit
import FirebaseDatabase
import QuartzCore
import CoreLocation
import Crashlytics

@IBDesignable
class HeatChatVC: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UserLocationManagerDelegate, UIActionSheetDelegate{

    @IBOutlet weak var messageView: UIScrollView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var chatBox: UITextView!
    @IBOutlet weak var chatView: UIView!
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
	
    var messages = [Message]()
    var messageViews = [UIView]()
    var sideBar = UITableView()
    var selectedUni : School?
	
	private var noMessagesLabel : NoMessagesView?
	private var titleLabel = UILabel()
    private var schools = [School]()
    private var yHeight: CGFloat = 0.0
    private var ref = DatabaseReference()
    let userLocationManager = UserLocationManager.sharedManager


    override func viewDidLoad() {
        super.viewDidLoad()
        
        userLocationManager.delegate = self

        navigationController?.navigationBar.barTintColor = UIColor(red: 0.3922, green: 0.5843, blue: 0.9294, alpha: 1.0) /* #6495ed */
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]

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
        if chatBox.isFirstResponder {
            chatBox.resignFirstResponder()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsShowing(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsHiding(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    fileprivate func loadUI() {
      
        getSchools()
        
        let navHeight = self.navigationController!.navigationBar.frame.height
        yHeight = navHeight * 1.05
		
		titleLabel.backgroundColor = UIColor.clear
		titleLabel.numberOfLines = 1
		titleLabel.textAlignment = .center
		titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
		titleLabel.textColor = .white
		titleLabel.text = "Work you fucker"
		titleLabel.adjustsFontSizeToFitWidth = true
		titleLabel.sizeToFit()
		navigationItem.title = "Heatchat"
		
        sideBar = UITableView(frame: CGRect(x: 0 - view.bounds.width * 0.5, y: self.navigationController!.navigationBar.frame.height * 1.45, width: view.bounds.width * 0.5, height: view.bounds.height - navHeight * 1.5 ))
        sideBar.delegate = self
        sideBar.dataSource = self
        sideBar.layer.borderWidth = 2
        sideBar.layer.borderColor = UIColor.black.cgColor
        sideBar.layer.cornerRadius = 5
        sideBar.separatorStyle = .none

        view.addSubview(sideBar)
        animateSideBar(sideBar)
        
        messageView.delegate = self
        messageView.contentSize = CGSize(width: view.bounds.width, height: 0)
        
        self.chatBox.delegate = self
        
    }
    
    @IBAction func universityIconTapped(_ sender: Any) {
        animateSideBar(sideBar)
    }
    
    private func setupChatBar() {
        //if selectedUni is nil, user hasn't selected a university so this setup wouldn't be needed yet.
        if let selectedUni = selectedUni {
            let userLocation = CLLocation(latitude: defaults.double(forKey: "userLat"), longitude: defaults.double(forKey: "userLon"))
            let schoolLocation = CLLocation(latitude: selectedUni.lat, longitude: selectedUni.lon)
            let distance = userLocation.distance(from: schoolLocation) // in metres
			
			chatBox.layer.borderColor = UIColor.gray.cgColor
			chatBox.isEditable = false
			sendButton.isEnabled = false
            
            if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
                chatBox.text = "Turn on location to post!"
            } else {
                if distance > Double(selectedUni.radius * 1000) {
                    chatBox.text = "Too far away to post!"
                } else {
                    chatBox.layer.borderColor = UIColor.black.cgColor
                    chatBox.isEditable = true
                    chatBox.text = "Add a message.."
                    sendButton.isEnabled = true
                }
            }
        }
    }
    
    private func animateSideBar(_ sidebar: UIView) {
		
		view.bringSubview(toFront: sidebar)
        if sidebar.center.x < 0 {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                    sidebar.center.x += self.view.bounds.width * 0.5
            })
//            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
//                sidebar.center.x += self.view.bounds.width * 0.5
//            })
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                sidebar.center.x -= self.view.bounds.width * 0.5
            })
        }
    }
    
    @IBAction private func userTappedView(_ sender: Any) {
        if sideBar.center.x > 0 {
            animateSideBar(sideBar)
        }
    }
    
    private func getSchools() {
        Database.database().reference().child("schools").observeSingleEvent(of: .value, with: { (data) in
            for item in data.children{
                let snap = item as! DataSnapshot
                self.addSchool((snap.value as? [String:Any])!)
            }
        })
    }
    
    private func addSchool(_ data : [String : Any]) {
        
        let school = School(dict: data)
        schools.append(school!)
        sideBar.reloadData()
    }
    
	private func createChatMessage(data : [String : Any], key : String) {
        
        let chatMessage = Chat(data: data)
        
        if let chatMessage = chatMessage {
            
            let textLabel = createTextView(chatMessage)
			textLabel.keyTag = key
            let timeLabel = createTimeStamp(textLabel, chatMessage: chatMessage)
		
            messageView.addSubview(textLabel)
            messageView.addSubview(timeLabel)
			
			
            messageViews.append(textLabel)
            
            yHeight += textLabel.bounds.height + 10
            messageView.contentSize.height = yHeight
            
            if let frame = messageViews.last?.frame {
                
                messageView.scrollRectToVisible(CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height + 10), animated: true)
                
            }
        }
    }
    
    private func createTextView(_ chatMessage : Chat) -> MessageView {
        //message from other user
		var textLabel = MessageView(frame: CGRect(x: view.bounds.width * 0.025, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125), textContainer: NSTextContainer?.none, tag: "hello", message: chatMessage)
       // var textLabel = MessageView(frame: CGRect(x: view.bounds.width * 0.025, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125))
        textLabel.backgroundColor = .white
        textLabel.text = chatMessage.text
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = #colorLiteral(red: 0.3764705882, green: 0.462745098, blue: 0.9882352941, alpha: 1)
        textLabel.sizeToFit()
        
        if defaults.string(forKey: "userID") == chatMessage.uid {
//            textLabel = UITextView(frame: CGRect(x: view.bounds.width * 0.5, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125))
			textLabel = MessageView(frame: CGRect(x: view.bounds.width * 0.025, y: yHeight, width: view.bounds.width * 0.65, height: view.bounds.height * 0.125), textContainer: NSTextContainer?.none, tag: "hellosss", message: chatMessage)
            textLabel.backgroundColor = UIColor(red: 0.3922, green: 0.5843, blue: 0.9294, alpha: 1.0) /* #6495ed */
            textLabel.font = UIFont.systemFont(ofSize: 14)
            textLabel.textColor = .white
            textLabel.text = chatMessage.text
            textLabel.sizeToFit()
            textLabel.center.x = messageView.bounds.width*0.975 - textLabel.bounds.width * 0.5
        }
		
        textLabel.clipsToBounds = false
        textLabel.layer.shadowColor = UIColor.gray.cgColor
        textLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        textLabel.layer.shadowOpacity = 1.0
        textLabel.layer.cornerRadius = 10
        textLabel.isUserInteractionEnabled = true
		textLabel.isEditable = false
		textLabel.isScrollEnabled = false
		textLabel.message = chatMessage
		
		let tapHold = UILongPressGestureRecognizer(target: self, action: #selector(messageTapped(_:)))
		textLabel.addGestureRecognizer(tapHold)
        return textLabel
    }
    
    private func createTimeStamp(_ textLabel: UITextView, chatMessage : Chat) -> UILabel {
        
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
	
	private func setupChatListener(_ index : Int){
		
		if selectedUni == nil || selectedUni!.path != schools[index].path {
			if selectedUni != nil {
				ref.child("schoolMessages").child(selectedUni!.path).child("messages").removeAllObservers()
			}
			selectedUni = schools[index]
			messages.removeAll()
			messageViews.removeAll()
			messageView.subviews.forEach({$0.removeFromSuperview()})
			
			let path = ref.child("schoolMessages").child(selectedUni!.path).child("messages")
			
			path.observeSingleEvent(of: .value, with: { (snapshot) in
				if snapshot.hasChildren() {
					self.ref.child("schoolMessages").child(self.selectedUni!.path).child("messages").queryOrdered(byChild: "time").queryLimited(toLast: 100).observe(DataEventType.childAdded) { (data) in
						
						if data.hasChildren() {
							guard let key = data.key as? String else {return}
							guard let data = data.value as? [String : Any] else {return}
							
							if let noMessagesLabel = self.noMessagesLabel {
								if noMessagesLabel.isDescendant(of: self.view) {
									noMessagesLabel.removeFromSuperview()
								}
							}
							self.createChatMessage(data: data, key: key)
						}
					}
				} else {
					self.checkForMessages()
				}
			})
			
			DispatchQueue.main.async {
				self.titleLabel.text = "\(self.selectedUni!.name) Heatchat"
				self.navigationItem.titleView = self.titleLabel
				self.navigationItem.title = nil
				self.setupChatBar()
			}
		}
		animateSideBar(sideBar)
	}
	
	@objc private func messageTapped(_ gesture : UILongPressGestureRecognizer){
		
		let view = (gesture.view as! MessageView)
		let key = view.keyTag
		let uid = view.message.uid
		
		let actionSheet = UIAlertController(title: "Message Actions", message: "What would you like to do about this message?", preferredStyle: UIAlertControllerStyle.actionSheet)
		
		let blockAction = UIAlertAction(title: "Block User", style: .default) { (action) in
			self.blockUser(uid)
		}
		actionSheet.addAction(blockAction)
		
		let flagAction = UIAlertAction(title: "Flag Comment", style: .default) { (action) in
			//flag comment ID - key
			//notify user comment has been sent to admin for moderation and will be resolved within 24 hours
			//remove comment, adjust messageView by comment.height
		}
		actionSheet.addAction(flagAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
		}
		actionSheet.addAction(cancelAction)
		
		self.present(actionSheet, animated: true) {
			
		}
		
	}
	
	private func blockUser(_ uid : String){
		//TODO: add user to defaults dictionary with key = blockedUsers
		print(uid)
	}
    
    @objc private func keyboardIsShowing(_ notification : Notification) {
        chatBox.text = ""
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            
            let keyboardRect = keyboardFrame.cgRectValue
			var contentInset = messageView.contentInset
			contentInset.bottom = keyboardRect.height + chatView.bounds.height
			messageView.contentInset = contentInset
			
			messageView.scrollRectToVisible((messageViews.last?.frame)!, animated: true)
			
//            messageView.frame.origin.y -= keyboardRect.height
            chatView.frame.origin.y -= keyboardRect.height

         }
    }
    
    @objc private func keyboardIsHiding(_ notification : Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            
            let keyboardRect = keyboardFrame.cgRectValue
//            messageView.frame.origin.y += keyboardRect.height
			messageView.contentInset = UIEdgeInsets.zero
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

    @IBAction private func sendTapped(_ sender: Any) {
        let message = ["lat" : defaults.double(forKey: "userLat"), "lon" : defaults.double(forKey: "userLon"), "text" : chatBox.text, "time" : Int64(NSDate().timeIntervalSince1970 * 1000.0), "uid" : defaults.string(forKey: "userID")!] as [String : Any]
        if let selectedUni = selectedUni {
            //temporary until I fix placeholder issues.
            if chatBox.text != "" && chatBox.text != "Add a message.." {
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
		
		setupChatListener(indexPath.row)

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
    
    private func checkLocation() {
        
        switch(CLLocationManager.authorizationStatus()) {
        case .denied, .notDetermined, .restricted:
            CLLocationManager().requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            CLLocationManager().startUpdatingLocation()
        }
    }
    
    func userDidUpdateLocationStatus() {
        setupChatBar()
    }
	
	func checkForMessages() {
		
		if let noMessagesLabel = self.noMessagesLabel {
			if noMessagesLabel.isDescendant(of: self.view) {
				noMessagesLabel.removeFromSuperview()
			}
		}
		
		//TODO: clean up with setupChatbox.
		if let selectedUni = selectedUni, messageViews.count == 0 {
			let userLocation = CLLocation(latitude: defaults.double(forKey: "userLat"), longitude: defaults.double(forKey: "userLon"))
			let schoolLocation = CLLocation(latitude: selectedUni.lat, longitude: selectedUni.lon)
			let distance = userLocation.distance(from: schoolLocation) // in metres
			
			if distance > Double(selectedUni.radius * 1000) {
				noMessagesLabel = NoMessagesView(frame: view.frame, isClose: false)
			} else {
				noMessagesLabel = NoMessagesView(frame: view.frame, isClose: true)
			}
			view.addSubview(noMessagesLabel!)
		}
	}
}

extension UITextView {
	
}

