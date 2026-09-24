//
//  MetalHUDEnabler.swift
//  Pomelo
//
//  Created by Stossy11 on 9/11/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import Foundation

func enableMetalHUD() {
    // Set the environment variable
    setenv("MTL_HUD_ENABLED", "1", 1)

}

func openMetalDylib() -> Bool {
    let path = "/usr/lib/libMTLHud.dylib"

    // Load the dynamic library
    if dlopen(path, RTLD_NOW) != nil {
        // Library loaded successfully
        print("Library loaded from \(path)")
        return true
    } else {
        // Handle error
        if let error = String(validatingUTF8: dlerror()) {
            print("Error loading library: \(error)")
        }
        return false
    }
}

func disableMetalHUD() {
    setenv("MTL_HUD_ENABLED", "0", 1)
}
