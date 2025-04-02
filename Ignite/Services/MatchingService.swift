//
//  MatchingService.swift
//  Ignite
//
//  Created by Henry Bowman on 4/6/25.
//

import Foundation
import Firebase
import FirebaseFirestore

enum MatchingError: Error {
    case fetchFailed(String)
    case updateFailed(String)
    case notAuthorized
    case noMoreBusinesses
    case invalidData
}

/// Service to handle matching between investors and businesses
class MatchingService {
    // MARK: - Singleton
    static let shared = MatchingService()
    
    // MARK: - Properties
    private let db = FirebaseManager.shared.db
    private let businessService = BusinessService.shared
    private let notificationManager = NotificationManager.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Matching Operations
    
    /// Get next batch of businesses for the investor to swipe
    /// - Parameters:
    ///   - batchSize: Number of businesses to fetch
    ///   - categories: Optional array of categories to filter by
    ///   - completion: Result with array of businesses or error
    func getNextBusinessBatch(batchSize: Int = 10,
                             categories: [String]? = nil,
                             completion: @escaping (Result<[Business], MatchingError>) -> Void) {
        
        guard let investorID = FirebaseManager.shared.currentUserID else {
            completion(.failure(.notAuthorized))
            return
        }
        
        // Get investor preferences
        getInvestorPreferences(investorID: investorID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let preferences):
                // Use preferences to get matching businesses
                let investorCategories = preferences.investmentFocus.isEmpty ? nil : preferences.investmentFocus
                let finalCategories = categories ?? investorCategories
                
                self.businessService.getBusinessesForInvestor(
                    investorID: investorID,
                    categories: finalCategories,
                    limit: batchSize
                ) { result in
                    switch result {
                    case .success(let businesses):
                        if businesses.isEmpty {
                            completion(.failure(.noMoreBusinesses))
                        } else {
                            completion(.success(businesses))
                        }
                    case .failure(let error):
                        completion(.failure(.fetchFailed(error.localizedDescription)))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get matches for an entrepreneur
    /// - Parameters:
    ///   - entrepreneurID: ID of the entrepreneur
    ///   - completion: Result with array of investor matches or error
    func getEntrepreneurMatches(entrepreneurID: String,
                               completion: @escaping (Result<[Match], MatchingError>) -> Void) {
        
        // First get all businesses owned by the entrepreneur
        businessService.getEntrepreneurBusinesses { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let businesses):
                if businesses.isEmpty {
                    completion(.success([]))
                    return
                }
                
                // Get all matches for each business
                let businessIDs = businesses.map { $0.id }
                self.getMatchesForBusinesses(businessIDs: businessIDs) { result in
                    switch result {
                    case .success(let matches):
                        completion(.success(matches))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(.fetchFailed(error.localizedDescription)))
            }
        }
    }
    
    /// Get matches for an investor
    /// - Parameters:
    ///   - investorID: ID of the investor
    ///   - completion: Result with array of business matches or error
    func getInvestorMatches(investorID: String,
                           completion: @escaping (Result<[Match], MatchingError>) -> Void) {
        
        // Get businesses the investor has liked
        db.collection(Constants.Collections.investors).document(investorID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(.fetchFailed(error.localizedDescription)))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists,
                  let data = snapshot.data(),
                  let likedBusinesses = data["likedBusinesses"] as? [String] else {
                completion(.failure(.invalidData))
                return
            }
            
            if likedBusinesses.isEmpty {
                completion(.success([]))
                return
            }
            
            // Get matches (mutual likes)
            self.getMatchesForInvestor(investorID: investorID, likedBusinessIDs: likedBusinesses) { result in
                switch result {
                case .success(let matches):
                    completion(.success(matches))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Swipe Actions
    
    /// Handle investor swiping right (like) on a business
    /// - Parameters:
    ///   - businessID: ID of the business
    ///   - completion: Result with match status or error
    func swipeRight(businessID: String,
                   completion: @escaping (Result<MatchStatus, MatchingError>) -> Void) {
        
        guard let investorID = FirebaseManager.shared.currentUserID else {
            completion(.failure(.notAuthorized))
            return
        }
        
        businessService.likeBusiness(businessID: businessID, investorID: investorID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Check if this created a match (mutual like)
                self.checkForMatch(businessID: businessID, investorID: investorID) { result in
                    switch result {
                    case .success(let isMatch):
                        if isMatch {
                            // It's a match!
                            completion(.success(.match))
                        } else {
                            // Just a like, no match yet
                            completion(.success(.liked))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(.updateFailed(error.localizedDescription)))
            }
        }
    }
    
    /// Handle investor swiping left (dislike) on a business
    /// - Parameters:
    ///   - businessID: ID of the business
    ///   - completion: Result with success or error
    func swipeLeft(businessID: String,
                  completion: @escaping (Result<Void, MatchingError>) -> Void) {
        
        guard let investorID = FirebaseManager.shared.currentUserID else {
            completion(.failure(.notAuthorized))
            return
        }
        
        businessService.dislikeBusiness(businessID: businessID, investorID: investorID) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(.updateFailed(error.localizedDescription)))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get investor preferences
    /// - Parameters:
    ///   - investorID: ID of the investor
    ///   - completion: Result with investor preferences or error
    private func getInvestorPreferences(investorID: String,
                                     completion: @escaping (Result<InvestorPreferences, MatchingError>) -> Void) {
        
        db.collection(Constants.Collections.investors).document(investorID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(.fetchFailed(error.localizedDescription)))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists,
                  let data = snapshot.data() else {
                completion(.failure(.invalidData))
                return
            }
            
            let investmentFocus = data["investmentFocus"] as? [String] ?? []
            let minAmount = data["minInvestmentAmount"] as? Double
            let maxAmount = data["maxInvestmentAmount"] as? Double
            
            let preferences = InvestorPreferences(
                investmentFocus: investmentFocus,
                minInvestmentAmount: minAmount,
                maxInvestmentAmount: maxAmount
            )
            
            completion(.success(preferences))
        }
    }
    
    /// Check if a business and investor have a mutual like (match)
    /// - Parameters:
    ///   - businessID: ID of the business
    ///   - investorID: ID of the investor
    ///   - completion: Result with match status or error
    private func checkForMatch(businessID: String,
                            investorID: String,
                            completion: @escaping (Result<Bool, MatchingError>) -> Void) {
        
        // Get the business to check if entrepreneur has liked the investor
        businessService.getBusiness(id: businessID) { result in
            switch result {
            case .success(let business):
                let isMatch = business.likedByInvestors.contains(investorID)
                completion(.success(isMatch))
            case .failure(let error):
                completion(.failure(.fetchFailed(error.localizedDescription)))
            }
        }
    }
    
    /// Get matches for a list of businesses
    /// - Parameters:
    ///   - businessIDs: Array of business IDs
    ///   - completion: Result with array of matches or error
    private func getMatchesForBusinesses(businessIDs: [String],
                                      completion: @escaping (Result<[Match], MatchingError>) -> Void) {
        
        let group = DispatchGroup()
        var matches: [Match] = []
        var fetchError: MatchingError?
        
        for businessID in businessIDs {
            group.enter()
            
            // Get business details
            businessService.getBusiness(id: businessID) { result in
                switch result {
                case .success(let business):
                    // For each investor who liked this business
                    for investorID in business.likedByInvestors {
                        // Create a match object
                        let match = Match(
                            businessID: businessID,
                            businessName: business.name,
                            businessImageURL: business.imageURLs.first,
                            entrepreneurID: business.entrepreneurId,
                            investorID: investorID,
                            createdAt: Date() // Ideally we'd track the actual match date
                        )
                        
                        matches.append(match)
                    }
                case .failure:
                    // Continue even if one business fails
                    break
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success(matches))
            }
        }
    }
    
    /// Get matches for an investor
    /// - Parameters:
    ///   - investorID: ID of the investor
    ///   - likedBusinessIDs: Array of business IDs liked by the investor
    ///   - completion: Result with array of matches or error
    private func getMatchesForInvestor(investorID: String,
                                    likedBusinessIDs: [String],
                                    completion: @escaping (Result<[Match], MatchingError>) -> Void) {
        
        let group = DispatchGroup()
        var matches: [Match] = []
        var fetchError: MatchingError?
        
        for businessID in likedBusinessIDs {
            group.enter()
            
            // Get business details
            businessService.getBusiness(id: businessID) { result in
                switch result {
                case .success(let business):
                    // Check if business has also liked the investor
                    if business.likedByInvestors.contains(investorID) {
                        // It's a match
                        let match = Match(
                            businessID: businessID,
                            businessName: business.name,
                            businessImageURL: business.imageURLs.first,
                            entrepreneurID: business.entrepreneurId,
                            investorID: investorID,
                            createdAt: Date() // Ideally we'd track the actual match date
                        )
                        
                        matches.append(match)
                    }
                case .failure:
                    // Continue even if one business fails
                    break
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success(matches))
            }
        }
    }
}

// MARK: - Supporting Models

/// Status of a match after swiping
enum MatchStatus {
    case liked    // Just liked, no match yet
    case match    // Mutual like (match)
}

/// Model representing investor preferences
struct InvestorPreferences {
    let investmentFocus: [String]
    let minInvestmentAmount: Double?
    let maxInvestmentAmount: Double?
}

/// Model representing a match between entrepreneur and investor
struct Match: Identifiable {
    let id = UUID().uuidString
    let businessID: String
    let businessName: String
    let businessImageURL: String?
    let entrepreneurID: String
    let investorID: String
    let createdAt: Date
    var hasMessaged: Bool = false
}
