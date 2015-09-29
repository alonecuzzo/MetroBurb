//: Playground - noun: a place where people can play

import UIKit
import CoreLocation
import XCPlayground

enum LIRRParamLocation: Int {
    case ID = 0
    case Name = 1
    case Latitude = 2
    case Longitude = 3
    case ParamCount = 4 //always have this at the bottom
}

struct Stop {
    
    let id: Int
    let name: String
    let location: CLLocation
}


extension String {
    
//    func rangeOfQuote() -> NSRange {
//        let firstMatch = self.rangeOfString("\"")?.endIndex
//        let range = (firstMatch + 1)...(self.utf16.count - 1 - firstMatch)
//        let secondMatch = self.rangeOfString("\"", options: NSStringCompareOptions.CaseInsensitiveSearch, range: NSRange(firstMatch + 1, self.utf16.count - 1 - firstMatch, locale: nil))
//    }
//    u know what? these always have quotes jus tpop the first and last chars
    
    func toStop() -> Stop {
//       ([\"])(?:\\\\\\1|.)*?\\1 
//        func quoteStrippedString(s: String) -> String {
////            let range = s.rangeOfString("([\"])(?:\\\\\\1|.)*?\\1", options:.RegularExpressionSearch)
//            let range = s.rangeOfString("(?<=\")[^w]+(?=\")", options:.RegularExpressionSearch)
//            var found = ""
//            if range != nil {
//                found = s.substringWithRange(range!)
//                print("found: \(found)") // found: google
//            }
//            return found
        
//        }
        
        func quoteStrippedString(s: String) -> String {
            let myString = s as NSString
            return myString.substringWithRange(NSRange(location: 1, length: myString.length - 2))
        }

        let a = self.componentsSeparatedByString(",")
        let b = a.map { quoteStrippedString($0) }
        
        let id = Int(b[LIRRParamLocation.ID.rawValue])
        let name = b[LIRRParamLocation.Name.rawValue]
        let lat = Double(b[LIRRParamLocation.Latitude.rawValue])
        let lon = Double(b[LIRRParamLocation.Longitude.rawValue])
        let loc = CLLocation(latitude: lat!, longitude: lon!)

        let stop = Stop(id: id!, name: name, location: loc)
        return stop
    }
    
    func toStops() -> [Stop] {
        return self.componentsSeparatedByString("\n").map { $0.toStop() }
    }
}


//conver this one string to a stop
//let s = "\"1\",\"Long Island City\",\"40.74128\",\"-73.95639\"".toStops()
//s.name


let ss = "\"1\",\"Long Island City\",\"40.74128\",\"-73.95639\"\n\"20\",\"Broadway\",\"40.76164\",\"-73.80176\"".toStops()
ss[0].location.description

XCPSharedDataDirectoryPath

let fileString = XCPSharedDataDirectoryPath + "stops.txt"
if let data = NSData(contentsOfFile: fileString) {
    let string = NSString(data: data, encoding: NSUTF8StringEncoding)
    
} else {
    print("ho")
}

let owlPath = XCPSharedDataDirectoryPath + "owl.jpg"
if let image = UIImage(contentsOfFile: owlPath) {
    image
    
    
}

let fileURL = NSURL(fileURLWithPath: fileString)
//let contents = String(contentsOfFile: fileURL, encoding: NSUTF8StringEncoding, error: nil)
let contents: NSString?
do {
    contents = try String (contentsOfFile: fileString, encoding: NSUTF8StringEncoding)
} catch {
    print("why")
    contents = nil
}

contents //awesome now we need to delete the first line
var lines = contents?.componentsSeparatedByString("\n")
lines?.removeFirst()
lines?[12].toStop().name


let stopz = lines?.map { $0.toStop() }
stopz


//stopz[57].name

let sto = lines![(lines?.count)! - 1].toStop()
sto.name
//"20","Broadway”,”40.76164","-73.80176"

//how do we determine whether to use db or not 

//maybe we store this text file somewhere... on the repo

//then we look at it to check if we have the most recent
//store the date for the most recent in the user defaults



//for str in lines! {
////    str.toStop()
//    if let s = str.toStop() {
//        
//    } else {
//        
//    }
//}

//let stops = lines?.map { $0.toStop() }

//let c = String(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding)

//let filePath = XCPSharedDataDirectoryPath.stringByAppendingPathComponent("<fileName>")



