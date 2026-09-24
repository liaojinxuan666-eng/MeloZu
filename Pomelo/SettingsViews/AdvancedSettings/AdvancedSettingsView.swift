//
//  AdvancedSettingsView.swift
//  Pomelo
//
//  Created by Stossy11 on 14/7/2024.
//

import SwiftUI
import UniformTypeIdentifiers
import Foundation

struct AdvancedSettingsView: View {
    @AppStorage("icloudsaves2") var icloudsaves: Bool = false
    @AppStorage("isfullscreen") var isFullScreen: Bool = false
    @AppStorage("169fullscreen") var sixteenbynineaspect: Bool = false
    @AppStorage("ClearBackingRegion") var kpagetable: Bool = false
    @AppStorage("WaitingforJIT") var waitingJIT: Bool = false
    @AppStorage("cangetfullpath") var canGetFullPath: Bool = false
    @AppStorage("onscreenhandheld") var onscreenjoy: Bool = false
    
    @AppStorage("showMetalHUD") var showMetalHUD: Bool = false
    
    @AppStorage("canShowMetalHUD") var canShowMetalHUD: Bool = false
    @AppStorage("ShowMenuButton") private var ShowMenuButton: Bool = true
    @AppStorage("hideLastNameTop") var hideLastName: Bool = false
    
    @AppStorage("disableMainScreen") var disableMainScreen: Bool = false
    
    @AppStorage("disabletouch") var disableTouch: Bool = false
    
    @AppStorage("pomeloRPC") var pomeloRPC: Bool = false
    
    @AppStorage("pomeloRPCIP") var pomeloRPCip: String = ""
    
    @Environment(\.colorScheme) var colorScheme
    @State var isshowing = false
    
    var body: some View {
        ScrollView {
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        Toggle("Fullscreen", isOn: $isFullScreen)
                            .padding()
                    }
                }
            Text("Makes the games stretch to fill the screen.")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
            
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        Toggle("Fullscreen (16/9)", isOn: $sixteenbynineaspect)
                            .padding()
                    }
                }
            Text("Keeps the games in a 16:9 aspect ratio but fills the screen.")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
            
            if colorScheme == .light {
                Rectangle()
                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .frame(width: .infinity, height: 50)
                    .overlay() {
                        HStack {
                            Toggle("Disable \(deviceType()) Screen", isOn: $disableMainScreen)
                                .padding()
                        }
                    }
                Text("When AirPlaying the \(deviceType()) Screen will be disabled (Including On Screen Controller).")
                    .padding(.bottom)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            if canShowMetalHUD {// (Int(UIDevice.current.systemVersion) ?? 0 >= 16) || canShowMetalHUD {
                Rectangle()
                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .frame(width: .infinity, height: 50)
                    .overlay() {
                        HStack {
                            Toggle("Show Metal HUD", isOn: $showMetalHUD)
                                .padding()
                        }
                    }
                    .onChange(of: showMetalHUD) { new in
                        print("Show MetalHUD? \(new)")
                        if new {
                            enableMetalHUD()
                        } else {
                            disableMetalHUD()
                        }
                    }
                Text("This shows the current FPS (framerate), Memory Usage, and other information when running the emulation.")
                    .padding(.bottom)
                    .font(.footnote)
                    .foregroundColor(.gray)
            } else {
                Rectangle()
                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .frame(width: .infinity, height: 50)
                    .overlay() {
                        HStack {
                            Text("Metal HUD is not avalible on \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                                .padding(.horizontal)
                            Spacer()
                        }
                    }
                    .padding(.bottom)
                    .onAppear() {
                        showMetalHUD = false
                    }
            }
            
            /*
            if deviceOwnerLastName != nil {
                Rectangle()
                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .frame(width: .infinity, height: 50)
                    .overlay() {
                        HStack {
                            Toggle("Hide Last Name", isOn: $hideLastName)
                                .padding()
                        }
                    }
                Text("Hide your last name at the top of the Game Selector Screen.")
                    .padding(.bottom)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        Toggle("iCloud Saves", isOn: $icloudsaves)
                            .padding()
                            .onChange(of: icloudsaves) { value in
                                if value {
                                    // moveFoldersToICloud()
                                } else {
                                    // restoreFoldersFromiCloud()
                                }
                            }
                    }
                }
            Text("This enables iCloud storage for game saves, ensuring your progress syncs seamlessly across all your devices. WARNING: You will loose all your game saves on other devices.")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
             */
            
            
            
            
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        Toggle("Menu Button", isOn: $ShowMenuButton)
                            .padding()
                    }
                }
            Text("The exiting game feature in the menu is very unstable and can cause crashes and other issues when exiting games")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
            
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        Toggle("Pomelo RPC", isOn: $pomeloRPC)
                            .padding()
                    }
                }
            Text("This adds support for Discord Rich Presence (RPC). (This needs a desktop companion app)")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
            
            if pomeloRPC {
                Rectangle()
                    .fill(Color(uiColor: UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .frame(width: .infinity, height: 50)
                    .overlay() {
                        HStack {
                            Text("Pomelo RPC IP")
                                .padding()
                            TextField("Server Address", text: $pomeloRPCip)
                        }
                    }
                Text("Please enter the Pomelo RPC Desktop Companion App Server Address.")
                    .padding(.bottom)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        Toggle("Disable Touch", isOn: $disableTouch)
                            .padding()
                    }
                }
            Text("This option disables the touch screen in games.")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
            
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        if DeviceMemory.has8GBOrMore {
                            Toggle("Memory Usage Increase", isOn: $kpagetable)
                                .padding()
                        } else {
                            Toggle("Memory Usage Increase", isOn: $kpagetable)
                                .padding()
                                .disabled(true)
                        }
                    }
                }
            Text("This makes games a little more stable but a lot of games will crash as you will run out of Memory way quicker, 8GB Memory is needed for this feature.")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
            
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        Toggle("Check for Booting OS", isOn: $canGetFullPath)
                            .padding()
                    }
                }
            Text("If you do not have the neccesary files for Booting the Switch OS, it will just crash almost instantly.")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
            
            Rectangle()
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(width: .infinity, height: 50)
                .overlay() {
                    HStack {
                        Toggle("Set OnScreen Controls to Handheld", isOn: $onscreenjoy)
                            .padding()
                    }
                }
            Text("You need in Core Settings to set \"use_docked_mode = 0\"")
                .padding(.bottom)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .onAppear() {
            // isshowing = true
        }
        .onDisappear() {
            // isshowing = false
        }
    }
}

func moveFoldersToICloud() {
    let fileManager = FileManager.default

    // Get the app's Documents directory
    let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

    // Paths to your original folders in your app's Documents directory
    let nandOriginalPath = documentsPath.appendingPathComponent("nand").path

    // Create backup directory path
    let backupPath = documentsPath.appendingPathComponent("backup").path

    // iCloud Documents directory
    if let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
        let nandICloudPath = iCloudURL.appendingPathComponent("nand")

        do {
            // Create backup folder if it doesn't exist
            if !fileManager.fileExists(atPath: backupPath) {
                try fileManager.createDirectory(atPath: backupPath, withIntermediateDirectories: true, attributes: nil)
            }

            // Backup the nand folder
            let nandBackupPath = backupPath + "/nand"
            if !fileManager.fileExists(atPath: nandBackupPath) {
                try fileManager.copyItem(atPath: nandOriginalPath, toPath: nandBackupPath)
                print("Backup created for nand folder at \(nandBackupPath)")
            }

            // Backup the shader folder

            // Move the nand folder to iCloud
            try fileManager.moveItem(atPath: nandOriginalPath, toPath: nandICloudPath.path)
            print("Moved nand folder to iCloud.")

            // Move the shader folder to iCloud

            // Create symlink for nand
            try fileManager.createSymbolicLink(atPath: nandOriginalPath, withDestinationPath: nandICloudPath.path)
            print("Created symlink for nand.")

            // Create symlink for shader
            print("Folders moved to iCloud and symlinks created successfully.")
            
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    } else {
        print("Could not find iCloud Drive.")
    }
}


func restoreFoldersFromiCloud() {
    let fileManager = FileManager.default

    // Get the app's Documents directory
    let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

    // Paths to your original folders in your app's Documents directory
    let nandOriginalPath = documentsPath.appendingPathComponent("nand").path

    // iCloud Documents directory
    if let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
        let nandICloudPath = iCloudURL.appendingPathComponent("nand")
        
        do {
            // Remove the symlink for nand if it exists
            if fileManager.fileExists(atPath: nandOriginalPath) {
                try fileManager.removeItem(atPath: nandOriginalPath)
            }

            // Move the nand folder back to Documents
            try fileManager.moveItem(atPath: nandICloudPath.path, toPath: nandOriginalPath)
            
            print("Folders restored from iCloud successfully.")
            
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    } else {
        print("Could not find iCloud Drive.")
    }
}
func deviceType() -> String {
    if UIDevice.current.userInterfaceIdiom == .phone {
        return "iPhone"
    } else if UIDevice.current.userInterfaceIdiom == .pad {
        return "iPad"
    } else {
        return "Mac"
    }
}
