//
//  ftViewController.swift/Users/huangy4/Desktop/College Work/Senior/Summer/Senior Project/Find-Dine/Find&Dine/Find&Dine/ftViewController.swift
//  Find&Dine
//
//  Created by Yan Wen Huang on 6/17/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import UIKit
import TCPickerView
import GooglePlaces

class ftViewController: UIViewController, TCPickerViewOutput {
    
    @IBOutlet weak var locationInput: UITextField!
    @IBOutlet weak var travelDistanceInput: UITextField!
    @IBOutlet weak var showMeal: UIButton!
    @IBOutlet weak var daySelection: UIButton!
    
    var placesClient: GMSPlacesClient!
    
    var currentLocationUse = 0
    var typeOfMeal = [String]()
    var dayOfWeekVal = [String]()
    var meal = ""
    var day = ""
    
    private let theme = TCPickerViewDarkTheme()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesClient = GMSPlacesClient.shared()
        
        //add Done buttons to keyboard tool bar. Used to dismiss keyboard when user is done with input
        locationInput.addDoneButtonOnKeyboard()
        travelDistanceInput.addDoneButtonOnKeyboard()
    }
    
    /*
     Purpose: To create a popup selection of different types of meal
              Store the selection into a array/list
    */
    @IBAction func mealBtnPressed(_ sender: Any) {
        //Setup for TCPickerView module - Meal Selection
        var picker: TCPickerViewInput = TCPickerView()
        picker.title = "Type of Meal"
        let meal = [
            "Breakfast",
            "Lunch",
            "Dinner"
            ]
        let values = meal.map { TCPickerView.Value(title: $0) }
        picker.values = values
        picker.theme = self.theme
        picker.delegate = self
        picker.selection = .multiply
        self.typeOfMeal.removeAll()
        picker.completion = { (selectedIndexes) in
            for i in selectedIndexes {
                print(values[i].title)
                //Store selected value then append to array
                let meal = values[i].title
                print("Chosen Meal: \(meal)")
                self.typeOfMeal.append(mealValue(meal: String(describing: meal)).meal);
            }
            print("Chose meal: ", self.typeOfMeal)
        }
        picker.show()
    }
    
    /*
     Purpose: To create a popup selection of different days of the week
              Store the selection into a array/list
    */
    @IBAction func dayBtnPressed(_ sender: Any) {
        //Setup for TCPickerView module - dayOfWeek Selection
        var picker: TCPickerViewInput = TCPickerView()
        picker.title = "Day of the Week"
        let dayOfWeek = [
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "Sunday"
            ]
        let values = dayOfWeek.map { TCPickerView.Value(title: $0) }
        picker.values = values
        picker.theme = self.theme
        picker.delegate = self
        picker.selection = .multiply
        self.dayOfWeekVal.removeAll()
        picker.completion = { (selectedIndexes) in
            for i in selectedIndexes {
                print(values[i].title)
                //Store selected value and then append to array
                let day = values[i].title
                print("Chosen day of the week: \(day)")
                self.dayOfWeekVal.append(dayOfWeekValue(dayOfWeek: String(describing: day)).dayOfWeek);
            }
            print("Chose day of the week: ", self.dayOfWeekVal)
        }
        picker.show()
    }
    
    /*
     Purpose: Displays in terminal the row that the user selected
    */
    func pickerView(_ pickerView: TCPickerViewInput, didSelectRowAtIndex index: Int) {
        print("User select row at index: \(index)")
    }
    
    /*
     Purpose: 
    */
    @IBAction func findFoodTruck(_ sender: Any) {
        performSegue(withIdentifier: "foodTruckList", sender: self)
    }
    
    /*
     Purpose: Prepare to send data from this ViewController to resultsViewController
     
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let ftVC = segue.destination as! ftResultViewController
        ftVC.location = self.locationInput.text!
        ftVC.locationFlag = self.currentLocationUse
        ftVC.travelDistance = self.travelDistanceInput.text!
        ftVC.typeOfMealValue = self.typeOfMeal
        ftVC.dayOfWeekValue = self.dayOfWeekVal
    }
    
    /**
     Purpose: Retrieve current location's address
     
     Parameter: sender: UIButton, when the button is pressed, execute this function
    */
    @IBAction func getCurrentPlace(_ sender: Any) {
        // get the current place
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            // if there is an error then output the error
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            // if there is info about this place then retrieve it and then set the location field to the formatted address of the current location
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.locationInput.text = place.formattedAddress?.components(separatedBy: ", ").joined(separator: "\n")
                }
            }
        })
        
        // flag for use in resultsViewController
        currentLocationUse = 1
    }
}
