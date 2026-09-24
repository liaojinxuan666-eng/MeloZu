//
//  SudachiMetalView.swift
//  Pomelo
//
//  Created by Stossy11 on 22/10/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI
import Sudachi
import Foundation
import GameController
import UIKit

struct SudachiMetalView: View {
    @StateObject var viewModel: SudachiEmulationViewModel
    @Binding var mtkview: MTKView?
    @Binding var device: MTLDevice?
    @AppStorage("isairplay") private var isairplay: Bool = true
    @State var airplaylater: Bool
    var body: some View {
        if #available(iOS 16.0, *) {
            MetalView(device: device) { view in
                DispatchQueue.main.async {
                    if let metalView = view as? MTKView {
                        if !airplaylater {
                            mtkview = metalView
                            viewModel.configureSudachi(with: metalView)
                        } else {
                            let sudachi = Sudachi.shared
                            sudachi.configure(layer: metalView.layer as! CAMetalLayer, with: metalView.frame.size)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .persistentSystemOverlays(.hidden)
            .onRotate { size in
                if !isairplay {
                    viewModel.handleOrientationChange()
                }
            }
        } else {
            MetalView(device: device) { view in
                DispatchQueue.main.async {
                    if let metalView = view as? MTKView {
                        if !airplaylater {
                            mtkview = metalView
                            viewModel.configureSudachi(with: metalView)
                        } else {
                            let sudachi = Sudachi.shared
                            
                            sudachi.configure(layer: metalView.layer as! CAMetalLayer, with: metalView.frame.size)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onRotate { size in
                if !isairplay {
                    viewModel.handleOrientationChange()
                }
            }
        }
    }
}
