//
//  Monad.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import Result
import RxSwift
import RxCocoa

//TODO: Cleanup this file!!!

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

func fileContentsInt(contents: FileContents) -> Int? {
    return contents.integerValue
}

func fileContentsString(contents: FileContents) -> String? {
    return contents as? String
}

func fileContentsDouble(contents: FileContents) -> Double? {
    return contents.doubleValue
}

infix operator <-> {
}

func <-> <T>(property: ControlProperty<T>, variable: Variable<T>) -> Disposable {
    let bindToUIDisposable = variable
        .bindTo(property)
    let bindToVariable = property
        .subscribe(onNext: { n in
            variable.value = n
            }, onCompleted:  {
                bindToUIDisposable.dispose()
        })
    
    return StableCompositeDisposable.create(bindToUIDisposable, bindToVariable)
}

//Decoding
infix operator >>> { associativity left precedence 150 }

func >>><A,B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

//maybe we make a concrete errortype to pass around?

func >>><A, B>(a: Result<A, ConcreteErrorType>, f: A -> Result<B, ConcreteErrorType>) -> Result<B, ConcreteErrorType> {
    switch a {
    case let .Success(x): return f(x)
    case let .Failure(error): return .Failure(error)
    }
}
//what if there's a third type C that specifies the error?
//what is best way to enforce that C is an errortyep
//monad, monad, mondad
func >>><A, B, C: ErrorType>(a: Result<A, C>, f: A -> Result<B, C>) -> Result<B, C> {
    switch a {
    case let .Success(x): return f(x)
    case let .Failure(error): return .Failure(error)
    }
}

//where C.something == T
//monad, throws, monad
//this now transforms a {} -> throws block into a result
func >>><A, B, C>(a: Result<A, C>, f: A throws -> Result<B, C>) -> Result<B, ConcreteErrorType> {
    return a.pack { () -> B in
        do {
            guard let aValue = a.value else {
                throw ConcreteErrorType()
            }
            return try f(aValue).value!
        } catch {
            throw ConcreteErrorType()
        }
    }
}

//1. optionals
//2. result<value, error>
//3. try/throws


//interesting idea from: https://gist.github.com/rnapier/dbffbf54274a880a6ac7
// & http://radex.io/swift/error-conversions/
// on the subject of error types
extension Result {
    
    //monad -> throws
    func extract() throws -> T {
        switch self {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error as ErrorType
        }
    }
    
    //throws -> monad, returns Result<T, ErrorTYpe>
    //maybe it takes a value
    
    //goes from throws() -> monad
    //do { try block = value, return .Success with block as T
    //} catch {
    // throw error
    
    //packing a try/catch into a result...
    //research zipping
    func pack<U>(block: () throws -> U) -> Result<U, ConcreteErrorType> {
        do {
            return .Success(try block())
        } catch { //what about the specific error, should work w/ the error
            return .Failure(ConcreteErrorType())
        }
    }
}

infix operator ?! {
associativity right
precedence 131
}

func ?!<T>(optional: T?, @autoclosure error: () -> ErrorType) throws -> T {
    if let value = optional {
        return value
    } else {
        throw error()
    }
}

//<A: where A == T || A == B>

//monad/monad -> throws
//func >>><A, B, C>(a: Result<A, C>, f: A -> Result<B, C>) throws -> Result<B, C> {
//    do {
////        switch a {
////        case let .Success(x): return f(x)
////        case let .Failure(error): throw error
////        }
//        //how can extract() help? we should use some conversion helper -> result -> errortype
//        return try a.extract()
//    } catch {
//        throw a.error!
//    }
//}

//mondad/throws throws
//func >>><A, B, C>(a: Result<A, C>, f: A throws -> Result<B, C>) throws -> Result<B, C> {
//    do {
//        switch a {
//        case let .Success(x): return try f(x)
//        case let .Failure(error): throw error
//        }
//    } catch is ConcreteErrorType {
//        throw a.error! //should have an error
//    } catch {
//        throw ConcreteErrorType() //we don't know what happened
//    }
//}

//throws/monad -> throws
//throws/monad -> monad
//monad/throws -> monad *
//monad/throws -> throws
//mondad/mondad -> throws
//mondad/mondad -> monad *
//throws / throws -> monad
//throws / throws -> throws

//http://robnapier.net/throw-what-dont-throw
//enum Result<T> {
//    case Success(T)
//    case Failure(ErrorType)
//
//    func value() throws -> T {
//        switch self {
//        case .Success(let value): return value
//        case .Failure(let err): throw err
//        }
//    }
//
//    init(@noescape f: () throws -> T) {
//        do    { self = .Success(try f()) }
//        catch { self = .Failure(error) }
//    }
//}

//extension Result {
//
//    init(@noescape f:() throws -> T) {
//        do { self = .Success(try f()) }
//        catch { self = Result.Failure(error) }
//    }
//}


//fmap
infix operator <^> { associativity left }

//TODO: need A -> B <^> Result version
func <^><A,B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

func <^><A,B>(f: A -> Result<B, MetroBurbError>, a: Result<A, ConcreteErrorType>) throws -> Result<B, MetroBurbError> {
    switch a {
    case let .Success(x): return f(x)
    case let .Failure(error): throw error
    }
}

//apply
infix operator <*> { associativity left }

//TODO: need to get tries <*> result
func <*><A,B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a, fx = f {
        return fx(x)
    } else {
        return .None
    }
}

func <*><A,B>(f: A throws -> Result<B, MetroBurbError>, a: Result<A, ConcreteErrorType>) throws -> Result<B, MetroBurbError> {
    do {
        switch a {
        case let .Success(x): return try f(x)
        case let .Failure(error): throw error
        }
    } catch is ConcreteErrorType { //we can catch e here?
        throw a.error!
    } catch {
        throw ConcreteErrorType() //should never hit this point
    }
}






struct FileContentsParser<A> {
    
    static func fileContents(contents: FileContents) -> Result<A, ConcreteErrorType> {
        if let contents = contents as? A {
            return .Success(contents)
        }
        return .Failure(ConcreteErrorType())
    }
    
    static func fileContentsThrows(contents: FileContents) throws -> Result<A, MetroBurbError> {
        guard let contents = contents as? A else {
            throw ConcreteErrorType()
        }
        return .Success(contents)
    }
}

