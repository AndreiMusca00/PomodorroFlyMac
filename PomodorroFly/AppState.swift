//
//  AppState.swift
//  PomodorroFly
//
//  Created by Andrei Musca on 05.11.2025.
//

//
//  AppStateViewModel.swift
//  PursePartners
//
//  Created by Andrei Musca on 03.09.2025.

import SwiftUI
import Combine

@MainActor
final class AppStateViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService, userRepo: UserRepository) {
        
        Publishers.CombineLatest(
            authService.$isLoading,
            userRepo.$isReady,
        )
        .map { authLoading, userReady in
            // loading = true dacă auth încă se încarcă sau repo-urile nu sunt gata
            authLoading || !userReady
        }
        .receive(on: RunLoop.main)
        .assign(to: \.isLoading, on: self)
        .store(in: &cancellables)
    }
}
