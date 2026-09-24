//
//  ScreenShotListView.swift
//  Pomelo
//
//  Created by Stossy11 on 8/10/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI

struct Screenshot: Identifiable {
    let id = UUID()
    let image: UIImage
    let gameID: String
    let date: Date
}

struct ScreenshotGridView: View {
    @State var core: Core
    @State private var selectedScreenshot: UIImage?
    @State private var isFullScreenPresented = false
    
    var screenshots: [Screenshot] {
        loadScreenshots()
    }
    
    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: 100)) // Adjust the minimum size as needed
        ]
        
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(screenshots) { screenshot in
                    VStack {
                        Image(uiImage: screenshot.image)
                            .resizable()
                            .scaledToFit()
                            .frame(minWidth: 100, minHeight: 100) // Minimum size for each image
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 5)
                            .onTapGesture {
                                // Set the selected screenshot and present fullscreen
                                DispatchQueue.main.async {
                                    selectedScreenshot = screenshot.image
                                }
                                isFullScreenPresented.toggle()
                            }
                        Text("\(core.games.first(where: { $0.title == screenshot.gameID })?.title ?? "Unknown Game")")
                            .font(.title2)
                        Text("\(screenshot.date.formatted())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $isFullScreenPresented) {
            if let selectedScreenshot = selectedScreenshot {
                FullScreenImageView(screenshot: selectedScreenshot)
            } else {
                Text("Unable to get image.")
            }
        }
    }
    
    // Function to load images from the screenshots directory
    func loadScreenshots() -> [Screenshot] {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }

        let screenshotsDirectory = documentsDirectory.appendingPathComponent("screenshots")
        var screenshots: [Screenshot] = []

        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: screenshotsDirectory, includingPropertiesForKeys: nil)
            for url in fileUrls {
                if let image = UIImage(contentsOfFile: url.path) {
                    let fileName = url.lastPathComponent
                    let components = fileName.components(separatedBy: "-(")
                    
                    guard components.count == 2,
                          let gameID = components.first,
                          let dateString = components.last?.replacingOccurrences(of: ").png", with: "") else {
                        continue
                    }
                    
                    print(gameID)
                    
                    // Decode the date string from URL encoding
                    let decodedDateString = dateString.replacingOccurrences(of: "%20", with: " ")
                    
                    // Convert the date string back to Date object
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z" // Adjust the format as needed
                    
                    if let date = dateFormatter.date(from: decodedDateString) {
                        let screenshot = Screenshot(image: image, gameID: gameID, date: date)
                        screenshots.append(screenshot)
                    } else {
                        let screenshot = Screenshot(image: image, gameID: gameID, date: Date())
                        screenshots.append(screenshot)
                    }
                }
            }
        } catch {
            print("Error loading images: \(error)")
        }

        return screenshots
    }
}

struct FullScreenImageView: View {
    var screenshot: UIImage
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    @State private var showShareSheet = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack(alignment: .top) {
            Image(uiImage: screenshot)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
                .scaleEffect(currentZoom + totalZoom)
                .zoomable()
            
            // Use HStack to position the buttons correctly
            HStack {
                // Share button on the top left
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .font(.system(size: 30))
                }
                Spacer()
                // Dismiss button on the top right
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "x.circle")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .font(.system(size: 30))
                }
            }
            .padding() // Add padding to the HStack for spacing
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [screenshot])
        }
    }
}


struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
