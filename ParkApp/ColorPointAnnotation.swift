//
//  ColorPointAnnotation.swift
//  ParkApp
//
//  Created by Michael Bharrat on 8/2/16.
//  Copyright © 2016 Michael Bharrat. All rights reserved.
//

import UIKit
import MapKit
//make image a pin
class ColorPointAnnotation: MKPointAnnotation {
    var imageName: String!

}

//if you just wanted to change pin color
/*
class ColorPointAnnotation: MKPointAnnotation {
    var pinColor: UIColor

    init(pinColor: UIColor) {
    self.pinColor = pinColor
    super.init()
    }
}
*/
