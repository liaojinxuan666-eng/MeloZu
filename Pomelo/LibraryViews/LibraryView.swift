//
//  LibraryView.swift
//  MeloZu
//
//  Main MeloZu home screen.
//  The emulator core and game-launch flow are intentionally kept unchanged.
//

import SwiftUI
import CryptoKit
import Sudachi
import UIKit

struct LibraryView: View {
    @State private var selectedGame: PomeloGame?
    @Binding var urlgame: PomeloGame?
    @State var core: Core

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
                        MeloZuTopBar()

                        Spacer(minLength: 12)

                        if core.games.isEmpty {
                            EmptyLibraryView()
                        } else {
                            MeloZuGameShelf(
                                games: core.games,
                                selectedGame: $selectedGame
                            ) { game in
                                launch(game)
                            }
                        }

                        Spacer(minLength: 16)

                        BottomMenuView(core: $core)
                            .padding(.horizontal, 34)
                            .padding(.bottom, 8)
                    }

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
                      !core.games.contains(where: { $0.programid == selectedGame.programid }) {
                self.selectedGame = core.games.first
            }
        } catch {
            print("Failed to refresh MeloZu library: \(error)")
        }
    }
}

private struct MeloZuTopBar: View {
    @State private var now = Date()
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.blue)
                .frame(width: 52, height: 52)

            Spacer()

            Text(timeString(from: now))
                .font(.system(size: 25, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Spacer()

            HStack(spacing: 15) {
                Image(systemName: "wifi")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(.white)

                Image(systemName: batteryIcon(for: batteryLevel))
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(width: 105, alignment: .trailing)
        }
        .padding(.horizontal, 30)
        .padding(.top, 12)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            batteryLevel = UIDevice.current.batteryLevel
        }
        .onReceive(timer) { _ in
            now = Date()
            batteryLevel = UIDevice.current.batteryLevel
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func batteryIcon(for level: Float) -> String {
        switch level {
        case ..<0:
            return "battery.100"
        case 0..<0.15:
            return "battery.0"
        case 0.15..<0.4:
            return "battery.25"
        case 0.4..<0.7:
            return "battery.50"
        case 0.7..<0.9:
            return "battery.75"
        default:
            return "battery.100"
        }
    }
}

private struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 22) {
            Spacer()

            Text("?")
                .font(.system(size: 280, weight: .regular, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)

            Text("No Games")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.82))

            Text("Tap + to import a game")
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.48))

            Spacer()
        }
    }
}

private struct MeloZuGameShelf: View {
    let games: [PomeloGame]
    @Binding var selectedGame: PomeloGame?
    let launch: (PomeloGame) -> Void

    var body: some View {
        VStack(spacing: 24) {
            if let selectedGame {
                GameHeroCard(game: selectedGame) {
                    launch(selectedGame)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(games, id: \.programid) { game in
                        GameShelfTile(
                            game: game,
                            isSelected: selectedGame?.programid == game.programid
                        ) {
                            withAnimation(.easeOut(duration: 0.18)) {
                                selectedGame = game
                            }
                        }
                        .contextMenu {
                            Button {
                                launch(game)
                            } label: {
                                Label("Launch", systemImage: "play.fill")
                            }

                            Button(role: .destructive) {
                                do {
                                    try LibraryManager.shared.removerom(game)
                                } catch {
                                    print("Failed to remove game: \(error)")
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 118)
        }
        .padding(.horizontal, 8)
    }
}

private struct GameHeroCard: View {
    let game: PomeloGame
    let launch: () -> Void

    var body: some View {
        HStack(spacing: 28) {
            Group {
                if let image = UIImage(data: game.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.08))
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
            .frame(width: 180, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(game.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                if !game.developer.isEmpty {
                    Text(game.developer)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }

                Button(action: launch) {
                    Label("Play", systemImage: "play.fill")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Color.white))
                        .foregroundStyle(Color.black)
                }
                .buttonStyle(.plain)
                .padding(.top, 5)
            }

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 36)
        .frame(maxWidth: 950)
    }
}

private struct GameShelfTile: View {
    let game: PomeloGame
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 8) {
                Group {
                    if let image = UIImage(data: game.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                            Image(systemName: "questionmark")
                                .font(.system(size: 24))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.white : Color.white.opacity(0.10),
                            lineWidth: isSelected ? 3 : 1
                        )
                )
                .scaleEffect(isSelected ? 1.03 : 1.0)

                Text(game.title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(isSelected ? 1 : 0.55))
                    .lineLimit(1)
                    .frame(width: 110)
            }
        }
        .buttonStyle(.plain)
    }
}
