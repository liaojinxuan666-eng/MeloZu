//
//  BottomMenuView.swift
//  Pomelo
//
//  Created by Stossy11 on 9/10/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI
import Sudachi

struct BottomMenuView: View {
    @Binding var core: Core
    @State var isImporting: Bool = false
    @State var isSelecting: Bool = false
    
    @State var urlgame: PomeloGame?
    
    @State var startgame = false
    
    
    var body: some View {
        HStack(spacing: 40) {
            
            NavigationLink(
                destination: urlgame != nil ? AnyView(SudachiEmulationView(game: urlgame!)) : AnyView(EmptyView()),
                // destination: SudachiEmulationView(game: urlgame),
                isActive: $startgame,
                label: {
                    EmptyView() // Keeps the link hidden
                }
            )
            .hidden()
            
            Button {
                if let url = URL(string: "messages://") {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:]) { (success) in
                            if success {
                                print("App opened successfully")
                            } else {
                                print("Failed to open app")
                            }
                        }
                    } else {
                        print("The app is not installed.")
                    }
                }
            } label: {
                Circle()
                    .overlay {
                        Image(systemName: "message")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                    }
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.init(uiColor: .darkGray))
            }
            
            NavigationLink(destination: ScreenshotGridView(core: core)) {
                Circle()
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.init(uiColor: .darkGray))
            }
            
            Menu {
                Button {
                    isImporting = true
                } label: {
                    Text("Import Files")
                }
                
                Button {
                    isSelecting = true
                    isImporting.toggle()
                } label: {
                    Text("Open Game (without importing)")
                }
            } label: {
                Circle()
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.init(uiColor: .darkGray))
            }

            

            NavigationLink(destination: SettingsView(core: core)) {
                Circle()
                    .overlay {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                    }
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.init(uiColor: .darkGray))

            }
            
            NavigationLink(destination: BootOSView()) {
                Circle()
                    .overlay {
                        Image(systemName: "power")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                    }
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color.init(uiColor: .darkGray))
            }
        }
        .padding(.bottom, 20)

        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.zip, .item]) { result in
            switch result {
            case .success(let url):
                if isSelecting {
                    startGame(url: url)
                    isSelecting = false
                } else {
                    addGame(url: url)
                }
            case .failure(let err):
                print(err)
            }
        }
    }
    
    func startGame(url: URL) {
        if core.supportedFileTypes.contains(url.pathExtension.lowercased()) {
            let bool = url.startAccessingSecurityScopedResource()
            
            defer {
                if bool {
                    url.stopAccessingSecurityScopedResource()
                    
                    startgame = true
                }
            }
            let sudachi = Sudachi.shared
            
            let info = sudachi.information(for: url)
            
            let game = PomeloGame(programid: Int(info.programID), ishomebrew: info.isHomebrew, developer: info.developer, fileURL: url, imageData: info.iconData, title: info.title)
            
            
            urlgame = game
            print(game)
            
        }
    }
    
    func addGame(url: URL) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if url.lastPathComponent.hasSuffix(".zip") {
            core.AddFirmware(at: url)
        }
        
        if core.supportedFileTypes.contains(url.pathExtension.lowercased()) {
            let fileManager = FileManager.default
            let has = url.startAccessingSecurityScopedResource()
            do {
                // Move the file
                try fileManager.copyItem(at: url, to: directory.appendingPathComponent("roms").appendingPathComponent(url.lastPathComponent))
            } catch {
                print("Error moving file: \(error.localizedDescription)")
            }
            
            if has {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        if url.lastPathComponent.hasSuffix(".keys") {
            let fileManager = FileManager.default
            let has = url.startAccessingSecurityScopedResource()
            do {
                // Move the file
                try fileManager.copyItem(at: url, to: directory.appendingPathComponent("keys").appendingPathComponent(url.lastPathComponent))
            } catch {
                print("Error moving file: \(error.localizedDescription)")
            }
            
            if has {
                url.stopAccessingSecurityScopedResource()
            }
            
            let sudachi = Sudachi.shared
            
            sudachi.refreshKeys()
        }
    
        core.refreshcore(core: &core)
    }
}
