//
//  EntrepreneurDashboardView.swift
//  Ignite
//
//  Created by Henry Bowman on 4/5/25.
//

import SwiftUI
import Charts

struct EntrepreneurDashboardView: View {
    @StateObject private var viewModel = EntrepreneurDashboardViewModel()
    @State private var showingCreateBusinessSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Quick Stats
                    statsSection
                    
                    // Business List Header with Action Button
                    HStack {
                        Text("My Businesses")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            showingCreateBusinessSheet = true
                        }) {
                            Label("Add", systemImage: "plus.circle.fill")
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Constants.UI.primaryColor)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Business Cards
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if viewModel.businesses.isEmpty {
                        emptyBusinessState
                    } else {
                        businessList
                    }
                    
                    // Funding Activity
                    if !viewModel.businesses.isEmpty {
                        fundingActivitySection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingCreateBusinessSheet) {
                Text("Create Business View")
                    .presentationDetents([.large])
            }
        }
    }
    
    // MARK: - View Components
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, \(viewModel.userName)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Welcome to your business dashboard")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private var statsSection: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                statCard(
                    title: "Businesses",
                    value: "\(viewModel.businesses.count)",
                    icon: "briefcase.fill",
                    color: .blue
                )
                
                statCard(
                    title: "Total Raised",
                    value: viewModel.totalFundingRaisedFormatted,
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 15) {
                statCard(
                    title: "Investor Matches",
                    value: "\(viewModel.totalInvestorMatches)",
                    icon: "person.2.fill",
                    color: .purple
                )
                
                statCard(
                    title: "Funding Goal",
                    value: viewModel.totalFundingGoalFormatted,
                    icon: "chart.bar.fill",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var emptyBusinessState: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .padding()
            
            Text("Create Your First Business")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start by adding information about your business idea and set funding goals.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingCreateBusinessSheet = true
            }) {
                Text("Create Business")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Constants.UI.primaryColor)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var businessList: some View {
        VStack(spacing: 15) {
            ForEach(viewModel.businesses) { business in
                BusinessCardView(business: business)
                    .padding(.horizontal)
            }
        }
    }
    
    private var fundingActivitySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Funding Progress")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if #available(iOS 16.0, *) {
                fundingChart
            } else {
                // Fallback for iOS 15
                Text("Funding chart available in iOS 16 and later")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            recentActivityList
        }
    }
    
    @available(iOS 16.0, *)
    private var fundingChart: some View {
        Chart {
            ForEach(viewModel.businesses) { business in
                BarMark(
                    x: .value("Business", business.name),
                    y: .value("Raised", business.fundingRaised)
                )
                .foregroundStyle(Color.blue.gradient)
                
                BarMark(
                    x: .value("Business", business.name),
                    y: .value("Remaining", business.fundingGoal - business.fundingRaised)
                )
                .foregroundStyle(Color.gray.opacity(0.3).gradient)
            }
        }
        .frame(height: 250)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var recentActivityList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            if viewModel.recentActivities.isEmpty {
                Text("No recent activity to show")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.recentActivities, id: \.id) { activity in
                    HStack(spacing: 15) {
                        Image(systemName: activity.icon)
                            .font(.system(size: 24))
                            .foregroundColor(activity.iconColor)
                            .frame(width: 40, height: 40)
                            .background(activity.iconColor.opacity(0.1))
                            .cornerRadius(20)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(activity.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(activity.timeAgo)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Business Card View
struct BusinessCardView: View {
    let business: Business
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Business Image
            if let firstImageURL = business.imageURLs.first, let url = URL(string: firstImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    )
            }
            
            // Business Name & Category
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(business.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(business.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(business.stage.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(stageColor(for: business.stage).opacity(0.2))
                    .foregroundColor(stageColor(for: business.stage))
                    .cornerRadius(8)
            }
            
            // Funding Progress
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(Int(business.fundingProgress))% Funded")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(business.formattedFundingRaised) of \(business.formattedFundingGoal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 10)
                            .opacity(0.3)
                            .foregroundColor(.gray)
                            .cornerRadius(5)
                        
                        Rectangle()
                            .frame(width: min(CGFloat(business.fundingProgress) * geometry.size.width / 100, geometry.size.width), height: 10)
                            .foregroundColor(.blue)
                            .cornerRadius(5)
                    }
                }
                .frame(height: 10)
            }
            
            // Investor Matches
            HStack {
                Label("\(business.likedByInvestors.count) interested investors", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink(destination: Text("Business Detail View for \(business.name)")) {
                    Text("View Details")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func stageColor(for stage: BusinessStage) -> Color {
        switch stage {
        case .idea:
            return .purple
        case .prototype:
            return .blue
        case .mvp:
            return .green
        case .growth:
            return .orange
        case .scaling:
            return .red
        }
    }
}

// MARK: - ViewModel
class EntrepreneurDashboardViewModel: ObservableObject {
    @Published var businesses: [Business] = []
    @Published var recentActivities: [ActivityItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    var userName: String {
        AuthService.shared.currentUser?.name.components(separatedBy: " ").first ?? "Entrepreneur"
    }
    
    var totalFundingRaised: Double {
        businesses.reduce(0) { $0 + $1.fundingRaised }
    }
    
    var totalFundingRaisedFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalFundingRaised)) ?? "$\(Int(totalFundingRaised))"
    }
    
    var totalFundingGoal: Double {
        businesses.reduce(0) { $0 + $1.fundingGoal }
    }
    
    var totalFundingGoalFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalFundingGoal)) ?? "$\(Int(totalFundingGoal))"
    }
    
    var totalInvestorMatches: Int {
        var uniqueInvestors = Set<String>()
        for business in businesses {
            for investorId in business.likedByInvestors {
                uniqueInvestors.insert(investorId)
            }
        }
        return uniqueInvestors.count
    }
    
    init() {
        // Load initial data
        Task {
            await loadData()
        }
        
        // Sample activity data - in a real app, these would come from a database
        loadSampleActivities()
    }
    
    @MainActor
    func loadData() async {
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        isLoading = true
        error = nil
        
        // Example implementation - in a real app, this would fetch from Firebase
        // For now, we'll use sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            
            self.businesses = [
                Business(
                    id: UUID().uuidString,
                    entrepreneurId: currentUser.id,
                    name: "EcoFriendly Packaging",
                    tagline: "Sustainable packaging solutions",
                    description: "Creating eco-friendly packaging alternatives for small businesses",
                    problem: "Plastic packaging creates significant environmental waste",
                    solution: "Our biodegradable packaging made from plant materials",
                    targetMarket: "Small to medium retailers and food businesses",
                    businessModel: "Direct sales to businesses with subscription options",
                    stage: .prototype,
                    category: "Environment",
                    fundingGoal: 35000,
                    fundingRaised: 12500,
                    equity: 15,
                    imageURLs: ["https://example.com/image1.jpg"],
                    likedByInvestors: ["investor1", "investor2", "investor3"]
                ),
                Business(
                    id: UUID().uuidString,
                    entrepreneurId: currentUser.id,
                    name: "Study Buddy App",
                    tagline: "Connect with study partners",
                    description: "App that connects students for study sessions and homework help",
                    problem: "Students struggle to find compatible study partners",
                    solution: "AI-powered matching algorithm connects students with similar needs",
                    targetMarket: "High school and college students",
                    businessModel: "Freemium model with premium features",
                    stage: .mvp,
                    category: "Education",
                    fundingGoal: 20000,
                    fundingRaised: 15000,
                    equity: 10,
                    imageURLs: ["https://example.com/image2.jpg"],
                    likedByInvestors: ["investor2", "investor4"]
                )
            ]
            
            self.isLoading = false
        }
    }
    
    private func loadSampleActivities() {
        recentActivities = [
            ActivityItem(
                id: "1",
                icon: "dollarsign.circle.fill",
                iconColor: .green,
                title: "New Investment",
                description: "EcoFriendly Packaging received a $5,000 investment",
                timeAgo: "2 hours ago"
            ),
            ActivityItem(
                id: "2",
                icon: "person.fill.checkmark",
                iconColor: .blue,
                title: "Investor Match",
                description: "2 new investors liked your Study Buddy App",
                timeAgo: "1 day ago"
            ),
            ActivityItem(
                id: "3",
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .purple,
                title: "Funding Milestone",
                description: "Study Buddy App reached 75% of funding goal",
                timeAgo: "3 days ago"
            )
        ]
    }
}

// MARK: - Activity Model
struct ActivityItem: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let timeAgo: String
}

struct EntrepreneurDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        EntrepreneurDashboardView()
    }
}
