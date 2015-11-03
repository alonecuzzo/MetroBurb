//
//  Monad.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import Result


typealias IntParser = FileContentsParser<Int>
typealias StringParser = FileContentsParser<String>
typealias DoubleParser = FileContentsParser<Double>

typealias FileContents = AnyObject
typealias LineParsingStrategy = (String -> [String]?)


func fileContents<A>(contents: FileContents, type: A.Type) -> Result<A, ConcreteErrorType> {
    if let contents = contents as? A {
        return .Success(contents)
    }
    return .Failure(ConcreteErrorType())
}


func decodeObject<A: TextFileDecodeable>(contents: FileContents) -> Result<A, ConcreteErrorType> {
    return resultFromOptional(A.decode(fileContentsString(contents)!, line: .LIRR), error: ConcreteErrorType()) //come back and create an actual error
}


func resultFromOptional<A>(optional: A?, error: ConcreteErrorType) -> Result<A, ConcreteErrorType> {
    guard let optional = optional else {
        return .Failure(error)
    }
    return .Success(optional)
}
