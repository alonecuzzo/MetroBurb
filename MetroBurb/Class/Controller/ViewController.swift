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
    }
}

// MARK: Location Setup
extension ViewController {
    private func setupLocation() -> Void {
        let svm = stopViewModel
        locationManager = MetroBurbCoreLocationManager(
            locationReceivedBlock: { (location) -> Void in
               svm.userLocation.value = location!
            },
            internalAlertBlock: { [weak self] (manager) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    let alertController = UIAlertController(title: "Can we get your location?", message: "We need this!", preferredStyle: UIAlertControllerStyle.Alert)
                    let defaultAction = UIAlertAction(title: "Allow", style: UIAlertActionStyle.Default) { action -> Void in
                        manager.requestAlwaysAuthorization()
                    }
                    let cancelAction = UIAlertAction(title: "Don't Allow", style: UIAlertActionStyle.Default, handler: nil)
                    alertController.addAction(cancelAction)
                    alertController.addAction(defaultAction)
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
