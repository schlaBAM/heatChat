//
//  School.swift
//  HeatChat
//
//  Created by BAM on 2017-11-06.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation

struct School {
    let lat : Double
    let lon : Double
    let name : String
    let path : String
    
    init?(dict: [String:Any]){
        guard
            let lat = dict["lat"] as? Double,
            let lon = dict["lon"] as? Double,
            let name = dict["name"] as? String,
            let path = dict["path"] as? String
            else {
                print("Unable to generate school")
                return nil
        }
        self.lat = lat
        self.lon = lon
        self.name = name
        self.path = path
    }
}
