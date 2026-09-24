//
//  DeviceMemory.swift
//  Pomelo
//
//  Created by Stossy11 on 16/11/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import UIKit
import SwiftUI
import Foundation

enum DeviceMemory {
    /// Check if device has 8GB or more RAM
    static var has8GBOrMore: Bool {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.physicalMemory >= 7 * 1024 * 1024 * 1024 // 8GB in bytes
        #else
        return ProcessInfo.processInfo.physicalMemory >= 7 * 1024 * 1024 * 1024 // 8GB in bytes
        #endif
    }
    
    /// Get total RAM in GB (rounded)
    static var totalRAM: Int {
        Int(ProcessInfo.processInfo.physicalMemory / 1024 / 1024 / 1024) + 1
    }
}

