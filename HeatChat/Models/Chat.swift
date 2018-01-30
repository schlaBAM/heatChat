//
//  Chat.swift
//  HeatChat
//
//  Created by BAM on 2017-10-30.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation
import UIKit

let filteredWords = ["fuck", "shit", "nigger", "ass", "bitch", "cunt", "slut", "whore", "fag", "retard", "rape", "chink"]

struct Color {
    var hex : String
    var textColor : String
    
    init?(data : [String : String]){
        guard
            let hex = data["hexColor"] as? String,
            let textColor = data["textColor"] as? String
            else { return nil }
        self.hex = hex
        self.textColor = textColor
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

struct Chat {

    var text : String
    var uid : String
    var lat : Float
    var lon : Float
    var time : CLong
    
    init?(data : [String : Any]){
            guard
                let text = data["text"] as? String,
                let uid = data["uid"] as? String,
                let lat = data["lat"] as? Float,
                let lon = data["lon"] as? Float,
                let time = data["time"] as? CLong
                else {
                    print("Unable to generate message: \(String(describing: data["text"])), \(String(describing: data["uid"])), \(String(describing: data["lat"])), \(String(describing: data["lon"])), \(String(describing: data["time"]))")
                    return nil
            }
            
            self.text = text
            self.uid = uid
            self.lat = lat
            self.lon = lon
            self.time = time
        
        if let filterEnabled = UserDefaults.standard.bool(forKey: "filterEnabled") as? Bool, filterEnabled, containsSwearWord(text: text, filteredWords: filteredWords) {
                return nil
            }
        
            if let blockedUsers = UserDefaults.standard.stringArray(forKey: "blockedUsers") {
                if blockedUsers.contains(where: {$0 == uid}) {
                    print("\(uid) is blocked")
                    return nil
                }
            }
        }
    
        func containsSwearWord(text : String, filteredWords : [String]) -> Bool{
            return filteredWords.reduce(false) { $0 || text.lowercased().contains($1) }
        }
    }

/*
 
 Core data for the future. Unneeded for now and irrelevant to this file.
 
 -----------------------------------------------------------------------
 
 let context = appDel.persistentContainer.viewContext
 let chatMessage = Message(context: context)
 
 chatMessage.text = (data["text"] as! String).trimmingCharacters(in: .newlines)
 chatMessage.uid = data["uid"] as? String
 chatMessage.lat = data["lat"] as! Double
 chatMessage.lon = data["lon"] as! Double
 chatMessage.time = data["time"] as! Int64
 messages.append(chatMessage)
 
 */
