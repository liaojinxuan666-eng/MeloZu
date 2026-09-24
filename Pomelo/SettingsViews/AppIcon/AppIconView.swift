//
//  AppIconView.swift
//  Pomelo
//
//  Created by Stossy11 on 23/10/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI

struct AppIcon: Identifiable {
    let id = UUID()
    let name: String
    var iconName: String?
}

struct AppIconSwitcherView: View {
    @State private var selectedIcon: String?
    @Environment(\.colorScheme) var colorScheme
    
    let appIcons: [AppIcon] = [
        AppIcon(name: "Default", iconName: nil),
        AppIcon(name: "Secondary", iconName: "secondary"),
        AppIcon(name: "Old", iconName: "old"),
    ]
    
    var body: some View {
        List {
            ForEach(appIcons) { icon in
                IconRow(icon: icon, isSelected: icon.iconName == selectedIcon)
                    .onTapGesture {
                        changeAppIcon(to: icon.iconName)
                    }
            }
        }
        .navigationTitle("App Icons")
        .onAppear {
            // Get current app icon
            
            if let iconName = UIApplication.shared.alternateIconName {
                selectedIcon = iconName
            }
        }
    }
    
    private func changeAppIcon(to iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("App icon changing not supported")
            return
        }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            } else {
                selectedIcon = iconName
            }
        }
    }
}

struct IconRow: View {
    var icon: AppIcon
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var issdark: Bool {
        if colorScheme == .dark, (icon.iconName ?? "") == "secondary" {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        HStack {
            
            if let iconImage = getIconImage(for: icon.iconName) {
                if let iconImage = getIconImage(for: "secondary-dark"), issdark {
                    Image(uiImage: iconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                } else {
                    Image(uiImage: iconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                }
            } else {
                // Fallback to app's primary icon
                if let primaryIcon = Bundle.main.icon {
                    Image(uiImage: primaryIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                }
            }
            
            Text(icon.name)
                .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func getIconImage(for iconName: String?) -> UIImage? {
        if let iconName = iconName {
            // Try to get alternate icon
            return UIImage(named: iconName)
        } else {
            // Return primary app icon
            return Bundle.main.icon
        }
    }
}

// Extension to get the app's primary icon
extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
