//
//  ViewController.swift
//  Find&Dine
//
//  Created by Gregory Lee on 6/4/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import UIKit
import GooglePlaces

class ViewController: UIViewController, CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // init location manager
    let locationManager = CLLocationManager()
    
    // init GMSPlacesClient
    var placesClient: GMSPlacesClient!
    
    // Connections to input fields for ViewController
    @IBOutlet weak var locationInput: UITextField!
    @IBOutlet weak var travelDistanceInput: UITextField!
    @IBOutlet weak var searchKeywordsInput: UITextField!
    @IBOutlet weak var ratingInput: UISlider!
    @IBOutlet weak var reviewServiceInput: UISwitch!
    @IBOutlet weak var minPriceInput: UISegmentedControl!
    @IBOutlet weak var maxPriceInput: UISegmentedControl!
    @IBOutlet weak var ratingOutput: UILabel!
    @IBOutlet weak var searchTypeInput: UISegmentedControl!
    
    // variables used for storing values from non text fields
    // each set to a default value
    var currentLocationUse = 0
    var rating = 3.0
    var service = "Google"
    var type = "restaurant"
    var minPrice = 1
    var maxPrice = 2
    var sv = UIView()
    
    // separate lists for food and reataurants
    let food = ["Burrito", "Pizza", "Burger", "Sushi"]
    let restaurant = ["American", "Cajun", "Chinese", "French", "Filipino", "Greek", "Indian", "Indonesian", "Italian", "Japanese", "Jewish", "Korean", "Malaysian", "Mexican", "Polish" , "Portugese", "Punjabi", "Russian", "Thai", "Turkish"]
    
    // set default list
    var pickerData = ["American", "Cajun", "Chinese", "French", "Filipino", "Greek", "Indian", "Indonesian", "Italian", "Japanese", "Jewish", "Korean", "Malaysian", "Mexican", "Polish" , "Portugese", "Punjabi", "Russian", "Thai", "Turkish"]
    
    /**
     Purpose: To define how many columns show up in the UIPickerView
     
     Return: 1. Only 1 column of options will be visible
     */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /**
     Purpose: To return the number of elements in the array
     
     Return: pickerData.count. denotes how many rows to make for the UIPickerView
     */
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    /**
     Purpose: To return the data stored at row
     
     Return: pickerData[row]. returns stored data at element row
     */
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    /**
     Purpose: To set the display to match the data that was selected
     */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        searchKeywordsInput.text = pickerData[row]
    }
    
    /**
     Purpose: Retrieve value of the rating slider if it is moved.
     
     Parameter: UISlider: The position of the slider indicates its value
     
     */
    @IBAction func ratingChange(_ sender: UISlider) {
        // set current value to the input from the UISlider
        let currentValue = ratingInput.value
        
        // update label in ViewController to display current value
        ratingOutput.text = "\(Int(currentValue))"
        
        // set the current value as the rating
        rating = Double(currentValue)
    }
    
    /**
     Purpose: To determine which rating service to use (Google (default) or Yelp)
     
     Parameter: UISwitch: the switch's position determines which service is used
     
     */
    @IBAction func serviceChange(_ sender: UISwitch) {
        // if the switch is in the on position, then use the Yelp service
        if reviewServiceInput.isOn {
            service = "Yelp"
        }
        else {
            service = "Google"
        }
    }
    
    @IBAction func SearchTypeChange(_ sender: UISegmentedControl) {
        switch searchTypeInput.selectedSegmentIndex {
        case 0:
            type = "restaurant"
            pickerData = restaurant
            searchKeywordsInput.text = ""
            searchKeywordsInput.placeholder = "Mexican, Chinese, Italian..."
        case 1:
            type = "food"
            pickerData = food
            searchKeywordsInput.text = ""
            searchKeywordsInput.placeholder = "Pizza, Burritos, Ramen..."
        default:
            break
        }
    }
    
    /**
     Purpose: to get the minPrice set by the user
     
     Parameter: sender: This is a UISegmentedControl which contains 4 options in this implementation
     
     */
    @IBAction func minPriceChange(_ sender: UISegmentedControl) {
        // Go into switch to determine which option was selected then set minPrice to the corresponding value
        // disable options in maxPriceInput if the minPriceInput > maxPriceInput
        switch minPriceInput.selectedSegmentIndex {
        case 0:
            minPrice = 1
            maxPriceInput.setEnabled(true, forSegmentAt: 0)
            maxPriceInput.setEnabled(true, forSegmentAt: 1)
            maxPriceInput.setEnabled(true, forSegmentAt: 2)
            maxPriceInput.setEnabled(true, forSegmentAt: 3)
        case 1:
            minPrice = 2
            maxPriceInput.setEnabled(false, forSegmentAt: 0)
            maxPriceInput.setEnabled(true, forSegmentAt: 1)
            maxPriceInput.setEnabled(true, forSegmentAt: 2)
            maxPriceInput.setEnabled(true, forSegmentAt: 3)
        case 2:
            minPrice = 3
            maxPriceInput.setEnabled(false, forSegmentAt: 0)
            maxPriceInput.setEnabled(false, forSegmentAt: 1)
            maxPriceInput.setEnabled(true, forSegmentAt: 2)
            maxPriceInput.setEnabled(true, forSegmentAt: 3)
        case 3:
            minPrice = 4
            maxPriceInput.setEnabled(false, forSegmentAt: 0)
            maxPriceInput.setEnabled(false, forSegmentAt: 1)
            maxPriceInput.setEnabled(false, forSegmentAt: 2)
            maxPriceInput.setEnabled(true, forSegmentAt: 3)
        default:
            break
        }
    }
    
    /**
     Purpose: to get the maxPrice set by the user
     
     Parameter: sender: This is a UISegmentedControl which contains 4 options in this implementation
     
     */
    @IBAction func maxPriceChange(_ sender: UISegmentedControl) {
        // Go into switch to determine which option was selected then set maxPrice to the corresponding value
        switch maxPriceInput.selectedSegmentIndex {
        case 0:
            maxPrice = 1
        case 1:
            maxPrice = 2
        case 2:
            maxPrice = 3
        case 3:
            maxPrice = 4
        default:
            break
        }
    }
    
    /**
     Purpose: Prepare to send data from this ViewController to resultsViewController
     
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // init resultsViewController as the segue destination
        let resultsViewController = segue.destination as! resultsViewController
        resultsViewController.locationFlag = currentLocationUse
        resultsViewController.location = locationInput.text!
        resultsViewController.travelDistance = travelDistanceInput.text!
        resultsViewController.keyword = searchKeywordsInput.text!
        resultsViewController.service = service
        resultsViewController.minPrice = minPrice
        resultsViewController.maxPrice = maxPrice
        resultsViewController.minRating = Float(rating)
        resultsViewController.searchType = type
        // resultsViewController.sv = sv
    }
    
    private func convertDist(dist: Double) -> Double {
        let temp = dist * 1609.334
        return temp
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesClient = GMSPlacesClient.shared()
        
        // set inital place holder text for searchKeywordsInput
        searchKeywordsInput.placeholder = "Mexican, Chinese, Italian..."
        
        // set numeric keypad with decimal to travel dist input
        travelDistanceInput.keyboardType = UIKeyboardType.decimalPad
        
        // set location manager as delegate
        locationManager.delegate = self
        
        // request for use of location
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // init UIPickerView to list many types of restaurants
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 220))
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        // disabled because idk how to implement thing to block users from putting in toenail
        //        searchKeywordsInput.inputView = pickerView
        searchKeywordsInput.addDoneButtonOnKeyboard()
        
        // add Done buttons to keyboard tool bar. Used to dismiss keyboard when user is done with input
        locationInput.addDoneButtonOnKeyboard()
        travelDistanceInput.addDoneButtonOnKeyboard()
        
        // init right bar button. When pressed exec goToNextPage func
        let rightBarButton = UIBarButtonItem(title: "Find", style: .plain, target: self, action: #selector(goToNextPage))
        
        // add to navigation bar
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    /**
     Purpose: to check inputs so that empty values are not used in the API strings
     
     */
    @objc func goToNextPage() {
        if locationInput.text != "" && travelDistanceInput.text != "" {
            //            sv = ViewController.displaySpinner(onView: self.view)
            performSegue(withIdentifier: "toResults", sender: self)
        }
        else if locationInput.text == "" || travelDistanceInput.text == "" {
            // init alertsheet
            let alert = UIAlertController(title: "Input Error", message: "Please specify a location and search radius.", preferredStyle: .alert)
            
            // add close option. Selecting this option will call openGoogleMaps
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            
            // display alert to user
            self.present(alert, animated: true)
        }
    }
    
    /**
     Purpose: Retrieve current location's address
     
     Parameter: sender: UIButton, when the button is pressed, execute this function
     */
    @IBAction func getCurrentPlace(_ sender: UIButton) {
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

extension ViewController {
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}

extension UITextField {
    
    @IBInspectable var doneAccessory: Bool{
        get {
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone {
                addDoneButtonOnKeyboard()
            }
        }
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        self.resignFirstResponder()
    }
}
