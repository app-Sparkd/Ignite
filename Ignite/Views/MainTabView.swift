//
//  MainTabView.swift
//  Ignite
//
//  Created by Henry Bowman on 4/5/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var authService = AuthService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if let user = authService.currentUser {
                Group {
                    switch user.userType {
                    case .entrepreneur:
                        // Entrepreneur Tabs
                        EntrepreneurDashboardView()
                            .tabItem {
                                Label("Dashboard", systemImage: "chart.bar.fill")
                            }
                            .tag(0)
                        
                        Text("My Businesses")
                            .tabItem {
                                Label("Businesses", systemImage: "briefcase.fill")
                            }
                            .tag(1)
                        
                        Text("Investors")
                            .tabItem {
                                Label("Investors", systemImage: "person.2.fill")
                            }
                            .tag(2)
                        
                    case .investor:
                        // Investor Tabs
                        InvestorDashboardView()
                            .tabItem {
                                Label("Dashboard", systemImage: "chart.bar.fill")
                            }
                            .tag(0)
                        
                        Text("Discover")
                            .tabItem {
                                Label("Discover", systemImage: "flame.fill")
                            }
                            .tag(1)
                        
                        Text("Investments")
                            .tabItem {
                                Label("Investments", systemImage: "dollarsign.circle.fill")
                            }
                            .tag(2)
                        
                    case .admin:
                        // Admin Tabs
                        Text("Admin Dashboard")
                            .tabItem {
                                Label("Dashboard", systemImage: "chart.bar.fill")
                            }
                            .tag(0)
                        
                        Text("Users")
                            .tabItem {
                                Label("Users", systemImage: "person.3.fill")
                            }
                            .tag(1)
                        
                        Text("Businesses")
                            .tabItem {
                                Label("Businesses", systemImage: "building.2.fill")
                            }
                            .tag(2)
                    }
                }
                
                // Common Tab for all user types
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(3)
            }
        }
        .accentColor(Constants.UI.primaryColor)
    }
}

// MARK: - Profile View for all users
struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 15) {
                        // Profile image
                        if let photoURL = authService.currentUser?.photoURL, !photoURL.isEmpty {
                            AsyncImage(url: URL(string: photoURL)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(Color.gray.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        // User details
                        VStack(alignment: .leading, spacing: 6) {
                            if let user = authService.currentUser {
                                Text(user.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(user.userType.rawValue.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 10)
                } header: {
                    Text("My Profile")
                }
                
                // Settings section
                Section {
                    NavigationLink(destination: Text("Account Settings")) {
                        Label("Account Settings", systemImage: "person.text.rectangle")
                    }
                    
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                    
                    if let user = authService.currentUser, user.userType == .investor {
                        NavigationLink(destination: Text("Payment Methods")) {
                            Label("Payment Methods", systemImage: "creditcard.fill")
                        }
                    }
                    
                    NavigationLink(destination: Text("Privacy")) {
                        Label("Privacy & Security", systemImage: "lock.fill")
                    }
                } header: {
                    Text("Settings")
                }
                
                // Support section
                Section {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle.fill")
                    }
                    
                    NavigationLink(destination: Text("Contact Support")) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                    
                    NavigationLink(destination: Text("About")) {
                        HStack {
                            Label("About \(Constants.App.name)", systemImage: "info.circle.fill")
                            Spacer()
                            Text("v\(Constants.App.version)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("Support")
                }
                
                // Sign out button
                Section {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut { _ in }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
