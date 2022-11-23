//
//  AircraftState.swift
//  DJISDKSwiftDemo
//
//  Created by kist on 2022/11/14.
//  Copyright © 2022 DJI. All rights reserved.
//

import Foundation
import UIKit
import DJISDK
import CDJoystick
import Network

class AircraftState: UIViewController, DJIFlightControllerDelegate {
    
    
    var didReceiveDataHandler: ((Data) -> ())? = nil
    
    var flightController: DJIFlightController?
    var DroneState: DJIFlightControllerState?
    var timer: Timer?
    var timer2: Timer?
    
    @IBOutlet weak var Altitude: UILabel!
    @IBOutlet weak var Roll: UILabel!
    @IBOutlet weak var Pitch: UILabel!
    @IBOutlet weak var Yaw: UILabel!
    @IBOutlet weak var Velocity_X: UILabel!
    @IBOutlet weak var Velocity_Y: UILabel!
    @IBOutlet weak var Velocity_Z: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

  
}
