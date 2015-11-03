//
//  StopParsingStrategy.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation

protocol StopParsingStrategy {
    static func values(contents: String) -> [String]?
}