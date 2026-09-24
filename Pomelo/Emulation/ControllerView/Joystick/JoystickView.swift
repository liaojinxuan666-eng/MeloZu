//
//  JoystickView.swift
//  Pomelo
//
//  Created by Stossy11 on 30/9/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI
import SwiftUIJoystick
import Sudachi

public struct Joystick: View {
    @State var iscool: Bool? = nil
    var id: Int {
        if onscreenjoy {
            return 8
        }
        return 0
    }
    @AppStorage("onscreenhandheld") var onscreenjoy: Bool = false
    
    let sudachi = Sudachi.shared
    
    @ObservedObject public var joystickMonitor = JoystickMonitor()
    var dragDiameter: CGFloat {
        var selfs = CGFloat(160)
        if UIDevice.current.systemName.contains("iPadOS") {
            return selfs * 1.2
        }
        return selfs
    }
    private let shape: JoystickShape = .circle
    
    public var body: some View {
        VStack{
            JoystickBuilder(
                monitor: self.joystickMonitor,
                width: self.dragDiameter,
                shape: .circle,
                background: {
                    Text("")
                        .hidden()
                },
                foreground: {
                    Circle().fill(Color.gray)
                        .opacity(0.7)
                },
                locksInPlace: false)
            .onChange(of: self.joystickMonitor.xyPoint) { newValue in
                let scaledX = Float(newValue.x)
                let scaledY = Float(-newValue.y) // my dumbass broke this by having -y instead of y :/ (well it appears that with the new joystick code, its supposed to be -y)
                print("Joystick Position: (\(scaledX), \(scaledY))")
                
                if iscool != nil {
                    sudachi.thumbstickMoved(analog: .right, x: scaledX, y: scaledY, controllerid: id)
                } else {
                    sudachi.thumbstickMoved(analog: .left, x: scaledX, y: scaledY, controllerid: id)
                }
            }
        }
    }
}
