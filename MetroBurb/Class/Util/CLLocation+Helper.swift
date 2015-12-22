//
//  CLLocation+Helper.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - Convenience curried CLLocation creation.
extension CLLocation {
    static func create(lat: Double?)(lon: Double?) -> CLLocation? {
        if let lat = lat, lon = lon {
            return CLLocation(latitude: lat, longitude: lon)
        }
        return .None
    }
}
