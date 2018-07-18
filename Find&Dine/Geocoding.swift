////
////  Geocoding.swift
////  Find&Dine
////
////  Created by Gregory Lee on 6/21/18.
////  Copyright © 2018 WIT Senior Design. All rights reserved.
////
//
//import Foundation
//import GoogleMaps
//import GooglePlaces
//
////struct geocoding: Codable {
////    let html_attributions = [String:String]()
////    let results: [infoResult]?
////}
//
//////supplementary structs
////struct infoResult: Codable {
////    let geometry: loc?
////    let icon: String?
////    let id: String?
////    let name: String?
////    let opening_hours: hours?
////    let photos: [image]?
////    let place_id: String?
////    let price_level: Int?
////    let rating: Double?
////    let reference: String?
////    let scope: String?
////    let types: [String]?
////    let vicinity: String?
////}
////struct lines: Codable {
////    let line: [String]?
////}
////struct log_info: Codable {
////    let experiment_id: [String]?
////    let query_geographic_location: String?
////}
////struct loc: Codable {
////    let location: [String: Double]?
////}
////struct location: Codable {
////    let lat: Double
////    let lng: Double
////}
////struct hours: Codable {
////    let open_now: Bool?
////    let weekday_text: [String]?
////}
////struct image: Codable {
////    let height: Int?
////    let html_attributions: [String]?
////    let photo_reference: String?
////    let width: Int?
////}
////
////struct RestInfo {
////    let lat: Double
////    let lng: Double
////    let pid: String
////}
//
//class Geocoding: Operation {
//
//    var RestInfoList = [RestInfo]()
//
//    override func main(){
//        print("in main")
//        geocodeRequest()
//    }
//
//    //get Geocode requests
//    // func geocodeRequest(lat: String, lng: String, radius: String, keyword: String) {
//    func geocodeRequest() {
//
////    var RestArr = [RestInfo]()
////    let RestFail = RestInfo(lat: 0.0, lng: 0.0, pid: "fail")
//
//    //new key: AIzaSyDtbc_paodfWo1KRW0fGQ1dB--g8RyG-Kg
//    /* Prob gonna have to have 2 different urlstrings for keyword/no keyword */
//    let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=42.3360247,-71.0949302&radius=400&type=restaurant&keyword=pizza&key=AIzaSyDtbc_paodfWo1KRW0fGQ1dB--g8RyG-Kg"
//
//    guard let url = URL(string: urlString) else { return }
//
//    URLSession.shared.dataTask(with: url) { (data, response, error) in
//    // if error != nil { print(error!.localizedDescription) }
//    guard let data = data else { return }
//
//    //Implement JSON decoding and parsing
//    do {
//        //Decode retrived data with JSONDecoder and use geocoding for type
//        let restaurantInfo = try JSONDecoder().decode(geocoding.self, from: data)
//
//        for elem in (restaurantInfo.results)! {
//            self.RestInfoList.append(RestInfo(lat: elem.geometry?.location!["lat"]! as! Double, lng: elem.geometry?.location!["lng"]! as! Double, pid: elem.place_id!))
//        }
//
//    } catch let jsonError { print(jsonError) }
//        // print("count in geocoding: ", RestArr.count)
//    }.resume()
//
//    // return RestArr
//    }
//
//}
