////
////  yelpAPIRequest.swift
////  Find&Dine
////
////  Created by Gregory Lee on 7/19/18.
////  Copyright © 2018 WIT Senior Design. All rights reserved.
////
//
//import Foundation
//
////struct yelpJSON: Codable {
////    let name: String?
////    let image_url: String?
////    let rating: Float?
////    let coordinates: coordYelp?
////    let price: String?
////    let location: [addrYelp]?
////}
////struct coordYelp: Codable {
////    let lat: Float?
////    let lng: Float?
////}
////struct addrYelp: Codable {
////    let display_address:[daddrYelp]?
////}
////struct daddrYelp: Codable {
////    let l1: String?
////}
//
////
//struct yelpRestInfo {
//    let name: String
//    let addr: String
//    let rating: String
//    let price: String
//}
//
//class yelpAPIRequest {
//
//    var restInfo = [yelpRestInfo]()
//
//    func yelpBusinessSearch() {
//        let apiKey = "kGYByIBQ7we_w1NzMu7vlcxXw0FkM7FcFQpphMExWkzAvSCYTenJkTT4Ps5pOT_AoDwPB2LkHJ8HxExdL0spNO0I-qx5NIZwzPkGLtMBsojzzmPoO7ouYtIlomITW3Yx"
//
//        //        let urlString = "https://api.yelp.com/v3/businesses/search?term=food&location=boston"
//        let urlString = "https://leeg3.github.io/yelp1.json"
//
//        guard let url = URL(string: urlString) else { return }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        //        let config = URLSessionConfiguration.default
//        //        let authString = "Bearer \(apiKey)"
//        //        config.httpAdditionalHeaders = ["Authorization" : authString]
//        //        let session = URLSession(configuration: config)
//
//        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
////            if let httpResponse = response as? HTTPURLResponse {
////                let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
////                print(dataString!)
////            }
//            if error != nil {
//                print(error!.localizedDescription)
//            }
//
//            guard let data = data else { return }
//
//            do {
//                let yelpInfo = try JSONDecoder().decode(yelpJSON.self, from: data)
//
//                print(yelpInfo.name!)
//                print(yelpInfo.rating!)
//                print(yelpInfo.coordinates!)
//                print(yelpInfo.price!)
//                print(yelpInfo.location!)
//            }
//            catch {
//
//            }
//
//        }
//
//        task.resume()
//    }
//
////    func geocode() {
////        // set urlString to be URL type?
////
////        let urlString = "https://leeg3.github.io/yelp1.json"
////
////        guard let url = URL(string: urlString) else { return }
////
////        // create task to execute API call and parse the JSON into the RestList array
//
////        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
//
////            // if the error is not nil, then print out error message
////            if error != nil {
////                print(error!.localizedDescription)
////            }
////
////            // make sure data is data
////            guard let data = data else { return }
////
////            // Implement JSON decoding and parsing
////            do {
////                // Decode retrived data with JSONDecoder into format specified by geocodingJSON
////                let restaurantInfo = try JSONDecoder().decode(geocodingJSON.self, from: data)
////
////                // append each restaurant info to the array if it is greater than the minRating
////                if restaurantInfo.status == "OK" {
////                    self.results = 0
////                    for elem in (restaurantInfo.results)! {
////                        if elem.rating >= rating {
////                            self.RestList.append(RestInfo(lat: elem.geometry?.location!["lat"]! as! Double, lng:elem.geometry?.location!["lng"]! as! Double, pid: elem.place_id!))
////                        }
////                    }
////                }
////                else {
////                    self.results = 1
////                    print("no results")
////                    return
////                }
////            } catch let jsonError { print(jsonError) }
////
////            //            if self.RestList.count != 0 {
////            // calc random number and add to list
////            self.randomNum = Int(arc4random_uniform(UInt32(self.RestList.count)))
////            self.randomNumList.append(self.randomNum)
////
////            // update display to the first randomly generated resturant
////            self.setDisplay(pid: self.RestList[self.randomNum].pid)
////
////            // set coordinates of resturant
////            self.restPosCoord = CLLocationCoordinate2D(latitude: self.RestList[self.randomNum].lat, longitude: self.RestList[self.randomNum].lng)
////            //            }
////            //            else if self.RestList.count == 0 {
////            //                self.results = 2
////            //            }
////
////        }
////
////        // start task specified above
////        task.resume()
////    }
//}
///**
// //
// //  ViewController.swift
// //  FindDineTest
// //
// //  Created by Gregory Lee on 6/4/18.
// //  Copyright © 2018 WIT Senior Design. All rights reserved.
// //
//
// /**
// YELP NOTES for future
// omitting term = searches food and restaurant TEST
//
// need to handle 25 mi limit on yelp searches, returns area to big value
//
//
// */
//
// import UIKit
// import GooglePlacePicker
// import GoogleMaps
//
// struct yelpJSON: Codable {
// let businesses: [rest]?
// }
// struct rest: Codable {
// let name: String?
// let image_url: String?
// let rating: Float?
// let coordinates: coordYelp?
// let price: String?
// let location: daddr?
// }
// struct coordYelp: Codable {
// let latitude: Double?
// let longitude: Double?
// }
// struct daddr: Codable {
// let display_address: [String]?
// }
//
//
// class resultsViewController: UIViewController {
//
// @IBOutlet weak var restName: UILabel!
// @IBOutlet weak var restAddr: UILabel!
// @IBOutlet weak var restRating: UILabel!
// @IBOutlet weak var restPrice: UILabel!
//
// //    private var RestList = [RestInfo]()
// //    private var randomNum = Int()
//
// override func viewDidLoad() {
// super.viewDidLoad()
// // Do any additional setup after loading the view, typically from a nib.
//
// print("before func call")
// yelpJSONRequest()
//
// }
//
// override func didReceiveMemoryWarning() {
// super.didReceiveMemoryWarning()
// // Dispose of any resources that can be recreated.
// }
//
// func yelpJSONRequest() {
// let apiKey = "kGYByIBQ7we_w1NzMu7vlcxXw0FkM7FcFQpphMExWkzAvSCYTenJkTT4Ps5pOT_AoDwPB2LkHJ8HxExdL0spNO0I-qx5NIZwzPkGLtMBsojzzmPoO7ouYtIlomITW3Yx"
//
// let urlString = "https://api.yelp.com/v3/businesses/search?term=food&location=boston"
// //let urlString = "https://leeg3.github.io/yelp2.json"
//
// guard let url = URL(string: urlString) else { return }
//
// var request = URLRequest(url: url)
// request.httpMethod = "GET"
// let config = URLSessionConfiguration.default
// let authString = "Bearer \(apiKey)"
// config.httpAdditionalHeaders = ["Authorization" : authString]
// let session = URLSession(configuration: config)
//
// let task = session.dataTask(with: url) { (data, response, error) in
// if error != nil {
// print(error!.localizedDescription)
// }
//
// guard let data = data else { return }
//
// print("before JSON decode")
//
// do {
// let yelpInfo = try JSONDecoder().decode(yelpJSON.self, from: data)
// //                let yelpInfo = try JSONDecoder().decode(yelp3.self, from: data)
//
// print(yelpInfo.businesses![0].name!)
// print(yelpInfo.businesses![0].location!.display_address![0])
// print(yelpInfo.businesses![0].location!.display_address![1])
// print(yelpInfo.businesses![0].rating!)
// print(yelpInfo.businesses![0].price!)
// print(yelpInfo.businesses![0].coordinates!.latitude!)
// print(yelpInfo.businesses![0].coordinates!.longitude!)
// }
// catch let jsonError { print(jsonError) }
//
// }
//
// task.resume()
// }
//
// //    func geocodeRequest() {
// //        //new key: AIzaSyDtbc_paodfWo1KRW0fGQ1dB--g8RyG-Kg
// //        /* Prob gonna have to have 2 different urlstrings for keyword/no keyword */
// //        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=42.3360247,-71.0949302&radius=400&type=restaurant&keyword=pizza&key=AIzaSyDtbc_paodfWo1KRW0fGQ1dB--g8RyG-Kg"
// //
// //        guard let url = URL(string: urlString) else { return }
// //
// //        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
// //            if error != nil {
// //                print(error!.localizedDescription)
// //            }
// //
// //            guard let data = data else { return }
// //
// //            //Implement JSON decoding and parsing
// //            do {
// //                //Decode retrived data with JSONDecoder and use geocoding for type
// //                let restaurantInfo = try JSONDecoder().decode(geocoding.self, from: data)
// //
// //                for elem in (restaurantInfo.results)! {
// //                    self.RestList.append(RestInfo(lat: elem.geometry?.location!["lat"]! as! Double, lng:elem.geometry?.location!["lng"]! as! Double, pid: elem.place_id!))
// //                }
// //            } catch let jsonError { print(jsonError) }
// //
// //            self.randomNum = Int(arc4random_uniform(UInt32(self.RestList.count)))
// //            print(self.randomNum)
// //            print("num of elems in restList: ", self.RestList.count)
// //
// //            self.setDisplay(pid: self.RestList[0].pid, lat: self.RestList[0].lat, lng: self.RestList[0].lng)
// //
// //        }
// //
// //        task.resume()
// //
// //    }
//
// func setDisplay(pid: String, lat: Double, lng: Double) {
// let placeID = pid
// let placesClient = GMSPlacesClient()
//
// placesClient.lookUpPlaceID(placeID, callback: { (place, error) -> Void in
// if let error = error {
// print("lookup place id query error: \(error.localizedDescription)")
// return
// }
//
// guard let place = place else {
// print("No place details for \(placeID)")
// return
// }
//
// self.restName.text = place.name
// self.restAddr.text = place.formattedAddress
// self.restRating.text = String(place.rating)
// self.restPrice.text = self.text(for: place.priceLevel)
// //self.loadFirstPhotoForPlace(placeID: place.placeID)
// })
// //set marker
// /** Markers are currents being set with the wrong name **/
// //        let position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
// //        let marker = GMSMarker(position: position)
// //        marker.title = restName.text
// //        marker.map = mapView
// }
//
// // Return the appropriate text string for the specified |GMSPlacesPriceLevel|.
// func text(for priceLevel: GMSPlacesPriceLevel) -> String {
// switch priceLevel {
// case .free: return NSLocalizedString("Free", comment: "Free")
// case .cheap: return NSLocalizedString("$", comment: "$")
// case .medium: return NSLocalizedString("$$", comment: "$$")
// case .high: return NSLocalizedString("$$$", comment: "$$$")
// case .expensive: return NSLocalizedString("$$$$", comment: "$$$$")
// case .unknown: return NSLocalizedString("Unknown", comment: "Unknown")
// }
// }
//
// }
//
//
// */
