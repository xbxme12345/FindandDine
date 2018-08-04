//
//  ViewController.swift
//  Find&Dine
//
//  Created by Gregory Lee on 6/4/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import UIKit
import GooglePlaces

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    // init location manager
    let locationManager = CLLocationManager()
    
    // init GMSPlacesClient
    var placesClient: GMSPlacesClient!
    
    // define connections to input fields for ViewController
    @IBOutlet weak var locationInput: UITextField!
    @IBOutlet weak var travelDistanceInput: UITextField!
    @IBOutlet weak var searchKeywordsInput: UITextField!
    @IBOutlet weak var ratingInput: UISlider!
    @IBOutlet weak var minPriceInput: UISegmentedControl!
    @IBOutlet weak var maxPriceInput: UISegmentedControl!
    @IBOutlet weak var ratingOutput: UILabel!
    @IBOutlet weak var serviceInput: UISegmentedControl!
    
    // variables used for storing values from user. Each has a default value and is reflected in the UI
    private var rating = 3.0
    private var service = "Google"
    private var type = "restaurant"
    private var minPrice = 1
    private var maxPrice = 2
    
    /**
     Purpose: Retrieve value of the rating slider if it is moved.
     
     Parameter: UISlider: The position of the slider indicates its value
     */
    @IBAction func ratingChange(_ sender: UISlider) {
        // set current value to the input from the UISlider and round value to nearest tenth.
        let currentValue = Float(round(ratingInput.value*10)/10)
        
        // update label in ViewController to display current value
        ratingOutput.text = "\(currentValue)"
        
        // set the current value as the rating
        rating = Double(currentValue)
    }
    
    /**
     Purpose: Determine which rating service to use, Google (default) or Yelp
     
     Parameter: UISegmentedControll: the selected segment determines which service is used. Default is Google 
     */
    @IBAction func serviceSelector(_ sender: UISegmentedControl) {
        switch serviceInput.selectedSegmentIndex {
        case 0:
            service = "Google"
        case 1:
            service = "Yelp"
        default:
            break
        }
    }
    
    /**
     Purpose: To get the minPrice set by the user
     
     Parameter: sender: This is a UISegmentedControl which contains 4 options in this implementation
     */
    @IBAction func minPriceChange(_ sender: UISegmentedControl) {
        // Switch used to determine which option was selected then set minPrice to the corresponding value
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
     Purpose: To get the maxPrice set by the user
     
     Parameter: sender: This is a UISegmentedControl which contains 4 options in this implementation
     */
    @IBAction func maxPriceChange(_ sender: UISegmentedControl) {
        // Switch used to determine which option was selected then set maxPrice to the corresponding value
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
        
        // assign values from this VC to resultsVC
        resultsViewController.location = locationInput.text!
        resultsViewController.travelDistance = travelDistanceInput.text!
        resultsViewController.keyword = searchKeywordsInput.text!
        resultsViewController.service = service
        resultsViewController.minPrice = minPrice
        resultsViewController.maxPrice = maxPrice
        resultsViewController.minRating = Float(rating)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set placeholder text for locationInput to notify user that the current address is going to be used
        locationInput.placeholder = "Loading current address..."
        
        // set places sdk client
        placesClient = GMSPlacesClient.shared()
        
        // request for use of location if first time using app
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // update locationInput to display current location
        setCurrentLocation()
        
        // set location manager as delegate
        locationManager.delegate = self
        
        // set inital place holder text for search radius
        travelDistanceInput.placeholder = "0.5, 1, 2.25,... "
        
        // set inital place holder text for searchKeywordsInput
        searchKeywordsInput.placeholder = "Enter a restaurant or food type"
        
        // set numeric keypad with decimal for travel distance input
        travelDistanceInput.keyboardType = UIKeyboardType.decimalPad
        
        // set default distance for users
        travelDistanceInput.text = "1"
        
        // add Done buttons to keyboard tool bar. Used to dismiss keyboard when user is done with input
        locationInput.addDoneButtonOnKeyboard()
        travelDistanceInput.addDoneButtonOnKeyboard()
        searchKeywordsInput.addDoneButtonOnKeyboard()
        
        // init right bar button. When pressed exec goToNextPage func
        let rightBarButton = UIBarButtonItem(title: "Search", style: .plain, target: self, action: #selector(goToNextPage))
        
        // add to navigation bar
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    /**
     Purpose: to check inputs so that empty values are not used in the API strings
     */
    @objc func goToNextPage() {
        // if both location and distance are specified, then send all info to resultsVC
        if locationInput.text != "" && travelDistanceInput.text != "" {
            if service == "Yelp" && searchKeywordsInput.text! == "" {
                // init alert
                let alert = UIAlertController(title: "Input Error", message: "Please specify a keyword when using Yelp.", preferredStyle: .alert)
                
                // add close option. Selecting this option will call openGoogleMaps
                alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                
                // display alert to user
                self.present(alert, animated: true)
            }
            else {
                performSegue(withIdentifier: "toResults", sender: self)
            }
        }
        // else display alert to user notifying them to fill out both fields
        else if locationInput.text! == "" || travelDistanceInput.text! == "" { 
            // init alert
            let alert = UIAlertController(title: "Input Error", message: "Please specify a location and a valid search radius.", preferredStyle: .alert)
            
            // add close option. Selecting this option will call openGoogleMaps
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            
            // display alert to user
            self.present(alert, animated: true)
        }
    }
    
    /**
     Purpose: Retrieve address of current location and set locationInput to the address
     */
    func setCurrentLocation() {
        // get the current location
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
    }
}

/**
 Purpose: To add the Done button to the keyboards so that the keyboards can be dismissed when the user is done entering their input
 */
extension UITextField {
    @IBInspectable var doneAccessory: Bool {
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
