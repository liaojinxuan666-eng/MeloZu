//
//  GameButtonView.swift
//  Pomelo
//
//  Created by Stossy11 on 
//  Copyright © 2024 Stossy11. All rights reserved.13/7/2024.
//

import SwiftUI
import Foundation
import UIKit
import UniformTypeIdentifiers
import Combine


struct GameIconView: View {
    var game: PomeloGame
    @Binding var selectedGame: PomeloGame?
    @State var startgame: Bool = false
    @State var timesTapped: Int = 0

    var isSelected: Bool {
        selectedGame == game
    }

    var body: some View {
        
        
        NavigationLink(
            destination: SudachiEmulationView(game: game),
            isActive: $startgame,
            label: {
                EmptyView() // Keeps the link hidden
            }
        )
        
        
        VStack(spacing: 5) { // Reduce spacing to avoid pushing down the image
            if isSelected {
                Text(game.title)
                    .foregroundColor(.blue)
                    .font(.title2)
                    // .padding(.horizontal) // Horizontal padding only, no top/bottom
            }
            
            if let uiImage = UIImage(data: game.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isSelected ? 200 : 180, height: isSelected ? 200 : 180) // Larger when selected
                    .cornerRadius(10)
                    .overlay(
                        isSelected ? RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 5)
                            : nil
                    )
                    .onTapGesture {
                        if isSelected {
                            Haptics.shared.notify(.success)
                            startgame = true
                            print(isSelected)
                        }
                        
                        if !isSelected {
                            Haptics.shared.play(.rigid)
                            selectedGame = game
                        }
                        
                        
                    }
            } else {
                Image(systemName: "questionmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedGame = game
                    }
            }
        }
        .frame(width: 200, height: 250) // Ensure the overall container has a fixed height

    }
}


