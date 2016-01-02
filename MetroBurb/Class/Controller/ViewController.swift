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
    
    let headerView = UIView()
    
    let tableView = UITableView()
    
    //debug
    var stopNameLabel = UILabel(frame: CGRect(x: 20, y: 70, width: 300, height: 60))
    private var locationManager: MetroBurbCoreLocationManager!
    private let CellIdentifier = "CellIdentifier"
    private let darkGray = UIColor(rgba: "#2C2D34")
    
    //MARK: Method
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(rgba: "#0F0F0F")
        setupLocation()
        stopViewModel.closestStopString.asObservable().subscribeNext { [unowned self] in
            self.stopNameLabel.text = $0
            }.addDisposableTo(disposeBag)
        setupTableView()
        stopNameLabel.hidden = true
        setupHeaderView()
//        testDB()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private func setupHeaderView() -> Void {
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: headerHeight)
        headerView.alpha = 0.97
        headerView.backgroundColor = UIColor(rgba: "#2C2D34")
        
        let labelHeight: CGFloat = 50
        let labelY: CGFloat = (headerHeight / 2) - (labelHeight / 2)
        let startStationLabel = UILabel(frame: CGRect(x: 20, y: labelY, width: 150, height: 50))
        startStationLabel.text = "Great Neck"
        startStationLabel.font = UIFont(name: "HelveticaNeue", size: 20)
        startStationLabel.textColor = UIColor.whiteColor()
        headerView.addSubview(startStationLabel)
       
        let endStationLabel = UILabel(frame: CGRect(x: 200, y: labelY, width: 150, height: labelHeight))
        endStationLabel.text = "Penn Station"
        endStationLabel.font = startStationLabel.font
        endStationLabel.textColor = startStationLabel.textColor
        endStationLabel.textAlignment = NSTextAlignment.Right
        headerView.addSubview(endStationLabel)
        
        let swapButton = UIButton(type: UIButtonType.Custom)
        swapButton.setBackgroundImage(UIImage(named: "swapButton"), forState: UIControlState.Normal)
        swapButton.frame.size = CGSize(width: 20, height: 22)
        swapButton.center = headerView.center
        headerView.addSubview(swapButton)
        
        view.addSubview(headerView)
    }
    
    let headerHeight: CGFloat = 80
    
    func setupTableView() -> Void {
        view.addSubview(tableView)
        tableView.registerClass(TripTableViewCell.classForCoder(), forCellReuseIdentifier: CellIdentifier)
        tableView.frame = view.frame
        tableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = 50
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.backgroundColor = UIColor(rgba: "#0F0F0F")
        let helveticaNeueLightString = "HelveticaNeue-Light"
        FakeTrips.trips().asDriver(onErrorJustReturn: []).drive(tableView.rx_itemsWithCellFactory) { [unowned self] (tv, idx, trip) -> UITableViewCell in
           let cell = self.tableView.dequeueReusableCellWithIdentifier(self.CellIdentifier) as! TripTableViewCell
//            cell.textLabel?.text = trip.departureTime
            let timeAttribute = [
                NSFontAttributeName : UIFont(name: helveticaNeueLightString, size: 30.0)!
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
            cell.tripTimeLabel.attributedText = txt
            
            cell.tripTypeLabel.text = trip.tripType.description
            
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
    
    let tripTypeLabel = UILabel()
    let tripTimeLabel = UILabel()
    let lightBackgroundView = UIView()
    let progressBar = UIView()
    
    let halfwayMarker = UIView()
    let twoThirdsMarker = UIView()
    let oneThirdMarker = UIView()
    
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
        self.tripTimeLabel.textColor = UIColor(rgba: "#FFFFFF")
        self.selectionStyle = UITableViewCellSelectionStyle.None
        tripTypeLabel.textAlignment = NSTextAlignment.Right
        lightBackgroundView.addSubview(tripTypeLabel)
        tripTypeLabel.textColor = UIColor(rgba: "#BFBFBF")
        tripTypeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        contentView.addSubview(lightBackgroundView)
        lightBackgroundView.backgroundColor = UIColor(rgba: "#40414A")
        lightBackgroundView.addSubview(tripTimeLabel)
        lightBackgroundView.addSubview(progressBar)
        progressBar.backgroundColor = UIColor(rgba: "#C2606F")
        halfwayMarker.backgroundColor = backgroundColor
        twoThirdsMarker.backgroundColor = backgroundColor
        oneThirdMarker.backgroundColor = backgroundColor
        lightBackgroundView.addSubview(halfwayMarker)
        lightBackgroundView.addSubview(twoThirdsMarker)
        lightBackgroundView.addSubview(oneThirdMarker)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let labelWidth: CGFloat = 100
        let labelHeight: CGFloat = 50
        tripTypeLabel.frame = CGRect(x: contentView.frame.size.width - labelWidth - 15, y: (contentView.frame.height / 2) - (labelHeight / 2) - 4, width: labelWidth, height: labelHeight)
        
        tripTimeLabel.frame = CGRect(x: 15, y: -10, width: contentView.frame.width - 25, height: 60)
        lightBackgroundView.frame = CGRect(x: 0, y: 0, width: contentView.frame.width, height: 46)
        
        let progressBarHeight: CGFloat = 3
        progressBar.frame = CGRect(x: 0, y: lightBackgroundView.frame.height - progressBarHeight, width: lightBackgroundView.frame.width, height: progressBarHeight)
        
        let markerSize = CGSize(width: 3, height: progressBarHeight)
        let markerY = lightBackgroundView.frame.height - markerSize.height
        
        halfwayMarker.center.x = lightBackgroundView.center.x
        halfwayMarker.frame.origin.y = markerY
        halfwayMarker.frame.size = markerSize
        
        twoThirdsMarker.frame = CGRect(origin: CGPoint(x: (3/4) * lightBackgroundView.frame.width, y: markerY), size: markerSize)
        oneThirdMarker.frame = CGRect(origin: CGPoint(x: (1/4) * lightBackgroundView.frame.width, y: markerY), size: markerSize)
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
