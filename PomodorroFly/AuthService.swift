//
//  AuthService.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var currentUser: User? = Auth.auth().currentUser
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        observeAuthState()
    }
    
    private func observeAuthState() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isLoading = false
            }
        }
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Sign In / Sign Up
    func login(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUser = result.user
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            currentUser = authResult.user
        } catch let error as NSError {
            if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                throw NSError(domain: "SignupError", code: 409, userInfo: [NSLocalizedDescriptionKey: "Există deja un cont cu acest email."])
            } else if error.code == AuthErrorCode.invalidEmail.rawValue {
                throw NSError(domain: "SignupError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email invalid."])
            } else if error.code == AuthErrorCode.weakPassword.rawValue {
                throw NSError(domain: "SignupError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Parola este prea slabă."])
            } else {
                throw error
            }
        }
    }
    
    func signInWithApple(idToken: String, rawNonce: String) async throws {
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idToken,
            rawNonce: rawNonce,
            accessToken: nil
        )
        let result = try await Auth.auth().signIn(with: credential)
        currentUser = result.user
    }
    
    
    func logOut() async throws {
        try Auth.auth().signOut()
        currentUser = nil
    }
    
   
    
    func deleteCurrentUser() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Nu există user autentificat."])
        }
        
        do {
            try await user.delete()
            currentUser = nil
        } catch let error as NSError {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Reautentificare necesară înainte de ștergere."])
            } else {
                throw NSError(domain: "AuthError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Eroare la ștergerea contului: \(error.localizedDescription)"])
            }
        }
    }
}
