//
//  UserViewModel.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class UserViewModel: ObservableObject {
    @Published var user: UserModel = UserModel.empty
    var isLoggedIn: Bool {
        !user.id.isEmpty
    }
    
    private let repository: UserRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: UserRepository) {
        self.repository = repository
        
        // 🔹 Observ userul din repo
        repository.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.user = user
            }
            .store(in: &cancellables)
    }
    
    func checkUsernameExists(_ username: String) async throws-> Bool {
        return try await repository.checkUsernameExists(username)
    }
    
    func updateUser(_ user: UserModel) async {
        await repository.updateCurrentUser(user)
    }
}
