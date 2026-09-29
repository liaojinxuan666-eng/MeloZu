//
//  BootOSView.swift
//  MeloZu
//
//  v4 修复要点：
//  1. 【核心】彻底解决导入残缺固件后卡 Loading 死循环的问题。
//     在 UI 层强制执行物理文件校验（检查 qlaunch 和 prod.keys），
//     只要缺少，强制阻断 bootSystem，绝对不进入 SudachiEmulationView。
//  2. 完善报错引导，明确指出市面固件包缺失 qlaunch (0100000000001000) 的问题。
//  3. 新增“清除固件”按钮，方便用户重置错误的固件导入。
//

import SwiftUI
import Sudachi
import UniformTypeIdentifiers
import Foundation
import UIKit
import Zip

struct BootOSView: View {
    @State private var bootSystem = false
    @State private var showPicker = false
    @State private var showError = false
    @State private var showResetConfirm = false
    @State private var errorMessage = ""
    @State private var isImporting = false
    @State private var statusText = ""
    @State private var diagReport = ""
    @State private var localZips: [URL] = []
    @State private var isFirmwareReady = false

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
            scanLocalFirmware()
            refreshBootState()
        }
        .sheet(isPresented: $showPicker) {
            DocumentPicker(
                onPick: { url in
                    showPicker = false
                    beginImport(from: url)
                },
                onCancel: {
                    showPicker = false
                }
            )
        }
        .alert("Firmware Import Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Reset Firmware", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetFirmware()
            }
        } message: {
            Text("This will delete all imported firmware and keys. Are you sure?")
        }
    }

    // MARK: - UI

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

            ScrollView {
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

                        Spacer()

                        if isFirmwareReady {
                            Button {
                                showResetConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.red.opacity(0.8))
                                    .padding(8)
                                    .background(.white.opacity(0.1), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 28)

                    Text("Welcome")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
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

                    localFirmwareSection
                        .padding(.top, 26)

                    Button {
                        showPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            if isImporting {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "arrow.down.to.line.compact")
                            }

                            Text(isImporting ? "Importing…" : "Choose ZIP from Files…")
                        }
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .frame(height: 52)
                        .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isImporting)
                    .padding(.top, 20)

                    if isImporting && !statusText.isEmpty {
                        Text(statusText)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 14)
                    }

                    if !diagReport.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(diagReport)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.55))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if !isFirmwareReady {
                                Text("⚠️ Firmware incomplete. Please import a full Switch firmware dump containing qlaunch (0100000000001000).")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.orange)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            .white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .padding(.top, 14)
                    }

                    Spacer(minLength: 30)
                }
                .padding(24)
                .frame(maxWidth: 720, alignment: .leading)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var localFirmwareSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Firmware in app folder")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))

                Button {
                    scanLocalFirmware()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.5))
            }

            Text("Files → On My iPhone → \(appFolderName)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))

            Text(sandboxPath)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.32))
                .fixedSize(horizontal: false, vertical: true)

            if localZips.isEmpty {
                Text(
                    "No .zip found here yet. Drop a firmware .zip into the " +
                    "folder above, then tap the refresh button."
                )
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(localZips, id: \.self) { url in
                    Button {
                        beginImport(from: url)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.zipper")
                                .font(.system(size: 15, weight: .semibold))

                            Text(url.lastPathComponent)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer(minLength: 8)

                            Text(fileSizeText(url))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(
                            .white.opacity(0.09),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isImporting)
                }
            }
        }
        .frame(maxWidth: 620, alignment: .leading)
    }

    // MARK: - Local scanning

    private func scanLocalFirmware() {
        let fm = FileManager.default
        let documents = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]

        writeMarkerFileIfNeeded()

        var dirs: [URL] = [documents]
        dirs.append(documents.appendingPathComponent("roms", isDirectory: true))
        dirs.append(documents.appendingPathComponent("incoming", isDirectory: true))

        var found: [URL] = []
        for dir in dirs {
            guard let entries = try? fm.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in entries where entry.pathExtension.lowercased() == "zip" {
                found.append(entry)
            }
        }

        var seen = Set<String>()
        localZips = found.filter { url in
            let name = url.lastPathComponent
            if seen.contains(name) { return false }
            seen.insert(name)
            return true
        }
    }

    private func fileSizeText(_ url: URL) -> String {
        let fm = FileManager.default
        let attrs = try? fm.attributesOfItem(atPath: url.path)
        let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private var sandboxPath: String {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].path
    }

    private var appFolderName: String {
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !name.isEmpty {
            return name
        }
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !name.isEmpty {
            return name
        }
        return "MeloZu"
    }

    private func writeMarkerFileIfNeeded() {
        let fm = FileManager.default
        let marker = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("DROP_FIRMWARE_ZIP_HERE.txt")

        guard !fm.fileExists(atPath: marker.path) else { return }

        let text = """
        This is the MeloZu app sandbox (Documents) folder.

        Put your Switch firmware .zip in this folder, then open MeloZu
        and tap the refresh button in the "Firmware in app folder" section.

        Do NOT put the .zip inside nand/ — MeloZu extracts it there itself.

        Sandbox path:
        \(sandboxPath)
        """

        try? text.write(to: marker, atomically: true, encoding: .utf8)
    }

    // MARK: - Import entry point

    private func beginImport(from url: URL) {
        guard !isImporting else { return }

        isImporting = true
        diagReport = ""
        statusText = "Preparing…"

        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        do {
            try PomeloFileManager.shared.createdirectories()
        } catch {
            isImporting = false
            errorMessage = "Failed to create directories:\n\(error.localizedDescription)"
            showError = true
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.runImport(source: url, documents: documents)
        }
    }

    // MARK: - Background import

    private func runImport(source: URL, documents: URL) {
        let fm = FileManager.default

        func setStatus(_ text: String) {
            DispatchQueue.main.async {
                self.statusText = text
            }
        }

        func fail(_ text: String) {
            DispatchQueue.main.async {
                self.isImporting = false
                self.statusText = ""
                var message = text
                if !self.diagReport.isEmpty {
                    message += "\n\n--- Diagnostics ---\n" + self.diagReport
                }
                self.errorMessage = message
                self.showError = true
                // 【关键修复】：发生错误时，强制重置 boot 状态，防止卡死
                self.bootSystem = false
            }
        }

        setStatus("Reading \(source.lastPathComponent)…")

        let accessed = source.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                source.stopAccessingSecurityScopedResource()
            }
        }

        let incoming = documents.appendingPathComponent("incoming", isDirectory: true)
        do {
            try fm.createDirectory(at: incoming, withIntermediateDirectories: true)
        } catch {
            fail("Could not create staging folder:\n\(error.localizedDescription)")
            return
        }

        let localZip = incoming.appendingPathComponent("firmware.zip")
        if fm.fileExists(atPath: localZip.path) {
            try? fm.removeItem(at: localZip)
        }

        let sourceIsInsideSandbox = source.path.hasPrefix(documents.path)

        var zipToUse = source

        if !sourceIsInsideSandbox {
            setStatus("Copying ZIP into app storage…")

            var coordError: NSError?
            var copyError: Error?

            NSFileCoordinator().coordinate(
                readingItemAt: source,
                options: [],
                error: &coordError
            ) { readURL in
                do {
                    try fm.copyItem(at: readURL, to: localZip)
                } catch {
                    copyError = error
                }
            }

            if let copyError = copyError {
                fail("Failed to copy the ZIP into app storage:\n\(copyError.localizedDescription)")
                return
            }
            if let coordError = coordError {
                fail("File coordinator error:\n\(coordError.localizedDescription)")
                return
            }

            zipToUse = localZip
        }

        let zipAttributes = try? fm.attributesOfItem(atPath: zipToUse.path)
        let zipSize = (zipAttributes?[.size] as? NSNumber)?.int64Value ?? 0

        guard zipSize > 0 else {
            fail("The ZIP is 0 bytes and could not be read:\n\(zipToUse.path)")
            return
        }

        let zipSizeText = ByteCountFormatter.string(fromByteCount: zipSize, countStyle: .file)
        setStatus("Extracting \(zipSizeText) ZIP… this may take a minute.")

        let registered = documents.appendingPathComponent(
            "nand/system/Contents/registered",
            isDirectory: true
        )

        do {
            try fm.createDirectory(at: registered, withIntermediateDirectories: true)
        } catch {
            fail("Could not create firmware folder:\n\(error.localizedDescription)")
            return
        }

        do {
            try Zip.unzipFile(
                zipToUse,
                destination: registered,
                overwrite: true,
                password: nil
            )
        } catch {
            var detail = "Unzip failed:\n\(error.localizedDescription)"
            detail += "\n\nRaw error: \(error)"
            detail += "\n\nZIP: \(zipToUse.lastPathComponent) (\(zipSizeText))"
            fail(detail)
            return
        }

        setStatus("Scanning extracted files…")
        analyzeFirmware(documents: documents, zipSize: zipSize)
    }

    // MARK: - Diagnostics

    private func analyzeFirmware(documents: URL, zipSize: Int64) {
        let fm = FileManager.default
        let registered = documents.appendingPathComponent(
            "nand/system/Contents/registered",
            isDirectory: true
        )

        flattenIfNested(registered)

        var ncaCount = 0
        var qlaunchFound = false
        var totalBytes: UInt64 = 0
        var sampleNames: [String] = []

        if let enumerator = fm.enumerator(
            at: registered,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        ) {
            for case let file as URL in enumerator {
                let name = file.lastPathComponent
                let lower = name.lowercased()

                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0 {
                    totalBytes += UInt64(size)
                }

                guard lower.hasSuffix(".nca") else { continue }

                ncaCount += 1
                if sampleNames.count < 3 {
                    sampleNames.append(name)
                }

                if lower.hasPrefix("0100000000001000") {
                    qlaunchFound = true
                }
            }
        }

        let prodKeysOK = fm.fileExists(
            atPath: documents.appendingPathComponent("keys/prod.keys").path
        )
        let titleKeysOK = fm.fileExists(
            atPath: documents.appendingPathComponent("keys/title.keys").path
        )

        let extractedText = ByteCountFormatter.string(
            fromByteCount: Int64(totalBytes),
            countStyle: .file
        )
        let zipText = ByteCountFormatter.string(fromByteCount: zipSize, countStyle: .file)

        var report = ""
        report += "ZIP size: \(zipText)\n"
        report += "Extracted: \(extractedText)\n"
        report += "NCAs in registered/: \(ncaCount)\n"
        report += "qlaunch 0100000000001000: \(qlaunchFound ? "FOUND" : "MISSING")\n"
        report += "prod.keys: \(prodKeysOK ? "present" : "MISSING")\n"
        report += "title.keys: \(titleKeysOK ? "present" : "MISSING")\n"
        if !sampleNames.isEmpty {
            report += "Sample: \(sampleNames.joined(separator: ", "))"
        }

        var problem: String?

        if ncaCount == 0 {
            problem = """
            Unzip reported success, but no .nca files were found in:
            nand/system/Contents/registered

            The ZIP probably does not contain Switch firmware NCAs directly.
            """
        } else if !qlaunchFound {
            problem = """
            Extracted \(ncaCount) .nca files, but the qlaunch system NCA \
            (0100000000001000) is missing.

            【重要提示】市面上的很多固件包是残缺的（例如只有游戏或更新包）。
            MeloZu 引导进入原生 Switch 桌面，必须要求完整的系统固件，
            请确保你的固件包包含 qlaunch (0100000000001000)。
            """
        } else if !prodKeysOK {
            problem = """
            Firmware looks good (\(ncaCount) NCAs, qlaunch found).

            But prod.keys is MISSING in the keys/ folder — the Switch OS \
            cannot boot without it. Put prod.keys into:
            On My iPhone/MeloZu/keys/
            """
        }

        DispatchQueue.main.async {
            self.isImporting = false
            self.statusText = ""
            self.diagReport = report

            // 【核心修复】：先强制阻断，再尝试刷新状态
            if problem != nil {
                self.bootSystem = false
                self.isFirmwareReady = false
            } else {
                self.refreshBootState()
            }

            let canBoot = self.bootSystem

            if let problem = problem {
                self.errorMessage = problem + "\n\n--- Diagnostics ---\n" + report
                self.showError = true
            } else if !canBoot {
                self.errorMessage = """
                All firmware files are present, but the system still says it \
                cannot boot.

                Try force-quitting and relaunching MeloZu.
                """ + "\n\n--- Diagnostics ---\n" + report
                self.showError = true
            }
        }
    }

    private func flattenIfNested(_ registered: URL) {
        let fm = FileManager.default

        guard let entries = try? fm.contentsOfDirectory(
            at: registered,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else { return }

        let visible = entries.filter { !$0.lastPathComponent.hasPrefix(".") }

        if visible.contains(where: { $0.pathExtension.lowercased() == "nca" }) {
            return
        }

        guard visible.count == 1 else { return }

        let inner = visible[0]
        let isDir = (try? inner.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        guard isDir else { return }

        guard let innerEntries = try? fm.contentsOfDirectory(
            at: inner,
            includingPropertiesForKeys: nil
        ) else { return }

        for entry in innerEntries {
            let target = registered.appendingPathComponent(entry.lastPathComponent)
            if fm.fileExists(atPath: target.path) {
                try? fm.removeItem(at: target)
            }
            try? fm.moveItem(at: entry, to: target)
        }

        try? fm.removeItem(at: inner)
    }

    // MARK: - Boot state

    private func refreshBootState() {
        do {
            try PomeloFileManager.shared.createdirectories()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // 1. 独立物理文件校验
        let qlaunchPath = documents.appendingPathComponent(
            "nand/system/Contents/registered/0100000000001000.nca"
        )
        let prodKeysPath = documents.appendingPathComponent("keys/prod.keys")
        
        let qlaunchExists = FileManager.default.fileExists(atPath: qlaunchPath.path)
        let prodKeysExists = FileManager.default.fileExists(atPath: prodKeysPath.path)

        // 2. 只有物理文件齐全，且底层核心认可时，才允许启动
        let coreCanBoot = Sudachi.shared.canGetFullPath() || canGetFullPath
        let canBoot = qlaunchExists && prodKeysExists && coreCanBoot
        
        isFirmwareReady = canBoot
        bootSystem = canBoot
        
        if canBoot {
            print("[MeloZu] Firmware check passed. Booting system...")
        } else {
            print("[MeloZu] Firmware check failed. qlaunch: \(qlaunchExists), prodKeys: \(prodKeysExists), core: \(coreCanBoot)")
        }
    }

    // MARK: - Reset Firmware

    private func resetFirmware() {
        let fm = FileManager.default
        let documents = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let pathsToRemove = [
            documents.appendingPathComponent("nand", isDirectory: true),
            documents.appendingPathComponent("keys", isDirectory: true),
            documents.appendingPathComponent("incoming", isDirectory: true)
        ]
        
        for path in pathsToRemove {
            if fm.fileExists(atPath: path.path) {
                try? fm.removeItem(at: path)
            }
        }
        
        DispatchQueue.main.async {
            self.diagReport = ""
            self.isFirmwareReady = false
            self.bootSystem = false
            self.scanLocalFirmware()
        }
    }
}

// MARK: - Manual document picker

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType.zip, UTType.archive, UTType.data],
            asCopy: true
        )
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL) -> Void
        private let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let url = urls.first else {
                onCancel()
                return
            }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
