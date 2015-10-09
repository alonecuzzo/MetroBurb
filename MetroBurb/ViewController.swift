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

//func >>><A, B>(a: Result<A, ConcreteErrorType>, f: A -> throws Result<B, ConcreteErrorType>) -> Result<B, ConcreteErrorType> {
//    do {
//        try f(x)
//    } catch {
//        return .Failure(error)
//    }
//}

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
    case MetroNorth, LIRR
    
    var parsingStrategy: LineParsingStrategy {
        switch self {
        case .MetroNorth:
            return MetroNorthParsingStrategy.values
        case .LIRR:
            return LIRRParsingStrategy.values
        }
    }
}

extension Line {
    
    func localTextStorageDirectory() -> String {
        switch self {
        case .MetroNorth:
            return "data/mnorth"
        case .LIRR:
            return "data/lirr"
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
        
        func quoteStrippedString(s: String) -> String {
            let myString = s as NSString
            return myString.substringWithRange(NSRange(location: 1, length: myString.length - 2))
        }
        
        let someContents: FileContents = 4
        print("contents type \(NSNumber.self)")
        
        let mirror = Mirror(reflecting: someContents)
        print("mirror type: \(mirror.subjectType)")
        //how's it going to know which type to infer?
        //someInt >>> fileContents -> how to know the intended type that we want to cast to?
//        let result: Result<Int, ConcreteErrorType> = fileContents(someContents, type: Int.self)
//        print("result value: \(result.value)")
//        print("result error: \(result.error)")
        
        
//        let rush = FileContentsParser<Int>().fileContents(contents)
//        ru
        
//        let result = IntParser.fileContents(someContents)
//        
//        do {
//            let result = try StringParser.fileContentsThrows(someContents)
//        } catch {
//            //somethign
//        }
        
        
        let a = contents.componentsSeparatedByString(",")
        return a.map { quoteStrippedString($0) }
        
    }
}

typealias IntParser = FileContentsParser<Int>
typealias StringParser = FileContentsParser<String>
typealias DoubleParser = FileContentsParser<Double>

/**
*  THIS CAN WRAP THE FILE CONTENTS! now how to make this throwable? do we want to?
*  not really a parser... more like a type caster?
*/
struct FileContentsParser<A> {
    
    static func fileContents(contents: FileContents) -> Result<A, ConcreteErrorType> {
        if let contents = contents as? A {
            return .Success(contents)
        }
        return .Failure(ConcreteErrorType())
    }
    
    static func fileContentsThrows(contents: FileContents) throws -> Result<A, NoError> {
        guard let contents = contents as? A else {
            throw ConcreteErrorType()
        }
        return .Success(contents)
    }
}


//Parsing help
//func fancyFileContentsInt(contents: FileContents) throws -> Result<Int, MetroBurbConcreteErrorType> {
//    //
//}

//can we do a fileContents -> Result generalized function?
func fileContents<A>(contents: FileContents, type: A.Type) -> Result<A, ConcreteErrorType> {
    if let contents = contents as? A {
        return .Success(contents)
    }
    return .Failure(ConcreteErrorType())
}


func fileContentsInt(contents: FileContents) -> Int? {
    return contents.integerValue
}

func fileContentsString(contents: FileContents) -> String? {
    return contents as? String
}

func fileContentsDouble(contents: FileContents) -> Double? {
    return contents.doubleValue
}


// MARK: - Convenience curried CLLocation creation.
extension CLLocation {
    
    static func create(lat: Double?)(lon: Double?) -> CLLocation? {
        if let lat = lat, lon = lon {
            return CLLocation(latitude: lat, longitude: lon)
        }
        return .None
    }
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

protocol StopService {
    
    var line: Line { get }
    
    func requestForStopsStringSignal() -> SignalProducer<String, MetroBurbError>
}


struct LocalTextStopService: StopService {
    
    //this should know about the line
    let line: Line
    
    func requestForStopsStringSignal() -> SignalProducer<String, MetroBurbError> {
        
        return SignalProducer { sink, disposable in //what about need of [weak self] in structs? can you weakify a value type? or should you?
            
            let filePath = NSBundle.mainBundle().pathForResource("stops", ofType: "txt", inDirectory: self.line.localTextStorageDirectory())
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
    
    let stops = MutableProperty<[Stop?]>([Stop?]())
    let closestStopString = MutableProperty<String>("Loading...")
    let userLocation = MutableProperty<CLLocation>(CLLocation())
    
    init(service: StopService) {
        self.service = service
        
        service.requestForStopsStringSignal().observeOn(QueueScheduler.mainQueueScheduler).start(Event.sink(error: { error in
            
                print("some error: \(error)")
            
            }, next: { [unowned self] fileContents in
                
                var lines = fileContents.componentsSeparatedByString("\n")
                lines.removeFirst()
                self.stops.value = lines.map { Stop.decode($0, line: self.service.line) } //i think an error can happen here, we should have a result handler
            }))
        
        userLocation.producer.observeOn(QueueScheduler.mainQueueScheduler).startWithNext { [weak self] newLocation in
            
            func closestStop(stops: [Stop?], toLocation ourLocation: CLLocation) -> Stop? {
                
                var distance = DBL_MAX
                var stopToReturn: Stop?
                
                for stop in stops {
                    if let stop = stop {
                        if ourLocation.distanceFromLocation(stop.location) < distance {
                            distance = ourLocation.distanceFromLocation(stop.location)
                            stopToReturn = stop
                        }
                    }
                }
                
                return stopToReturn
            }
            
            guard let stop = closestStop(self!.stops.value, toLocation: newLocation) else {
                self?.closestStopString.value = "Errr"
                return
            }
            
            self?.closestStopString.value = stop.name
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
        ClosestStopNotFound(location: CLLocation)
//        StopConversionFromStringError(param: LIRRParamColumn)
}

//great article - http://artsy.github.io/blog/2015/09/24/mvvm-in-swift/
//viewcontroller should NOT know about the model note to self
class ViewController: UIViewController {
    
    
    //MARK: Property
    let MTA_API_TOKEN = "c7ed3e715a3e71f70e051cf0a80e4c3d"
    let manager = CLLocationManager()
    
    let stopViewModel: StopViewModel = {
        let service = LocalTextStopService(line: Line.LIRR)
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

