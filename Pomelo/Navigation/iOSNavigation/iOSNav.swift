//
//  iOSNav.swift
//  Pomelo
//
//  Created by Stossy11 on 9/11/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI

struct iOSNav<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack(root: content)
        } else {
            NavigationView(content: content)
                .navigationViewStyle(StackNavigationViewStyle())
                .navigationViewStyle(.stack)
        }
    }
}
