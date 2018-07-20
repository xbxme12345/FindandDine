//
//  resultsViewController.swift
//  Find&Dine
//
//  Created by Gregory Lee on 6/6/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//


import UIKit
import GooglePlacePicker
import GoogleMaps
import CDYelpFusionKit
import Foundation

/**
 Purpose: This is used to capture all of the properties listed in the JSON result
 */
struct geocodingJSON: Codable {
    let html_attributions = [String:String]()
    let results: [infoResult]?
    let status: String
}
// supplementary structs
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

//************************************
// yelp structures
struct yelpJSON: Codable {
    let name: String?
    let image_url: String?
    let rating: Float?
    let coordinates: coordYelp?
    let price: String?
    let location: [addrYelp]?
}
struct coordYelp: Codable {
    let lat: Float?
    let lng: Float?
}
struct addrYelp: Codable {
    let display_address:[daddrYelp]?
}
struct daddrYelp: Codable {
    let l1: String?
}
//************************************
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
    var sv = UIView()
    
    //**
    var searchType = String()
    
    // variables to store the location at which the search will occur
    private var originlatitude = Double()
    private var originlongitude = Double()
    
    //array used to store each restaurant's information
    private var RestList = [RestInfo]()
    
    //store random number calculated from RestList.count
    private var randomNum = Int()
    
    //store random numbers to ensure that no duplicates are used
    private var randomNumList = [Int]()
    
    //store restaurant coordinates
    private var restPosCoord = CLLocationCoordinate2D()
    
    private var results = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // let sv = ViewController.displaySpinner(onView: self.view)
        
        // set location manager delegate and request for location use if not authorized already
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // if the Use Current Location button was pressed, then get the current location of the device and store those for use in the geocodeRequest function
        if locationFlag == 1 {
            originlatitude = (locationManager.location?.coordinate.latitude)!
            originlongitude = (locationManager.location?.coordinate.longitude)!
        }
        else {
            //getCoordinatesOfAddress()?
        }
        
        // convert distance from miles to meters
        travelDistMeters = getDistance(distance: Double(travelDistance)!)
        
        if service == "Google" {
            
            print("in google")
        
            // exec geocodeRequest to get resturants based on criteria from user
            geocodeRequest(lat: originlatitude, lng: originlongitude, radius: travelDistMeters, keyword: keyword, type: searchType, minPrice: minPrice , maxPrice: maxPrice, minRating: minRating)
            
            // wait for API call to return results
            while (results == -1) {
                print("waiting for results...")
            }
            
            // if there are results then wait for coordinates to be set and then place first marker
            // else if no results are returned, display an alert and then acknowledged, return to previous screen
            if results == 0 {
                // wait for lat and lng to be set before proceeding
                while (restPosCoord.longitude == 0.0) {
                    print("waiting for coordinates...")
                }
                
                // ViewController.removeSpinner(spinner: self.view)
                // set marker of first restaurant
                placeMarker(position: restPosCoord)
                
                if RestList.count == 1 {
                    searchAgain.isEnabled = false
                }
            }
            else {
                // init alert
                let alert = UIAlertController(title: "Output Error", message: "0 results returned. Please change search criteria and try again.", preferredStyle: .alert)
                
                // add close option. When tapped, it will dismiss the message and return the user to the previous screen
                alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { action in self.navigationController?.popViewController(animated: true)}))
                
                // display alert to user
                self.present(alert, animated: true)
            }
        }
        else { //Yelp service
            print("in yelp")
            
            // init yelp service with API key
//            let yelpAPIClient = CDYelpAPIClient(apiKey: "kGYByIBQ7we_w1NzMu7vlcxXw0FkM7FcFQpphMExWkzAvSCYTenJkTT4Ps5pOT_AoDwPB2LkHJ8HxExdL0spNO0I-qx5NIZwzPkGLtMBsojzzmPoO7ouYtIlomITW3Yx")
            
            yelpBusinessSearch()
            
        }
    }
    
    func yelpBusinessSearch() {
//        let apiKey = "kGYByIBQ7we_w1NzMu7vlcxXw0FkM7FcFQpphMExWkzAvSCYTenJkTT4Ps5pOT_AoDwPB2LkHJ8HxExdL0spNO0I-qx5NIZwzPkGLtMBsojzzmPoO7ouYtIlomITW3Yx"
        
        //        let urlString = "https://api.yelp.com/v3/businesses/search?term=food&location=boston"
        let urlString = "https://leeg3.github.io/yelp1.json"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        //        let config = URLSessionConfiguration.default
        //        let authString = "Bearer \(apiKey)"
        //        config.httpAdditionalHeaders = ["Authorization" : authString]
        //        let session = URLSession(configuration: config)
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            //            if let httpResponse = response as? HTTPURLResponse {
            //                let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            //                print(dataString!)
            //            }
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            
            do {
                let yelpInfo = try JSONDecoder().decode(yelpJSON.self, from: data)
                
                print(yelpInfo.name!)
                print(yelpInfo.rating!)
                print(yelpInfo.coordinates!)
                print(yelpInfo.price!)
                print(yelpInfo.location!)
            }
            catch {
                
            }
            
        }
        
        task.resume()
        
        
    }
    
    
    func geocodeRequest(lat: Double, lng: Double, radius: Double, keyword: String, type: String, minPrice: Int, maxPrice: Int, minRating: Float) {
        
        // replace spaces in keyword with + for API call
        var word = keyword
        if keyword.contains(" ") {
            word = keyword.replacingOccurrences(of: " ", with: "+")
            print("word: ", word)
        }
        
        // if the rating is 5, set to 4.5 and continue
        var rating = minRating
        if rating == 5.0 {
            rating = 4.5
        }
        
        // URL string that returns the JSON object for parsing
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lng)&radius=\(radius)&type=\(searchType)&minprice=\(minPrice)&maxprice=\(maxPrice)&keyword=\(word)&key=AIzaSyDtbc_paodfWo1KRW0fGQ1dB--g8RyG-Kg"
        
        // set urlString to be URL type?
        guard let url = URL(string: urlString) else { return }
        
        // create task to execute API call and parse the JSON into the RestList array
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
                if restaurantInfo.status == "OK" {
                    self.results = 0
                    for elem in (restaurantInfo.results)! {
                        if elem.rating >= rating {
                            self.RestList.append(RestInfo(lat: elem.geometry?.location!["lat"]! as! Double, lng:elem.geometry?.location!["lng"]! as! Double, pid: elem.place_id!))
                        }
                    }
                }
                else {
                    self.results = 1
                    print("no results")
                    return
                }
            } catch let jsonError { print(jsonError) }
            
            //            if self.RestList.count != 0 {
            // calc random number and add to list
            self.randomNum = Int(arc4random_uniform(UInt32(self.RestList.count)))
            self.randomNumList.append(self.randomNum)
            
            // update display to the first randomly generated resturant
            self.setDisplay(pid: self.RestList[self.randomNum].pid)
            
            // set coordinates of resturant
            self.restPosCoord = CLLocationCoordinate2D(latitude: self.RestList[self.randomNum].lat, longitude: self.RestList[self.randomNum].lng)
            //            }
            //            else if self.RestList.count == 0 {
            //                self.results = 2
            //            }
            
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
            //            print(place.formattedAddress!)
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
    
    /**
     Purpose: to open the dedicated maps app on phone for turn by turn directions to location
     
     Parameter: sender: UIButton: when the Get Directions button is pressed, exec this function
     
     Note: There is no way to change defulat applications in iOS, therefore an alertsheet is used to allow the user to pick which service they want to use.
     
     */
    @IBAction func getDirections(_ sender: UIButton) {
        
        // init alertsheet
        let alert = UIAlertController(title: "Navigation Service", message: "Which Navigation Service would you like to use?", preferredStyle: .actionSheet)
        
        // add Google Maps option. Selecting this option will call openGoogleMaps
        alert.addAction(UIAlertAction(title: "Google Maps", style: .default, handler: { action in self.openGoogleMaps()}))
        // add Apple Maps option. Selecting this option will call openAppleMaps
        alert.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { action in self.openAppleMaps()}))
        // close alert sheet
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil ))
        
        // display alert to user
        self.present(alert, animated: true)
    }
    
    /**
     Purpose: to determine if a stret number is present in the formatted address from Google
     
     Parameter: input: This is the address of a resturant which is checked for a street number
     
     Return: Bool - if a street number is found, then return True, else return false
     */
    private func containsStreetNum(input: String) -> Bool {
        // init bool var
        var streetNumIsPresent = false
        
        // create a character array of the address
        var temp = Array(input)
        
        // search the first 4 entries for a street number, if there is a number then set streetNumIsPresent to True
        var num = 0
        while (num <= 3) {
            if temp[num] >= "0" && temp[num] <= "9" {
                streetNumIsPresent = true
            }
            num+=1
        }
        
        // return streetNumIsPresent
        return streetNumIsPresent
    }
    
    /**
     Purpose: to open Google Maps app on phone
     
     */
    private func openGoogleMaps() {
        // init beginning of string used for URL call
        var destAddr = "comgooglemaps://?daddr="
        
        //determine if a street number is in the resturant address
        let streetNumIsPresent = containsStreetNum(input: placeAddr.text!)
        
        // If there is a street number, then add the address to the URL call string and replace the spaces with +
        if streetNumIsPresent {
            destAddr.append(placeAddr.text!)
            destAddr = destAddr.replacingOccurrences(of: " ", with: "+")
        }
        
        // set destAdrr as a URL fand then check if it can be opened.
        // If it can be opened then open the application and send it the data via URL
        // if not then open in safari with the web URL using lat and lng
        let mapURL = URL(string: destAddr)
        if UIApplication.shared.canOpenURL(mapURL!)
        {
            UIApplication.shared.open(mapURL!, options: [:], completionHandler: nil)
        }
        else {
            // open safari
            if let webURL = URL(string: "https://google.com/maps?daddr=\(restPosCoord.latitude),\(restPosCoord.longitude)") {
                UIApplication.shared.open(webURL, options: [:])
            }
            else {
                print("Error with opening google maps in safari")
            }
        }
    }
    
    /**
     Purpose: to open Apple Maps app on phone
     
     */
    private func openAppleMaps() {
        // init first part of URL
        var destAddr = "maps://?daddr="
        
        //determine if there is a street number present
        let streetNumIsPresent = containsStreetNum(input: placeAddr.text!)
        
        // if a street number is present, then append resturant address to string and remove commas and replace spaces with +
        // if not then use lat and lng of resturant
        if streetNumIsPresent {
            destAddr.append(placeAddr.text!)
            destAddr = destAddr.replacingOccurrences(of: ",", with: "")
            destAddr = destAddr.replacingOccurrences(of: " ", with: "+")
        }
        else {
            destAddr.append("\(restPosCoord.latitude),\(restPosCoord.longitude)")
        }
        
        // init string as URL
        // if the url can be opened in apple maps then open apple maps and display directions to resturant
        // if not then open google maps with safari to display directions
        let mapURL = URL(string: destAddr)
        if UIApplication.shared.canOpenURL(mapURL!)
        {
            UIApplication.shared.open(mapURL!, options: [:], completionHandler: nil)
        }
        else {
            // open safari
            if let webURL = URL(string: "https://google.com/maps?daddr=\(restPosCoord.latitude),\(restPosCoord.longitude)") {
                UIApplication.shared.open(webURL, options: [:])
            }
            else {
                print("Error with opening google maps in safari")
            }
        }
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
        
        // init var to hold inputted distance and zoom level
        let dist = Double(travelDistance)!
        var zoom = Float()
        
        if dist > 0 && dist <= 0.5 {
            zoom = 14
        }
        else if dist > 0.6 && dist <= 1.5 {
            zoom = 13
        }
        else if dist > 1.6 && dist <= 2.5 {
            zoom = 12
        }
        else if dist > 2.5 && dist <= 4 {
            zoom = 11
        }
        else if dist > 4 {
            zoom = 10
        }
        
        // set camera position and zoom
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: zoom, bearing: 0, viewingAngle: 0)
        // stop updating location of user
        locationManager.stopUpdatingLocation()
    }
}

extension resultsViewController {
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
