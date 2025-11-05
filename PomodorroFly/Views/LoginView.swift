//
//  LoginView.swift
//  PursePartners
//
//  Created by Andrei Musca on 12.08.2025.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userVM: UserViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isPasswordVisible = false
    @State var currentNonce: String?

    var body: some View {
        NavigationStack{
            ZStack {
                VStack(spacing: 25) {
                    
                    TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                            .padding()
                    
                    
                    SecureField("Enter your password", text: $password)
                               .textFieldStyle(RoundedBorderTextFieldStyle())
                               .disableAutocorrection(true)
                    
                    Text(errorMessage ?? " ")   // spațiu gol când nu e mesaj, ca să ocupe spațiu
                        .foregroundColor(errorMessage == nil ? .clear : .red)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .animation(.easeInOut(duration: 0.3), value: errorMessage)
                        .padding(.top, -20)
                    
                    // Buton Login
                    Button(action: {
                        if email.isEmpty || password.isEmpty {
                            errorMessage = "Please fill in both email and password."
                        } else if !isValidEmail(email) {
                            errorMessage = "Please enter a valid email address."
                        } else {
                            errorMessage = nil
                            Task {
                                do {
                                    try await AuthService.shared.login(email: email, password: password)
                                } catch {
                                    print("APARE EROARE DE LA FIREBASEL \n")
                                    print(error.localizedDescription)
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }) {
                        Text("Login")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.glassProminent)
                    .padding(.top, 12)

                    
                    // Sign up
                    HStack {
                        Text("Don't have an account?")
                            .font(.footnote)
//                        NavigationLink(destination: SignUpView()) {
//                            Text("Sign Up")
//                                .font(.footnote)
//                                .foregroundColor(.blue)
//                        }
                    }
                    
                    // Divider OR
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        Text("OR")
                            .font(.caption)
                        Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    }
                    
//                    // Social buttons
//                    HStack(spacing: 20) {
//                        SignInWithAppleButton(onRequest: { request in
//                            let nonce = randomNonceString()
//                            currentNonce = nonce
//                            request.requestedScopes = [.email]
//                            request.nonce = sha256(nonce)
//                        }, onCompletion: { result in
//                            switch result {
//                            case .success(let authResults):
//                                switch authResults.credential {
//                                case let appleIDCredential as ASAuthorizationAppleIDCredential:
//                                    
//                                    guard let nonce = currentNonce else {
//                                        fatalError("Invalid state: A login callback was received, but no login request was sent.")
//                                    }
//                                    guard let appleIDToken = appleIDCredential.identityToken else {
//                                        fatalError("Invalid state: A login callback was received, but no login request was sent.")
//                                    }
//                                    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//                                        print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
//                                        return
//                                    }
//                                    
//                                    Task {
//                                        try await AuthService.shared.signInWithApple(idToken: idTokenString, rawNonce: nonce)
//                                        if userVM.isLoggedIn {
//                                            dismiss()
//                                        }
//                                    }
//                                default:
//                                    break
//                                    
//                                }
//                            default:
//                                break
//                            }
//                        })
//                        .frame(height: 50)
//                        .signInWithAppleButtonStyle(.white)
//                        .cornerRadius(30)
//                        .shadow(color: .black.opacity(0.3), radius: 3, x: 4, y: 4)
//                        
//                    }
//                    
                    
                    
                    // Footer links
                    HStack(spacing: 15) {
                        Button("Terms") {}
                        Button("Privacy Policy") {}
                        Button("Contact Us") {}
                    }
                    .font(.caption2)
                    .padding(.bottom, 10)
                }
                .padding(.horizontal, 30)
                
            }
        }
    }
    func isValidEmail(_ email: String) -> Bool {
        // expresie regex simplă, nu 100% completă dar bună pentru început
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
//    private func randomNonceString(length: Int = 32) -> String {
//            precondition(length > 0)
//            var randomBytes = [UInt8](repeating: 0, count: length)
//            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
//            if errorCode != errSecSuccess {
//                fatalError(
//                    "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
//                )
//            }
//            
//            let charset: [Character] =
//            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//            
//            let nonce = randomBytes.map { byte in
//                // Pick a random character from the set, wrapping around if needed.
//                charset[Int(byte) % charset.count]
//            }
//            
//            return String(nonce)
//        }
//        
//        @available(iOS 13, *)
//        private func sha256(_ input: String) -> String {
//            let inputData = Data(input.utf8)
//            let hashedData = SHA256.hash(data: inputData)
//            let hashString = hashedData.compactMap {
//                String(format: "%02x", $0)
//            }.joined()
//            
//            return hashString
//        }
}
