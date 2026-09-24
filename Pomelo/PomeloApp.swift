//
//  PomeloApp.swift
//  Pomelo
//
//  Created by Stossy11 on 13/7/2024.
//

import SwiftUI
import AppIntents

infix operator --: LogicalDisjunctionPrecedence

func --(lhs: Bool, rhs: Bool) -> Bool {
    return lhs || rhs
}

@main
struct PomeloApp: App {
    
    init() {
        setMoltenVKSettings()
    }
    
    var body: some Scene {
        WindowGroup {
            if #available(iOS 16, *) {
                ContentView() // i dont know if i should change anything
                    .persistentSystemOverlays(.hidden)
            } else {
                ContentView() // i dont know if i should change anything
            }
        }
    }
    
    private func setMoltenVKSettings() {
        
        
        let settings: [String: String] = [
            "MVK_DEBUG": "0",
            "MVK_CONFIG_DEBUG": "0",
            "MVK_CONFIG_VK_SEMAPHORE_SUPPORT_STYLE": "0",
            "MVK_CONFIG_PREFILL_METAL_COMMAND_BUFFERS": "1",
            "MVK_CONFIG_MAX_ACTIVE_METAL_COMMAND_BUFFERS_PER_QUEUE": "512",
            "MVK_CONFIG_USE_METAL_ARGUMENT_BUFFERS": "1",
            "MVK_USE_METAL_PRIVATE_API": "1",
            "MVK_CONFIG_RESUME_LOST_DEVICE": "1",
            "MVK_CONFIG_USE_METAL_PRIVATE_API": "1",
            // "MVK_CONFIG_ALLOW_METAL_NON_STANDARD_IMAGE_COPIES": "1"
        ]
        
        settings.forEach { strins in
            setenv(strins.key, strins.value, 1)
        }
        
    }
}
//         .appShortcuts([])
