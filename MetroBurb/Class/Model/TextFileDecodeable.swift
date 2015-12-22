//
//  TextFileDecodeable.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation

protocol TextFileDecodeable {
    static func decode(contents: String, line: Line) -> Self?
}
