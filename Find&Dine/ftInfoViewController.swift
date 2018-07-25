//
//  ftInfoViewController.swift
//  Find&Dine
//
//  Created by Yan Wen Huang on 6/17/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import Foundation
import GoogleMaps
import UIKit

class ftInfoViewController: UIViewController {
    
    @IBOutlet weak var foodTruckName: UILabel!
    @IBOutlet weak var ftAddress: UILabel!
    @IBOutlet weak var ftMeal: UILabel!
    @IBOutlet weak var ftDay: UILabel!
    
    //@IBOutlet weak var mapView: MKMapView!
    
    //local variables for receiving data from tableView VC
    var location = String()
    var meal = String()
    var dayOfWeek = String()
    var ftName = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        foodTruckName.text = ftName
        ftAddress.text = location
        ftMeal.text = meal
        
        print(ftName, " ", location, " ", meal, " ", dayOfWeek)
        
    }
}
