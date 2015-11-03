//
//  MetroBurbError.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import CoreLocation

struct ConcreteErrorType: ErrorType {}

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