//
//  Chat.swift
//  HeatChat
//
//  Created by BAM on 2017-10-30.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation
import FirebaseDatabase

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
                    print("Unable to generate message")
                    return nil
            }
            
            self.text = text
            self.uid = uid
            self.lat = lat
            self.lon = lon
            self.time = time
            
        }
    }
