//
//  StopService.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import RxSwift
import SQLite

//1. closest stop service really, since that's all it's getting for us - doesn't matter where it comes from
//2. the db stop service can handle all interfacing with the stops, we'll still need to convert them into stops, but this should be returning a stop model objcect
//3. or do we have a stop service that allows us to do what we want to the stops?

//what are things that we want to do with the stops
//get stop by id
//get stop by location
//get stop by name

struct Location {
    let latitude: Double
    let longitude: Double
}

//there's a trip
struct Trip {
    let tripID: String
    let tripHeadSign: String //"Penn Station", "Bablyon" etc
    let directionID: Int //1 means going out, 0 means coming in
}

//1. can we get all of the trips for a stop
//2. can we then get all of the trips at a stop with a departure time within an hour
//3. then out of those just show the arrival times w/ the matching stopid

//we want to select a stop, and see the trips that terminate at the other stop

//going to be async and possibly failable - that's why we have observables instead of just returning values
protocol StopServiceProtocol {
    func getStop(id: Int) -> Observable<Stop>
    func getStop(location: Location) -> Observable<Stop>
    func getStop(name: String) -> Observable<Stop>
}

//should we make this configd w/ a line yes
class SQLiteStopService: StopServiceProtocol {
    
    //MARK: Property
    let line: Line
    var db: Connection!
    let stops = Table("stops")
    
    
    //MARK: Method
    init(line: Line) {
        self.line = line
        setupDB()
    }
    
    func setupDB() -> Void {
        let filePath = NSBundle.mainBundle().pathForResource("gtfs", ofType: "db", inDirectory: line.localDBDirectory)
        do {
            db = try Connection(filePath!)
        } catch {
            print("couldnt connect to db")
            return //some error or something
        }
    }
    
    func getStop(id: Int) -> Observable<Stop> {
        //should these be responsible for transformations?
        //really we just return Stop.decode() -> so we need something that can decode these
//        let stop
        return create { [weak self] observer in
            let queryId = Expression<String>("stop_id")
//            let idToCompare = Expression<Int64>(value: Int64(id))
//            let stopQuery = self?.stops.filter(queryId == 1)
            let s = self?.stops.filter(queryId == String(id))
//            for stop in (self?.db.prepare((self?.stops)!))! {
//                print("stop: \(stop[queryId])")
//            }
            for stop in (self?.db.prepare(s!))! {
                print("id: \(stop[queryId])")
            }
            return NopDisposable.instance
        }
    }
    
    func getStop(location: Location) -> Observable<Stop> {
        
        return create { observer in
           
            return NopDisposable.instance
        }
    }
    
    
    func getStop(name: String) -> Observable<Stop> {
        
        return create { observer in
           
            return NopDisposable.instance
        }
    }
    
    
}



//protocol ClosestStopService {
//    func closestStop
//}

/**
 *  Base protocol for Stop retrieval services.
 */
protocol StopService {
    
    /// Line type
    var line: Line { get }
    
    /**
     Requests list of stops for a particular line.
     
     - returns: An observable signal.
     */
    func requestForStopsStringSignal() -> Observable<String>
}
