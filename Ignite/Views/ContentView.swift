import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        ZStack {
            if authService.isLoading {
                loadingView
            } else if !authService.isAuthenticated {
                AuthenticationView()
            } else {
                mainView
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { authService.error != nil },
            set: { if !$0 { authService.error = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(authService.error ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)
            
            Text("Loading...")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 20)
        }
    }
    
    private var mainView: some View {
        TabView {
            if let user = authService.currentUser {
                switch user.userType {
                case .entrepreneur:
                    EntrepreneurDashboardPlaceholder()
                        .tabItem {
                            Label("Dashboard", systemImage: "chart.pie.fill")
                        }
                    
                    Text("My Businesses")
                        .tabItem {
                            Label("Businesses", systemImage: "briefcase.fill")
                        }
                    
                case .investor:
                    InvestorDashboardPlaceholder()
                        .tabItem {
                            Label("Dashboard", systemImage: "chart.pie.fill")
                        }
                    
                    Text("Discover")
                        .tabItem {
                            Label("Discover", systemImage: "flame.fill")
                        }
                    
                case .admin:
                    Text("Admin Dashboard")
                        .tabItem {
                            Label("Dashboard", systemImage: "gear")
                        }
                }
                
                ProfilePlaceholder()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
        }
    }
}

// Placeholder views until we implement the real ones
struct EntrepreneurDashboardPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Entrepreneur Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Coming soon!")
                .font(.headline)
            
            Button("Sign Out") {
                AuthService.shared.signOut { _ in }
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

struct InvestorDashboardPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Investor Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Coming soon!")
                .font(.headline)
            
            Button("Sign Out") {
                AuthService.shared.signOut { _ in }
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

struct ProfilePlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let user = AuthService.shared.currentUser {
                Text("Name: \(user.name)")
                Text("Email: \(user.email)")
                Text("Account Type: \(user.userType.rawValue.capitalized)")
            }
            
            Button("Sign Out") {
                AuthService.shared.signOut { _ in }
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
