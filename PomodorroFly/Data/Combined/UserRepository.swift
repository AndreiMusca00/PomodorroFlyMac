//
//  UserRepository.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//
import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class UserRepository: ObservableObject {
    @Published private(set) var currentUser: UserModel = UserModel.empty
    
    @Published private(set) var currentUserReady: Bool = false
    @Published var isReady: Bool = false
    
    private let remote: UserRemote
    private var userListener: ListenerRegistration?
    private var cancellable: AnyCancellable?
    
    init(remote: UserRemote = UserRemote(), authService: AuthService ) {
        self.remote = remote
        
        // Observăm schimbarea userului
        cancellable = authService.$currentUser.sink { [weak self] user in
            Task { await self?.handleAuthUserChange(user) }
        }
    }
    
    private func updateIsReady() {
        // Dacă currentUser e gata și prietenii sunt gata (sau nu avem prieteni), repo e gata
        if currentUserReady {
            isReady = true
        }
    }

    // MARK: - Auth / Current User
    private func handleAuthUserChange(_ authUser: User?) async {
        removeUserListener()
        currentUser = .empty
        
        currentUserReady = false
        isReady = false
        
        guard let authUser = authUser else {
            // user delogat → repo gata
            currentUserReady = true
            updateIsReady()
            return
        }
        
        do {
            try await loadOrCreateUser(uid: authUser.uid, email: authUser.email ?? "")
            currentUserReady = true
            updateIsReady()
        } catch {
            print("❌ Failed to loadOrCreateUser: \(error)")
            currentUserReady = true
            updateIsReady()
        }
    }
    
    func loadOrCreateUser(uid: String, email: String) async throws {
        if let existing = try await remote.fetchUser(uid: uid) {
            self.currentUser = existing
            observeUserChanges(uid: uid)
            return
        }
        
        let newUser = UserModel(
            id: uid,
            addedDateTime: Date().description,
            email: email,
            name: "",
            isUsernameSet: false,
            isPremium: false,
            subscriptionType: nil,
            subscriptionStartDate: nil,
            subscriptionEndDate: nil,
            lastReceiptData: nil
        )
        
        try await remote.createUser(newUser)
        self.currentUser = newUser
        observeUserChanges(uid: uid)
    }
    
    func updateCurrentUser(_ user: UserModel) async {
        self.currentUser = user
        do {
            try await remote.updateUser(user)
        } catch {
            print("⚠️ Eroare update user: \(error.localizedDescription)")
        }
    }
    
    func deleteCurrentUser() async throws {
        let uid = currentUser.id
        try await remote.deleteUser(uid: uid)
        self.currentUser = UserModel.empty
    }
    
    // MARK: - Friends / Other Users
    func searchUsers(byName name: String) async throws -> [UserModel] {
        return try await remote.searchUsers(byName: name)
    }
    
    func checkUsernameExists(_ username: String) async throws -> Bool {
        try await remote.checkUsernameExists(username)
    }
    
    // MARK: - Live updates
    private func observeUserChanges(uid: String) {
        userListener?.remove()
        let db = Firestore.firestore()
        
        userListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snapshot, let data = snapshot.data() else { return }
                guard
                    let addedDateTime = data["addedDateTime"] as? String,
                    let name = data["name"] as? String,
                    let email = data["email"] as? String,
                    let isUserNameSet = data["isUserNameSet"] as? Bool,
                    let isPremium = data["isPremium"] as? Bool
                else { return }
                
                let subscriptionType = data["subscriptionType"] as? String
                let subscriptionStartDate = data["subscriptionStartDate"] as? String
                let subscriptionEndDate = data["subscriptionEndDate"] as? String
                let lastReceiptData = data["lastReceiptData"] as? String
                
                let updatedUser = UserModel(
                    id: uid,
                    addedDateTime: addedDateTime,
                    email: email,
                    name: name,
                    isUsernameSet: isUserNameSet,
                    isPremium: isPremium,
                    subscriptionType: subscriptionType,
                    subscriptionStartDate: subscriptionStartDate,
                    subscriptionEndDate: subscriptionEndDate,
                    lastReceiptData: lastReceiptData
                )
                
                Task { @MainActor in
                    self.currentUser = updatedUser
                }
            }
    }
    
    private func removeUserListener() {
        userListener?.remove()
        userListener = nil
    }
}
