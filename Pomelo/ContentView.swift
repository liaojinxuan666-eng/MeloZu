import SwiftUI
import Sudachi
import Foundation
import UIKit
import AuthenticationServices

struct ContentView: View {
    @AppStorage("useTrollStore") private var useTrollStore = false
    @AppStorage("showMetalHUD") private var showMetalHUD = false
    @AppStorage("canShowMetalHUD") private var canShowMetalHUD = false
    @AppStorage("disclamerAgreed") private var dismissedDisclaimer = false

    var body: some View {
        BootOSView()
            .persistentSystemOverlays(.hidden)
            .sheet(
                isPresented: Binding(
                    get: { !dismissedDisclaimer },
                    set: { dismissedDisclaimer = !$0 }
                )
            ) {
                LegalDisclaimerView(isinsettings: false)
            }
            .onAppear {
                if !UserDefaults.standard.bool(forKey: "JIT-ENABLED"), useTrollStore {
                    askForJIT()
                }

                canShowMetalHUD = openMetalDylib()
                showMetalHUD ? enableMetalHUD() : disableMetalHUD()

                do {
                    try PomeloFileManager.shared.createdirectories()
                } catch {
                    print("Failed to create MeloZu directories: \(error)")
                }

                ASAuthorizationAppleIDProvider().getCredentialState(
                    forUserID: UserDefaults.standard.string(forKey: "deviceOwnerID") ?? "0"
                ) { state, _ in
                    if state != .authorized {
                        UserDefaults.standard.set(nil, forKey: "deviceOwnerName")
                        UserDefaults.standard.set(nil, forKey: "deviceOwnerLastName")
                        UserDefaults.standard.set(nil, forKey: "deviceOwnerID")
                    }
                }
            }
    }
}
