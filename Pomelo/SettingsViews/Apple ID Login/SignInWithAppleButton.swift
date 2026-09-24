//
//  SignInWithAppleButton.swift
//  Pomelo
//
//  Created by Stossy11 on 9/11/2024.
//  Copyright © 2024 Stossy11. All rights reserved.
//


import AuthenticationServices
import SwiftUI

struct SignInApple: View {
    var body: some View {
        
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName]
            },
            onCompletion: { result in
                switch result {
                case .success(let authResults):
                    if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                        let firstName = appleIDCredential.fullName?.givenName
                        let lastName = appleIDCredential.fullName?.familyName

                        
                        UserDefaults.standard.set(appleIDCredential.user, forKey: "deviceOwnerID")
                    
                        UserDefaults.standard.set(firstName, forKey: "deviceOwnerName")
                        UserDefaults.standard.set(lastName, forKey: "deviceOwnerLastName")
                        UserDefaults.standard.synchronize()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        )
        .frame(height: 44)
        .padding()
    }
}
