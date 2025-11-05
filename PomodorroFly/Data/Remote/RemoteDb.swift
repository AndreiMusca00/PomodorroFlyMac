//
//  RemoteDb.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Firebase

final class RemoteDb {
    static let shared = RemoteDb()

    let firestore: Firestore
    let auth: Auth

    private init() {
        self.firestore = Firestore.firestore()
        self.auth = Auth.auth()

        print("✅ Remote DB initialized (Firebase)")
    }

    var currentUserId: String? {
        auth.currentUser?.uid
    }

    func collection(_ name: String) -> CollectionReference {
        firestore.collection(name)
    }

    func document(_ path: String) -> DocumentReference {
        firestore.document(path)
    }
}
