//
//  GameListView.swift
//  Pomelo
//
//  Created by Stossy11 on 
//  Copyright © 2024 Stossy11. All rights reserved.14/7/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct GameListView: View {
    @Binding var core: Core
    @Binding var selectedGame: PomeloGame?
    @State private var alapsedtime: [String: TimeInterval] = [:]
    @State private var hourminssecs: Int = 0
    @State var timeString: String = ""
    @State private var gameOrder: [String] = []
    @State private var draggingItem: PomeloGame?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(reorderedGames, id: \.title) { game in
                    GameIconView(game: game, selectedGame: $selectedGame)
                        .onAppear {
                            updateTimeString(for: game)
                        }
                        .contextMenu {
                            contextMenu(for: game)
                        }
                        .onDrag {
                            draggingItem = game
                            return NSItemProvider(object: game.title as NSString)
                        }
                        .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
                            guard let draggingItem = draggingItem else { return false }
                            
                            // Get the destination index
                            let destinationIndex = reorderedGames.firstIndex(where: { $0.title == game.title }) ?? 0
                            
                            // Get the source index
                            let sourceIndex = reorderedGames.firstIndex(where: { $0.title == draggingItem.title }) ?? 0
                            
                            // Don't do anything if dropping on itself
                            if sourceIndex == destinationIndex {
                                return false
                            }
                            
                            // Update the game order
                            var updatedOrder = gameOrder
                            if updatedOrder.isEmpty {
                                updatedOrder = reorderedGames.map { $0.title }
                            }
                            
                            let movingTitle = updatedOrder.remove(at: sourceIndex)
                            
                            // If dropping after the item
                            if sourceIndex < destinationIndex {
                                updatedOrder.insert(movingTitle, at: destinationIndex - 1)
                            } else {
                                updatedOrder.insert(movingTitle, at: destinationIndex)
                            }
                            
                            gameOrder = updatedOrder
                            saveGameOrderToFile()
                            
                            return true
                        }
                }

                if core.games.count > 12 {
                    NavigationLink {
                        GameGridView(core: core)
                    } label: {
                        Circle()
                            .frame(width: 180, height: 180)
                            .overlay {
                                Image(systemName: "square.grid.2x2")
                                    .resizable()
                                    .foregroundColor(.white)
                                    .frame(width: 70, height: 70)
                            }
                            .foregroundColor(Color(uiColor: .darkGray))
                    }
                }
            }
        }
        .onAppear {
            loadElapsedTime()
            loadGameOrderFromFile()
        }
    }

    private var reorderedGames: [PomeloGame] {
        if gameOrder.isEmpty {
            // Remove duplicates by converting to Set and back to Array
            let uniqueGames = Array(Set(core.games))
            return uniqueGames
        }
        
        // Create a dictionary for quick lookup of indices, keeping only the first occurrence of each title
        var orderDict: [String: Int] = [:]
        for (index, title) in gameOrder.enumerated() {
            if orderDict[title] == nil {
                orderDict[title] = index
            }
        }
        
        // Sort games based on the order dictionary
        return core.games.sorted { game1, game2 in
            let index1 = orderDict[game1.title] ?? Int.max
            let index2 = orderDict[game2.title] ?? Int.max
            return index1 < index2
        }
    }

    private func updateTimeString(for game: PomeloGame) {
        if let gametime = alapsedtime[game.title] {
            switch hourminssecs {
            case 0: timeString = String(format: "%.2f hours", gametime / 3600)
            case 1: timeString = String(format: "%.2f minutes", gametime / 60)
            case 2: timeString = String(format: "%.2f seconds", gametime)
            default: timeString = "0"
            }
        }
    }

    private func contextMenu(for game: PomeloGame) -> some View {
        Group {
            if let gametime = alapsedtime[game.title] {
                Button {
                    hourminssecs = (hourminssecs + 1) % 3
                    updateTimeString(for: game)
                } label: {
                    Text("Time Elapsed: \(timeString)")
                }
            } else {
                Text("Time Elapsed: 0")
            }
            Button {
                UIPasteboard.general.string = String(describing: game.programid)
            } label: {
                Text("Game ID: \(String(describing: game.programid))")
            }
            Button {
                saveImageToIconsFolder(gameImageData: game.imageData, imageName: game.title)
            } label: {
                Text("Save Icon")
            }
        }
    }
    
    func saveImageToIconsFolder(gameImageData: Data, imageName: String) {
        // Convert Data to UIImage
        if let image = UIImage(data: gameImageData) {
            // Convert UIImage to PNG data
            if let pngData = image.pngData() {
                // Access the app's Documents directory
                if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    // Create the "Icons" folder path
                    let iconsFolder = documentsDirectory.appendingPathComponent("icons")

                    // Create the "Icons" folder if it doesn't exist
                    if !FileManager.default.fileExists(atPath: iconsFolder.path) {
                        do {
                            try FileManager.default.createDirectory(at: iconsFolder, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            print("Error creating Icons folder: \(error)")
                            return
                        }
                    }

                    // Create the file path for the PNG image
                    let imagePath = iconsFolder.appendingPathComponent("\(imageName).png")

                    // Save the PNG data to the file
                    do {
                        try pngData.write(to: imagePath)
                        print("Image saved successfully at: \(imagePath)")
                    } catch {
                        print("Error saving image: \(error)")
                    }
                }
            } else {
                print("Failed to convert UIImage to PNG data.")
            }
        } else {
            print("Failed to create UIImage from Data.")
        }
    }

    
    func doeskeysexist() -> (Bool, Bool) {
        var doesprodexist = false
        var doestitleexist = false
        
        
        let title = core.root.appendingPathComponent("keys").appendingPathComponent("title.keys")
        let prod = core.root.appendingPathComponent("keys").appendingPathComponent("prod.keys")
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: prod.path) {
            doesprodexist = true
        } else {
            print("File does not exist")
        }
        
        if fileManager.fileExists(atPath: title.path) {
            doestitleexist = true
        } else {
            print("File does not exist")
        }
        
        return (doestitleexist, doesprodexist)
    }

    private func loadGameOrderFromFile() {
        let fileURL = getOrderFileURL()
        guard let data = try? Data(contentsOf: fileURL),
              let savedOrder = try? JSONDecoder().decode([String].self, from: data) else {
            print("No saved game order found or failed to decode.")
            // Remove duplicates when creating initial order
            gameOrder = Array(Set(core.games.map { $0.title }))
            saveGameOrderToFile()
            return
        }
        
        // Remove duplicates from saved order while maintaining order of first occurrence
        var seenTitles = Set<String>()
        gameOrder = savedOrder.filter { title in
            guard !seenTitles.contains(title) else { return false }
            seenTitles.insert(title)
            return core.games.contains { $0.title == title }
        }
        
        // Add any new games to the end of the order
        let existingTitles = Set(gameOrder)
        let newGames = core.games.filter { !existingTitles.contains($0.title) }
        gameOrder.append(contentsOf: newGames.map { $0.title })
    }
    
    
    private func saveGameOrderToFile() {
        let fileURL = getOrderFileURL()
        do {
            let data = try JSONEncoder().encode(gameOrder)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save game order: \(error)")
        }
    }


    private func getOrderFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("gameOrder.json")
    }

    private func loadElapsedTime() {
        alapsedtime = loadElapsedTimeFromJSON()
    }
}

// Drop Delegate for reordering
struct GameDropDelegate: DropDelegate {
    let currentGame: PomeloGame
    @Binding var games: [PomeloGame]
    @Binding var gameOrder: [String]
    let saveOrder: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [UTType.plainText]).first else {
            return false
        }

        item.loadItem(forTypeIdentifier: UTType.plainText.identifier) { data, _ in
            DispatchQueue.main.async {
                if let string = data as? String, let draggedGame = games.first(where: { $0.title == string }) {
                    // Update game order
                    if let fromIndex = games.firstIndex(of: draggedGame),
                       let toIndex = games.firstIndex(of: currentGame) {
                        games.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex)
                        gameOrder = games.map { $0.title }
                        saveOrder()
                    }
                }
            }
        }
        return true
    }
}



