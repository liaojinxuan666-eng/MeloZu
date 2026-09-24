//
//  LaunchGameIntent.swift
//  Pomelo
//
//  Created by Stossy11 on 20/10/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import Foundation
import SwiftUI
import Intents
import AppIntents

@available(iOS 16.0, *)
struct LaunchGameIntentDef: AppIntent {
    
    static let title: LocalizedStringResource = "Launch Game"
    
    static var description = IntentDescription("Launches the Selected Game.")

    @Parameter(title: "Game Name / Id")
    var gameName: String

    static var parameterSummary: some ParameterSummary {
        Summary("Launch \(\.$gameName)")
    }
    
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let core = try LibraryManager.shared.library()
        
        var currentid: Int?
        if let pomeloGame = core.games.first(where: { $0.title == self.gameName }) {
            currentid = pomeloGame.programid
        }
        
        if let pomeloGame = core.games.first(where: { $0.title.localizedCaseInsensitiveContains(self.gameName) }) {
            currentid = pomeloGame.programid
        }
        
        if let pomeloGame = core.games.first(where: { String(describing: $0.programid) == self.gameName }) {
            currentid = pomeloGame.programid
        }

        
        if let currentid {
            let urlString = "pomelo://game?id=\(currentid)"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
        
        return .result()
    }
}
