//
//  TopBarView.swift
//  Pomelo
//
//  Created by Stossy11 on 9/10/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI
import Combine
import Sudachi

struct TopBarView: View {
    @State private var currentDate: Date = Date()
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel
    @State private var batteryState: UIDevice.BatteryState = UIDevice.current.batteryState
    @State private var creatinguser: Bool = false
    @State private var username: String = ""
    @AppStorage("deviceOwnerName") var deviceOwnerName: String?
    @AppStorage("deviceOwnerLastName") var deviceOwnerLastName: String?
    @AppStorage("hideLastNameTop") var hideLastName: Bool = false
    
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 60, on: .main, in: .common).autoconnect() // Update every minute
    }

    var body: some View {
        let hour = Calendar.current.component(.hour, from: currentDate)
        let minutes = Calendar.current.component(.minute, from: currentDate)

        HStack {
            NavigationLink {
                SudachiEmulationView(game: PomeloGame(programid: 0, ishomebrew: false, developer: "", fileURL: URL(string: "BootMii")!, imageData: Data(), title: "Mii Maker"))
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            
             
            /*
            Button {
                creatinguser.toggle()
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
            .alert("Create User", isPresented: $creatinguser) {
                TextField("username", text: $username)
                    .onSubmit {
                        let sudachi = Sudachi.shared
                        if sudachi.createUser(uuid: UUID(), username: username) {
                            print("Created User \(username)")
                        } else {
                            print("Failed to Create User \(username)")
                        }
                    }
            }
            */
            Spacer()
            if let user = deviceOwnerName {
                if hideLastName {
                    Text("Welcome \(user)!")
                        .font(.system(size: 22))
                } else if let deviceOwnerLastName  {
                    Text("Welcome \(user) \(deviceOwnerLastName)!")
                        .font(.system(size: 22))
                } else {
                    Text("Welcome \(user)!")
                        .font(.system(size: 22))
                } // deviceOwnerLastName
            } else {
                Text("\(hour % 12 == 0 ? 12 : hour % 12):\(String(format: "%02d", minutes)) \(hour >= 12 ? "PM" : "AM")")
                    // .foregroundColor(.black)
                    .font(.system(size: 22))
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "wifi")
                Image(systemName: batteryImageName(for: batteryLevel))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .onReceive(timer) { _ in
            currentDate = Date()
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            
            batteryLevel = UIDevice.current.batteryLevel
            batteryState = UIDevice.current.batteryState
        }
    }

    private func batteryImageName(for level: Float) -> String {
        switch level {
        case 0.0: return "battery.0"
        case 0.1..<0.25: return "battery.25"
        case 0.25..<0.5: return "battery.50"
        case 0.5..<0.75: return "battery.75"
        case 0.75..<1.0: return "battery.75"
        default: return "battery.100"
        }
    }
}

