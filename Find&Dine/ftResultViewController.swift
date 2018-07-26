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

//Main Struct
struct ftJSON: Codable {
    let html_attributions = [String:String]()
    let results: [ftResult]?
    let status: String
}
//Supplementary struct
struct ftResult: Codable {
    let location: String
    let mealValue: String
    let dayValue: String
    let ftName: String
}

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

/**
 Purpose: defines the ftInfo type. This is the info stored for each resturant
 */
struct ftInfo {
    let meal: String
    let location: String
    let dayOfWeek: String
    let foodTruckName: String
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

//Global Variables to be used on other VC
//Store the food truck to display in table view UI
var foodTruckList = [ftInfo]()
var selectedIndex = 0
var name = ""
var address = ""
var meal = ""
var day = ""

class ftResultViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //Define connections
    @IBOutlet weak var tableViewFoodTruck: UITableView!
    
    //Local variables for receiving data from ftViewController
    var locationFlag = Int()
    var location = String()
    var travelDistance = String()
    var typeOfMealValue = [String]()
    var dayOfWeekValue = [String]()
    
    //Array to store all distinct addresses in JSON file
    var allFTAddress = Set<String>()
    
    //List to store all addresses along with the distance to current location
    var tmpDistAddress = [distanceLoc]()
    
    //Array to store food truck addresses which are within travel distance input of the user's current location
    var closeByFTAddress = Set<String>()
    
    //Arrays used to store distance between origin and destination
    var distanceText = [String]()
    var distanceDouble = [Double]()
    var closeDistStore = [Double]()
    
    //Init location manager
    private let locationManager = CLLocationManager()
    
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
        cell.detailTextLabel?.text = "\(foodTruck.location)    \(foodTruck.dayOfWeek) \(foodTruck.meal)"
        
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set location manager delegate and request for location use if not authorized already
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
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: [])
                guard let jsonArray = jsonResponse as? [[String: Any]] else {return}
                
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
                let result2 = result.trimmingCharacters(in: .whitespacesAndNewlines)
                let result3 = result2.replacingOccurrences(of: ",", with: "")
                let result4 = NSString(string: result3).doubleValue
                self.distanceDouble.append(result4)
            }
            
            //Compare all distance to user inputted travel distance
            //distance <= user input travel distance
            for i in self.distanceDouble {
                if(i <= travelDistKM) {
                    //Stores the distance that are <= user input travel distance
                    self.closeDistStore.append(i)
                } else {
                    //Skip if distance > user input travel distance
                }
            }
            
            //Get the index of the stored distance in closeDistStore array from distanceDouble array of all addresses
            //Take the index value to locate the address and append to string set
            for i in self.closeDistStore {
                let val = self.distanceDouble.index(of: i)
                let locIndex = allFTAddressArr[val!]
                self.closeByFTAddress.insert(locIndex)
            }
            
            //Calls function to retrieve food truck information
            self.getFoodTruckInfo(address: self.closeByFTAddress)
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
    
    /*
     Purpose: Change distance from string to double
     
     Return: Returns distance as double
    */
    func convertDistDouble(distance: Double) -> Double {
        let distanceInKM = distance * 1.0
        return distanceInKM
    }
    
    /*
     Purpose: Get food truck info based upon address that are close to user's location
    */
    func getFoodTruckInfo(address: Set<String>){
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
            
            //Parse through json file using close by address, user selected type of meal and day of the week
            //Append all results/food truck info to array
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: [])
                guard let jsonArray = jsonResponse as? [[String: Any]] else {return}
                
                for elem in jsonArray {
                    if address.contains(elem["Location"] as! String) {
                        if self.typeOfMealValue.contains(elem["Meal"] as! String) {
                            if self.dayOfWeekValue.contains(elem["DayOfWeek"] as! String) {
                                //print(elem["FoodTruck"], " at ", elem["Location"], " for ", elem["Meal"])
                                foodTruckList.append(ftInfo(meal: elem["Meal"] as! String, location: elem["Location"] as! String, dayOfWeek: elem["DayOfWeek"] as! String, foodTruckName: elem["FoodTruck"] as! String))
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


