//
//  SettingsView.swift
//  Pomelo
//
//  Created by Stossy11 on 14/7/2024.
//

import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @State var core: Core
    @State var showprompt = false
    @AppStorage("icon") var iconused = 1
    @AppStorage("cantouchapplepen") var applepen: Bool = false
    
    @AppStorage("useTrollStore") var useTrollStore: Bool = false
    @AppStorage("deviceOwnerID") var deviceOwnerID: String?
    
    @AppStorage("showfunnibackground") private var showbackground: Bool = false
    
    @State var timestapped: Int = 0
    
    @State var isshown: Bool = true
    
    var body: some View {
        iOSNav {
            ScrollView {
                VStack(alignment: .center) {
                    if iconused == 1 {
                        if let image = UIImage(named: AppIconProvider.appIcon()) {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    Text("Welcome To Pomelo")
                        .padding()
                        .font(.title)
                }
                .padding()
                VStack(alignment: .leading) {
                    
                    NavigationLink(destination: InfoView()) {
                        Rectangle()
                            .fill(Color(uiColor: UIColor.secondarySystemBackground)) // Set the fill color (optional)
                            .cornerRadius(10) // Apply rounded corners
                            .frame(width: .infinity, height: 50) // Set the desired dimensions
                            .overlay() {
                                HStack {
                                    Text("About")
                                        .foregroundColor(.primary)
                                        .padding()
                                    Spacer()
                                }
                            }
                    }
                    .padding()
                    
                    NavigationLink {
                        CoreSettingsView()
                    } label: {
                        Rectangle()
                            .fill(Color(uiColor: UIColor.secondarySystemBackground)) // Set the fill color (optional)
                            .cornerRadius(10) // Apply rounded corners
                            .frame(width: .infinity, height: 50) // Set the desired dimensions
                            .overlay() {
                                VStack {
                                    HStack {
                                        Text("Core Settings")
                                            .foregroundColor(.primary)
                                            .padding()
                                        Spacer()
                                    }
                                }
                            }
                    }
                    .foregroundColor(.primary)
                    .padding()
                    
                    if UIDevice.current.systemVersion <= "17.0.1" {
                        Rectangle()
                            .fill(Color(uiColor: UIColor.secondarySystemBackground)) // Set the fill color (optional)
                            .cornerRadius(10) // Apply rounded corners
                            .frame(width: .infinity, height: 50) // Set the desired dimensions
                            .overlay() {
                                HStack {
                                    Toggle(isOn: $useTrollStore) {
                                        Text("TrollStore")
                                            .foregroundColor(.primary)
                                            .padding()
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                            .padding()
                    }
                    
                    /*
                     NavigationLink(destination: AppIconView()) {
                     Rectangle()
                     .fill(Color(uiColor: UIColor.secondarySystemBackground)) // Set the fill color (optional)
                     .cornerRadius(10) // Apply rounded corners
                     .frame(width: .infinity, height: 50) // Set the desired dimensions
                     .overlay() {
                     HStack {
                     Text("App Icon")
                     .foregroundColor(.primary)
                     .padding()
                     Spacer()
                     }
                     }
                     }
                     .padding()
                     */
                    
                    // NavigationLink(
                    NavigationLink(destination: AdvancedSettingsView()) {
                        Rectangle()
                            .fill(Color(uiColor: UIColor.secondarySystemBackground)) // Set the fill color (optional)
                            .cornerRadius(10) // Apply rounded corners
                            .frame(width: .infinity, height: 50) // Set the desired dimensions
                            .overlay() {
                                HStack {
                                    Text("App Settings")
                                        .foregroundColor(.primary)
                                        .padding()
                                    Spacer()
                                }
                            }
                        
                    }
                    .padding()
                    
                    
                    NavigationLink(destination: AppIconSwitcherView()) {
                        Rectangle()
                            .fill(Color(uiColor: UIColor.secondarySystemBackground)) // Set the fill color (optional)
                            .cornerRadius(10) // Apply rounded corners
                            .frame(width: .infinity, height: 50) // Set the desired dimensions
                            .overlay() {
                                HStack {
                                    Text("App Icon")
                                        .foregroundColor(.primary)
                                        .padding()
                                    Spacer()
                                }
                            }
                        
                    }
                    .padding()
                    
                    if timestapped >= 10 || showbackground {
                        Rectangle()
                            .fill(Color(uiColor: UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .frame(width: .infinity, height: 50)
                            .overlay() {
                                HStack {
                                    Toggle("Enable Apple Inteligence Background", isOn: $showbackground)
                                        .padding()
                                }
                            }
                            .padding(.horizontal)
                        Text("This is a secret, cool. (only works on iOS 18+)")
                            .padding(.bottom)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                    }
                    
                    NavigationLink(destination: LegalDisclaimerView(isinsettings: true)) {
                        Rectangle()
                            .fill(Color(uiColor: UIColor.secondarySystemBackground)) // Set the fill color (optional)
                            .cornerRadius(10) // Apply rounded corners
                            .frame(width: .infinity, height: 50) // Set the desired dimensions
                            .overlay() {
                                HStack {
                                    Text("Terms and Conditions")
                                        .foregroundColor(.primary)
                                        .padding()
                                    Spacer()
                                }
                            }
                    }
                    .padding()

                    HStack(alignment: .center) {
                        Spacer()
                        Text("By \(getDeveloperNames())")
                            .font(.caption2)
                            .onTapGesture {
                                timestapped += 1
                            }
                        Spacer()
                    }
                }
            }
            .onAppear() {
                do {
                    core = try LibraryManager.shared.library()
                } catch {
                    print("Failed to fetch library: \(error)")
                }
            }
            .alert(isPresented: $showprompt) {
                Alert(title: Text("TrollStore"), message: Text("Enabling JIT in App is currenly not supported please enabble JIT from inside TrollStore."), dismissButton: .default(Text("OK")))
            }
        }
        
    }
}
