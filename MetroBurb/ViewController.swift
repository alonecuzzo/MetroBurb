//
//  ViewController.swift
//  MetroBurb
//
//  Created by Jabari Bell on 9/28/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import UIKit
import Darwin
import CoreLocation


/**
*  Describes a stop on the given train service. (At the moment either LIRR or MNorth)
*/
struct Stop {
    
    let id: Int
    let name: String
    let location: CLLocation
}


class ViewController: UIViewController {
    
    
    //MARK: Property
    let MTA_API_TOKEN = "c7ed3e715a3e71f70e051cf0a80e4c3d"
    let manager = CLLocationManager()
    
    //debug
    var stopNameLabel :UILabel = UILabel(frame: CGRect(x: 20, y: 70, width: 300, height: 60))

    
    //MARK: Method
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        manager.delegate = self
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.requestAlwaysAuthorization()
        }
    }
}


// MARK: - Debug
extension ViewController {
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        stopNameLabel.text = "Be patient loading"
        view.addSubview(stopNameLabel)
    }
}


// MARK: - Stop
extension ViewController {
    
    
    /**
    Gets LIRR data from stops.txt file.  Need to handle MNorth as well.
    
    - returns: An array of Stops, .None if it fails.
    */
    func getStopData() -> [Stop]? {
        
        let filePath = NSBundle.mainBundle().pathForResource("stops", ofType: "txt", inDirectory: "data/lirr")
        let contents: NSString?
        do {
            
            contents = try String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
        } catch {
            
            return .None
        }
        
//        print(contents)
        
        var lines = contents?.componentsSeparatedByString("\n")
        lines?.removeFirst()
        return lines?.map { $0.toStop() }
    }
    
    
    /**
    Takes an array of Stop objects and determines the closest Stop to the location that is provided.
    
    - parameter stops:       Array of Stops (atm provided from the text file)
    - parameter ourLocation: The current location of the user.
    
    - returns: The closest Stop.
    */
    func closestStop(stops: [Stop], toLocation ourLocation: CLLocation) -> Stop? {
        
        var distance = DBL_MAX
        var stopToReturn: Stop?
        
        for stop in stops {
            if ourLocation.distanceFromLocation(stop.location) < distance {
                distance = ourLocation.distanceFromLocation(stop.location)
                stopToReturn = stop
            }
        }
        
        return stopToReturn
    }
}


// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            
            manager.startUpdatingLocation()
        }
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        manager.stopUpdatingLocation()
        
        //Our Stop of interest
        let stop = closestStop(getStopData()!, toLocation: newLocation)!
        print("closest stop name: " + stop.name)
        
        self.stopNameLabel.text = stop.name
        stopNameLabel.setNeedsDisplay()
    }
}


// MARK: - Stop convenience conversion for String type
extension String {

    /**
    Column for LIRR Parameter
    
    - ID:         Stop ID
    - Name:       Stop Name
    - Latitude:   Stop Latitude
    - Longitude:  Stop Longitude
    */
    enum LIRRParamColumn: Int {
        
        case ID = 0
        case Name = 1
        case Latitude = 2
        case Longitude = 3
    }
    
    
    /**
    Convert String to Stop. This addresses the need to parse the "stops.txt" 
    The stops come on a single line in the format: "\"1\",\"Long Island City\",\"40.74128\",\"-73.95639\""
    
    - returns: Stop
    */
    func toStop() -> Stop {
        
        func quoteStrippedString(s: String) -> String {
            
            let myString = s as NSString
            return myString.substringWithRange(NSRange(location: 1, length: myString.length - 2))
        }
        
        let a = self.componentsSeparatedByString(",")
        let b = a.map { quoteStrippedString($0) }
        
        let id = Int(b[LIRRParamColumn.ID.rawValue])
        let name = b[LIRRParamColumn.Name.rawValue]
        let lat = Double(b[LIRRParamColumn.Latitude.rawValue])
        let lon = Double(b[LIRRParamColumn.Longitude.rawValue])
        let loc = CLLocation(latitude: lat!, longitude: lon!)
        
        let stop = Stop(id: id!, name: name, location: loc)
        return stop
    }
}

