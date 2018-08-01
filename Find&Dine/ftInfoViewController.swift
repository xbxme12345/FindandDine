//
//  ftInfoViewController.swift
//  Find&Dine
//
//  Created by Yan Wen Huang on 6/17/18.
//  Copyright © 2018 WIT Senior Design. All rights reserved.
//

import Foundation
import GoogleMaps
import UIKit
import MapKit

class ftInfoViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var foodTruckName: UILabel!
    @IBOutlet weak var ftAddress: UILabel!
    @IBOutlet weak var ftMeal: UILabel!
    @IBOutlet weak var ftDay: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    //local variables for receiving data from tableView VC
    var location = String()
    var meal = String()
    var dayOfWeek = String()
    var ftName = String()
    var link = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        foodTruckName.text = ftName
        ftAddress.text = location
        ftMeal.text = meal
        ftDay.text = dayOfWeek
        
        self.mapView.mapType = MKMapType.standard
        self.mapView.showsUserLocation = true
        
        let annotation = MKPointAnnotation()
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(self.location) { (placemarks, error) in
            let placemark = placemarks?.first
            let lat = placemark?.location?.coordinate.latitude
            let lon = placemark?.location?.coordinate.longitude
            
            annotation.title = "\(self.ftName)"
            annotation.subtitle = "\(self.location)"
            annotation.coordinate = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
            
            let latDelta: CLLocationDegrees = 0.05
            let lonDelta: CLLocationDegrees = 0.05
            let span: MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            let location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            self.mapView.setRegion(region, animated: true)
            self.mapView.addAnnotation(annotation)
        }
    }
    
    @IBAction func openFTLink(_ sender: Any) {
        openUrl(urlStr: "\(self.link)")
    }
    
    func openUrl(urlStr: String) {
        if let url = NSURL(string: urlStr) {
            UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func openMap(_ sender: Any) {
        coordinates(forAddress: "\(location)") {
            (location) in
            guard let location = location else {
                return
            }
            self.openMapForPlace(lat: location.latitude, long: location.longitude)
        }
    }
    
    
    func coordinates(forAddress address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) {
            (placemarks, error) in
            guard error == nil else {
                print("Geocoding Error: \(error!)")
                completion(nil)
                return
            }
            completion(placemarks?.first?.location?.coordinate)
        }
    }
    
    public func openMapForPlace(lat:Double = 0, long:Double = 0, placeName:String = "") {
        let latitude: CLLocationDegrees = lat
        let longitude: CLLocationDegrees = long
        
        let regionDistance:CLLocationDistance = 100
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.location
        mapItem.openInMaps(launchOptions: options)
    }
}
