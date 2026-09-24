//
//  SudachiEmulationHandler.swift
//  Pomelo
//
//  Created by Stossy11 on 22/7/2024.
//

import SwiftUI
import Sudachi
import Metal
import Foundation


class SudachiEmulationViewModel: ObservableObject {
    @Published var isShowingCustomButton = true
    @State var should = false
    var device: MTLDevice?
    @State var mtkView: MTKView = MTKView()
    var CaLayer: CAMetalLayer?
    @State var isPaused: Bool = false
    private var sudachiGame: PomeloGame?
    private let sudachi = Sudachi.shared
    private var thread: Thread!
    private var isRunning = false
    var doesneedresources = false
    @State var iscustom: Bool = false

    private var gameTimer: Timer?
    private var elapsedTime: TimeInterval = 0
    private var startTime: Date?
    
    private var rpctimer: Timer?
    
    init(game: PomeloGame?) {
        self.device = MTLCreateSystemDefaultDevice()
        self.sudachiGame = game
    }

    func configureSudachi(with mtkView: MTKView) {
        self.mtkView = mtkView
        device = self.mtkView.device
        guard !isRunning else { return }
        isRunning = true
        sudachi.configure(layer: mtkView.layer as! CAMetalLayer, with: mtkView.frame.size)
        
        iscustom = ((sudachiGame?.fileURL.startAccessingSecurityScopedResource()) != nil)
        
        print("Is outside URL? \(iscustom ? "Yes" : "No")")
        
        
        // startGameTimer() // Start the timer when the game starts
        if #available(iOS 17.0, *) {
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                if let sudachiGame = self.sudachiGame {
                    if sudachiGame.fileURL == URL(string: "BootMii") {
                        self.sudachi.bootMii()
                    } else {
                        self.sudachi.insert(game: sudachiGame.fileURL)
                    }
                } else {
                    self.sudachi.bootOS()
                }
            }
        } else {
            DispatchQueue.main.async {
                if let sudachiGame = self.sudachiGame {
                    if sudachiGame.fileURL == URL(string: "BootMii") {
                        self.sudachi.bootMii()
                    } else {
                        self.sudachi.insert(game: sudachiGame.fileURL)
                    }
                } else {
                    self.sudachi.bootOS()
                }
            }
        }
        
        if UserDefaults.standard.bool(forKey: "pomeloRPC") {
            startRPCTimer()
        }
        
        thread = .init(block: self.step)
        thread.name = "Pomelo"
        thread.qualityOfService = .userInteractive
        thread.threadPriority = 0.9
        thread.start()
    }

    private func step() {
        while true {
            sudachi.step()
        }
    }

    func customButtonTapped() {
        stopEmulation()
    }

    private func stopEmulation() {
        if isRunning {
            isRunning = false
            stopGameTimer() // Stop the timer and save elapsed time
            rpctimer?.invalidate()
            rpctimer = nil
            sudachi.exit()
            thread.cancel()
            if iscustom {
                sudachiGame?.fileURL.stopAccessingSecurityScopedResource()
            }
        }
    }
    
    public func startRPCTimer() {
        if let sudachiGame {
            startRPC(game: sudachiGame)
        } else {
            startRPC(game: PomeloGame(programid: 0, ishomebrew: false, developer: "Nintendo", fileURL: URL(string: "/")!, imageData: Data(), title: "Home Menu"))
        }
        
        rpctimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.runEveryFiveSeconds()
        }
    }

    private func runEveryFiveSeconds() {
        rpcHeartBeat()
    }

    public func startGameTimer() {
        startTime = Date()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let startTime = self.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)
                saveElapsedTimeToJSON()
            }
        }
    }

    private func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
        saveElapsedTimeToJSON()
    }

    private func saveElapsedTimeToJSON() {
        var newEntry: [String: TimeInterval]
        if let game = sudachiGame {
            newEntry = [game.title: elapsedTime]
        } else {
            newEntry = ["Home Menu": elapsedTime]
        }
        
        let fileURL = getDocumentsDirectory().appendingPathComponent("PomeloInfo.json")
        
        do {
            var existingData: [String: TimeInterval] = [:]
            
            // Check if the file exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // Read existing data
                let data = try Data(contentsOf: fileURL)
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: TimeInterval] {
                    existingData = json
                }
            }
            
            // Merge new data with existing data
            for (key, value) in newEntry {
                existingData[key] = value
            }
            
            // Write updated data back to the file
            let updatedJsonData = try JSONSerialization.data(withJSONObject: existingData, options: .prettyPrinted)
            try updatedJsonData.write(to: fileURL, options: .atomic)
            
            print("Successfully saved elapsed time to \(fileURL.path)")
        } catch {
            print("Error saving elapsed time: \(error.localizedDescription)")
        }
    }

    func handleOrientationChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let interfaceOrientation = self.getInterfaceOrientation(from: UIDevice.current.orientation)
            self.sudachi.orientationChanged(orientation: interfaceOrientation, with: self.mtkView.layer as! CAMetalLayer, size: mtkView.frame.size)
        }
    }

    private func getInterfaceOrientation(from deviceOrientation: UIDeviceOrientation) -> UIInterfaceOrientation {
        switch deviceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .unknown
        }
    }
}

func getDocumentsDirectory() -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}
