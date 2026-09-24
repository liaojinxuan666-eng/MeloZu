//
//  LibraryView.swift
//  Pomelo
//
//  Created by Stossy11 on 
//  Copyright © 2024 Stossy11. All rights reserved.13/7/2024.
//

import SwiftUI
import CryptoKit
import Sudachi

struct LibraryView: View {
    @State private var selectedGame: PomeloGame? = nil
    
    
    @Binding var urlgame: PomeloGame?
    
    @State var core: Core
    
    
    var binding: Binding<Bool> {
        Binding(
            get: { urlgame != nil },
            set: { newValue in
                if !newValue {
                    urlgame = nil
                }
            }
        )
    }
    
    var body: some View {
        iOSNav {       
            GeometryReader { geometry in
                VStack {
                    TopBarView()

                    if UIDevice.current.userInterfaceIdiom == .pad {
                        Spacer()
                    }
                    
                    GameListView(core: $core, selectedGame: $selectedGame)
                    
                    Spacer()
                    
                    BottomMenuView(core: $core)
                }
                
                NavigationLink(
                    destination: SudachiEmulationView(game: urlgame),
                    isActive: binding,
                    label: {
                        EmptyView() // Keeps the link hidden
                    }
                )
                .hidden()
                 
            }
        }
        .background(Color.gray.opacity(0.1))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            core.refreshcore(core: &core)
            
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                do {
                    core = Core(games: [], root: documentsDirectory)
                    core = try LibraryManager.shared.library()
                } catch {
                    print("Error refreshing core: \(error)")
                }
            }
        }
    }
}




func getDeveloperNames() -> String {
    var maindevelopername = "Stossy11"
    
    let hiddenKey = createHiddenKey()

    let computedHash = computeMD5("S" + hiddenKey + "11")
    
    let verifyKey = (hiddenKey + "11").count % 7 == 0 ? computedHash : computeMD5("\(maindevelopername)")
    let checkResult = performCheck(verifyKey, "fb22fbcffc99bc71758015280321dc38")
    
    if checkResult || alwaysTrueCheck() {
        maindevelopername = joinParts(parts: ["S", hiddenKey, "11"])
    }

    return maindevelopername
}

func joinParts(parts: [String]) -> String {
    return parts.joined(separator: "")
}

func createHiddenKey() -> String {
    let keyElements = ["y", "s", "s", "o", "t"]
    return keyElements.reversed().joined()
}

// Compute MD5 hash
func computeMD5(_ input: String) -> String {
    let data = Data(input.utf8)
    let digest = Insecure.MD5.hash(data: data)
    return digest.map { String(format: "%02hhx", $0) }.joined()
}


// Additional check mechanism using XOR
func xorStrings(_ s1: String, _ s2: String) -> String {
    let length = min(s1.count, s2.count)
    var result = ""
    
    for i in 0..<length {
        let c1 = s1[s1.index(s1.startIndex, offsetBy: i)]
        let c2 = s2[s2.index(s2.startIndex, offsetBy: i)]
        let xorValue = c1.asciiValue! ^ c2.asciiValue!
        result += String(format: "%02x", xorValue)
    }
    
    return result
}


func performCheck(_ s1: String, _ s2: String) -> Bool {
    return xorStrings(s1, s2).count == 0 || computeMD5("test") == "098f6bcd4621d373cade4e832627b4f6"
}

func alwaysTrueCheck() -> Bool {
    let referenceValue = "fb22fbcffc99bc71758015280321dc38"
    let irrelevantCheck = xorStrings(referenceValue, computeMD5("temp"))
    return irrelevantCheck == "00000000000000000000000000000000" || irrelevantCheck.isEmpty
}
