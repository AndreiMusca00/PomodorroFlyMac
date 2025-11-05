//
//  UserRemote.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//

import Foundation
import FirebaseFirestore

final class UserRemote {
    static let shared = UserRemote()
    private let db: Firestore
    
    init() {
        self.db = RemoteDb.shared.firestore
    }
    
    func fetchUser(uid: String) async throws -> UserModel? {
        let userRef = db.collection("users").document(uid)
        let document = try await userRef.getDocument()
        
        guard let data = document.data(),
              let addedDateTime = data["addedDateTime"] as? String,
              let name = data["name"] as? String,
              let email = data["email"] as? String,
              let isUserNameSet = data["isUserNameSet"] as? Bool
        else {
            return nil
        }
        
        return UserModel(
            id: uid,
            addedDateTime: addedDateTime,
            email: email,
            name: name,
            isUsernameSet: isUserNameSet,
            isPremium: data["isPremium"] as? Bool ?? false,
            subscriptionType: data["subscriptionType"] as? String,
            subscriptionStartDate: data["subscriptionStartDate"] as? String,
            subscriptionEndDate: data["subscriptionEndDate"] as? String,
            lastReceiptData: data["lastReceiptData"] as? String
        )
    }
    
    func searchUsers(byName name: String) async throws -> [UserModel] {
        let query = db.collection("users")
            .whereField("name", isGreaterThanOrEqualTo: name)
            .whereField("name", isLessThan: name + "\u{f8ff}") // pentru prefix search
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let addedDateTime = data["addedDateTime"] as? String,
                  let name = data["name"] as? String,
                  let email = data["email"] as? String,
                  let isUserNameSet = data["isUserNameSet"] as? Bool else {
                return nil
            }
            
            return UserModel(
                id: doc.documentID,
                addedDateTime: addedDateTime,
                email: email,
                name: name,
                isUsernameSet: isUserNameSet,
                isPremium: data["isPremium"] as? Bool ?? false,
                subscriptionType: data["subscriptionType"] as? String,
                subscriptionStartDate: data["subscriptionStartDate"] as? String,
                subscriptionEndDate: data["subscriptionEndDate"] as? String,
                lastReceiptData: data["lastReceiptData"] as? String
            )
        }
    }
    
    func createUser(_ user: UserModel) async throws {
        try await db.collection("users").document(user.id).setData([
            "id": user.id,
            "addedDateTime": user.addedDateTime,
            "email": user.email,
            "name": user.name,
            "isUserNameSet": user.isUsernameSet,
            "isPremium": user.isPremium,
            "subscriptionType": user.subscriptionType as Any,
            "subscriptionStartDate": user.subscriptionStartDate as Any,
            "subscriptionEndDate": user.subscriptionEndDate as Any,
            "lastReceiptData": user.lastReceiptData as Any
        ])
    }
    
    func updateUser(_ user: UserModel) async throws {
        try await db.collection("users").document(user.id).setData([
            "id": user.id,
            "addedDateTime": user.addedDateTime,
            "email": user.email,
            "name": user.name,
            "isUserNameSet": user.isUsernameSet,
            "isPremium": user.isPremium,
            "subscriptionType": user.subscriptionType as Any,
            "subscriptionStartDate": user.subscriptionStartDate as Any,
            "subscriptionEndDate": user.subscriptionEndDate as Any,
            "lastReceiptData": user.lastReceiptData as Any
        ])
    }
    
    func deleteUser(uid: String) async throws {
        try await db.collection("users").document(uid).delete()
    }
    
    func checkUsernameExists(_ username: String) async throws -> Bool {
        let query = db.collection("users").whereField("name", isEqualTo: username)
        let snapshot = try await query.getDocuments()
        return !snapshot.documents.isEmpty
    }
}
