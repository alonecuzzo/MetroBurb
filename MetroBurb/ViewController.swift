//
//  ViewController.swift
//  MetroBurb
//
//  Created by Jabari Bell on 9/28/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import UIKit
import Darwin
import Result
import CoreLocation
import ReactiveCocoa


//Decoding 
infix operator >>> { associativity left precedence 150 }

func >>><A,B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

//maybe we make a concrete errortype to pass around?
struct ConcreteErrorType: ErrorType {}

func >>><A, B>(a: Result<A, ConcreteErrorType>, f: A -> Result<B, ConcreteErrorType>) -> Result<B, ConcreteErrorType> {
    switch a {
    case let .Success(x): return f(x)
    case let .Failure(error): return .Failure(error)
    }
}

//fmap
infix operator <^> { associativity left }

func <^><A,B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

//apply
infix operator <*> { associativity left }

func <*><A,B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a, fx = f {
        return fx(x)
    } else {
        return .None
    }
}


protocol TextFileDecodeable {
    static func decode(contents: String, line: Line) -> Self?
}

typealias FileContents = AnyObject
typealias LineParsingStrategy = (String -> [String]?)

enum Line {
    case MTA, LIRR
    
    var parsingStrategy: LineParsingStrategy {
        switch self {
        case .MTA:
            return MetroNorthParsingStrategy.values
        case .LIRR:
            return LIRRParsingStrategy.values
        }
    }
}


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
    
    //Note: can try something like this for the location: s[3] >>> (s[2] >>> createLocation)
    static func decode(contents: String, line: Line) -> Stop? {
        return line.parsingStrategy(contents) >>> { s in
            return Stop.create <^> s[0] >>> fileContentsInt <*> s[1] >>> fileContentsString <*> CLLocation(latitude: fileContentsDouble(s[2]) ?? 0, longitude: fileContentsDouble(s[3]) ?? 0) <*> line
        }
    }
}

//does it make sense to associate the strategy w/ the linetype?

protocol StopParsingStrategy {
    static func values(contents: String) -> [String]?
}

struct MetroNorthParsingStrategy: StopParsingStrategy {
    static func values(contents: String) -> [String]? {
        return [""]
    }
}

struct LIRRParsingStrategy: StopParsingStrategy {
    static func values(contents: String) -> [String]? {
        return [""]
    }
}


//Parsing help
func fileContentsInt(contents: FileContents) -> Int? {
    return contents as? Int
}

func fileContentsString(contents: FileContents) -> String? {
    return contents as? String
}

func fileContentsDouble(contents: FileContents) -> Double? {
    return contents as? Double
}

//pass in a dictionary w/ the lat lon
func createCoreLocation(lat: Double?)(lon: Double?) -> CLLocation {
    return CLLocation(latitude: lat ?? 0, longitude: lon ?? 0)
}

func decodeObject<A: TextFileDecodeable>(contents: FileContents) -> Result<A, ConcreteErrorType> {
    return resultFromOptional(A.decode(fileContentsString(contents)!, line: .LIRR), error: ConcreteErrorType()) //come back and create an actual error
}

func resultFromOptional<A>(optional: A?, error: ConcreteErrorType) -> Result<A, ConcreteErrorType> {
    guard let optional = optional else {
        return .Failure(error)
    }
    return .Success(optional)
}


class StopService {
    
    func requestForStopsSignal() -> SignalProducer<String, MetroBurbError> {
        
        return SignalProducer { sink, disposable in
            
            let filePath = NSBundle.mainBundle().pathForResource("stops", ofType: "txt", inDirectory: "data/lirr")
            let contents: NSString?
            do {
                contents = try String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
                sendNext(sink, contents! as String)
                sendCompleted(sink)
            } catch {
                let error = MetroBurbError(type: MetroBurbErrorType.StopFileReadingError, domain: "com.our.domain.or.whatever")
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


struct MetroBurbError: ErrorType {
    
    let type: MetroBurbErrorType
    let domain: String
}

/**
Error handling

- StopFileParsingError:          Could not parse the file for some reason.
- StopFileReadingError:          Could not read the file.
- ClosestStopNotFound:           Could not find a closest stop at user's location.
- StopConversionFromStringError: Could not convert String to stop for provided parameter.
*/
enum MetroBurbErrorType: ErrorType {
    case StopFileParsingError,
        StopFileReadingError,
        ClosestStopNotFound(location: CLLocation),
        StopConversionFromStringError(param: LIRRParamColumn)
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
//            throw MetroBurbErrorType.StopConversionFromStringError(param: .ID)
            return .None
        }
        
        guard let lat = Double(b[LIRRParamColumn.Latitude.rawValue]) else {
//            throw MetroBurbErrorType.StopConversionFromStringError(param: .Latitude)
            return .None
        }
        
        guard let lon = Double(b[LIRRParamColumn.Longitude.rawValue]) else {
//            throw MetroBurbErrorType.StopConversionFromStringError(param: .Longitude)
            return .None
        }
        
        //double lat double lon
        
        let name = b[LIRRParamColumn.Name.rawValue]
        let loc = CLLocation(latitude: lat, longitude: lon)
        
        let stop = Stop(id: id, name: name, location: loc, line: .LIRR)
        return stop
    }
}

