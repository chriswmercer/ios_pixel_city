//
//  FlickrApiURLBuilder.swift
//  PIxel City
//
//  Created by Chris Mercer on 19/04/2020.
//  Copyright © 2020 Chris Mercer. All rights reserved.
//

import Foundation

class FlickrApiURLBuilder {
    public private(set) var url = String()
    
    init(apiKey: String, lat: String, lon: String, radius: Float32, radius_units: String = "mi", perPage: Int) {
        url = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(lat)&lon=\(lon)&radius=\(radius)&radius_units=\(radius_units)&per_page=\(perPage)&format=json&nojsoncallback=1"
    }
    
    convenience init(apiKey: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) {
        let lat = String(annotation.coordinate.latitude)
        let lon = String(annotation.coordinate.longitude)
        let radius: Float32 = 1.0
        let radius_units = "mi"
        self.init(apiKey: apiKey, lat: lat, lon: lon, radius: radius, radius_units: radius_units, perPage: number)
    }
}
