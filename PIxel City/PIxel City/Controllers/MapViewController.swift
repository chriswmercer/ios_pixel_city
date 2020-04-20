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
import Alamofire
import AlamofireImage

class MapViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullupHeight: NSLayoutConstraint!
    
    var authorised = false
    var locationManager = CLLocationManager()
    let regionRadius: Double = 1000 //1000m
    
    var spinner: UIActivityIndicatorView?
    var progressLabel: UILabel?
    let screensize = UIScreen.main.bounds
    
    var collectionView: UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addGesture()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoViewCell.self, forCellWithReuseIdentifier: REUSE_ID_PHOTOCELL)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
        pullUpView.addSubview(collectionView!)
    }
    
    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      return true
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
    
    func addSwipe() {
        let swipeRecogniser = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipeRecogniser.direction = .down
        pullUpView.addGestureRecognizer(swipeRecogniser)
    }
    
    func animateViewUp() {
        pullupHeight.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown() {
        cancelAllSessions()
        pullupHeight.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screensize.width / 2) - (spinner!.frame.width / 2), y: pullupHeight.constant / 2)
        spinner?.style = .large
        spinner?.color = .darkGray
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel() {
        progressLabel = UILabel()
        let progressLabelWidth = Int(screensize.width - 40)
        progressLabel?.frame = CGRect(x: Int((screensize.width / 2)) - (progressLabelWidth / 2), y: (Int(pullupHeight.constant) / 2) + 25, width: progressLabelWidth, height: 40)
        progressLabel?.font = UIFont(name: FONT_AVENIR_NEXT, size: 14)
        progressLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLabel?.textAlignment = .center
        progressLabel?.text = "Please wait..."
        collectionView?.addSubview(progressLabel!)
    }
    
    func removeProgressLabel() {
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
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
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: REUSE_ID_PIN)
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePins()
        animateViewUp()
        addSwipe()
        removeSpinner()
        removeProgressLabel()
        addSpinner()
        addProgressLabel()
                
        let touchPoint = sender.location(in: mapView)
        let touchCoord = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(identifier: REUSE_ID_PIN, coords: touchCoord)
        
        cancelAllSessions()
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImages { (complete) in
                    if complete {
                        self.removeSpinner()
                        self.removeProgressLabel()
                    }
                }
            }
        }
        
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: touchCoord, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(region, animated: true)
    }
    
    func removePins() {
        for pin in mapView.annotations {
            mapView.removeAnnotation(pin)
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, completion: @escaping (_ status: Bool) -> ()) {
        imageUrlArray = []
        
        Alamofire.request(FlickrApiURLBuilder(apiKey: FLICKR_KEY, withAnnotation: annotation, andNumberOfPhotos: 40).url).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            print(json)
            guard let photosDict = json["photos"] as? Dictionary<String, AnyObject> else { return }
            guard let photos = photosDict["photo"] as? [Dictionary<String, AnyObject>] else { return }
            for photo in photos {
                let farmValue = photo["farm"]!
                let serverValue = photo["server"]!
                let idValue = photo["id"]!
                let secretValue = photo["secret"]!
                let postUrl = "https://farm\(farmValue).staticflickr.com/\(serverValue)/\(idValue)_\(secretValue).jpg"
                self.imageUrlArray.append(postUrl)
            }
            completion(true)
        }
    }
    
    func retrieveImages(completion: @escaping (_ status: Bool) -> ()) {
        imageArray = []
        for url in imageUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLabel?.text = "\(self.imageArray.count)/40 images downloaded..."
                if self.imageArray.count == self.imageUrlArray.count {
                    completion(true)
                }
            }
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() }) //kinda link
            downloadData.forEach({ $0.cancel() })
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

extension MapViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //coming from number of items in array
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: REUSE_ID_PHOTOCELL, for: indexPath) as? PhotoViewCell
        return cell!
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}
