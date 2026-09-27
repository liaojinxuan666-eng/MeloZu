//
//  BootOSView.swift
//  MeloZu
//
//  v3 修复要点：
//  1. 【核心】新增「从 App 沙盒直接导入」——App 开了 UIFileSharingEnabled，
//     用户只要把固件 zip 放进「文件」App → 我的 iPhone → MeloZu，
//     App 就能自己扫描出来，点一下就导入。完全绕开系统文件选择器。
//  2. 文件选择器改为手写 UIDocumentPickerViewController 桥接，
//     并使用 asCopy: true —— iOS 会把文件复制进 App 自己的临时目录，
//     不存在安全作用域 / 文件提供者读取失败的问题。
//  3. 解压仍在后台线程，错误原文直接弹窗显示。
//  4. 解压后扫描目录，报告 NCA 数量 / qlaunch / prod.keys。
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
    @State private var errorMessage = ""
    @State private var isImporting = false
    @State private var statusText = ""
    @State private var diagReport = ""
    @State private var localZips: [URL] = []

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
        .alert("Firmware", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
                        Text(diagReport)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
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

        // 去掉重复（incoming 里可能有上次导入的副本）
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

    /// App 沙盒 Documents 的真实路径（显示出来方便用户确认）
    private var sandboxPath: String {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].path
    }

    /// 该 App 在「文件」App 里「我的 iPhone」下显示的文件夹名
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

    /// 在沙盒里放一个标记文件，方便用户在「文件」App 里认出这个目录
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
            }
        }

        setStatus("Reading \(source.lastPathComponent)…")

        let accessed = source.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                source.stopAccessingSecurityScopedResource()
            }
        }

        // 把 zip 统一拷到 incoming/firmware.zip，避免后续路径/权限问题
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

        // 如果源文件本来就在沙盒里（用户放进 Documents 的情况），直接解压它
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

        // 直接调用 Zip，把原始错误暴露出来（Core.AddFirmware 会吞掉错误）
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

            This ZIP does not look like a complete Switch firmware dump.
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

            self.refreshBootState()
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

    /// 如果 registered/ 下只有唯一一个子文件夹，把它的内容提到上层
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

        let canBoot = Sudachi.shared.canGetFullPath() || canGetFullPath
        bootSystem = canBoot
    }
}

// MARK: - Manual document picker

/// 手写 UIDocumentPickerViewController 桥接。
/// asCopy: true 让 iOS 把选中的文件复制到 App 自己的临时目录，
/// 返回的 URL 可被 App 直接读取，不存在安全作用域 / 文件提供者问题。
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
