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
import UIColor_Hex_Swift

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
    
    let tableView: UITableView = UITableView()
    
    //debug
    var stopNameLabel = UILabel(frame: CGRect(x: 20, y: 70, width: 300, height: 60))
    private var locationManager: MetroBurbCoreLocationManager!
    private let CellIdentifier = "CellIdentifier"
    private let darkGray = UIColor(rgba: "#2C2D34")
    
    //MARK: Method
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = darkGray
        setupLocation()
        stopViewModel.closestStopString.subscribeNext { [unowned self] in
            self.stopNameLabel.text = $0
            }.addDisposableTo(disposeBag)
        setupTableView()
        stopNameLabel.hidden = true
//        testDB()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func setupTableView() -> Void {
        view.addSubview(tableView)
        tableView.registerClass(TripTableViewCell.classForCoder(), forCellReuseIdentifier: CellIdentifier)
        tableView.frame = view.frame
        tableView.rowHeight = 63
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.backgroundColor = darkGray
        let helveticaNeueLightString = "HelveticaNeue-Light"
        FakeTrips.trips().asDriver(onErrorJustReturn: []).drive(tableView.rx_itemsWithCellFactory) { [unowned self] (tv, idx, trip) -> UITableViewCell in
           let cell = self.tableView.dequeueReusableCellWithIdentifier(self.CellIdentifier) as! TripTableViewCell
//            cell.textLabel?.text = trip.departureTime
            let timeAttribute = [
                NSFontAttributeName : UIFont(name: helveticaNeueLightString, size: 25.0)!
            ]
            let suffixAttribute = [
                NSFontAttributeName : UIFont(name: helveticaNeueLightString, size: 15.0)!]
            let arrivalTimeAttribute = [
                NSFontAttributeName : UIFont(name: helveticaNeueLightString, size: 20.0)!]
            let timeString = trip.departureTime + "P - " + trip.arrivalTime + "P"
            let txt = NSMutableAttributedString(string: timeString, attributes: timeAttribute)
//            var txt2 = txt + NSAttributedString(string: "P", attributes: suffixAttribute)
            txt.addAttributes(suffixAttribute, range: NSRange(location: trip.departureTime.characters.count, length: 1))
            txt.addAttributes(suffixAttribute, range: NSRange(location: timeString.characters.count - 1, length: 1))
            txt.addAttributes(arrivalTimeAttribute, range: NSRange(location: timeString.characters.count - 1 - trip.arrivalTime.characters.count, length: trip.arrivalTime.characters.count))
            cell.textLabel?.attributedText = txt
            
            
            return cell
        }.addDisposableTo(disposeBag)
    }
    
    func testDB() -> Void {
        let service = SQLiteStopService(line: .LIRR)
        service.getStop(24).subscribeNext { next -> Void in //penn station
            //should get a stop here
            print("got it")
        }.addDisposableTo(disposeBag)
    }
}


class TripTableViewCell: UITableViewCell {
    //gonna need attributed strings for formatting
    //progress bar at bottom
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() -> Void {
        self.backgroundColor = UIColor(rgba: "#2C2D34")
        self.textLabel?.textColor = UIColor(rgba: "#F7F7F7")
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
