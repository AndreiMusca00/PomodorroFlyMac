import SwiftUI

struct ContentView: View {
    @StateObject private var appState: AppStateViewModel
    @StateObject private var userVM: UserViewModel
    
    init() {
        let authService = AuthService.shared  // 🔑 un singur punct de intrar
        //MARK: Repos
        let userRepo = UserRepository(authService: authService)
        
        //MARK: VMs
        _userVM = StateObject(wrappedValue: UserViewModel(repository: userRepo))
        _appState = StateObject(wrappedValue: AppStateViewModel(authService: authService, userRepo: userRepo))
    }
    
    var body: some View {
            
            Group {
                 if !userVM.isLoggedIn {
                    LoginView()
                        .environmentObject(userVM)
                 } else {
                    MainView()
                        .environmentObject(userVM)
                      //  .environmentObject(sessionsVM)
                }
            }
        }
    
}
