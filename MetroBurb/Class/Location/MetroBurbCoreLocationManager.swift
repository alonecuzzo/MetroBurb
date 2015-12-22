//
//  MetroBurbCoreLocationManager.swift
//  MetroBurb
//
//  Created by Jabari Bell on 12/22/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation

import Foundation
import RxSwift
import RxCocoa
import CoreLocation


class MetroBurbCoreLocationManager {
    
    //MARK: Property
    private let locationManager: CLLocationManager
    private let disposeBag: DisposeBag = DisposeBag()
    
    
    //MARK: Method
    init(locationReceivedBlock: (location: CLLocation?) -> Void, internalAlertBlock: (MetroBurbCoreLocationManager) -> Void) {
        self.locationManager = CLLocationManager()
        let status = CLLocationManager.authorizationStatus()
        
        if status == .NotDetermined {
            internalAlertBlock(self)
        }
        locationManager.rx_didUpdateLocations
            .distinctUntilChanged({ (lhs, rhs) -> Bool in
                return lhs.first?.coordinate.latitude == rhs.first?.coordinate.latitude
                    && lhs.first?.coordinate.longitude == rhs.first?.coordinate.longitude
            })
            .subscribeNext { [weak self] locations -> Void in
                self?.locationManager.stopUpdatingLocation()
                locationReceivedBlock(location: locations.first)
            }
            .addDisposableTo(disposeBag)
        
        locationManager.rx_didChangeAuthorizationStatus.subscribeNext { [weak self] status -> Void in
            self?.startUpdatingLocationIfAuthorized(status!)
        }.addDisposableTo(disposeBag)
        startUpdatingLocationIfAuthorized(status)
    }
    
    func requestAlwaysAuthorization() -> Void {
        locationManager.requestAlwaysAuthorization()
    }
    
    private func startUpdatingLocationIfAuthorized(status: CLAuthorizationStatus) -> Void {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}
