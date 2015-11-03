//
//  LIRRParsingStrategy.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation


struct LIRRParsingStrategy: StopParsingStrategy {
    
    static func values(contents: String) -> [String]? {
        func quoteStrippedString(s: String) -> String {
            let myString = s as NSString
            return myString.substringWithRange(NSRange(location: 1, length: myString.length - 2))
        }
        let a = contents.componentsSeparatedByString(",")
        return a.map { quoteStrippedString($0) }
    }
}
