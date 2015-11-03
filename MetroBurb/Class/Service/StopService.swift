//
//  StopService.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import RxSwift

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
