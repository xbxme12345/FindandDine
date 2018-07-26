//
//  foodTruck.swift
//  Find&Dine
//
//  Created by Yan Wen Huang on 7/17/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import Foundation

class foodTruck {
    var meal: String
    var location: String
    var dayOfWeek: String
    var foodTruckName: String
    
    init(meal: String, location: String, dayOfWeek: String, foodTruckName: String) {
        self.meal = meal
        self.location = location
        self.dayOfWeek = dayOfWeek
        self.foodTruckName = foodTruckName
    }
}
