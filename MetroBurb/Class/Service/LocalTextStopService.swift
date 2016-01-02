//
//  LocalTextStopService.swift
//  MetroBurb
//
//  Created by Jabari Bell on 10/26/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import Foundation
import RxSwift

/**
 *  Retrieves stop information from local text files. (MTA/LIRR- maybe struct name should reflect this)
 */
public struct LocalTextStopService: StopService {
    
    let line: Line
    
    //wrong this is a request for the closest stop...
    public func requestForStopsStringSignal() -> Observable<String> {
        
        return Observable.create { observer in
            let filePath = NSBundle.mainBundle().pathForResource("stops", ofType: "txt", inDirectory: self.line.localTextStorageDirectory())
            let contents: NSString?
            do {
                contents = try String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
                observer.on(.Next(contents! as String))
                observer.on(.Completed)
            } catch {
                let error = MetroBurbError(type: MetroBurbErrorType.StopFileReadingError, domain: "com.our.domain.or.whatever")
                observer.on(.Error(error))
            }
            return NopDisposable.instance
        }
    }
}