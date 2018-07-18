//
//  ParseJSON.swift
//  Find&Dine
//
//  Created by Gregory Lee on 7/9/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import Foundation

class ParseJSON: Operation {
    
    var pid = String()
    var lat = Double()
    var lng = Double()
    
    
    func setRestaurant(num: Int, RestList: Array<RestInfo>) {
        
        let restaurant = RestList[num]
        
        pid = restaurant.pid
        lat = restaurant.lat
        lng = restaurant.lng
    }
    
}
