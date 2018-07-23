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
    
    //Arrays used to store distance between origin and destination
    var distanceText = [String]()
    var distanceDouble = [Double]()
    
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
            
            //Assign array to allFTAddressArr to be passed into a function
            let allFTAddressArr = Array(self.allFTAddress)
            
            //Input array to calculate distance between all food truck addresses
            self.getDistLoc(inputArray: allFTAddressArr)
            
            //Converting the travel distance from miles to kilometer and storing as a double
            let travelDistKM = self.getDistance(distance: Double(self.travelDistance)!)
            print("travel distance: ", travelDistKM)
            
            //Convert all distance calculated and convert to double
            //Append all resulting double values to distanceDouble array
            for val in self.distanceText {
                let result = String(val.characters.dropLast(2))
                var result2 = result.trimmingCharacters(in: .whitespacesAndNewlines)
                var result3 = result2.replacingOccurrences(of: ",", with: "")
                var result4 = NSString(string: result3).doubleValue
                self.distanceDouble.append(result4)
            }
            
            print(self.distanceDouble)
            
            //Compare all distance to user inputted travel distance
            //distance <= user input travel distance
            for i in self.distanceDouble {
                if(i <= travelDistKM) {
                    
                } else {
                    //Skip if distance > user input travel distance
                }
            }
            
            /*
            for add in allFTAddressArr {
                
            }
            */

        }
        task.resume()
    }
    
    /**
     Purpose: Convert distance from miles to meters
     
     Return: return converted distance
     */
    func getDistance(distance: Double) -> Double {
        // formula for converting miles to meters
        let distanceInMeters = distance * 1.60934
        
        // return distance in meters
        return distanceInMeters
    }
    
    func convertDistDouble(distance: Double) -> Double {
        let distanceInKM = distance * 1.0
        return distanceInKM
    }
    
    /*
     Purpose: Calculate the distance between two address
    */
    func getDistLoc(inputArray: Array<Any>) {
        
        let allAddressArr = inputArray
        
        for address in allAddressArr {
            // URL string that returns the JSON object for parsing
            let urlString = "https://maps.googleapis.com/maps/api/distancematrix/json?origins=\(self.location)&destinations=\(address)&key=AIzaSyDtbc_paodfWo1KRW0fGQ1dB--g8RyG-Kg"
            
            guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!) else { return }
            
            do {
                let base_url = try! Data(contentsOf: url)
                let jsonResponse = try! JSONSerialization.jsonObject(with: base_url, options: []) as! NSDictionary
                let json1 = jsonResponse["rows"] as! NSArray
                let json2 = json1[0] as! NSDictionary
                let json3 = json2["elements"] as! NSArray
                let dic = json3[0] as! NSDictionary
                
                let distance = dic["distance"] as! NSDictionary
                if let distanceTxt = distance["text"] as? String {
                    self.distanceText.append(distanceTxt)
                }
                
            } catch {
                print(error.localizedDescription)
            }
            
        }
    }
    
}

