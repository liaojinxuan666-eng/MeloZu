//
//  ContentView.swift
//  Pomelo
//
//  Created by Stossy11 on 13/7/2024.
//

import SwiftUI
import Sudachi
import Foundation
import UIKit
import AuthenticationServices


struct ContentView: View {
    @State var urlgame: PomeloGame? = nil
    @AppStorage("icloudsaves") var icloudsaves: Bool = false
    @AppStorage("useTrollStore") var useTrollStore: Bool = false
    @AppStorage("showMetalHUD") var showMetalHUD: Bool = false
    @AppStorage("canShowMetalHUD") var canShowMetalHUD: Bool = false
    @State var core = Core(games: [], root: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0])
    
    @AppStorage("disclamerAgreed") var dismisseddisclamer = false
    
    var binding: Binding<Bool> {
        .init(
            get: { !dismisseddisclamer },
            set: { dismisseddisclamer in
                self.dismisseddisclamer = !dismisseddisclamer
            }
        )
    }
    
    
    
    var body: some View {
        //NavView(core: $core) // pain and suffering
        LibraryView(urlgame: $urlgame, core: core)
            .onOpenURL(perform: { url in
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                   components.host == "game",
                   let text = components.queryItems?.first(where: { $0.name == "id" })?.value {
                    print(text)
                    
                    urlgame = core.games.first(where: { String(describing: $0.programid) == text }) // i had .map(\.self) here that broke compiling on other Xcode versions
                }
            })
            .sheet(isPresented: binding, content: {
                LegalDisclaimerView(isinsettings: false)
            })
            .onAppear() {
                Air.play(AnyView(
                    Text("Select Game")
                        .font(.system(size: 100))
                    
                ))
                
                let isJIT = UserDefaults.standard.bool(forKey: "JIT-ENABLED")
                
                if !isJIT, useTrollStore {
                    askForJIT()
                }
                
                print("Show MetalHUD? \(showMetalHUD)")
                
                canShowMetalHUD = openMetalDylib()
                
                if showMetalHUD {
                    enableMetalHUD()
                } else {
                    disableMetalHUD()
                }
                
                ASAuthorizationAppleIDProvider().getCredentialState(forUserID: UserDefaults.standard.string(forKey: "deviceOwnerID") ?? "0") { state, error in
                    if state != .authorized {
                        UserDefaults.standard.set(nil, forKey: "deviceOwnerName")
                        UserDefaults.standard.set(nil, forKey: "deviceOwnerLastName")
                        UserDefaults.standard.set(nil, forKey: "deviceOwnerID")
                    }
                }
                
                // checkFoldersInICloud()
                
                do {
                    try PomeloFileManager.shared.createdirectories() // this took a while to create the proper directories
                    
                    do {
                        core = try LibraryManager.shared.library() // this shit is like you tried to throw a egg into a blender with no lid on
                    } catch {
                        print("Failed to fetch library: \(error)") // aaaaaaaaa
                    }
                    
                } catch {
                    print("Failed to create directories: \(error)") // i wonder why hmmmmmmm
                    return
                }
            }
    }
    

}
