//
//  Stop.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import CoreLocation

/**
 *  Describes a stop on the given train service. (At the moment either LIRR or MNorth)
 */
struct Stop: TextFileDecodeable {
    
    //MARK: Property
    let id: Int
    let name: String
    let location: CLLocation
    let line: Line
    
    //MARK: Method
    static func create(id: Int)(name: String)(location: CLLocation)(line: Line) -> Stop {
        return Stop(id: id, name: name, location: location, line: line)
    }
    
    static func decode(contents: String, line: Line) -> Stop? {
        return line.parsingStrategy(contents) >>> { s in
            Stop.create <^>
                s[0] >>> fileContentsInt //id
                <*> s[1] >>> fileContentsString //name
                <*> CLLocation.create(s[2] >>> fileContentsDouble)(lon: s[3] >>> fileContentsDouble) //location
                <*> line //line
        }
    }
}

