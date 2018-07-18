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
    
    // Connections to input fields for ViewController
    @IBOutlet weak var locationInput: UITextField!
    @IBOutlet weak var travelDistanceInput: UITextField!
    @IBOutlet weak var searchKeywordsInput: UITextField!
    @IBOutlet weak var ratingInput: UISlider!
    @IBOutlet weak var reviewServiceInput: UISwitch!
    @IBOutlet weak var minPriceInput: UISegmentedControl!
    @IBOutlet weak var maxPriceInput: UISegmentedControl!
    @IBOutlet weak var ratingOutput: UILabel!
    
    // variables used for storing values from non text fields
    // each set to a default value
    var currentLocationUse = 0
    var rating = 3.0
    var service = "Google"
    var minPrice = 1
    var maxPrice = 2

    /** get value of slider and set rating
     Purpose: Retrieve value of the rating slider if it is moved.
     
     Parameter: UISlider: The position of the slider indicates its value
     
     */
    @IBAction func ratingChange(_ sender: UISlider) {
        // set current value to the input from the UISlider
        let currentValue = ratingInput.value
        
        // update label in ViewController to display current value
        ratingOutput.text = "\(currentValue)"
        
        // set the current value as the rating
        rating = Double(currentValue)
    }
    
    /**determine service to use
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
    
    /**
     Purpose: to get the minPrice set by the user
     
     Parameter: sender: This is a UISegmentedControl which contains 4 options in this implementation
     
     */
    @IBAction func minPriceChange(_ sender: UISegmentedControl) {
        // Go into switch to determine which option was selected then set minPrice to the corresponding value
        switch minPriceInput.selectedSegmentIndex {
        case 0:
            minPrice = 1
        case 1:
            minPrice = 2
        case 2:
            minPrice = 3
        case 3:
            minPrice = 4
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
    }
    
    /**send data to results VC
     Purpose: Send data to the specified variables in resultsViewController from above
     
     Parameter: sender: the UIBarButtonItem which navigates to the next ViewController
     
     TESTTEST
     */
    @IBAction func Find(_ sender: UIBarButtonItem) {
        // make sure that location, distance and keyword are filled out before sending data
        if locationInput.text != "" && travelDistanceInput.text != "" && searchKeywordsInput.text != "" {
            performSegue(withIdentifier: "resultsViewController", sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesClient = GMSPlacesClient.shared()
        
        // set location manager as delegate
        locationManager.delegate = self
        
        // request for use of location
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

