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
    @IBOutlet weak var blockedNotificationView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var viewerLabel: UILabel!
    
    let appDel = UIApplication.shared.delegate as! AppDelegate
    let defaults = UserDefaults.standard
	
	var colors = [Color]()
	var userColors = [String : Color]()
    var messages = [Message]()
    var messageViews = [UIView]()
    var sideBar = UITableView()
    var selectedUni : School?
    var numberViewers : Int?
	var selfCounted = false
	
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
//		addColors()
		
        loadUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {

		setupNotifications()
        checkLocation()
		
		let filterChanged = defaults.bool(forKey: "filterChanged")
		
		if let selectedUni = selectedUni, filterChanged, let index = schools.index(where: {$0.name == selectedUni.name}) {
			setupChatListener(index, update: true)
			defaults.set(false, forKey: "filterChanged")
		}
		
    }
    
    override func viewWillDisappear(_ animated: Bool) {
		if chatBox.isFirstResponder {
			chatBox.resignFirstResponder()
		}
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
	
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsShowing(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardIsHiding(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
	
	//MARK: UI
    
    fileprivate func loadUI() {
		
		DispatchQueue.main.async {
			self.getSchools()
			self.getColors()
		}
		
        let navHeight = self.navigationController!.navigationBar.frame.height
        yHeight = navHeight * 1.05
		
//		titleLabel.backgroundColor = UIColor.clear
//		titleLabel.numberOfLines = 1
//		titleLabel.textAlignment = .center
//		titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
//		titleLabel.textColor = .white
//		titleLabel.text = "Work you fucker"
//		titleLabel.adjustsFontSizeToFitWidth = true
//		titleLabel.sizeToFit()
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
	
	/*
	private func addColors(){
		let colors = [
			["#BBBBFF","#000000"],
			["#BBDAFF","#000000"],
			["#CEF0FF","#000000"],
			["#ACF3FD","#000000"],
			["#B5FFFC","#000000"],
			["#A5FEE3","#000000"],
			["#B5FFC8","#000000"],
			["#FFBBBB","#000000"],
			["#FFACEC","#000000"],
			["#FFBBDD","#000000"],
			["#FFBBF7","#000000"],
			["#F2BCFE","#000000"],
			["#EDBEFE","#000000"],
			["#D0BCFE","#000000"],
			["#BBBBFF","#000000"],
			["#BBDAFF","#000000"],
			["#CEF0FF","#000000"],
			["#ACF3FD","#000000"],
			["#B5FFFC","#000000"],
			["#A5FEE3","#000000"],
			["#B5FFC8","#000000"],
			["#5757FF","#FFFFFF"],
			["#62D0FF","#000000"],
			["#06DCFB","#000000"],
			["#01FCEF","#000000"],
			["#03EBA6","#000000"],
			["#75B4FF","#FFFFFF"],
			["#75D6FF","#000000"],
			["#24E0FB","#000000"],
			["#1FFEF3","#000000"],
			["#03F3AB","#000000"],
			["#FF9797","#000000"],
			["#FF97E8","#000000"],
			["#FF97CB","#000000"],
			["#FE98F1","#000000"],
			["#ED9EFE","#000000"],
			["#E29BFD","#000000"],
			["#B89AFE","#000000"],
			["#F900F9","#FFFFFF"],
			["#DD75DD","#FFFFFF"],
			["#BD5CFE","#FFFFFF"],
			["#AE70ED","#FFFFFF"],
			["#9588EC","#FFFFFF"],
			["#44B4D5","#FFFFFF"],
			["#99C7FF","#000000"],
			["#A8E4FF","#000000"],
			["#75ECFD","#000000"],
			["#92FEF9","#000000"],
			["#7DFDD7","#000000"],
			["#8BFEA8","#000000"],
			["#93EEAA","#000000"],
			["#A6CAA9","#000000"],
			["#AAFD8E","#000000"],
			["#FFFF84","#000000"],
			["#EEF093","#000000"]
		]

		
		for pastel in colors {
			let color = ["hexColor" : pastel[0], "textColor" : pastel[1]] as [String : String]
			ref.child("colors").childByAutoId().setValue(color)
		}

	}

*/

	
	private func getColors(){
		ref.child("colors").observeSingleEvent(of: .value) { (data) in
			for item in data.children {
				let snap = item as! DataSnapshot
				let color = snap.value as? [String : String]
				let test = Color(data: color!)
				self.colors.append(test!)
			}
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
		schools.sort { ( $0.name < $1.name) }
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
		
		if(colors.isEmpty) {
			textLabel.backgroundColor = .white
			textLabel.textColor = #colorLiteral(red: 0.3764705882, green: 0.462745098, blue: 0.9882352941, alpha: 1)
		} else {
			if let user = userColors[chatMessage.uid] {
				textLabel.backgroundColor = UIColor(hexString: user.hex)
				textLabel.textColor = UIColor(hexString: user.textColor)
//				textLabel.backgroundColor = user.hexStringToUIColor(hex: user.hex)
//				textLabel.textColor = user.hexStringToUIColor(hex: user.textColor)
			} else {
				let random = Int(arc4random_uniform(UInt32(colors.count)))
				let color =  colors.remove(at: random)
				userColors[chatMessage.uid] = color
				textLabel.backgroundColor = UIColor(hexString: color.hex)
				textLabel.textColor = UIColor(hexString: color.textColor)
			}
		}

        textLabel.text = chatMessage.text
        textLabel.font = UIFont.systemFont(ofSize: 14)
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
		} else {
			let tapHold = UILongPressGestureRecognizer(target: self, action: #selector(messageTapped(_:)))
			textLabel.addGestureRecognizer(tapHold)
		}
		
        textLabel.clipsToBounds = false
        textLabel.layer.shadowColor = UIColor.gray.cgColor
        textLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        textLabel.layer.shadowOpacity = 1.0
        textLabel.layer.cornerRadius = 10
        textLabel.isUserInteractionEnabled = true
		textLabel.isSelectable = false
		textLabel.isEditable = false
		textLabel.isScrollEnabled = false
		textLabel.message = chatMessage
		
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
	
	private func setupChatListener(_ index : Int, update : Bool = false){
		
		if selectedUni == nil || selectedUni!.path != schools[index].path || update {
			if selectedUni != nil {
				
				ref.child("schoolMessages").child(selectedUni!.path).child("counter").removeAllObservers()
				ref.child("schoolMessages").child(selectedUni!.path).child("messages").removeAllObservers()
				
				if let viewers = numberViewers {
                    ref.child("schoolMessages/\(selectedUni!.path)/counter").setValue(viewers - 1)
                }
				
				selfCounted = false
				numberViewers = 0
			}

//            viewerLabel.isHidden = false

			userColors.removeAll()
			colors.removeAll()
			getColors()
			
			selectedUni = schools[index]
			messages.removeAll()
			messageViews.removeAll()
			messageView.subviews.forEach({$0.removeFromSuperview()})
			
			let path = ref.child("schoolMessages").child(selectedUni!.path)

			path.child("counter").observe(.value, with: { (snapshot) in
				if let viewers = snapshot.value as? Int {
					if !self.selfCounted {
						self.selfCounted = true
						print("yobish count is \(viewers)")
						self.numberViewers = viewers + 1
						self.ref.child("schoolMessages/\(self.selectedUni!.path)/counter").setValue(self.numberViewers!)
					} else {
						self.numberViewers = viewers
						print("heyo count is \(viewers)")
					}
				} else {
					//this should only hit if there's no counter already.
					self.selfCounted = true
					self.ref.child("schoolMessages/\(self.selectedUni!.path)/counter").setValue(1)
				}
			})
			
			
			path.child("messages").observeSingleEvent(of: .value, with: { (snapshot) in
				if !snapshot.hasChildren() {
					self.checkForMessages()
				}
			})

			path.child("messages").queryOrdered(byChild: "time").queryLimited(toLast: 100).observe(DataEventType.childAdded) { (data) in

				if data.hasChildren() {
					let key = data.key
					guard let data = data.value as? [String : Any] else {return}

					if let noMessagesLabel = self.noMessagesLabel {
						if noMessagesLabel.isDescendant(of: self.view) {
							noMessagesLabel.removeFromSuperview()
						}
					}
					self.createChatMessage(data: data, key: key)
				}
			}
			
			DispatchQueue.main.async {
//				self.titleLabel.text = "\(self.selectedUni!.name) Heatchat"
//				self.navigationItem.titleView = self.titleLabel
				self.navigationItem.title = "\(self.selectedUni!.name) Heatchat"
				self.setupChatBar()
			}
		}
		if !update {
			animateSideBar(sideBar)
		}
	}
	
	@objc private func messageTapped(_ gesture : UILongPressGestureRecognizer){
		
		let view = (gesture.view as! MessageView)
		let key = view.keyTag
		let message = view.message
		
		let actionSheet = UIAlertController(title: "Message Actions", message: "What would you like to do about this message?", preferredStyle: UIAlertControllerStyle.actionSheet)
		
		let blockAction = UIAlertAction(title: "Block User", style: .default) { (action) in
			self.blockUser(message!.uid)
		}
		actionSheet.addAction(blockAction)
		
		let flagAction = UIAlertAction(title: "Flag Comment", style: .default) { (action) in
			self.flagComment(key!, message!.text) //key isn't optional but whatever xcode
		}
		actionSheet.addAction(flagAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
		}
		actionSheet.addAction(cancelAction)
		
		self.present(actionSheet, animated: true)
		
	}
	
	private func flagComment(_ key : String, _ message: String) {
		
		if let selectedUni = selectedUni {
			let report = ["messageKey" : key, "message" : message]
			ref.child("reports").child(selectedUni.path).childByAutoId().setValue(report)
			
			let alert = UIAlertController(title: "Message Reported", message: "Comment has been sent to admin for moderation. This issue will be resolved within 24 hours.", preferredStyle: .alert)
			
			let alertButton = UIAlertAction(title: "OK", style: .cancel)
			alert.addAction(alertButton)
			self.present(alert, animated: true)
		}
	
		//TODO: remove comment, adjust messageView by comment.height

	}
	
	private func blockUser(_ uid : String){
		
		if var blockedUsers = defaults.stringArray(forKey: "blockedUsers"){
			blockedUsers.append(uid)
			defaults.set(blockedUsers, forKey: "blockedUsers")
		} else {
			defaults.set([uid], forKey: "blockedUsers")
		}
		
		if let index = schools.index(where: {$0.name == selectedUni!.name}) {
			let blockedNotification = UIView(frame: CGRect(x: 0, y: self.navigationController!.navigationBar.frame.height * 1.45, width: view.bounds.width, height: messageView.bounds.height*0.065))
			blockedNotification.backgroundColor = UIColor.black
			blockedNotification.alpha = 0.9

			let blockedLabel = UILabel(frame: CGRect(x: 0, y: 0, width: blockedNotification.bounds.width, height: blockedNotification.bounds.height))
			blockedLabel.text = "User blocked! You will no longer see their messages."
			blockedLabel.textColor = UIColor.white
			blockedLabel.font = UIFont.systemFont(ofSize: 14)
			blockedLabel.adjustsFontSizeToFitWidth = true
			blockedLabel.textAlignment = .center
			blockedNotification.addSubview(blockedLabel)
			view.addSubview(blockedNotification)

//			blockedNotificationView.isHidden = false
			
			UIView.animate(withDuration: 0.5, delay: 2.5, options: .curveLinear, animations: {
//				self.blockedNotificationView.alpha = 0.0
				blockedNotification.alpha = 0
			}, completion: { (_) in
//				self.blockedNotificationView.isHidden = true
				blockedNotification.removeFromSuperview()
			})
			


			setupChatListener(index, update: true)
		}
		
	}
	
	//MARK: Messaging
    
    @objc private func keyboardIsShowing(_ notification : Notification) {
		if chatBox.text == "Add a message.." {
        	chatBox.text = ""
		}
		
		view.bringSubview(toFront: chatBox)
		view.bringSubview(toFront: sendButton)
		
		if let noMessagesLabel = noMessagesLabel {
			view.sendSubview(toBack: noMessagesLabel)
		}
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            
            let keyboardRect = keyboardFrame.cgRectValue
			var contentInset = messageView.contentInset
			contentInset.bottom = keyboardRect.height + chatView.frame.height
			messageView.contentInset = contentInset
			
			if messageViews.count > 0 {
				messageView.scrollRectToVisible((messageViews.last?.frame)!, animated: true)
			}
			//			chatView.frame.origin.y -= keyboardRect.height
			chatView.frame.origin.y = stackView.frame.height - keyboardRect.height - chatView.bounds.height
         }
    }
    
    @objc private func keyboardIsHiding(_ notification : Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            
            let keyboardRect = keyboardFrame.cgRectValue
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
		
		let words = ["succ", "dicc", "licc"]
		
		if !(words.reduce(false) { $0 || chatBox.text.lowercased().contains($1) }) {
			let message = ["lat" : defaults.double(forKey: "userLat"), "lon" : defaults.double(forKey: "userLon"), "text" : chatBox.text, "time" : Int64(NSDate().timeIntervalSince1970 * 1000.0), "uid" : defaults.string(forKey: "userID")!] as [String : Any]
			if let selectedUni = selectedUni {
				//temporary until I fix placeholder issues.
				if chatBox.text != "" && chatBox.text != "Add a message.." {
					ref.child("schoolMessages").child(selectedUni.path).child("messages").childByAutoId().setValue(message)
				}
			}
		}
		chatBox.text.removeAll()
		view.endEditing(true)
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
				noMessagesLabel = NoMessagesView(frame: messageView.frame, isClose: false)
			} else {
				noMessagesLabel = NoMessagesView(frame: messageView.frame, isClose: true)
			}
			view.addSubview(noMessagesLabel!)
		}
	}
	
	//MARK: Sidebar + Location

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
}

extension UIColor {
	convenience init(hexString: String) {
		let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int = UInt32()
		Scanner(string: hex).scanHexInt32(&int)
		let a, r, g, b: UInt32
		switch hex.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (255, 0, 0, 0)
		}
		self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
	}
}

