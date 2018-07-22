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
 Purpose: This is used to capture all of the properties listed in the Google Places API JSON result
 */
// main struct
struct geocodingJSON: Codable {
    let html_attributions = [String:String]()
    let results: [infoResult]?
    let status: String
}
// supplementary structs
struct infoResult: Codable {
    let geometry: loc?
    let place_id: String?
    let price_level: Int?
    let rating: Float
}
struct loc: Codable {
    let location: [String: Double]?
}
struct location: Codable {
    let lat: Double
    let lng: Double
}

/**
 Purpose: defines the RestInfo type. This is the info stored for each resturant
 */
struct googleRestInfo {
    let lat: Double
    let lng: Double
    let pid: String
}

/**
 Purpose: This is used to capture all of the properties listed in the Yelp Fusion API JSON result
 */
// main struct
struct yelpJSON: Codable {
    let businesses: [rest]?
    let total: Int?
}
// supplementary structs
struct rest: Codable {
    let name: String?
    let image_url: String?
    let rating: Float?
    let coordinates: coordYelp?
    let price: String?
    let location: daddr?
}
struct coordYelp: Codable {
    let latitude: Double?
    let longitude: Double?
}
struct daddr: Codable {
    let display_address: [String?]
}

/**
 Purpose: defines the yelpInfo type. This is the format in which the info from the JSON result will be stored
 */
struct yelpRestInfo {
    let name: String
    let addr: String
    let rating: Float
    let price: String
    let lat: Double
    let lng: Double
}

class resultsViewController: UIViewController {
    
    // init location manager
    private let locationManager = CLLocationManager()
    
    // init map display
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
    var travelDistance = String()
    var keyword = String()
    var service = String()
    var minRating = Float()
    var minPrice = Int()
    var maxPrice = Int()
    var searchType = String()
    
    // variable to store distance converted into meters
    private var travelDistMeters = Double()
    
    // variables to store the location at which the search will occur
    private var originlatitude = Double()
    private var originlongitude = Double()
    
    // array used to store each restaurant's information from their respective services
    private var googleRestList = [googleRestInfo]()
    private var yelpRestList = [yelpRestInfo]()
    
    // store random number calculated from RestList.count
    private var randomNum = Int()
    
    // store random numbers to ensure that no duplicates are used
    private var randomNumList = [Int]()
    
    // store restaurant coordinates
    private var restPosCoord = CLLocationCoordinate2D()
    
    // used to determine if the JSON result contained data
    private var results = -1
    
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
        
        // convert distance from miles to meters
        travelDistMeters = getDistance(distance: Double(travelDistance)!)
        
        if service == "Google" {
            print("using Google")
            
            // exec API request to get resturants based on criteria from user
            googleGetRestaurants(lat: originlatitude, lng: originlongitude, radius: travelDistMeters, keyword: keyword, type: searchType, minPrice: minPrice , maxPrice: maxPrice, minRating: minRating)
            
            // wait for API call to return results
            while (results == -1) { }
            
            // if there are results then step in
            // else if no results are returned, display an alert and then when acknowledged, return to previous screen
            if results == 0 {
                // wait for lat and lng to be set before proceeding
                while (restPosCoord.longitude == 0.0) { }
                
                // set marker of first restaurant
                placeMarker(position: restPosCoord)
                
                // disable searchAgain button if there are <= 1 results from the search
                if googleRestList.count <= 1 {
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
            print("using Yelp")
            
            // retrieve list of restaurants from Yelp
            yelpGetRestaurants(lat: originlatitude, lng: originlongitude, radius: travelDistMeters, keyword: keyword, type: searchType, minPrice: minPrice , maxPrice: maxPrice, minRating: minRating)
            
            // wait for API call to return results
            while (results == -1) { }
            
            // if there are results then step in
            // else if no results are returned, display an alert and then acknowledged, return to previous screen
            if results == 0 {
                // wait for lat and lng to be set before proceeding
                while (restPosCoord.longitude == 0.0) { }
                
                // set marker of first restaurant
                placeMarker(position: restPosCoord)
                
                // disable button if there are <= 1 results in the array of restaurants
                if yelpRestList.count <= 1 {
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
    }
    
    /**
     Purpose: To retrieve information from Yelp Fusion API and append the qualifying restaurants into yelpRestList
     
     Parameters: lat: Double - latitude of device;
     lng: Double - longitude of device;
     radius: Double - search radius set by user;
     keyword: String - a keyword that is set by the user to narrow down the search results
     type: String - indicates if the user is looking for a restaurant or just food
     minPrice: Int - minimum price set by the user
     maxPrice: Int - maximum price set by user
     minRating: Float - minimum restaurant rating set by user
     */
    func yelpGetRestaurants(lat: Double, lng: Double, radius: Double, keyword: String, type: String, minPrice: Int, maxPrice: Int, minRating: Float) {
        // define API key
        let apiKey = "kGYByIBQ7we_w1NzMu7vlcxXw0FkM7FcFQpphMExWkzAvSCYTenJkTT4Ps5pOT_AoDwPB2LkHJ8HxExdL0spNO0I-qx5NIZwzPkGLtMBsojzzmPoO7ouYtIlomITW3Yx"
        
        // price handler
        var num = minPrice
        var priceString = String(minPrice)
        if minPrice >= maxPrice {
            priceString = String(minPrice)
        }
        else {
            num+=1
            while (num <= maxPrice) {
                priceString += "," + String(num)
                num+=1
            }
        }
        
        // keyword to lowercase, yelp API doesn't work with uppercase letters in their query
        let keyword_lcase = keyword.lowercased()
        
        // build URL for API request
        let urlString = "https://api.yelp.com/v3/businesses/search?term=\(searchType)&latitude=\(lat)&longitude=\(lng)&price=\(priceString)&radius=\(Int(radius))&categories=\(keyword_lcase)"
        
        guard let url = URL(string: urlString) else { return }
        
        // init URLRequest to add a GET method that supplies yelp with the API key
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let config = URLSessionConfiguration.default
        let authString = "Bearer \(apiKey)"
        config.httpAdditionalHeaders = ["Authorization" : authString]
        let session = URLSession(configuration: config)
        
        // define task for parsing JSON result from API call
        let task = session.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            // output JSON response
            if let httpResponse = response as? HTTPURLResponse {
                let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print(dataString!)
            }
            
            guard let data = data else { return }
            
            // decode JSON and parse info into yelpRestList
            do {
                let yelpRestResult = try JSONDecoder().decode(yelpJSON.self, from: data)
                
                // if results are returned by the API, then proceed with parse
                if yelpRestResult.total != 0 {
                    // iterate through yelpRestInfo
                    for elem in yelpRestResult.businesses! {
                        var temp: String
                        // if there is no address stored for a restaurant, then store the following string in its place
                        if elem.location!.display_address.count == 0 {
                            temp = "No address listed for restaurant"
                        }
                        // if there is only 1 element in the array, that element will be stored for the address
                        else if elem.location!.display_address.count == 1 {
                            temp = elem.location!.display_address[0]!
                        }
                        // else: combine both entries of the address into 1 and store in yelpRestList
                        else {
                            temp = elem.location!.display_address[0]! + " " + elem.location!.display_address[1]!
                        }
                        
                        // check rating
                        if elem.rating! >= minRating {
                            self.results = 0
                            self.yelpRestList.append(yelpRestInfo(name: elem.name!, addr: temp, rating: elem.rating!, price: elem.price!, lat: elem.coordinates!.latitude!, lng: elem.coordinates!.longitude!))
                        }
                    }
                }
                else {
                    self.results = 1
                    print("no results bc no results")
                    return
                }
            }
            catch let jsonError { print(jsonError) }
            
            if self.yelpRestList.count != 0 {
                // calculate a random number and add to list of random numbers. this list is used to ensure that there are no duplicate random numbers used
                self.randomNum = Int(arc4random_uniform(UInt32(self.yelpRestList.count)))
                self.randomNumList.append(self.randomNum)
                
                // update display to the first randomly generated resturant
                self.setDisplay(name: self.yelpRestList[self.randomNum].name, addr: self.yelpRestList[self.randomNum].addr, rating: self.yelpRestList[self.randomNum].rating, price: self.yelpRestList[self.randomNum].price)
                
                // set coordinates of resturant
                self.restPosCoord = CLLocationCoordinate2D(latitude: self.yelpRestList[self.randomNum].lat, longitude: self.yelpRestList[self.randomNum].lng)
            }
            else {
                self.results = 2
            }
        }
        // start task defined above
        task.resume()
    }
    
    // update display to show results found from yelp search
    func setDisplay(name: String, addr: String, rating: Float, price: String) {
        // update UI in main queue because UI changes must be done in the main queue
        DispatchQueue.main.async {
            self.restaurantName.text = name
            self.placeAddr.text = addr
            self.placeRating.text = String(rating)
            self.placePrice.text = price
            // need to figure out how to handle images from yelp
        }
    }
    
    /**
     Purpose: To retrieve information from Google Places API and append the qualifying restaurants into RestList
     
     Parameters: lat: Double - latitude of device;
     lng: Double - longitude of device;
     radius: Double - search radius set by user;
     keyword: String - a keyword that is set by the user to narrow down the search results
     type: String - indicates if the user is looking for a restaurant or just food
     minPrice: Int - minimum price set by the user
     maxPrice: Int - maximum price set by user
     minRating: Float - minimum restaurant rating set by user
     */
    func googleGetRestaurants(lat: Double, lng: Double, radius: Double, keyword: String, type: String, minPrice: Int, maxPrice: Int, minRating: Float) {
        
        // replace spaces in keyword with + for API call
        var word = keyword
        if keyword.contains(" ") {
            word = keyword.replacingOccurrences(of: " ", with: "+")
            print("word: ", word)
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
                
                // check JSON result to make sure that there were no errors
                if restaurantInfo.status == "OK" {
                    for elem in (restaurantInfo.results)! {
                        // append each restaurant info to the array if it is greater than the minRating
                        if elem.rating >= minRating {
                            self.results = 0
                            self.googleRestList.append(googleRestInfo(lat: elem.geometry?.location!["lat"]! as! Double, lng:elem.geometry?.location!["lng"]! as! Double, pid: elem.place_id!))
                        }
                    }
                }
                else {
                    self.results = 1
                    print("no results bc no results")
                    return
                }
            } catch let jsonError { print(jsonError) }
            // if empty due to rating don't do this
            if self.googleRestList.count != 0 {
                // calculate a random number and add to list of random numbers. this list is used to ensure that there are no duplicate random numbers used
                self.randomNum = Int(arc4random_uniform(UInt32(self.googleRestList.count)))
                self.randomNumList.append(self.randomNum)
                
                // update display to the first randomly generated resturant
                self.setDisplay(pid: self.googleRestList[self.randomNum].pid)
                
                // set coordinates of resturant
                self.restPosCoord = CLLocationCoordinate2D(latitude: self.googleRestList[self.randomNum].lat, longitude: self.googleRestList[self.randomNum].lng)
            }
            else {
                self.results = 2
            }
        }
        // start task specified above
        task.resume()
    }
    
    /**
     Purpose: updates the display in resultsViewController to show resturant name, address, rating, price and image of randomly generated resturant for a restaurant from Google
     */
    func setDisplay(pid: String) {
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
        
        var size = Int()
        
        // set size based on which service is used
        if service == "Google" {
            size = googleRestList.count
        }
        else {
            size = yelpRestList.count
        }
        
        // if statement to ensure that we generate the correct amount of random numbers
        if (randomNumList.count < size) {
            // generate a random number
            var temp = Int()
            
            // if the random number was already used (in randomNumList) then calculate again
            repeat {
                temp = Int(arc4random_uniform(UInt32(size)))
            } while (randomNumList.contains(temp))
            
            // set the newly calculated random number to randomNum to be used within this class and add it to the randomNumList
            randomNum = temp
            randomNumList.append(randomNum)
            
            // update the display
            if service == "Google" {
                setDisplay(pid: googleRestList[randomNum].pid)
                
                restPosCoord = CLLocationCoordinate2D(latitude: googleRestList[randomNum].lat, longitude: googleRestList[randomNum].lng)
            }
            else {
                setDisplay(name: yelpRestList[randomNum].name, addr: yelpRestList[randomNum].addr, rating: yelpRestList[randomNum].rating, price: yelpRestList[randomNum].price)
                
                restPosCoord = CLLocationCoordinate2D(latitude: yelpRestList[randomNum].lat, longitude: yelpRestList[randomNum].lng)
            }

            // place new marker
            placeMarker(position: restPosCoord)
            
            // if we have reached the end of the list of restaurants, disable the button
            if (randomNumList.count == size) {
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
        var urlString = "comgooglemaps://?daddr="
        
        //determine if a street number is in the resturant address
        let streetNumIsPresent = containsStreetNum(input: placeAddr.text!)
        
        // If there is a street number, then add the address to the URL call string and replace the spaces with +
        if streetNumIsPresent {
            urlString.append(placeAddr.text!)
            urlString = urlString.replacingOccurrences(of: " ", with: "+")
        }
        
        // set urlString as a URL fand then check if it can be opened.
        // If it can be opened then open the application and send it the data via URL
        // if not then open in safari with the web URL using lat and lng
        let mapURL = URL(string: urlString)
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
        var urlString = "maps://?daddr="
        
        //determine if there is a street number present
        let streetNumIsPresent = containsStreetNum(input: placeAddr.text!)
        
        // if a street number is present, then append resturant address to string and remove commas and replace spaces with +
        // if not then use lat and lng of resturant
        if streetNumIsPresent {
            urlString.append(placeAddr.text!)
            urlString = urlString.replacingOccurrences(of: ",", with: "")
            urlString = urlString.replacingOccurrences(of: " ", with: "+")
        }
        else {
            urlString.append("\(restPosCoord.latitude),\(restPosCoord.longitude)")
        }
        
        // init string as URL
        // if the url can be opened in apple maps then open apple maps and display directions to resturant
        // if not then open google maps with safari to display directions
        let mapURL = URL(string: urlString)
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
     
     Parameters: manager: this is a CLLocationManager var that is defined at the beginning of the class
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
     
     Parameters: manager: CLLocationManager; locations: a location passed to it
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
