import SwiftUI
import Sudachi
import UniformTypeIdentifiers

struct BootOSView: View {
    @State private var bootSystem = false
    @State private var showImporter = false
    @State private var showError = false
    @State private var errorMessage = ""

    @AppStorage("cangetfullpath") private var canGetFullPath = false

    var body: some View {
        Group {
            if bootSystem {
                SudachiEmulationView(game: nil)
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()

                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: "cpu")
                            .font(.system(size: 72))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("MeloZu")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Switch firmware required")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))

                        Text("Import your firmware ZIP. MeloZu will then enter the Switch Home Menu directly.")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 520)

                        Button {
                            showImporter = true
                        } label: {
                            Label("Import Firmware", systemImage: "arrow.down.circle.fill")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 28)
                                .padding(.vertical, 15)
                                .background(Capsule().fill(.white))
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
        .onAppear {
            refreshBootState()
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.zip]
        ) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed { url.stopAccessingSecurityScopedResource() }
                }

                let documents = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                )[0]

                let core = Core(games: [], root: documents)
                core.AddFirmware(at: url)

                refreshBootState()

                if !bootSystem {
                    errorMessage = "Firmware was imported, but the required Switch system files were not detected."
                    showError = true
                }

            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Firmware", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
