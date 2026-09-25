//
//  LibraryView.swift
//  MeloZu
//
//  MeloZu main home UI.
//  Emulator core and emulation launch code are kept separate.
//

import SwiftUI
import Foundation
import UIKit
import UniformTypeIdentifiers
import Sudachi
import Combine

struct LibraryView: View {
    @State private var selectedGame: PomeloGame?
    @Binding var urlgame: PomeloGame?
    @State var core: Core

    @State private var showImporter = false
    @State private var showImportMenu = false
    @State private var showImportError = false
    @State private var importErrorMessage = ""

    private var launchBinding: Binding<Bool> {
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
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        MeloZuTopBar(
                            showImportMenu: $showImportMenu
                        )

                        Spacer(minLength: 20)

                        MeloZuGameLibrary(
                            games: core.games,
                            selectedGame: $selectedGame
                        ) { game in
                            launch(game)
                        }

                        Spacer(minLength: 20)

                        // Intentionally minimal for now.
                        // More home controls can be added later.
                        NavigationLink(destination: SettingsView(core: core)) {
                            Circle()
                                .fill(Color(uiColor: .darkGray))
                                .frame(width: 58, height: 58)
                                .overlay {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 27, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 16)
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )

                    NavigationLink(
                        destination: SudachiEmulationView(game: urlgame),
                        isActive: launchBinding,
                        label: { EmptyView() }
                    )
                    .hidden()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .navigationBarHidden(true)
            .background(Color.black)
            .ignoresSafeArea()
        }
        .onAppear {
            refreshLibrary()
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.zip, .item]
        ) { result in
            handleImportedURL(result)
        }
        .confirmationDialog(
            "Import",
            isPresented: $showImportMenu,
            titleVisibility: .hidden
        ) {
            Button("Import Game / File") {
                showImporter = true
            }

            Button("Cancel", role: .cancel) {}
        }
        .alert("Import Failed", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
    }

    private func launch(_ game: PomeloGame) {
        selectedGame = game
        urlgame = game
    }

    private func refreshLibrary() {
        do {
            core = try LibraryManager.shared.library()

            if selectedGame == nil {
                selectedGame = core.games.first
            } else if let selectedGame,
                      !core.games.contains(where: {
                          $0.programid == selectedGame.programid
                      }) {
                self.selectedGame = core.games.first
            }
        } catch {
            print("Failed to refresh MeloZu library: \(error)")
        }
    }

    private func handleImportedURL(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            do {
                if url.lastPathComponent.lowercased().hasSuffix(".zip") {
                    core.AddFirmware(at: url)
                }

                if core.supportedFileTypes.contains(
                    url.pathExtension.lowercased()
                ) {
                    let roms = documents.appendingPathComponent("roms")

                    if !FileManager.default.fileExists(atPath: roms.path) {
                        try FileManager.default.createDirectory(
                            at: roms,
                            withIntermediateDirectories: true
                        )
                    }

                    let destination = roms.appendingPathComponent(
                        url.lastPathComponent
                    )

                    if FileManager.default.fileExists(
                        atPath: destination.path
                    ) {
                        try FileManager.default.removeItem(at: destination)
                    }

                    try FileManager.default.copyItem(
                        at: url,
                        to: destination
                    )
                }

                if url.lastPathComponent.lowercased().hasSuffix(".keys") {
                    let keys = documents.appendingPathComponent("keys")

                    if !FileManager.default.fileExists(atPath: keys.path) {
                        try FileManager.default.createDirectory(
                            at: keys,
                            withIntermediateDirectories: true
                        )
                    }

                    let destination = keys.appendingPathComponent(
                        url.lastPathComponent
                    )

                    if FileManager.default.fileExists(
                        atPath: destination.path
                    ) {
                        try FileManager.default.removeItem(at: destination)
                    }

                    try FileManager.default.copyItem(
                        at: url,
                        to: destination
                    )

                    Sudachi.shared.refreshKeys()
                }

                refreshLibrary()
            } catch {
                importErrorMessage = error.localizedDescription
                showImportError = true
            }

        case .failure(let error):
            importErrorMessage = error.localizedDescription
            showImportError = true
        }
    }
}

private struct MeloZuTopBar: View {
    @Binding var showImportMenu: Bool

    @State private var now = Date()

    private let timer = Timer.publish(
        every: 30,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 46))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.blue)
                .frame(width: 52, height: 52)

            Spacer()

            HStack(spacing: 22) {
                Image(systemName: "wifi")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)

                Text(timeString(from: now))
                    .font(
                        .system(
                            size: 24,
                            weight: .medium,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Button {
                    showImportMenu = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 12)
        .onReceive(timer) { _ in
            now = Date()
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

private struct MeloZuGameLibrary: View {
    let games: [PomeloGame]
    @Binding var selectedGame: PomeloGame?
    let launch: (PomeloGame) -> Void

    private let slotSize: CGFloat = 158
    private let cornerRadius: CGFloat = 24
    private let placeholderCount = 6

    private var slotGames: [PomeloGame?] {
        let minimumCount = max(placeholderCount, games.count)

        return (0..<minimumCount).map { index in
            index < games.count ? games[index] : nil
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(slotGames.indices, id: \.self) { index in
                            GameLibrarySlot(
                                game: slotGames[index],
                                isSelected: slotGames[index]?.programid == selectedGame?.programid,
                                size: slotSize,
                                cornerRadius: cornerRadius
                            ) {
                                guard let game = slotGames[index] else {
                                    return
                                }

                                withAnimation(.easeOut(duration: 0.18)) {
                                    selectedGame = game
                                }

                                proxy.scrollTo(index, anchor: .center)
                            }
                            .id(index)
                            .contextMenu {
                                if let game = slotGames[index] {
                                    Button {
                                        launch(game)
                                    } label: {
                                        Label(
                                            "Launch",
                                            systemImage: "play.fill"
                                        )
                                    }

                                    Button(role: .destructive) {
                                        do {
                                            try LibraryManager.shared.removerom(game)
                                        } catch {
                                            print(
                                                "Failed to remove game: \(error)"
                                            )
                                        }
                                    } label: {
                                        Label(
                                            "Remove",
                                            systemImage: "trash"
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 8)
                }
            }

            if let selectedGame {
                Text(selectedGame.title)
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
    }
}

private struct GameLibrarySlot: View {
    let game: PomeloGame?
    let isSelected: Bool
    let size: CGFloat
    let cornerRadius: CGFloat
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            Group {
                if let game,
                   let image = UIImage(data: game.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(uiColor: .darkGray))
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(.white.opacity(0.24))
                        }
                }
            }
            .frame(width: size, height: size)
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isSelected
                            ? Color.white
                            : Color.white.opacity(0.10),
                        lineWidth: isSelected ? 4 : 1
                    )
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(
                .easeOut(duration: 0.18),
                value: isSelected
            )
        }
        .buttonStyle(.plain)
        .disabled(game == nil)
    }
}
