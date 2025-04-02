//
//  Constants.swift
//  Ignite
//
//  Created by Henry Bowman on 4/5/25.
//

import SwiftUI

struct Constants {
    // MARK: - Database Collection Names
    struct Collections {
        static let users = "users"
        static let entrepreneurs = "entrepreneurs"
        static let investors = "investors"
        static let businesses = "businesses"
        static let investments = "investments"
        static let notifications = "notifications"
    }
    
    // MARK: - Storage Paths
    struct StoragePaths {
        static let profileImages = "profile_images"
        static let businessImages = "business_images"
        static let pitchDecks = "pitch_decks"
        static let contracts = "contracts"
    }
    
    // MARK: - UI Constants
    struct UI {
        // Colors
        static let primaryColor = Color.blue
        static let secondaryColor = Color.purple
        static let accentColor = Color.orange
        static let backgroundColor = Color(UIColor.systemBackground)
        static let secondaryBackgroundColor = Color(UIColor.secondarySystemBackground)
        
        // Font Sizes
        static let titleFont = Font.largeTitle.bold()
        static let headlineFont = Font.headline
        static let bodyFont = Font.body
        static let captionFont = Font.caption
        
        // Spacing
        static let smallSpacing: CGFloat = 8
        static let mediumSpacing: CGFloat = 16
        static let largeSpacing: CGFloat = 24
        
        // Corner Radius
        static let smallRadius: CGFloat = 8
        static let mediumRadius: CGFloat = 12
        static let largeRadius: CGFloat = 20
        
        // Card Dimensions
        static let cardWidth: CGFloat = UIScreen.main.bounds.width - 40
        static let cardHeight: CGFloat = 400
        
        // Animation Durations
        static let fastAnimation: Double = 0.2
        static let standardAnimation: Double = 0.3
        static let slowAnimation: Double = 0.5
    }
    
    // MARK: - Business Categories
    static let businessCategories = [
        "Technology",
        "Education",
        "Health",
        "Food",
        "Fashion",
        "Environment",
        "Social",
        "Gaming",
        "Art",
        "Other"
    ]
    
    // MARK: - Investment Tiers
    static let investmentTiers = [
        "Seed": 1000.0,
        "Angel": 5000.0,
        "Series A": 10000.0,
        "Series B": 25000.0
    ]
    
    // MARK: - Validation
    struct Validation {
        static let minPasswordLength = 6
        static let minBusinessNameLength = 3
        static let maxBusinessNameLength = 50
        static let minBusinessDescriptionLength = 20
        static let maxBusinessDescriptionLength = 500
        static let minFundingGoal: Double = 500.0
        static let maxFundingGoal: Double = 100000.0
        static let minEquityPercentage: Double = 1.0
        static let maxEquityPercentage: Double = 49.0
    }
    
    // MARK: - App Information
    struct App {
        static let name = "Teen Business Connect"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let contactEmail = "support@teenbusinessconnect.com"
        static let privacyPolicyURL = "https://teenbusinessconnect.com/privacy"
        static let termsURL = "https://teenbusinessconnect.com/terms"
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let defaultError = "Something went wrong. Please try again."
        static let networkError = "Network error. Please check your connection."
        static let authError = "Authentication failed. Please try again."
        static let permissionError = "You don't have permission to perform this action."
        static let validationError = "Please check your information and try again."
        static let businessCreationError = "Failed to create business. Please try again."
        static let investmentError = "Failed to process investment. Please try again."
    }
}
