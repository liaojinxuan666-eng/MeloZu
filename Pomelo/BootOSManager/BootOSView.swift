//
//  BootOSView.swift
//  MeloZu
//
//  v2 修复要点：
//  1. 解压放后台线程 —— 不再卡死主线程
//  2. 直接调用 Zip.unzipFile 并捕获错误，把「原始错误信息」显示在界面上
//     （v1 里 Core.AddFirmware 内部 catch 掉只 print，iOS 上完全看不到）
//  3. 先用 NSFileCoordinator 把 ZIP 拷进 App 自己的沙盒再解压
//     —— 绕开「文件」App 的文件提供者 / 安全作用域读取失败问题
//  4. 解压后扫描目录，报告 NCA 数量、qlaunch 是否存在、prod.keys 是否存在
//  5. 自动拍平 ZIP 里多余的嵌套文件夹
//

import SwiftUI
import Sudachi
import UniformTypeIdentifiers
import Foundation
import Zip

struct BootOSView: View {
    @State private var bootSystem = false
    @State private var showImporter = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isImporting = false
    @State private var statusText = ""
    @State private var diagReport = ""

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
            // .data 让选择器不因「类型不匹配」而把文件置灰导致点不动。
            // 导入后我们仍会校验内容，确认是不是合法固件。
            allowedContentTypes: [.zip, .archive, .data]
        ) { result in
            handleFirmwareImport(result)
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

                        if isImporting && !statusText.isEmpty {
                            Text(statusText)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 12)
                        }

                        if !diagReport.isEmpty {
                            Text(diagReport)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.55))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(12)
                                .frame(maxWidth: 620, alignment: .leading)
                                .background(
                                    .white.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                                .padding(.top, 14)
                        }

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

    // MARK: - Import entry point

    private func handleFirmwareImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            beginImport(from: url)
        case .failure(let error):
            isImporting = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func beginImport(from url: URL) {
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

        setStatus("Copying ZIP into app storage…")

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

        let accessed = source.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                source.stopAccessingSecurityScopedResource()
            }
        }

        // 用 NSFileCoordinator 读取，兼容 iCloud Drive / 文件提供者
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

        let zipAttributes = try? fm.attributesOfItem(atPath: localZip.path)
        let zipSize = (zipAttributes?[.size] as? NSNumber)?.int64Value ?? 0

        guard zipSize > 0 else {
            fail("The copied ZIP is 0 bytes — the source file could not be read.")
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

        // 直接调用 Zip，把原始错误暴露出来（不再被 Core.AddFirmware 吞掉）
        do {
            try Zip.unzipFile(
                localZip,
                destination: registered,
                overwrite: true,
                password: nil
            )
        } catch {
            var detail = "Unzip failed:\n\(error.localizedDescription)"
            detail += "\n\nRaw error: \(error)"
            detail += "\n\nZIP size: \(zipSizeText)"
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

        // 有些固件 ZIP 里套了一层文件夹，这里自动拍平
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
