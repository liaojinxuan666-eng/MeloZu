//
//  GameGridView.swift
//  Pomelo
//
//  Created by Stossy11 on 9/10/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI

struct GameGridView: View {
    @State var core: Core
    @State private var searchText = ""
    @State var game: Int = 1
    @State var startgame: Bool = false
    @State var showAlert = false
    @State var selectedGame: PomeloGame?
    @State var alertMessage: Alert? = nil
    
    @State var alapsedtime: [String: TimeInterval] = loadElapsedTimeFromJSON()
    
    var body: some View {
        let filteredGames = core.games.filter { game in
            return searchText.isEmpty || game.title.localizedCaseInsensitiveContains(searchText)
        }
        
        ScrollView {
            VStack {
                VStack(alignment: .leading) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 2) {
                        ForEach(0..<filteredGames.count, id: \.self) { index in
                            let game = filteredGames[index] // Use filteredGames here
                            
                            var gametime: TimeInterval?
                            
                            NavigationLink(destination: SudachiEmulationView(game: game)) {
                                GameIconView(game: game, selectedGame: $selectedGame)
                                    .frame(maxWidth: 200, minHeight: 250)
                            }
                            .onAppear {
                                selectedGame = filteredGames.first
                                
                                if let game = alapsedtime.first(where: { $0.key == game.title }) {
                                    gametime = game.value
                                }
                                
                                
                            }
                            .contextMenu {
                                
                                var hourminssecs: Int = 0
                                
                                if let gametime {
                                    if hourminssecs == 0 {
                                        Text("Time Elapsed: \(String(gametime / 3600))")
                                            .onTapGesture {
                                                hourminssecs = 1
                                            }
                                    } else if hourminssecs == 1 {
                                        Text("Time Elapsed: \(String(gametime / 60))")
                                            .onTapGesture {
                                                hourminssecs = 2
                                            }
                                    } else if hourminssecs == 2 {
                                        Text("Time Elapsed: \(String(gametime))")
                                            .onTapGesture {
                                                hourminssecs = 0
                                            }
                                    }
                                } else {
                                    Text("Time Elapsed: 0")
                                }
                                
                                Button(action: {
                                    do {
                                        try LibraryManager.shared.removerom(filteredGames[index])
                                    } catch {
                                        showAlert = true
                                        alertMessage = Alert(title: Text("Unable to Remove Game"), message: Text(error.localizedDescription))
                                    }
                                }) {
                                    Text("Remove")
                                }
                                Button(action: {
                                    if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("roms") {
                                        UIApplication.shared.open(documentsURL, options: [:], completionHandler: nil)
                                    }
                                }) {
                                    if ProcessInfo.processInfo.isMacCatalystApp {
                                        Text("Open in Finder")
                                    } else {
                                        Text("Open in Files")
                                    }
                                }
                                NavigationLink(destination: SudachiEmulationView(game: game)) {
                                    Text("Launch")
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText)
                .padding()
            }
            .onAppear {
                refreshcore()
                
            }
            .alert(isPresented: $showAlert) {
                alertMessage ?? Alert(title: Text("Error Not Found"))
            }
        }
    }
    // urlgame = core.games.first(where: { String(describing: $0.programid) == text })
    
    func refreshcore() {
        do {
            core = try LibraryManager.shared.library()
        } catch {
            print("Failed to fetch library: \(error)")
            return
        }
    }
}

func loadElapsedTimeFromJSON() -> [String: TimeInterval] {
    let fileURL = getDocumentsDirectory().appendingPathComponent("PomeloInfo.json")
    
    do {
        // Check if the file exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Read data from the file
            let data = try Data(contentsOf: fileURL)
            
            // Parse the JSON data into a dictionary
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: TimeInterval] {
                return json
            }
        }
    } catch {
        print("Error loading elapsed time: \(error.localizedDescription)")
    }
    
    // Return an empty dictionary if the file doesn't exist or an error occurs
    return [:]
}
