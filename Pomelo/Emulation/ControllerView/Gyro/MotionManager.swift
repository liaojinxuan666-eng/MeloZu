//
//  MotionManager.swift
//  Pomelo
//
//  Created by Stossy11 on 8/10/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//


import CoreMotion
import SwiftUI


class MotionManager : ObservableObject {

    let motion = CMMotionManager()
    var timer = Timer()
    var GyroVar = 0
    @State var gyroData: CMGyroData = CMGyroData()
    

    func startGyros() {
        if motion.isGyroAvailable {
            self.motion.gyroUpdateInterval = 1.0 / 60.0
            self.motion.startGyroUpdates()

            // Configure a timer to fetch the accelerometer data.

            self.timer = Timer(fire: Date(), interval: (1.0/60.0),

            repeats: true, block: { (timer) in
                if let data = self.motion.gyroData {
                    self.gyroData = data
                }
                // print("outloop")
            })

            RunLoop.current.add(self.timer, forMode: RunLoop.Mode.default)
        }
    }


    func stopGyros() {
        print("stop")
        self.timer.invalidate()
        self.motion.stopGyroUpdates()
    }
}
