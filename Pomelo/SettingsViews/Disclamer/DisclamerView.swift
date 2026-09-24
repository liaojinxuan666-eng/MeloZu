//
//  DisclamerView.swift
//  Pomelo
//
//  Created by Stossy11 on 20/11/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//

import SwiftUI

struct LegalDisclaimerView: View {
    @AppStorage("disclamerAgreed") var dismisseddisclamer = false
    @State private var navigateToApp = false
    
    @Environment(\.dismiss) var dismiss
    
    @State var agreedToDisclaimer: Bool = false
    
    @State var isinsettings: Bool
    
    @State var timestapped = 0
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms and Conditions")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                Text("""
This software is an emulator provided for educational and personal use purposes only. By using this software, you agree to the following terms and conditions:
                    
1. You are solely responsible for obtaining game files (ROMs) and system keys from your legally owned devices and games. These files must be obtained in compliance with your local copyright laws.
                    
2. The creators and maintainers of this emulator strictly prohibit the illegal distribution, duplication, or use of copyrighted material. Any use of this software that violates copyright law is entirely your responsibility.
                    
3. This emulator is intended only for users who own the original hardware and software. By proceeding, you confirm that you own the games and hardware for which you are using this software.
                    
4. The developers of this emulator disclaim all liability for damages, losses, or legal consequences resulting from the use of this software. The responsibility for compliance with copyright and intellectual property laws rests entirely with you, the user.
                    
5. By using this software, you agree that you are solely liable for any misuse, and you absolve the developers of all responsibility for how this emulator is used.

6. Any ROM you play on this emulator is your responsibility, including ensuring that its usage complies with all applicable laws and regulations. The developers hold no liability for improper use.
                    
Failure to agree to these terms means you are not permitted to use this software and could result in legal issues. \(!isinsettings ? "Please exit now if you do not agree." : "") \((timestapped > 10) ? "(or in other words just piracy is on you / not allowed)" : "")
""")
                .font(.body)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .onTapGesture {
                    timestapped += 1
                }
                
                if !isinsettings {
                    Toggle(isOn: $agreedToDisclaimer) {
                        Text("I have read and agree to the terms above.")
                            .font(.headline)
                            .foregroundColor(agreedToDisclaimer ? .green : .primary)
                    }
                    .padding()
                    
                    if agreedToDisclaimer {
                        Button {
                            dismisseddisclamer = false
                            dismiss()
                        } label: {
                            Text("Proceed to Pomelo")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    } else {
                        Text("You must agree to the terms before proceeding.")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Disclaimer")
    }
}
