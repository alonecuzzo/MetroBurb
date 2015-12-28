//
//  Line.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation

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

extension Line {
    var localDBDirectory: String {
        return "data/lirr/db"
    }
}
