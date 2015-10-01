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
import ReactiveCocoa


/**
*  Describes a stop on the given train service. (At the moment either LIRR or MNorth)
*/
struct Stop {
    
    let id: Int
    let name: String
    let location: CLLocation
}


class StopService {
    
    func requestForStopsSignal() -> SignalProducer<String, Error> {
        
        return SignalProducer { sink, disposable in
            
            let filePath = NSBundle.mainBundle().pathForResource("stops", ofType: "txt", inDirectory: "data/lirr")
            let contents: NSString?
            do {
                contents = try String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
                sendNext(sink, contents! as String)
                sendCompleted(sink)
            } catch {
                let error = Error(domain: "", code: Error.FileError.NotFound.hashValue)
                sendError(sink, error)
            }
        }
    }
}


class StopViewModel {
    
    let service: StopService
    
    let stops = MutableProperty<[Stop]>([Stop]())
    let closestStopString = MutableProperty<String>("Loading...")
    let userLocation = MutableProperty<CLLocation>(CLLocation())
    
    init(service: StopService) {
        self.service = service
        
        service.requestForStopsSignal().observeOn(QueueScheduler.mainQueueScheduler).start(Event.sink(error: { error in
            
                print("some error: \(error)")
            
            }, next: { fileContents in
                
                var lines = fileContents.componentsSeparatedByString("\n")
                lines.removeFirst()
                self.stops.value = lines.map { $0.toStop()! }
            }))
        
        userLocation.producer.observeOn(QueueScheduler.mainQueueScheduler).startWithNext { newLocation in
            
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
            
            guard let stop = closestStop(self.stops.value, toLocation: newLocation) else {
                self.closestStopString.value = "Errr"
                return
            }
            
            self.closestStopString.value = stop.name
        }
    }
}


struct Error : ErrorType {
    
    enum FileError {
        case NotFound
    }
    
    let domain: String
    let code: Int
    
    var _domain: String {
        return domain
    }
    var _code: Int {
        return code
    }
}

func ~=(lhs: Error, rhs: ErrorType) -> Bool {
    return lhs._domain == rhs._domain
        && rhs._code   == rhs._code
}


class ViewController: UIViewController {
    
    
    //MARK: Property
    let MTA_API_TOKEN = "c7ed3e715a3e71f70e051cf0a80e4c3d"
    let manager = CLLocationManager()
    
    let stopViewModel: StopViewModel = {
        let service = StopService()
        return StopViewModel(service: service)
    }()
    
    //debug
    var stopNameLabel = UILabel(frame: CGRect(x: 20, y: 70, width: 300, height: 60))

    
    //MARK: Method
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        stopNameLabel.rac_text <~ stopViewModel.closestStopString
        
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
        view.addSubview(stopNameLabel)
    }
}

/**
Erro handling

- StopFileParsingError:          Could not parse the file for some reason.
- StopFileReadingError:          Could not read the file.
- ClosestStopNotFound:           Could not find a closest stop at user's location.
- StopConversionFromStringError: Could not convert String to stop for provided parameter.
*/
enum MetroBurbError: ErrorType {
    case StopFileParsingError,
        StopFileReadingError,
        ClosestStopNotFound(location: CLLocation),
        StopConversionFromStringError(param: LIRRParamColumn)
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
        stopViewModel.userLocation.value = newLocation
    }
}


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


// MARK: - Stop convenience conversion for String type
extension String {
    
    
    /**
    Convert String to Stop. This addresses the need to parse the "stops.txt" 
    The stops come on a single line in the format: "\"1\",\"Long Island City\",\"40.74128\",\"-73.95639\""
    
    - returns: Stop
    */
    func toStop() -> Stop? {
        
        func quoteStrippedString(s: String) -> String {
            
            let myString = s as NSString
            return myString.substringWithRange(NSRange(location: 1, length: myString.length - 2))
        }
        
        let a = self.componentsSeparatedByString(",")
        let b = a.map { quoteStrippedString($0) }
        
        guard let id = Int(b[LIRRParamColumn.ID.rawValue]) else {
//            throw MetroBurbError.StopConversionFromStringError(param: .ID)
            return .None
        }
        
        guard let lat = Double(b[LIRRParamColumn.Latitude.rawValue]) else {
//            throw MetroBurbError.StopConversionFromStringError(param: .Latitude)
            return .None
        }
        
        guard let lon = Double(b[LIRRParamColumn.Longitude.rawValue]) else {
//            throw MetroBurbError.StopConversionFromStringError(param: .Longitude)
            return .None
        }
        
        let name = b[LIRRParamColumn.Name.rawValue]
        let loc = CLLocation(latitude: lat, longitude: lon)
        
        let stop = Stop(id: id, name: name, location: loc)
        return stop
    }
}

