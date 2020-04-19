//
//  ViewController.swift
//  PIxel City
//
//  Created by Chris Mercer on 19/04/2020.
//  Copyright © 2020 Chris Mercer. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var authorised = false
    var locationManager = CLLocationManager()
    let regionRadius: Double = 1000 //1000m
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addGesture()
    }

    @IBAction func centerMapButtonPressed(_ sender: Any) {
        centerMapOnUserLocation()
    }
    
    func addGesture() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        mapView.addGestureRecognizer(doubleTapGesture)
    }
}

extension MapViewController: MKMapViewDelegate {

    func centerMapOnUserLocation() {
        if !authorised {
            configureLocationServices()
        }
        guard let coords = locationManager.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coords, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(region, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePins()
        let touchPoint = sender.location(in: mapView)
        let touchCoord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(identifier: "droppablePin", coords: touchCoord)
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: touchCoord, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(region, animated: true)
    }
    
    func removePins() {
        for pin in mapView.annotations {
            mapView.removeAnnotation(pin)
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func configureLocationServices() {
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        
        authorised = true
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}
