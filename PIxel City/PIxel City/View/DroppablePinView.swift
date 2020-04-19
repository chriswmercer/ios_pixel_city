//
//  DroppablePinView.swift
//  PIxel City
//
//  Created by Chris Mercer on 19/04/2020.
//  Copyright © 2020 Chris Mercer. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    
    dynamic var coordinate: CLLocationCoordinate2D //must be dynamic
    var identifier: String

    init(identifier: String, coords: CLLocationCoordinate2D) {
        self.identifier = identifier
        self.coordinate = coords
        super.init()
    }
}
