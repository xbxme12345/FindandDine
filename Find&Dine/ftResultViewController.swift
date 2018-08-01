//
//  ftResultViewController.swift
//  Find&Dine
//
//  Created by Yan Wen Huang on 6/17/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

//Structure for Distance Matrix API JSON
struct JSON_Distance: Codable{
    var destination_addresses: [String]!
    var origin_addresses: [String]!
    var rows: [Element]!
    var status: String!
}

struct Element: Codable {
    var elements: [internalJSON]!
}

struct internalJSON: Codable {
    var distance: DistanceOrTime!
    var duration: DistanceOrTime!
    var status: String!
}

struct DistanceOrTime: Codable {
    var text: String
    var value: Double
}

//Structure for Food Truck JSON
struct JSON_FoodTruck: Codable {
    var Meal: String!
    var Location: String!
    var DayOfWeek: String!
    var FoodTruck: String!
    var Link: String!
}

//Structure to store food truck info
struct ftInfo {
    let meal: String
    let location: String
    let dayOfWeek: String
    let foodTruckName: String
    let ftLink: String
    
    init(meal: String, location: String, dayOfWeek: String, foodTruckName: String, ftLink: String) {
        self.meal = meal
        self.location = location
        self.dayOfWeek = dayOfWeek
        self.foodTruckName = foodTruckName
        self.ftLink = ftLink
    }
}

//Global Variables to be used on other VC
//Store the food truck info as global to display in table view UI
var foodTruckList = [ftInfo]()
var selectedIndex = 0
var name = ""
var address = ""
var meal = ""
var day = ""
var link = ""

class ftResultViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //Define connections
    @IBOutlet weak var tableViewFoodTruck: UITableView!
    
    //Local variables for receiving data from ftViewController
    var locationFlag = Int()
    var location = String()
    var travelDistance = String()
    var typeOfMealValue = [String]()
    var dayOfWeekValue = [String]()

    //Variable to store
    var travelDistKM: Double!
    
    //Init location manager
    private let locationManager = CLLocationManager()
    
    //Inititalize activity indicator
    let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
    
    /*
     Purpose: Determines the number of sections
     
     Return: The number of sections
    */
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /*
     Purpose: Determins the number of rows within the section
     
     Return: The number of rows in the section
    */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foodTruckList.count
    }
    
    /*
     Purpose: Fills each cell row with data and details
     
     Return: The populated cell
    */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "cell")
        //Enable scrolling for table view
        tableViewFoodTruck.isScrollEnabled = true;
        
        let foodTruck: ftInfo
        
        foodTruck = foodTruckList[indexPath.row]
        cell.textLabel?.text = foodTruck.foodTruckName
        cell.detailTextLabel?.text = "\(foodTruck.location)\n\(foodTruck.dayOfWeek) \(foodTruck.meal)"
        
        stopLoading()
        return cell
    }
    
    /*
     Purpose: Pass values/data of user selected row to global var. Perform segue to ftInfoViewController
    */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableViewFoodTruck.cellForRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
        
        let foodTruck: ftInfo
        let selectedIndex = indexPath.row
        foodTruck = foodTruckList[selectedIndex]
        name = foodTruck.foodTruckName
        location = foodTruck.location
        meal = foodTruck.meal
        day = foodTruck.dayOfWeek
        link = foodTruck.ftLink
        
        performSegue(withIdentifier: "segue", sender: cell)
    }
    
    /*
     Purpose: Prepare to send data from ftResultViewController to ftInfoViewController
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let ftVC = segue.destination as! ftInfoViewController
        ftVC.ftName = name
        ftVC.location = location
        ftVC.meal = meal
        ftVC.dayOfWeek = day
        ftVC.link = link
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Initializing the start of the activity indicator
        startLoading()
        
        //Set location manager delegate and request for location use if not authorized already
        locationManager.requestWhenInUseAuthorization()
        
        //Pass variable/value to function to convert from miles to meters
        self.travelDistKM = self.getDistance(distance: Double(self.travelDistance)!)
        
        //Function to retrieve food truck list based upon user criteria
        self.getFoodTruckInfo()
        
        //Clears foodTruckList array
        foodTruckList.removeAll()
    }
    
    /**
     Purpose: Convert distance from miles to meters
     
     Return: Returns converted distance
     */
    func getDistance(distance: Double) -> Double {
        //return distance in meters
        return (distance * 1609.34)
    }
    
    /*
     Purpose: Get food truck info based upon address that are close to user's location
    */
    func getFoodTruckInfo() {
        //JSON file link for food truck info
        //URL string that returns the JSON object for parsing
        guard let url = URL(string: "https://gist.githubusercontent.com/xbxme12345/ef39ccba761091e6d6cff365be5968fc/raw/c36a282557a79d35d43bdc6999e21c766bd289e5/foodtruck.json") else {return}
        
        //Intitialize the URL session with the online food truck JSON file
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let dataResponse = data,
                error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return
            }
            
            //Parse through json file using close by address, user selected type of meal and day of the week
            //Append all results/food truck info to array
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: [])
                guard let jsonArray = jsonResponse as? [[String: Any]] else {return}
                
                for elem in jsonArray {
                    if self.typeOfMealValue.contains(elem["Meal"] as! String) {
                        if self.dayOfWeekValue.contains(elem["DayOfWeek"] as! String) {
                            let urlString = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(self.location)&destinations=\(elem["Location"])&key=AIzaSyDtbc_paodfWo1KRW0fGQ1dB--g8RyG-Kg"
                            
                            guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!) else {return}
                            
                            let base_url = try! Data(contentsOf: url)
                            
                            var distData = try! JSONDecoder().decode(JSON_Distance.self, from: base_url)
                            
                            if((distData.rows[0].elements[0].distance.value) <= self.travelDistKM) {
                                foodTruckList.append(ftInfo(meal: elem["Meal"] as! String, location: elem["Location"] as!String, dayOfWeek: elem["DayOfWeek"] as! String, foodTruckName: elem["FoodTruck"] as! String, ftLink: elem["Link"] as! String))
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableViewFoodTruck.reloadData()
                }
                
            } catch let parsingError {
                print("Error: ", parsingError)
            }
        }
        task.resume()
    }
    
    /*
     Purpose: Starts the activity indicator
    */
    func startLoading() {
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        activityIndicator.color = UIColor.black
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    /*
     Purpose: Stops the activity indicator
    */
    func stopLoading() {
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
}
