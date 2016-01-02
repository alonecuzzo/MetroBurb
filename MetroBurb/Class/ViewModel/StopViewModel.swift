//
//  StopViewModel.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift

// this should really be named the closest stop view model, since that's really what it's all about - we only want to use this for the closest stop
class StopViewModel {
    
    //MARK: Property
    let service: StopService
    let stops = Variable([Stop?]())
    let closestStopString = Variable("Loading...")
    let userLocation = Variable(CLLocation())
    let disposeBag = DisposeBag()
    
    
    //MARK: Method
    init(service: StopService) {
        self.service = service
        service.requestForStopsStringSignal().subscribeOn(MainScheduler.instance).subscribeNext { fileContentsString in
                var lines = fileContentsString.componentsSeparatedByString("\n")
                lines.removeFirst()
                self.stops.value = lines.map { Stop.decode($0, line: self.service.line) } //i think an error can happen here, we should have a result handler
        }.addDisposableTo(disposeBag)
        
        userLocation.asObservable().observeOn(MainScheduler.instance).subscribeNext { [unowned self] newLocation in
            
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
            
            guard let stop = closestStop(self.stops.value, toLocation: newLocation) else {
                self.closestStopString.value = "Errr"
                return
            }
            
            self.closestStopString.value = stop.name
            
        }.addDisposableTo(disposeBag)
    }
}
