//
//  SudachiEmulationView.swift
//  Pomelo-V2
//
//  Created by Stossy11 on 16/7/2024.
//

import SwiftUI
import Sudachi
import Foundation
import GameController
import UIKit
import Darwin.POSIX.dlfcn


struct SudachiEmulationView: View {
    @StateObject private var viewModel: SudachiEmulationViewModel
    @State var controllerconnected = false
    @State var game: PomeloGame?
    @State var sudachi = Sudachi.shared
    @State var device: MTLDevice? = MTLCreateSystemDefaultDevice()
    @State var ShowPopup: Bool = false
    @State var mtkview: MTKView?
    @State private var thread: Thread!
    @State var uiTabBarController: UITabBarController?
    @State private var isFirstFrameShown = false
    @State private var switched = false
    @State private var wasairplay = false
    @State private var timer: Timer?
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("isairplay") private var isairplay: Bool = true
    @AppStorage("ShowMenuButton") private var ShowMenuButton: Bool = true
    @AppStorage("showfunnibackground") private var showbackground: Bool = false
    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    @Environment(\.presentationMode) var presentationMode
    @State private var isInBackground = false
    @AppStorage("disableMainScreen") var disableMainScreen: Bool = false
    
    @AppStorage("disableElapsedTime") var disableElapsedTime: Bool = false
    
    init(game: PomeloGame?) {
        _game = State(wrappedValue: game)
        _viewModel = StateObject(wrappedValue: SudachiEmulationViewModel(game: game))
    }

    var body: some View {
        
        
        ZStack {
            if (!disableMainScreen && !isairplay) {
                if #available(iOS 18.0, *), showbackground {
                    BackgroundView()
                        .ignoresSafeArea(.all)
                }
                if !isairplay, !switched {
                    SudachiMetalView(viewModel: viewModel, mtkview: $mtkview, device: $device, airplaylater: false)
                }
            }
            
            if disableMainScreen, isairplay {
                ControllerView()
                    .hidden()
            } else {
                ControllerView()
            }
            
            
            
            if (!disableMainScreen && !isairplay) {
                if ShowMenuButton {
                    VStack {
                        HStack {
                            Spacer()
                            Menu {
                                Button {
                                    if let metalView = mtkview {
                                        print("button pressed")
                                        
                                        let lastDrawableDisplayed = metalView.currentDrawable?.texture
                                        
                                        if let imageRef = lastDrawableDisplayed?.toImage() {
                                            let uiImage: UIImage = UIImage.init(cgImage: imageRef)
                                            
                                            if let pngData = uiImage.pngData() {
                                                // Define the path to save the PNG file
                                                if let game = self.game {
                                                    let fileURL = documentsDir.appendingPathComponent("screenshots/\(game.title)-(\(Date())).png")
                                                    print(Date())
                                                    do {
                                                        // Write the PNG data to the file
                                                        try pngData.write(to: fileURL)
                                                        print("Image saved to: \(fileURL.path)")
                                                    } catch {
                                                        print("Error saving PNG: \(error)")
                                                    }
                                                } else {
                                                    let fileURL = documentsDir.appendingPathComponent("screenshots/Home_Menu-(\(Date())).png")
                                                    
                                                    do {
                                                        // Write the PNG data to the file
                                                        try pngData.write(to: fileURL)
                                                        print("Image saved to: \(fileURL.path)")
                                                    } catch {
                                                        print("Error saving PNG: \(error)")
                                                    }
                                                }
                                            } else {
                                                print("Failed to convert UIImage to PNG data")
                                            }
                                        }
                                    }
                                } label: {
                                    Text("Take Screenshot")
                                        .font(.title)
                                        .padding()
                                }
                                
                                Button {
                                    viewModel.customButtonTapped()
                                    
                                    presentationMode.wrappedValue.dismiss()
                                } label: {
                                    Text("Exit (Unstable)")
                                }
                                
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .foregroundColor(Color.gray)
                            }
                        }
                        Spacer()
                    }
                }
            }
            
            
            
            if (disableMainScreen && isairplay) {
                Color.black
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .overlay(
            // Loading screen overlay on top of MetalView
            Group {
                if !isFirstFrameShown && !isairplay {
                    LoadingView()
                }
            }
                .transition(.opacity)
        )
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            print("AirPlay + \(Air.shared.connected)")
            
            print(disableMainScreen)
            print(isairplay)

            // Your existing variables
            isairplay = Air.shared.connected

            // Set up initial AirPlay view
            airplayafter(airplay: false)

            
            startPollingFirstFrameShowed()
        }
        .onDisappear {
            stopPollingFirstFrameShowed()
            UIApplication.shared.isIdleTimerDisabled = false
            uiTabBarController?.tabBar.isHidden = false
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func airplayafter(airplay: Bool) {
        isairplay = Air.shared.connected

        // Set up initial AirPlay view
        if isairplay, !isFirstFrameShown {
            let airplayView = AnyView(SudachiMetalView(
                viewModel: viewModel,
                mtkview: $mtkview,
                device: $device,
                airplaylater: airplay
            ))
            
            DispatchQueue.main.async {
                Air.play(airplayView)
            }
        }
    }
    
    
    private func startPollingFirstFrameShowed() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if sudachi.FirstFrameShowed() {
                withAnimation {
                    isFirstFrameShown = true
                }
                if !disableElapsedTime {
                    viewModel.startGameTimer()
                }
                stopPollingFirstFrameShowed()
            }
        }
    }

    private func stopPollingFirstFrameShowed() {
        timer?.invalidate()
        timer = nil
        print("Timer Invalidated")
    }
}


struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView("Loading...")
                // .font(.system(size: 90))
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
            Text("Please wait while the game loads.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
    }
}

extension View {
    func onRotate(perform action: @escaping (CGSize) -> Void) -> some View {
        self.modifier(DeviceRotationModifier(action: action))
    }
}



struct DeviceRotationModifier: ViewModifier {
    let action: (CGSize) -> Void
    @State var startedfirst: Bool = false

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size)
            })
            .onPreferenceChange(SizePreferenceKey.self) { newSize in
                if startedfirst {
                    action(newSize)
                } else {
                    startedfirst = true
                }
            }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}


struct BackgroundView: UIViewRepresentable {
    // This method creates and returns a UIView from the Apple Intelligence Lighting API.
    func makeUIView(context: Context) -> UIView {
        // Open the SwiftUICore framework dynamically.
        let handle = dlopen("/System/Library/Frameworks/SwiftUICore.framework/SwiftUICore", RTLD_NOW)
        
        // Get the symbol for "CoreViewMakeIntelligenceLightSourceView".
        guard let symbol = dlsym(handle, "CoreViewMakeIntelligenceLightSourceView") else {
            return UIView() // Return an empty UIView if symbol is not found
        }
        
        // Cast the symbol to a function that returns a UIView.
        let casted = unsafeBitCast(symbol, to: (@convention(thin) () -> UIView).self)
        let myView = casted()
        
        // Set the view to fill the entire screen.
        myView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView.frame = UIScreen.main.bounds
        
        return myView
    }
    
    // Required by UIViewRepresentable, but no updates are needed here.
    func updateUIView(_ uiView: UIView, context: Context) {}
}
