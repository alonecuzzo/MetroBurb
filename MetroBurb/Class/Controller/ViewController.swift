//
//  ViewController.swift
//  MetroBurb
//
//  Created by Jabari Bell on 9/28/15.
//  Copyright © 2015 Code Mitten. All rights reserved.
//

import UIKit
import Darwin
import Result
import RxSwift
import RxCocoa

//great article - http://artsy.github.io/blog/2015/09/24/mvvm-in-swift/
//viewcontroller should NOT know about the model note to self
class ViewController: UIViewController {
    
    //MARK: Property
    let MTA_API_TOKEN = "c7ed3e715a3e71f70e051cf0a80e4c3d" //TODO: move into environment var or something
    let disposeBag = DisposeBag()
    
    let stopViewModel: StopViewModel = {
        let service = LocalTextStopService(line: Line.LIRR)
        return StopViewModel(service: service)
    }()
    
    //debug
    var stopNameLabel = UILabel(frame: CGRect(x: 20, y: 70, width: 300, height: 60))
    private var locationManager: MetroBurbCoreLocationManager!

    
    //MARK: Method
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocation()
        stopViewModel.closestStopString.subscribeNext { [unowned self] in
            self.stopNameLabel.text = $0
            }.addDisposableTo(disposeBag)
        testDB()
    }
    
    func testDB() -> Void {
        let service = SQLiteStopService(line: .LIRR)
        service.getStop(23).subscribeNext { next -> Void in
            //should get a stop here
            print("got it")
        }.addDisposableTo(disposeBag)
    }
}

// MARK: Location Setup
extension ViewController {
    private func setupLocation() -> Void {
        let internalAlertTitle = "Can we get your location?"
        let internalAlertMessage = "We need this!"
        let cancelHandler: UIAlertActionHandlerBlock = { action -> Void in
            print("cancelled location")
            //set default line for app
        }
        let svm = stopViewModel
        locationManager = MetroBurbCoreLocationManager(
            locationReceivedBlock: { (location) -> Void in
                guard let location = location else { return }
                svm.userLocation.value = location
            },
            internalAlertBlock: { [weak self] (manager) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    let alertController = UIAlertController(title: internalAlertTitle, message: internalAlertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                    let defaultAction = UIAlertAction(title: "Allow", style: UIAlertActionStyle.Default) { action -> Void in
                        manager.requestAlwaysAuthorization()
                    }
                    let cancelAction = UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.Default, handler: cancelHandler)
                    alertController.addAction(cancelAction)
                    alertController.addAction(defaultAction)
                    manager.systemCancelAction = cancelHandler
                    self?.presentViewController(alertController, animated: true, completion: nil)
                }
            })
    }
}


// MARK: - Debug
extension ViewController {
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        view.addSubview(stopNameLabel)
    }
}
