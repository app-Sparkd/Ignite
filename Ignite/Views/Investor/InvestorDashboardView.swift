//
//  InvestorDashboardView.swift
//  Ignite
//
//  Created by Henry Bowman on 4/5/25.
//

import SwiftUI

struct InvestorDashboardView: View {
    @StateObject private var viewModel = InvestorDashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Portfolio Summary Card
                    portfolioSummaryCard
                    
                    // Investment Stats
                    statsSection
                    
                    // Recommended Businesses
                    recommendedBusinessesSection
                    
                    // Recent Investments
                    if !viewModel.investments.isEmpty {
                        recentInvestmentsSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, \(viewModel.userName)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Welcome to your investor dashboard")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private var portfolioSummaryCard: some View {
        VStack(spacing: 20) {
            Text("Portfolio Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Total Invested")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.totalInvestedFormatted)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 8) {
                    Text("Businesses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.investments.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 8) {
                    Text("Avg. Equity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.averageEquityFormatted)%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var statsSection: some View {
        VStack(spacing: 15) {
            HStack(spacing: 15) {
                statCard(
                    title: "Available Balance",
                    value: viewModel.availableBalanceFormatted,
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                statCard(
                    title: "Investment Opportunities",
                    value: "\(viewModel.recommendedBusinesses.count)",
                    icon: "lightbulb.fill",
                    color: .yellow
                )
            }
            
            HStack(spacing: 15) {
                statCard(
                    title: "Matched Businesses",
                    value: "\(viewModel.matchedBusinessCount)",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )
                
                statCard(
                    title: "Potential Returns",
                    value: "+\(viewModel.potentialReturnsFormatted)",
                    icon: "arrow.up.right.circle.fill",
                    color: .purple
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
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var recommendedBusinessesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recommended For You")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: Text("Discover View")) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if viewModel.recommendedBusinesses.isEmpty {
                Text("No recommendations at this time")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(viewModel.recommendedBusinesses) { business in
                            RecommendedBusinessCard(business: business)
                                .frame(width: 280, height: 320)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var recentInvestmentsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Investments")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                ForEach(viewModel.investments.prefix(3)) { investment in
                    InvestmentCardView(investment: investment)
                        .padding(.horizontal)
                }
            }
            
            if viewModel.investments.count > 3 {
                Button(action: {
                    // Navigate to all investments
                }) {
                    Text("View All Investments")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Recommended Business Card
struct RecommendedBusinessCard: View {
    let business: Business
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    )
            }
            
            // Business Info
            VStack(alignment: .leading, spacing: 8) {
                // Title and Category
                HStack {
                    Text(business.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(business.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Tagline
                Text(business.tagline)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Funding Details
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Funding Goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(business.formattedFundingGoal)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Equity Offered")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(business.equity))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 10) {
                    Button(action: {
                        // View Details
                    }) {
                        Text("Details")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        // Invest
                    }) {
                        Text("Invest Now")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(12)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Investment Card
struct InvestmentCardView: View {
    let investment: Investment
    @State private var businessName: String = "Loading..."
    @State private var businessCategory: String = ""
    
    var body: some View {
        HStack(spacing: 15) {
            // Business Logo Placeholder
            Color.gray.opacity(0.3)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.white)
                )
            
            // Investment Details
            VStack(alignment: .leading, spacing: 4) {
                Text(businessName)
                    .font(.headline)
                
                Text(businessCategory)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Invested: \(formattedAmount(investment.amount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Equity: \(String(format: "%.1f", investment.equityPercentage))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status Indicator
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge(for: investment.status)
                
                Text(formattedDate(investment.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            // In a real app, fetch the business details
            // For now, we'll simulate it with sample data
            loadBusinessDetails(for: investment.businessId)
        }
    }
    
    private func statusBadge(for status: InvestmentStatus) -> some View {
        let (backgroundColor, foregroundColor, text) = statusAttributes(for: status)
        
        return Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
    }
    
    private func statusAttributes(for status: InvestmentStatus) -> (Color, Color, String) {
        switch status {
        case .pending:
            return (Color.yellow.opacity(0.2), .orange, "Pending")
        case .completed:
            return (Color.green.opacity(0.2), .green, "Completed")
        case .cancelled:
            return (Color.red.opacity(0.2), .red, "Cancelled")
        }
    }
    
    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func loadBusinessDetails(for businessId: String) {
        // In a real app, fetch from Firebase
        // For demo purposes, we'll create a placeholder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.businessName = "Sample Business #\(Int.random(in: 1000...9999))"
            self.businessCategory = ["Technology", "Education", "Health", "Environment"].randomElement()!
        }
    }
}

// MARK: - Investment Model
struct Investment: Identifiable {
    var id: String
    var investorId: String
    var businessId: String
    var amount: Double
    var equityPercentage: Double
    var status: InvestmentStatus
    var contractURL: String?
    var transactionId: String?
    var createdAt: Date
    var completedAt: Date?
}

enum InvestmentStatus: String, Codable {
    case pending
    case completed
    case cancelled
}

// MARK: - ViewModel
class InvestorDashboardViewModel: ObservableObject {
    @Published var investments: [Investment] = []
    @Published var recommendedBusinesses: [Business] = []
    @Published var isLoading = false
    @Published var error: String?
    
    var userName: String {
        AuthService.shared.currentUser?.name.components(separatedBy: " ").first ?? "Investor"
    }
    
    var totalInvested: Double {
        investments.reduce(0) { $0 + $1.amount }
    }
    
    var totalInvestedFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalInvested)) ?? "$\(Int(totalInvested))"
    }
    
    var averageEquity: Double {
        guard !investments.isEmpty else { return 0 }
        return investments.reduce(0) { $0 + $1.equityPercentage } / Double(investments.count)
    }
    
    var averageEquityFormatted: String {
        String(format: "%.1f", averageEquity)
    }
    
    var availableBalance: Double = 50000 // Sample value
    
    var availableBalanceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: availableBalance)) ?? "$\(Int(availableBalance))"
    }
    
    var matchedBusinessCount: Int = 15 // Sample value
    
    var potentialReturns: Double = 8500 // Sample value
    
    var potentialReturnsFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: potentialReturns)) ?? "$\(Int(potentialReturns))"
    }
    
    init() {
        // Load initial data
        Task {
            await loadData()
        }
    }
    
    @MainActor
    func loadData() async {
        isLoading = true
        error = nil
        
        // In a real app, fetch from Firebase
        // For now, we'll use sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            
            // Sample investments
            self.investments = [
                Investment(
                    id: UUID().uuidString,
                    investorId: AuthService.shared.currentUser?.id ?? "",
                    businessId: "business1",
                    amount: 10000,
                    equityPercentage: 5.0,
                    status: .completed,
                    createdAt: Date().addingTimeInterval(-30*24*60*60) // 30 days ago
                ),
                Investment(
                    id: UUID().uuidString,
                    investorId: AuthService.shared.currentUser?.id ?? "",
                    businessId: "business2",
                    amount: 5000,
                    equityPercentage: 2.5,
                    status: .completed,
                    createdAt: Date().addingTimeInterval(-15*24*60*60) // 15 days ago
                ),
                Investment(
                    id: UUID().uuidString,
                    investorId: AuthService.shared.currentUser?.id ?? "",
                    businessId: "business3",
                    amount: 7500,
                    equityPercentage: 3.0,
                    status: .pending,
                    createdAt: Date().addingTimeInterval(-5*24*60*60) // 5 days ago
                )
            ]
            
            // Sample recommended businesses
            self.recommendedBusinesses = [
                Business(
                    id: UUID().uuidString,
                    entrepreneurId: "entrepreneur1",
                    name: "EcoTech Solutions",
                    tagline: "Sustainable technology for homes",
                    description: "Smart home technology that reduces energy consumption",
                    problem: "High energy costs and environmental impact",
                    solution: "AI-powered energy management system",
                    targetMarket: "Homeowners and apartment buildings",
                    businessModel: "Hardware sales with subscription service",
                    stage: .mvp,
                    category: "Technology",
                    fundingGoal: 75000,
                    fundingRaised: 30000,
                    equity: 15,
                    imageURLs: ["https://example.com/image1.jpg"]
                ),
                Business(
                    id: UUID().uuidString,
                    entrepreneurId: "entrepreneur2",
                    name: "HealthTrack",
                    tagline: "Personalized health monitoring",
                    description: "App that tracks health metrics and provides personalized advice",
                    problem: "Difficulty managing personal health data",
                    solution: "All-in-one health tracking and recommendation platform",
                    targetMarket: "Health-conscious consumers aged 25-55",
                    businessModel: "Freemium with premium subscription",
                    stage: .growth,
                    category: "Health",
                    fundingGoal: 50000,
                    fundingRaised: 35000,
                    equity: 10,
                    imageURLs: ["https://example.com/image2.jpg"]
                ),
                Business(
                    id: UUID().uuidString,
                    entrepreneurId: "entrepreneur3",
                    name: "LearnQuest",
                    tagline: "Gamified education for all ages",
                    description: "Educational platform that makes learning fun through games",
                    problem: "Lack of engagement in traditional education",
                    solution: "Game-based learning tailored to individual learning styles",
                    targetMarket: "Students and lifelong learners",
                    businessModel: "Subscription model with educational institutions",
                    stage: .prototype,
                    category: "Education",
                    fundingGoal: 40000,
                    fundingRaised: 10000,
                    equity: 12,
                    imageURLs: ["https://example.com/image3.jpg"]
                )
            ]
            
            self.isLoading = false
        }
    }
}

struct InvestorDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        InvestorDashboardView()
    }
}
