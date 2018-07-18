//
//  resultsViewController.swift
//  Find&Dine
//
//  Created by Gregory Lee on 6/6/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

/**
 SET DEFAULT VALUE FOR RATING
 check to make sure that the fields are filed out?
 
 
 ask yan how she do
 do a bit more testing on API call
 */

import UIKit
import GooglePlacePicker
import GoogleMaps
import Foundation

/**
 Purpose: This is used to capture all of the properties listed in the JSON result
 */
struct geocodingJSON: Codable {
    let html_attributions = [String:String]()
    let results: [infoResult]?
}
//supplementary structs
struct infoResult: Codable {
    let geometry: loc?
    let icon: String?
    let id: String?
    let name: String?
    let opening_hours: hours?
    let photos: [image]?
    let place_id: String?
    let price_level: Int?
    let rating: Float
    let reference: String?
    let scope: String?
    let types: [String]?
    let vicinity: String?
}
struct lines: Codable {
    let line: [String]?
}
struct log_info: Codable {
    let experiment_id: [String]?
    let query_geographic_location: String?
}
struct loc: Codable {
    let location: [String: Double]?
}
struct location: Codable {
    let lat: Double
    let lng: Double
}
struct hours: Codable {
    let open_now: Bool?
    let weekday_text: [String]?
}
struct image: Codable {
    let height: Int?
    let html_attributions: [String]?
    let photo_reference: String?
    let width: Int?
}

/**
 Purpose: defines the RestInfo type. This is the info stored for each resturant
 */
struct RestInfo {
    let lat: Double
    let lng: Double
    let pid: String
}

class resultsViewController: UIViewController {
    
    // init location manager
    private let locationManager = CLLocationManager()
    
    // init map view
    @IBOutlet weak var mapView: GMSMapView!
    
    // connect UI with variables
    @IBOutlet weak var restaurantName: UILabel!
    @IBOutlet weak var placeAddr: UILabel!
    @IBOutlet weak var placeRating: UILabel!
    @IBOutlet weak var placePrice: UILabel!
    @IBOutlet weak var restaurantImage: UIImageView!
    @IBOutlet weak var searchAgain: UIButton!
    
    // local variables for receiving data from 1st VC
    var locationFlag = Int() 
    var location = String()
    var travelDistMeters = Double()
    var travelDistance = String()
    var keyword = String()
    var service = String()
    var minRating = Float()
    var minPrice = Int()
    var maxPrice = Int()
    
    // variables to store the location at which the search will occur
    var originlatitude = Double()
    var originlongitude = Double()
    
    //array used to store each restaurant's information
    private var RestList = [RestInfo]()
    
    //store random number calculated from RestList.count
    private var randomNum = Int()
    
    //store random numbers to ensure that no duplicates are used
    private var randomNumList = [Int]()
    
    //store restaurant coordinates
    private var restPosCoord = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set location manager delegate and request for location use if not authorized already
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // if the Use Current Location button was pressed, then get the current location of the device and store those for use in the geocodeRequest function
        if locationFlag == 1 {
            originlatitude = (locationManager.location?.coordinate.latitude)!
            originlongitude = (locationManager.location?.coordinate.longitude)!
        }
        else {
            //getCoordinates()? 
        }
        
        // convert distance from miles to meters
        travelDistMeters = getDistance(distance: Double(travelDistance)!)
        
        // exec geocodeRequest to get resturants based on criteria from user
        geocodeRequest(lat: originlatitude, lng: originlongitude, radius: travelDistMeters, keyword: keyword, minPrice: minPrice , maxPrice: maxPrice, minRating: minRating)
        
        // wait for lat and lng to be set before proceeding
        while (restPosCoord.longitude == 0.0) {
            print("waiting...")
        }
        
        // set marker of first restaurant
        placeMarker(position: restPosCoord)
    }
    
    func geocodeRequest(lat: Double, lng: Double, radius: Double, keyword: String, minPrice: Int, maxPrice: Int, minRating: Float) {
        
        // URL string that returns the JSON object for parsing
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lng)&radius=\(radius)&type=restaurant&minprice=\(minPrice)&maxprice=\(maxPrice)&keyword=\(keyword)&key=AIzaSyDtbc_paodfWo1KRW0fGQ1dB--g8RyG-Kg"
        
        // set urlString to be URL type?
        guard let url = URL(string: urlString) else { return }
        
        //create task to execute API call and parse the JSON into the RestList array
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            // if the error is not nil, then print out error message
            if error != nil {
                print(error!.localizedDescription)
            }
            
            // make sure data is data
            guard let data = data else { return }
            
            // Implement JSON decoding and parsing
            do {
                // Decode retrived data with JSONDecoder into format specified by geocodingJSON
                let restaurantInfo = try JSONDecoder().decode(geocodingJSON.self, from: data)
        
                // append each restaurant info to the array if it is greater than the minRating
                for elem in (restaurantInfo.results)! {
                    if elem.rating >= minRating {
                        self.RestList.append(RestInfo(lat: elem.geometry?.location!["lat"]! as! Double, lng:elem.geometry?.location!["lng"]! as! Double, pid: elem.place_id!))
                    }
                }
            } catch let jsonError { print(jsonError) }
            
            // calc random number and add to list
            self.randomNum = Int(arc4random_uniform(UInt32(self.RestList.count)))
            self.randomNumList.append(self.randomNum)
            
            // update display to the first randomly generated resturant
            self.setDisplay(pid: self.RestList[self.randomNum].pid)
            
            // set coordinates of resturant
            self.restPosCoord = CLLocationCoordinate2D(latitude: self.RestList[self.randomNum].lat, longitude: self.RestList[self.randomNum].lng)
        }
        
        // start task specified above
        task.resume()
    }
    
    /**
     Purpose: updates the display in resultsViewController to show resturant name, address, rating, price and image of randomly generated resturant
     */
    func setDisplay(pid: String) {
//        let placeID = pid
        //init GMSPlacesClient() to access Google Places info
        let placesClient = GMSPlacesClient()
        
        // look up the placeID and then set the display fields
        placesClient.lookUpPlaceID(pid, callback: { (place, error) -> Void in
            // if there is an error then output the error and exit function
            if let error = error {
                print("lookup place id query error: \(error.localizedDescription)")
                return
            }
            // check that the location exists
            guard let place = place else {
                print("No place details for \(pid)")
                return
            }
            
            // set text fields to the resturant info
            self.restaurantName.text = place.name
            self.placeAddr.text = place.formattedAddress
            self.placeRating.text = String(place.rating)
            self.placePrice.text = self.text(for: place.priceLevel)
            self.loadFirstPhotoForPlace(placeID: place.placeID)
        })
    }
    
    /**
     Purpose: Place a marker onto the map
     
     Parameter: position: This stores the coordinates of the location
     
     */
    func placeMarker(position: CLLocationCoordinate2D) {
        // init a marker for the passed in position
        let marker = GMSMarker(position: position)
        
        //set title of the marker to the name of the resturant
        marker.title = restaurantName.text
        
        //update the map
        marker.map = mapView
    }
    
    /**
     Purpose: Generates a new random number
     
     Parameter: UIButton: waits for the UIButton to be pressed, then executes this function
    */
    @IBAction func SearchAgain(_ sender: UIButton) {
        // clear map of existing markers
        mapView.clear()
        
        // if statement to ensure that we generate the correct amount of random numbers
        if (randomNumList.count < RestList.count) {
            // generate a random number
            var temp = Int()
            
            // if the random number was already used (in randomNumList) then calculate again
            repeat {
                temp = Int(arc4random_uniform(UInt32(RestList.count)))
            } while (randomNumList.contains(temp))
            
            // set the newly calculated random number to randomNum to be used within this class and add it to the randomNumList
            randomNum = temp
            randomNumList.append(randomNum)
            
            // update the display
            setDisplay(pid: RestList[randomNum].pid)
            
            // set new coordinates
            restPosCoord = CLLocationCoordinate2D(latitude: RestList[randomNum].lat, longitude: RestList[randomNum].lng)
            
            // place new marker
            placeMarker(position: restPosCoord)
            
            // if we have reached the end of the RestList, disable the button
            if (randomNumList.count == RestList.count) {
                searchAgain.isEnabled = false;
            }
        }
    }
    
    /**
     Purpose: convert distance from miles to meters
     
     Return: return converted distance
     
     */
    func getDistance(distance: Double) -> Double {
        // formula for converting miles to meters
        let distanceInMeters = distance * 1609.344
        
        // return distance in meters
        return distanceInMeters
    }
    
    /**
     Purpose: convert Google places value into a string for output
     
     Parameter: priceLevel: stored price level for a specified place
     
     Return: A string that signifies how expensive a resturant is
     */
    func text(for priceLevel: GMSPlacesPriceLevel) -> String {
        // determine what the price level is and return the corresponding string
        switch priceLevel {
            case .free: return NSLocalizedString("Free", comment: "Free")
            case .cheap: return NSLocalizedString("$", comment: "$")
            case .medium: return NSLocalizedString("$$", comment: "$$")
            case .high: return NSLocalizedString("$$$", comment: "$$$")
            case .expensive: return NSLocalizedString("$$$$", comment: "$$$$")
            case .unknown: return NSLocalizedString("Unknown", comment: "Unknown")
            }
    }
    
    /**
     Purpose: To load the photo accessed by the Google Places SDK
     
     Parameter: placeID: This is used by Google to uniquely id a place
     
     */
    func loadFirstPhotoForPlace(placeID: String) {
        // look up the mage and then call the loadImageForMetaData function to set the image
        GMSPlacesClient.shared().lookUpPhotos(forPlaceID: placeID) { (photos, error) -> Void in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                if let firstPhoto = photos?.results.first {
                    self.loadImageForMetadata(photoMetadata: firstPhoto)
                }
            }
        }
    }
    
    /**
     Purpose: to help loadFirstPhotoForPlace function
     
     Parameter: photoMetaData: metadata passed to it from loadFirstPhotoForPlace
    */
    private func loadImageForMetadata(photoMetadata: GMSPlacePhotoMetadata) {
        // refresh the display if there are no errors with the first image associated with the place
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
            if let error = error {
                // TODO: handle the error.
                print("Error: \(error.localizedDescription)")
            } else {
                self.restaurantImage.image = photo;
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

/**
 Purpose: Used for location services and setting mapView camera
 */
extension resultsViewController: CLLocationManagerDelegate {

    /**
     Purpose: To manage some of the location settings for the app
     
     Parameters:
     manager: this is a CLLocationManager var that is defined at the beginning of the class
     status: checks the status of the location services
     
     */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // if the location services are not authorized return
        guard status == .authorizedWhenInUse else { return }

        // update location to current location
        locationManager.startUpdatingLocation()
    
        // enable current location to be visible on map
        mapView.isMyLocationEnabled = true
        
        // display current location as a the blue location button
        mapView.settings.myLocationButton = true
    }
    
    /**
     Purpose: Overloaded function, sets the camera zoom on map
     
     Parameters:
     manager: CLLocationManager
     locations: a location passed to it
     
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // if this is the first location continue, else exit function
        guard let location = locations.first else { return }
        
        // set camera position and zoom
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        
        // stop updating location of user
        locationManager.stopUpdatingLocation()
    }
}
