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
//struct Trip {
//    let tripID: String
//    let tripHeadSign: String //"Penn Station", "Bablyon" etc
//    let directionID: Int //1 means going out, 0 means coming in
//}

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
        
        //select * from stop_times where departure_time (is within 5 minutes) AND stop_id == 1
        
        let stopTimes = Table("stop_times")
        let alias = stopTimes.alias("myAlias")
        let tripID = Expression<String>("trip_id")
        let stopID = Expression<String>("stop_id")
//        let departureTime = Expression<NSDate>("departure_time")
        let startStopAlias = stopTimes.alias("startStopAlias")
        let endStopAlias = stopTimes.alias("endStopAlias")
        
        let startStopQuery = startStopAlias
            .filter(startStopAlias[stopID] == String(id))
        
        let endStopQuery = endStopAlias
            .filter(endStopAlias[stopID] == "25")
//        let tripIDAlias = endStopQuery.alias("stop_times")
        
        let departureTime = Expression<NSDate>("departure_time")
        //this returns distinct tripids
        let query = startStopQuery.select(startStopQuery[tripID].distinct, startStopQuery[departureTime]).join(endStopAlias, on: endStopAlias[tripID] == startStopQuery[tripID])
//        let query2 = query.filter(endStopAlias[stopID] == "25").filter(startStopQuery[departureTime] > NSDate()).order(startStopQuery[departureTime].asc)//this right here is giving us stops 24 & 25, little neck and great neck with departure times of whatever
        let query2 = query.filter(startStopQuery[departureTime] > NSDate()).order(startStopQuery[departureTime].asc)//this is giving us all of the trip ids with stopid 24 in it
        
        //now from this query, all we need is the departure time at that is close to the current time
        
        
        //departure times for start station
        //do we make a new query with these trip ids?
        let departureTimeQuery = query2.select(departureTime)
        
        //great neck = 25
        
        
        print("startStopQuery[tripID]: \(startStopQuery[stopID])")
        print("endStopQuery[tripID]: \(endStopQuery[stopID])")
        print("tripID: \(tripID)")
        print("startStopQuery[tripID]: \(startStopQuery[tripID])")
        print("endStopQuery[tripID]: \(endStopQuery[tripID])")
        
        print("startStopAlias[tripID]: \(startStopAlias[tripID])")
        print("endStopAlias[tripID]: \(endStopAlias[tripID])")
        
        print("alias[tripID]: \(alias[tripID])")
        print("query \(query.asSQL())")
        print("query2 \(query2.asSQL())")
        
        //that's the starting query, then we need to check from these trips, which end in the station that we want
        
//            .filter(NSDate(timeIntervalSinceNow: departureTime) < (60 * 60)) //1 hour
        
        return create { [weak self] observer in
//            let idToCompare = Expression<Int64>(value: Int64(id))
//            let stopQuery = self?.stops.filter(queryId == 1)
//            let s = self?.stops.filter(queryId == String(id))
//            for stop in (self?.db.prepare((self?.stops)!))! {
//                print("stop: \(stop[queryId])")
//            }
            for stop in (self?.db.prepare(query2))! {
                print("id: \(stop)")
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


enum TripType {
    case Local, Express
}

struct Trip {
    let departureTime: String
    let arrivalTime: String
    let tripType: TripType
}

//make a fake
class FakeTrips {
   
    class func trips() -> Observable<[Trip]> {
        return just([
            Trip(departureTime: "8:23", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "9:04", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "9:11", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "9:43", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "9:55", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "10:13", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "10:23", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "10:42", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "10:55", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "11:03", arrivalTime: "10:45", tripType: .Local),
            Trip(departureTime: "11:29", arrivalTime: "10:45", tripType: .Local)
            ])
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
