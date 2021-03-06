//
//  UserLocationManager.swift
//  HeatChat
//
//  Created by BAM on 2017-11-19.
//  Copyright © 2017 BAM. All rights reserved.
//

import Foundation
import CoreLocation

protocol UserLocationManagerDelegate{
    func userDidUpdateLocationStatus()
}

class UserLocationManager : NSObject, CLLocationManagerDelegate {
    
    static var sharedManager = UserLocationManager()
    private var locationManager = CLLocationManager()
    var currentLocation : CLLocation?
    var delegate : UserLocationManagerDelegate!
    var defaults = UserDefaults.standard
    
    private override init(){
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        updateLocation(manager)
        self.delegate.userDidUpdateLocationStatus()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateLocation(manager)
        self.delegate.userDidUpdateLocationStatus()
    }
    
    private func updateLocation(_ manager: CLLocationManager){
        if let coordinates = manager.location?.coordinate {
            print("coords: \(coordinates.latitude),\(coordinates.longitude)")
            defaults.set(coordinates.latitude, forKey: "userLat")
            defaults.set(coordinates.longitude, forKey: "userLon")
        }
    }
}

