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
import SQLite3

/*
struct Food_Truck: Decodable{
    let meal: String?
    let location: String?
    let dayOfWeek: String?
    let foodTruck: String?
    
    init(_ dictionary: [String:Any]) {
        meal = json["meal"] as? String ?? ""
        location = json["location"] as? String ?? ""
        dayOfWeek = json["dayOfWeek"] as? String ?? ""
        foodTruck = json["foodTruck"] as? String ?? ""
    }
}*/

struct Food_Truck {
    var meal: String
    var location: String
    var dayOfWeek: String
    var foodTruck: String
    
    init(_ dictionary: [String: Any]) {
        self.meal = dictionary["Meal"] as? String ?? ""
        self.location = dictionary["Location"] as? String ?? ""
        self.dayOfWeek = dictionary["DayOfWeek"] as? String ?? ""
        self.foodTruck = dictionary["FoodTruck"] as? String ?? ""
    }
}

struct AllFTAddress {
    var ftAddress: String
    
    init(ftAddress: String) {
        self.ftAddress = ftAddress
    }
}

struct distanceLoc {
    var ftLoc: String
    var ftDistance: String
    
    init(ftLoc: String, ftDistance: String) {
        self.ftLoc = ftLoc
        self.ftDistance = ftDistance
    }
}

struct distanceJSON: Codable {
    var distance: String
}

class ftResultViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableViewFoodTruck: UITableView!
    
    // local variables for receiving data from 1st VC
    var locationFlag = Int()
    var location = String()
    var travelDistance = String()
    var typeOfMealValue = [String]()
    var dayOfWeekValue = [String]()
    
    //Store the food truck to display in table view UI
    var foodTruckList = [foodTruck]()
    
    //Array to store all distinct addresses in JSON file
    var allFTAddress = Set<String>()
    
    //List to store all addresses along with the distance to current location
    var tmpDistAddress = [distanceLoc]()
    
    //Array to store food truck addresses which are within travel distance input of the user's current location
    var closeByFTAddress = [String]()
    
    //Init location manager
    private let locationManager = CLLocationManager()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foodTruckList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        let foodTruck: foodTruck
        foodTruck = foodTruckList[indexPath.row]
        cell.textLabel?.text = foodTruck.foodTruckName
        return cell
    }
    
    /* Example to append to FoodTruck list for table view
    func readJSONObject(object: [String: AnyObject]) {
        guard let ftData = object["ftData"] as? [[String: AnyObject]] else { return }
        
        for FoodTruck in ftData {
            guard let meal = FoodTruck["meal"] as? String,
                let dayOfWeek = FoodTruck["DayOfWeek"] as? String,
                let ftName = FoodTruck["FoodTruck"] as? String else { break }
            _ = ftName + " for " + meal + " on " + dayOfWeek
        
        }
    }*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set location manager delegate and request for location use if not authorized already
        //locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        //If 'Use Current Location' button was pressed, then get the current location of the device and store for use in the geocodeRequest function
        
        
        //convert distance from miles to meters
        
    
        //Prints out values passed through segue from ftViewController
        print("Location: ", location)
        print("Travel Distance: ", travelDistance)
        print("Type of Meal: ", typeOfMealValue)
        print("Day of the Week: ", dayOfWeekValue)
    
        //JSON file link for food truck info
        //URL string that returns the JSON object for parsing
        guard let url = URL(string: "https://gist.githubusercontent.com/xbxme12345/ef39ccba761091e6d6cff365be5968fc/raw/7ab6645d4b8049975b67e29883eb0bb5176575de/foodtruck.json") else {return}
        
        //Intitialize the URL session with the online food truck JSON file
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let dataResponse = data,
                error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return
            }
            
            //Clears out array before appending
            //self.allFTAddress.removeAll()
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: [])
                guard let jsonArray = jsonResponse as? [[String: Any]] else {return}

                /*
                guard let ftMeal = jsonArray[0]["Meal"] as? String else {print("not a meal string"); return}
                guard let ftLocation = jsonArray[1]["Location"] as? String else {print("not a location string");return}
                guard let ftDayOfWeek = jsonArray[2]["DayOfWeek"] as? String else {print("not a day of week string"); return}
                guard let ftName = jsonArray[3]["FoodTruck"] as? String else {print("not a name string");return}
                
                print(ftMeal)
                print(ftLocation)
                print(ftDayOfWeek)
                print(ftName)
                print(" ")*/
                
                //Prints all locations and food truck name
                /*
                for dic in jsonArray {
                    guard let ftMeal = dic["Meal"] as? String else {return}
                    guard let ftLocation = dic["Location"] as? String else {return}
                    guard let ftDayOfWeek = dic["DayOfWeek"] as? String else {return}
                    guard let ftName = dic["FoodTruck"] as? String else {return}
                }*/
                
                //Queries through JSON file and obtains all distinct addresses
                var temp: [String] = []
                for dic in jsonArray {
                    guard let ftLocation = dic["Location"] as? String else {return}
                    temp.append(ftLocation)
                    
                    //Append all distinct addresses to
                    for address in temp {
                        self.allFTAddress.insert(address)
                    }
                }
                
                /*
                var model = [Food_Truck]()
                for dic in jsonArray {
                    model.append(Food_Truck(dic))
                }
                print(model[0].foodTruck)*/
                
            } catch let parsingError {
                print("Error ", parsingError)
            }
            
            //Create function and pass the values of allFTAddress to calculate
            let allFTAddressArr = Array(self.allFTAddress)
            //print(allFTAddressArr)
            self.getDistLoc(inputArray: allFTAddressArr)
            
            /*
            for address in self.allFTAddress {
                print(address)
                guard let url2 = URL(string: "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=\(self.location)&destinations=\(address)&key=AIzaSyAif9oTDr1DTrTP1Z7oxsmdp3SSnwSHr-g") else {return}
                
                print(url2)
                let task = URLSession.shared.dataTask(with: url2) {(data, response, error) in
                    
                    guard let dataResponse = data, error == nil else {
                        print(error?.localizedDescription ?? "Response Error")
                        return
                    }
                    guard let data2 = data else {return}
                    print(data2)
                }
            }*/
        }
        task.resume()
    }
    
    /*
     Purpose: Calculate the distance between two address
    */
    func getDistLoc(inputArray: Array<Any>) {
        
        let allAddressArr = inputArray
        
        for address in allAddressArr {
            // URL string that returns the JSON object for parsing
            let urlString = "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=\(self.location)&destinations=\(address)&key=AIzaSyAif9oTDr1DTrTP1Z7oxsmdp3SSnwSHr-g"
            
            /*Url not returned value, is NIL (FIXXX!!!) */
            // set urlString to be URL type
            //guard let url = URL(string: urlString) else { return }
            
            print("Location Input: ", self.location)
            print("Address: ", address)
            print(urlString)
            /*
            let task = URLSession.shared.dataTask(with: url2) {(data, response, error) in
                
                guard let dataResponse = data, error == nil else {
                    print(error?.localizedDescription ?? "Response Error")
                    return
                }
                guard let data2 = data else {return}
                print(data2)
            }*/
        }
    }
    
}

