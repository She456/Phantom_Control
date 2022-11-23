//  VirtualSticksViewController.swift
//  Created by Dennis Baldwin on 3/18/20.
//  Copyright © 2020 DroneBlocks, LLC. All rights reserved.
//
//  Make sure you know what you're doing before running this code. This code makes use of the Virtual Sticks API.
//  This code has only been tested on DJI Spark, but should work on other DJI platforms. I recommend doing this outdoors to get familiar with the
//  functionality. It can certainly be run indoors since Virtual Sticks do not make use of GPS. Please make sure your flight mode switch is in
//  the default position. If any point you need to take control the switch can be toggled out of the default position so you have manual control
//  again. Virtual Sticks DOES NOT allow you to add any manual input to the flight controller when this mode is enabled. Good luck and I hope
//  to experiment with other flight paths soon.
import UIKit
import DJISDK
import CDJoystick
import Network

enum FLIGHT_MODE {
    case HOVERING
    case FORWARD
    case BACK
    case RIGHT
    case LEFT
    case UP
    case DOWN
    case TURN_RIGHT
    case TURN_LEFT
    case GO
}

class VirtualSticksViewController: UIViewController {
    
    // UDP connection
    var didReceiveDataHandler: ((Data) -> ())? = nil

    var connection: NWConnection?
    var hostUDP: NWEndpoint.Host = "172.16.0.99"
    // Ser 127.0.0.1
    // PNJ 192.168.1.162
    // Yoo 192.168.1.52
    // MAC 192.168.1.167
    // LVL 172.16.0.99 or 98
    var portUDP: NWEndpoint.Port = 8888
    var msg = "Please Check UDP connection . . ."
    // end
    
    // 조이스틱
    @IBOutlet weak var leftJoystick: CDJoystick!
    @IBOutlet weak var rightJoystick: CDJoystick!
    
    // present = 현재 값
    @IBOutlet weak var present_x: UILabel!
    @IBOutlet weak var present_y: UILabel!
    @IBOutlet weak var present_z: UILabel!
    @IBOutlet weak var present_yaw: UILabel!
    
    // goal = 목표 값
    @IBOutlet weak var goal_x: UITextField!
    @IBOutlet weak var goal_y: UITextField!
    @IBOutlet weak var goal_z: UITextField!
    @IBOutlet weak var goal_yaw: UITextField!
    
    // dis = 목표와 현재의 차이 값
    @IBOutlet weak var dis_x: UILabel!
    @IBOutlet weak var dis_y: UILabel!
    @IBOutlet weak var dis_z: UILabel!
    @IBOutlet weak var dis_yaw: UILabel!
    
    // DJISDK API, Timer 설정
    var flightController: DJIFlightController?
    var flightMode: FLIGHT_MODE?
    var count = 0           // Timer count
    var travel_count = 0    // travel 현재 번호
    var timer: Timer?
    var timer2: Timer?
    var main_timer: Timer?
    var vision_timer: Timer?
    var travel_timer: Timer?
    var show_timer: Timer?

    // Send Control Data에 이용
    @IBOutlet weak var control_value: UITextField!
    var radians: Float = 0.0
    let velocity: Float = 0.1
    var x: Float = 0.0
    var y: Float = 0.0
    var z: Float = 0.0
    var yaw: Float = 0.0
    var yawSpeed: Float = 30.0
    var throttle: Float = 0.0
    var roll: Float = 0.0
    var pitch: Float = 0.0
    
    // Control Data 계산에 이용
    var px: Float = 0.0
    var py: Float = 0.0
    var pz: Float = 0.0
    var pyaw: Float = 0.0
    var gx: Float = 0.0
    var gy: Float = 0.0
    var gz: Float = 0.0
    var gyaw: Float = 0.0
    var dx: Float = 0.0
    var dy: Float = 0.0
    var dz: Float = 0.0
    var dyaw: Float = 0.0
    
    // waypoint 좌표 값
    @IBOutlet weak var x0: UITextField!
    @IBOutlet weak var y0: UITextField!
    @IBOutlet weak var z0: UITextField!
    @IBOutlet weak var yaw0: UITextField!
    @IBOutlet weak var x1: UITextField!
    @IBOutlet weak var y1: UITextField!
    @IBOutlet weak var z1: UITextField!
    @IBOutlet weak var yaw1: UITextField!
    @IBOutlet weak var x2: UITextField!
    @IBOutlet weak var y2: UITextField!
    @IBOutlet weak var z2: UITextField!
    @IBOutlet weak var yaw2: UITextField!
    @IBOutlet weak var x3: UITextField!
    @IBOutlet weak var y3: UITextField!
    @IBOutlet weak var z3: UITextField!
    @IBOutlet weak var yaw3: UITextField!
    @IBOutlet weak var x4: UITextField!
    @IBOutlet weak var y4: UITextField!
    @IBOutlet weak var z4: UITextField!
    @IBOutlet weak var yaw4: UITextField!
    @IBOutlet weak var x5: UITextField!
    @IBOutlet weak var y5: UITextField!
    @IBOutlet weak var z5: UITextField!
    @IBOutlet weak var yaw5: UITextField!
    @IBOutlet weak var x6: UITextField!
    @IBOutlet weak var y6: UITextField!
    @IBOutlet weak var z6: UITextField!
    @IBOutlet weak var yaw6: UITextField!
    @IBOutlet weak var x7: UITextField!
    @IBOutlet weak var y7: UITextField!
    @IBOutlet weak var z7: UITextField!
    @IBOutlet weak var yaw7: UITextField!
    @IBOutlet weak var x8: UITextField!
    @IBOutlet weak var y8: UITextField!
    @IBOutlet weak var z8: UITextField!
    @IBOutlet weak var yaw8: UITextField!
    @IBOutlet weak var x9: UITextField!
    @IBOutlet weak var y9: UITextField!
    @IBOutlet weak var z9: UITextField!
    @IBOutlet weak var yaw9: UITextField!
    
    var xList = [String?](repeating: "0.0", count: 10)
    var yList = [String?](repeating: "0.0", count: 10)
    var zList = [String?](repeating: "0.0", count: 10)
    var yawList = [String?](repeating: "0.0", count: 10)
    
    @IBOutlet weak var travel_point_label: UILabel!
    var limit: Int = 0
    
    // UI Image View
    @IBOutlet weak var Playground: UIView!
    @IBOutlet weak var Drone: UIImageView!
    @IBOutlet weak var Waypoint: UIImageView!
    @IBOutlet weak var travel_point: UIImageView!
    
    @IBOutlet weak var throttle_A: UILabel!
    @IBOutlet weak var yaw_A: UILabel!
    
    // p-control
    let maxS: Float = 0.1 //max speed
    let minS: Float = 0.05 //min speed
    let d_max: Float = 0.1 //max speed at dx > d_max
    let d_min: Float = 0.025 //min speed at dx = d_min
    
    
    // Vision Positioning
    @IBOutlet weak var Vision: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Grab a reference to the aircraft
        if let aircraft = DJISDKManager.product() as? DJIAircraft {
            
            
            // Grab a reference to the flight controller
            if let fc = aircraft.flightController {
                
                // Store the flightController
          
                self.flightController = fc
                
                print("We have a reference to the FC")
                // Default the coordinate system to ground
                self.flightController?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.body
                
                // Default roll/pitch control mode to velocity
                self.flightController?.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.velocity
                
                // Set control modes
                self.flightController?.yawControlMode = DJIVirtualStickYawControlMode.angularVelocity
                
            }
            
            show_timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        }
        
//        self.flightController?.flightAssistant
//        if let flightAssistant_ = self.flightController?.flightAssistant as? DJIFlightAssistant{
//            flightAssistant_
//        }
        
        goal_x.text = "-0.2"
        goal_y.text = "-0.4"
        goal_z.text = "1.2"
        goal_yaw.text = "0.0"
        
        x0.text = "-0.2"; x1.text = "-0.2"
        x2.text = "-0.2"; x3.text = "-0.2"
        x4.text = "-0.2"; x5.text = "-0.2"
        x6.text = "-0.2"; x7.text = "-0.2"
        x8.text = "-0.2"; x9.text = "-0.2"
        
        y0.text = "-0.4"; y1.text = "-0.4"
        y2.text = "-0.4"; y3.text = "-0.4"
        y4.text = "-0.4"; y5.text = "-0.4"
        y6.text = "-0.4"; y7.text = "-0.4"
        y8.text = "-0.4"; y9.text = "-0.4"
        
        z0.text = "1.2"; z1.text = "1.2"
        z2.text = "1.2"; z3.text = "1.2"
        z4.text = "1.2"; z5.text = "1.2"
        z6.text = "1.2"; z7.text = "1.2"
        z8.text = "1.2"; z9.text = "1.2"
        
        yaw0.text = "0.0"; yaw1.text = "0.0"
        yaw2.text = "0.0"; yaw3.text = "0.0"
        yaw4.text = "0.0"; yaw5.text = "0.0"
        yaw6.text = "0.0"; yaw7.text = "0.0"
        yaw8.text = "0.0"; yaw9.text = "0.0"
        
        // Setup joysticks
        // Throttle/yaw
        leftJoystick.trackingHandler = { [self] joystickData in
            self.yaw = Float(joystickData.velocity.x) * self.yawSpeed
            
            self.throttle = Float(joystickData.velocity.y) * 5.0 * -1.0 // inverting joystick for throttle
            
            self.sendControlData(x: self.pitch, y: self.roll, z: self.throttle)
            
        }
        
        // Pitch/roll
        rightJoystick.trackingHandler = { joystickData in
            
            self.pitch = Float(joystickData.velocity.x) * 2.0
            self.roll = Float(joystickData.velocity.y) * 2.0 * -1.0
            
            
            self.sendControlData(x: self.pitch, y: self.roll, z: self.throttle)
            
        }
    }
    
    @IBAction func changeRollPitchControlMode(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            self.flightController?.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.velocity
        } else if sender.selectedSegmentIndex == 1 {
            self.flightController?.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.angle
        }
    }
    
    // User clicks the enter virtual sticks button
    @IBAction func enableVirtualSticks(_ sender: Any) {
        toggleVirtualSticks(enabled: true)
    }
    
    // User clicks the exit virtual sticks button
    @IBAction func disableVirtualSticks(_ sender: Any) {
        toggleVirtualSticks(enabled: false)
    }
    
    // Handles enabling/disabling the virtual sticks
    private func toggleVirtualSticks(enabled: Bool) {
            
        // Let's set the VS mode
        self.flightController?.setVirtualStickModeEnabled(enabled, withCompletion: { (error: Error?) in
            
            // If there's an error let's stop
            guard error == nil else { return }
            
            print("Are virtual sticks enabled? \(enabled)")
            
        })
        
    }
    
    @IBAction func takeoff(_ sender: UIButton) {
        DJISDKManager.missionControl()?.scheduleElement(DJITakeOffAction())
        DJISDKManager.missionControl()?.startTimeline()
        DJISDKManager.missionControl()?.unscheduleEverything()
    }
    
    @IBAction func land(_ sender: UIButton) {
        DJISDKManager.missionControl()?.scheduleElement(DJILandAction())
        DJISDKManager.missionControl()?.startTimeline()
        DJISDKManager.missionControl()?.unscheduleEverything()
    }
    
    
    @IBAction func hovering(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.HOVERING
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    
    @IBAction func forward(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.FORWARD
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
//        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    
    @IBAction func back(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.BACK
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
//        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    
    @IBAction func right(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.RIGHT
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
//        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    
    @IBAction func left(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.LEFT
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
//        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
        
    }
    
    @IBAction func up(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.UP
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    
    @IBAction func down(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.DOWN
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    
    @IBAction func turn_right(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.TURN_RIGHT
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    
    @IBAction func turn_left(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.TURN_LEFT
        
        // Schedule the timer at 20Hz while the default specified for DJI is between 5 and 25Hz
        // Note: changing the frequency will have an impact on the distance flown so BE CAREFUL
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(stop), userInfo: nil, repeats: true)
    }
    
    // UDP connection
    @IBAction func connect(_ sender: UIButton) {
        connectToUDP(hostUDP, portUDP)
        
        sender.tintColor = UIColor.red
    }
    
    @IBAction func get(_ sender: UIButton) {
        main_timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(get_coor), userInfo: nil, repeats: true)
        
        sender.tintColor = UIColor.red
    }
    
    @IBAction func go(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.GO
        //timerLoop()
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
    }
    
    @IBAction func travel(_ sender: UIButton) {
        xList = [x0.text, x1.text, x2.text, x3.text, x4.text, x5.text, x6.text, x7.text, x8.text, x9.text]
        yList = [y0.text, y1.text, y2.text, y3.text, y4.text, y5.text, y6.text, y7.text, y8.text, y9.text]
        zList = [z0.text, z1.text, z2.text, z3.text, z4.text, z5.text, z6.text, z7.text, z8.text, z9.text]
        yawList = [yaw0.text, yaw1.text, yaw2.text, yaw3.text, yaw4.text, yaw5.text, yaw6.text, yaw7.text, yaw8.text, yaw9.text]
        
        setupFlightMode()
        flightMode = FLIGHT_MODE.GO
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
        travel_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(travel_counter), userInfo: nil, repeats: true)
    }
    
    @IBAction func travel_stepper(_ sender: UIStepper) {
        travel_count = Int(sender.value)
        if travel_count > limit {
            travel_count %= (limit + 1)
        }
    }
    
    @IBAction func limit_stepper(_ sender: UIStepper) {
        limit = Int(sender.value)
        if limit > 9 {
            limit %= 10
        }
    }
    
    @IBAction func slider_th(_ sender: UISlider) {
        throttle_A.text = "\(round(sender.value)/10)"
        goal_z.text = throttle_A.text
    }
    
    @IBAction func slider_yaw(_ sender: UISlider) {
        yaw_A.text = "\(Int(round(sender.value)) / 5 * 5)"
        goal_yaw.text = yaw_A.text
    }
    
    @IBAction func set_waypoint(_ sender: UIButton) {
        if travel_count == 0 {
            x0.text = goal_x.text
            y0.text = goal_y.text
            z0.text = goal_z.text
            yaw0.text = goal_yaw.text
        } else if travel_count == 1 {
            x1.text = goal_x.text
            y1.text = goal_y.text
            z1.text = goal_z.text
            yaw1.text = goal_yaw.text
        } else if travel_count == 2 {
            x2.text = goal_x.text
            y2.text = goal_y.text
            z2.text = goal_z.text
            yaw2.text = goal_yaw.text
        } else if travel_count == 3 {
            x3.text = goal_x.text
            y3.text = goal_y.text
            z3.text = goal_z.text
            yaw3.text = goal_yaw.text
        } else if travel_count == 4 {
            x4.text = goal_x.text
            y4.text = goal_y.text
            z4.text = goal_z.text
            yaw4.text = goal_yaw.text
        } else if travel_count == 5 {
            x5.text = goal_x.text
            y5.text = goal_y.text
            z5.text = goal_z.text
            yaw5.text = goal_yaw.text
        } else if travel_count == 6 {
            x6.text = goal_x.text
            y6.text = goal_y.text
            z6.text = goal_z.text
            yaw6.text = goal_yaw.text
        } else if travel_count == 7 {
            x7.text = goal_x.text
            y7.text = goal_y.text
            z7.text = goal_z.text
            yaw7.text = goal_yaw.text
        } else if travel_count == 8 {
            x8.text = goal_x.text
            y8.text = goal_y.text
            z8.text = goal_z.text
            yaw8.text = goal_yaw.text
        }  else if travel_count == 9 {
            x9.text = goal_x.text
            y9.text = goal_y.text
            z9.text = goal_z.text
            yaw9.text = goal_yaw.text
        }
    }
    
    @IBAction func emergency_home(_ sender: UIButton) {
        setupFlightMode()
        flightMode = FLIGHT_MODE.GO
        goal_x.text = "-0.2"
        goal_y.text = "-0.4"
        goal_z.text = "1.2"
        goal_yaw.text = "0.0"
        
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
    }
    
    @IBAction func set_vision(_ sender: UIButton) {
        vision_timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(vision), userInfo: nil, repeats: true)
        
        sender.tintColor = UIColor.red
    }
    
    // Vision position func
    @objc func vision() {
        self.flightController?.setVisionAssistedPositioningEnabled(true , withCompletion: { (error: Error?) in
            
            if error != nil {
                self.Vision.text = "Error"
            } else {
                self.Vision.text = "Good"
            }
        })
    }
    
    // Get coordinate from Optitrack
    @objc func get_coor() {
        sendUDP("")
        receiveUDP()
        
        let coor = msg.components(separatedBy: " ")
        self.present_x.text = coor[0]
        self.present_y.text = coor[2] //foward back
        self.present_z.text = coor[1] //altitude
        self.present_yaw.text = coor[3]
        
        px = (coor[0] as NSString).floatValue //current right left
        py = (coor[2] as NSString).floatValue //current foward back
        pz = (coor[1] as NSString).floatValue //current altitude
        pyaw = (coor[3] as NSString).floatValue //current yaw
        
        gx = (goal_x.text! as NSString).floatValue //right
        gy = (goal_y.text! as NSString).floatValue //foward
        gz = (goal_z.text! as NSString).floatValue //altitude
        gyaw = (goal_yaw.text! as NSString).floatValue
        
        let dx1 = (gx - px) * Float(__cospi(Double(pyaw)/180.0))
        let dx2 = (gy - py) * Float(__sinpi(Double(pyaw)/180.0))
        let dy1 = (gx - px) * Float(__sinpi(Double(pyaw)/180.0))
        let dy2 = (gy - py) * Float(__cospi(Double(pyaw)/180.0))
        
        dx = Float(-dx1 - dx2) //right left controll with roll +sign right
        dy = Float(-dy1 + dy2) //foward back controll with pitch +sign foward
        dz = gz - pz
        let dyaw_ = gyaw - pyaw
        
        if(dyaw_ < -180){
            dyaw = 360 + dyaw_
        }else if(dyaw_ > 180){
            dyaw = dyaw_ - 360
        }else{
            dyaw = dyaw_
        }
        
        dis_x.text = String(dx)
        dis_y.text = String(dy)
        dis_z.text = String(dz)
        dis_yaw.text = String(dyaw)
    }
    
    // travel point, label, UIimage update
    @objc func update() {
        travel_point_label.text = "Waypoint : \(travel_count)/\(limit)"
        
        // Drone UIimage show
        Drone.frame.origin.x = CGFloat(-px+0.9)/3*700 - Drone.frame.width/2
        Drone.frame.origin.y = CGFloat(py-1.2)/(-3)*700 - Drone.frame.height/2
        
        // Waypoint UIimage show
        Waypoint.frame.origin.x = CGFloat(-gx+0.9)/3*700 - Waypoint.frame.width/2
        Waypoint.frame.origin.y = CGFloat(gy-1.2)/(-3)*700 - Waypoint.frame.height/2

        // Travelpoint UIimage show
        if travel_count == 0 {
            travel_point.frame.origin.x = convert_to_PG(value: x0.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y0.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 1 {
            travel_point.frame.origin.x = convert_to_PG(value: x1.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y1.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 2 {
            travel_point.frame.origin.x = convert_to_PG(value: x2.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y2.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 3 {
            travel_point.frame.origin.x = convert_to_PG(value: x3.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y3.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 4 {
            travel_point.frame.origin.x = convert_to_PG(value: x4.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y4.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 5 {
            travel_point.frame.origin.x = convert_to_PG(value: x5.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y5.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 6 {
            travel_point.frame.origin.x = convert_to_PG(value: x6.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y6.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 7 {
            travel_point.frame.origin.x = convert_to_PG(value: x7.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y7.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 8 {
            travel_point.frame.origin.x = convert_to_PG(value: x8.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y8.text, mode: "y") - travel_point.frame.height/2
            
        } else if travel_count == 9 {
            travel_point.frame.origin.x = convert_to_PG(value: x9.text, mode: "x") - travel_point.frame.width/2
            travel_point.frame.origin.y = convert_to_PG(value: y9.text, mode: "y") - travel_point.frame.height/2
            
        }
    }
    
    // stop timer func
    @objc func stop() {
        
        if count > 10 {
            self.count = 0
            self.timer?.invalidate()
            self.timer2?.invalidate()
        }
        
        else {
            count = count + 1
        }
        
    }
    
    // travel point counter func
    @objc func travel_counter() {
        
        if count > 5 {
            self.count = 0
            travel_count += 1
            
            if travel_count > limit {
                self.travel_count = 0
                
                self.timer?.invalidate()
                self.timer2?.invalidate()
                self.travel_timer?.invalidate()
            }
        }
        
        else {
            count = count + 1
        }
        
        goal_x.text = xList[travel_count]
        goal_y.text = yList[travel_count]
        goal_z.text = zList[travel_count]
        goal_yaw.text = yawList[travel_count]
    }
    
    func convert_to_PG(value: String?, mode: String) -> CGFloat{
        let val = (value! as NSString).floatValue
        
        if mode == "x" {
            let result = CGFloat((-val+0.9)/3*700)
            return result
        } else if mode == "y" {
            let result = CGFloat((val-1.2)/(-3)*700)
            return result
        }
        
        return 0.0
    }
    
    
    // Timer loop to send values to the flight controller
    // It's recommend to run this in the iOS simulator to see the x/y/z values printed to the debug window
    @objc func timerLoop() {
        
        // Add velocity to radians before we do any calculation
        radians += velocity
        let c_value = (control_value.text! as NSString).floatValue
        // Determine the flight mode so we can set the proper values
        switch flightMode {
            case .HOVERING:
                x = 0
                y = 0
                z = 0
                yaw = 0
            case .FORWARD:
                x = 0
                y = c_value
                z = 0
                yaw = 0
            case .BACK:
                x = 0
                y = -c_value
                z = 0
                yaw = 0
            case .RIGHT:
                x = c_value
                y = 0
                z = 0
                yaw = 0
            case .LEFT:
                x = -c_value
                y = 0
                z = 0
                yaw = 0
            case .UP:
                x = 0
                y = 0
                z = c_value
                yaw = 0
            case .DOWN:
                x = 0
                y = 0
                z = -c_value
                yaw = 0
            case .TURN_RIGHT:
                x = 0
                y = 0
                z = 0
                yaw = 30
            case .TURN_LEFT:
                x = 0
                y = 0
                z = 0
                yaw = -30
            case .GO:
                
                let maxSpeed: Float = 0.1 //only for throttle
                
                let dS: Float = maxS - minS
                let d_minmax: Float = d_max - d_min
            
                if px < 0.9 && px > -1.2 && py < 1.2 && py > -1.2 {
                    if dx > d_max {
                        x = maxS
                    } else if dx > d_min {
                        x = maxS - (d_max - dx) * dS / d_minmax
                    } else if dx < -d_max {
                        x = -maxS
                    } else if dx < -d_min {
                        x = -maxS + (d_max + dx) * dS / d_minmax
                    } else {
                        x = 0
                    }
                    
                    if dy > d_max {
                        y = maxS
                    } else if dy > d_min {
                        y = maxS - (d_max - dy) * dS / d_minmax
                    } else if dy < -d_max {
                        y = -maxS
                    } else if dy < -d_min {
                        y = -maxS + (d_max + dy) * dS / d_minmax
                    } else {
                        y = 0
                    }
                    
                    if dz > 0.1 {
                        z = 2 * maxSpeed
                    } else if dz > 0.025 {
                        z = dz * maxSpeed * 20
                    } else if dz < -0.025 {
                        z = dz * maxSpeed * 20
                    } else if dz < -0.1 {
                        z = -2 * maxSpeed
                    } else {
                        z = 0
                    }
                    
                    if dyaw > 10 {
                        yaw = 20
                    } else if dyaw > 0.5 {
                        yaw = dyaw * 2
                    } else if dyaw < -0.5 {
                        yaw = dyaw * 2
                    } else if dyaw < -10 {
                        yaw = -20
                    } else {
                        yaw = 0
                    }
                    
                }
            case .none:
                break
        }
        
        sendControlData(x: x, y: y, z: z)
    }
    
    private func sendControlData(x: Float, y: Float, z: Float) {
        print("Sending x: \(x), y: \(y), z: \(z), yaw: \(yaw)")
        
        // Construct the flight control data object
        var controlData = DJIVirtualStickFlightControlData()
        controlData.verticalThrottle = z //throttle // in m/s
        
        controlData.roll = y //roll
        controlData.pitch = x //pitch
        
        if self.flightController?.rollPitchControlMode == DJIVirtualStickRollPitchControlMode.angle {
            controlData.roll = x //roll
            controlData.pitch = -y //pitch
        }
        
        controlData.yaw = yaw
        
        // Send the control data to the FC
        self.flightController?.send(controlData, withCompletion: { (error: Error?) in
            
            // There's an error so let's stop
            if error != nil {
                
                print("Error sending data")
                
                // Disable the timer
                self.timer?.invalidate()
            }
        })
    }
    
    // Called before any new flight mode is initiated
    private func setupFlightMode() {
        
        // Reset radians
        radians = 0.0
        count = 0
        travel_count = 0
        // Invalidate timer if necessary
        // This allows switching between flight modes
        if timer != nil {
            print("invalidating")
            timer?.invalidate()
            timer2?.invalidate()
            travel_timer?.invalidate()
        }
    }

    // UDP Connection
    func connectToUDP(_ hostUDP: NWEndpoint.Host, _ portUDP: NWEndpoint.Port) {

        self.connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)

        self.connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
                case .ready:
                    print("State: Ready\n")
                case .setup:
                    print("State: Setup\n")
                case .cancelled:
                    print("State: Cancelled\n")
                case .preparing:
                    print("State: Preparing\n")
                default:
                    print("ERROR! State not defined!\n")
            }
        }

        self.connection?.start(queue: .global())
    }

    func sendUDP(_ content: Data) {
        self.connection?.send(content: content, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

    func sendUDP(_ content: String) {
        let contentToSendUDP = content.data(using: String.Encoding.utf8)
        self.connection?.send(content: contentToSendUDP, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

    func receiveUDP() {
        self.connection?.receiveMessage { (data, context, isComplete, error) in
            if (isComplete) {
                print("Receive is complete")
                if (data != nil) {
                    let backToString = String(decoding: data!, as: UTF8.self)

                    self.msg = backToString

                } else {
                    print("Data == nil")
                }
            }
        }
    }
    // UDP Connection - end
    
    
    // UI를 Touch할때 func
    override func touchesBegan(_ touches: Set<UITouch> , with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        let touch = touches.first!
        if touch.view == Playground {
            var location = touch.location(in: Playground)

            if location.x < Waypoint.frame.width/2 {
                location.x = Waypoint.frame.width/2
            } else if location.x > Playground.frame.width - Waypoint.frame.width/2 {
                location.x = Playground.frame.width - Waypoint.frame.width/2
            }
            
            if location.y < Waypoint.frame.height/2 {
                location.y = Waypoint.frame.height/2
            } else if location.y > Playground.frame.height - Waypoint.frame.height/2 {
                location.y = Playground.frame.height - Waypoint.frame.height/2
            }
            
            goal_x.text = "\(round((0.9-location.x/700*3)*100)/100)"
            goal_y.text = "\(round((location.y/700*(-3)+1.2)*100)/100)"
            return
        }
    }

    // UI를 Move할때 func
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        let touch = touches.first!
        if touch.view == Playground {
            var location = touch.location(in: Playground)
            
            if location.x < Waypoint.frame.width/2 {
                location.x = Waypoint.frame.width/2
            } else if location.x > Playground.frame.width - Waypoint.frame.width/2 {
                location.x = Playground.frame.width - Waypoint.frame.width/2
            }
            
            if location.y < Waypoint.frame.height/2 {
                location.y = Waypoint.frame.height/2
            } else if location.y > Playground.frame.height - Waypoint.frame.height/2 {
                location.y = Playground.frame.height - Waypoint.frame.height/2
            }
            
            goal_x.text = "\(round((0.9-location.x/700*3)*100)/100)"
            goal_y.text =  "\(round((location.y/700*(-3)+1.2)*100)/100)"
            return
        }
    }
}

// Contains map specific code
extension VirtualSticksViewController {

}
