import SwiftUI
import Sudachi
import UniformTypeIdentifiers

struct BootOSView: View {
    @State private var bootSystem = false
    @State private var showImporter = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isImporting = false

    @AppStorage("cangetfullpath") private var canGetFullPath = false

    var body: some View {
        Group {
            if bootSystem {
                SudachiEmulationView(game: nil)
            } else {
                firmwareSetupView
            }
        }
        .onAppear {
            refreshBootState()
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.zip]
        ) { result in
            handleFirmwareImport(result)
        }
        .alert("Firmware", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var firmwareSetupView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.04, blue: 0.055),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Spacer(minLength: 24)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(
                                    .white.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: 13)
                                )

                            Text("MeloZu")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Spacer(minLength: 28)

                        Text("Welcome")
                            .font(
                                .system(
                                    size: min(proxy.size.width * 0.055, 48),
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(.white)

                        Text("Set up your Switch system")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .padding(.top, 6)

                        Text(
                            "Import a Switch firmware ZIP to initialize the system environment. " +
                            "After setup, MeloZu will boot directly into the Switch Home Menu."
                        )
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                        .frame(maxWidth: 620, alignment: .leading)

                        Button {
                            showImporter = true
                        } label: {
                            HStack(spacing: 10) {
                                if isImporting {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Image(systemName: "arrow.down.to.line.compact")
                                }

                                Text(isImporting ? "Importing…" : "Import Firmware")
                            }
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .frame(height: 52)
                            .background(.white, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(isImporting)
                        .padding(.top, 28)

                        Text("Supported format: .zip")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.top, 10)

                        Spacer()
                    }
                    .frame(maxWidth: 720, maxHeight: .infinity, alignment: .leading)

                    Spacer(minLength: 24)
                }
                .padding(.vertical, 28)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func handleFirmwareImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            isImporting = true

            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            let core = Core(games: [], root: documents)
            core.AddFirmware(at: url)

            isImporting = false
            refreshBootState()

            if !bootSystem {
                errorMessage =
                    "Firmware was imported, but the required Switch system files were not detected."
                showError = true
            }

        case .failure(let error):
            isImporting = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func refreshBootState() {
        do {
            try PomeloFileManager.shared.createdirectories()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }

        bootSystem = Sudachi.shared.canGetFullPath() || canGetFullPath
    }
}
