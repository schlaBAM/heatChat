//
//  Chat.swift
//  HeatChat
//
//  Created by BAM on 2017-10-30.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation

let filteredWords = ["fuck", "shit", "nigger", "ass", "bitch", "cunt", "slut", "whore", "fag", "retard", "rape", "chink"]

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
            return filteredWords
                .reduce(false) { $0 || text.contains($1.lowercased()) }
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
