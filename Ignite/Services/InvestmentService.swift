//
//  InvestmentService.swift
//  Ignite
//
//  Created by Henry Bowman on 4/6/25.
//

import Foundation
import Firebase
import FirebaseFirestore

enum InvestmentError: Error {
    case creationFailed(String)
    case updateFailed(String)
    case fetchFailed(String)
    case notFound
    case invalidData
    case notAuthorized
    case insufficientFunds
    case businessNotFound
    case alreadyCompleted
    case invalidAmount
}

/// Service to handle investment-related operations with Firestore
class InvestmentService {
    // MARK: - Singleton
    static let shared = InvestmentService()
    
    // MARK: - Properties
    private let db = FirebaseManager.shared.db
    private let notificationManager = NotificationManager.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Investment Operations
    
    /// Create a new investment
    /// - Parameters:
    ///   - businessID: ID of the business receiving investment
    ///   - amount: Investment amount
    ///   - completion: Result with the created investment or error
    func createInvestment(businessID: String,
                          amount: Double,
                          completion: @escaping (Result<Investment, InvestmentError>) -> Void) {
        
        // Verify user is authorized
        guard let investorID = FirebaseManager.shared.currentUserID else {
            completion(.failure(.notAuthorized))
            return
        }
        
        // Validate amount
        guard amount > 0 else {
            completion(.failure(.invalidAmount))
            return
        }
        
        // Get business details to calculate equity
        BusinessService.shared.getBusiness(id: businessID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let business):
                // Calculate equity percentage based on amount and business funding goal/equity
                let equityPercentage = (amount / business.fundingGoal) * business.equity
                
                // Create investment object
                let investmentID = FirebaseManager.shared.generateID()
                let investment = Investment(
                    id: investmentID,
                    investorId: investorID,
                    businessId: businessID,
                    amount: amount,
                    equityPercentage: equityPercentage,
                    status: .pending
                )
                
                // Process the investment using a transaction
                self.processInvestment(investment: investment, business: business) { result in
                    switch result {
                    case .success(let processedInvestment):
                        // Success! Now send notification to entrepreneur
                        self.notificationManager.createNewInvestmentNotification(
                            businessID: businessID,
                            entrepreneurID: business.entrepreneurId,
                            investorID: investorID,
                            investmentID: processedInvestment.id,
                            amount: amount,
                            businessName: business.name
                        )
                        
                        // Check if business reached funding goal
                        let newTotalFunding = business.fundingRaised + amount
                        if newTotalFunding >= business.fundingGoal {
                            // Send funding goal notification
                            self.notificationManager.createFundingGoalNotification(
                                businessID: businessID,
                                entrepreneurID: business.entrepreneurId,
                                businessName: business.name,
                                fundingGoal: business.fundingGoal
                            )
                        }
                        
                        completion(.success(processedInvestment))
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure:
                completion(.failure(.businessNotFound))
            }
        }
    }
    
    /// Get an investment by ID
    /// - Parameters:
    ///   - id: ID of the investment to fetch
    ///   - completion: Result with the investment or error
    func getInvestment(id: String,
                       completion: @escaping (Result<Investment, InvestmentError>) -> Void) {
        
        db.collection(Constants.Collections.investments).document(id).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(.fetchFailed(error.localizedDescription)))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(.notFound))
                return
            }
            
            do {
                let data = snapshot.data() ?? [:]
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let investment = try JSONDecoder().decode(Investment.self, from: jsonData)
                completion(.success(investment))
            } catch {
                completion(.failure(.invalidData))
            }
        }
    }
    
    /// Get investments for the current investor
    /// - Parameters:
    ///   - limit: Maximum number of investments to fetch
    ///   - completion: Result with array of investments or error
    func getInvestorInvestments(limit: Int = 50,
                                completion: @escaping (Result<[Investment], InvestmentError>) -> Void) {
        
        guard let investorID = FirebaseManager.shared.currentUserID else {
            completion(.failure(.notAuthorized))
            return
        }
        
        db.collection(Constants.Collections.investments)
            .whereField("investorId", isEqualTo: investorID)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(.fetchFailed(error.localizedDescription)))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                do {
                    var investments: [Investment] = []
                    
                    for document in documents {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let investment = try JSONDecoder().decode(Investment.self, from: jsonData)
                        investments.append(investment)
                    }
                    
                    completion(.success(investments))
                } catch {
                    completion(.failure(.invalidData))
                }
            }
    }
    
    /// Get investments for a specific business
    /// - Parameters:
    ///   - businessID: ID of the business
    ///   - limit: Maximum number of investments to fetch
    ///   - completion: Result with array of investments or error
    func getBusinessInvestments(businessID: String,
                               limit: Int = 50,
                               completion: @escaping (Result<[Investment], InvestmentError>) -> Void) {
        
        db.collection(Constants.Collections.investments)
            .whereField("businessId", isEqualTo: businessID)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(.fetchFailed(error.localizedDescription)))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                do {
                    var investments: [Investment] = []
                    
                    for document in documents {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let investment = try JSONDecoder().decode(Investment.self, from: jsonData)
                        investments.append(investment)
                    }
                    
                    completion(.success(investments))
                } catch {
                    completion(.failure(.invalidData))
                }
            }
    }
    
    /// Cancel a pending investment
    /// - Parameters:
    ///   - investmentID: ID of the investment to cancel
    ///   - completion: Result with the updated investment or error
    func cancelInvestment(investmentID: String,
                          completion: @escaping (Result<Investment, InvestmentError>) -> Void) {
        
        guard let currentUserID = FirebaseManager.shared.currentUserID else {
            completion(.failure(.notAuthorized))
            return
        }
        
        // Get the investment first to check ownership and status
        getInvestment(id: investmentID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let investment):
                // Verify ownership
                guard investment.investorId == currentUserID else {
                    completion(.failure(.notAuthorized))
                    return
                }
                
                // Check if already completed
                guard investment.status == .pending else {
                    completion(.failure(.alreadyCompleted))
                    return
                }
                
                // Update investment status to cancelled
                var updatedInvestment = investment
                updatedInvestment.status = .cancelled
                
                // Process the cancellation
                self.updateInvestmentStatus(investment: updatedInvestment) { result in
                    switch result {
                    case .success(let finalInvestment):
                        completion(.success(finalInvestment))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Complete a pending investment
    /// - Parameters:
    ///   - investmentID: ID of the investment to complete
    ///   - completion: Result with the updated investment or error
    func completeInvestment(investmentID: String,
                           completion: @escaping (Result<Investment, InvestmentError>) -> Void) {
        
        // Get the investment first to verify details
        getInvestment(id: investmentID) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let investment):
                // Check if already completed
                guard investment.status == .pending else {
                    completion(.failure(.alreadyCompleted))
                    return
                }
                
                // Update investment status to completed
                var updatedInvestment = investment
                updatedInvestment.status = .completed
                updatedInvestment.completedAt = Date()
                
                // Process the completion
                self.updateInvestmentStatus(investment: updatedInvestment) { result in
                    switch result {
                    case .success(let finalInvestment):
                        completion(.success(finalInvestment))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Process a new investment with a transaction
    /// - Parameters:
    ///   - investment: The investment to process
    ///   - business: The business receiving the investment
    ///   - completion: Result with the processed investment or error
    private func processInvestment(investment: Investment,
                                business: Business,
                                completion: @escaping (Result<Investment, InvestmentError>) -> Void) {
        
        // Use a transaction to ensure data consistency
        FirebaseManager.shared.runTransaction({ transaction -> Investment? in
            // Get the latest business data
            let businessRef = self.db.collection(Constants.Collections.businesses).document(business.id)
            let businessDoc = try transaction.getDocument(businessRef)
            
            guard let businessData = businessDoc.data() else {
                throw InvestmentError.businessNotFound
            }
            
            // Update the business's funding raised amount
            let currentFunding = businessData["fundingRaised"] as? Double ?? 0
            let newFunding = currentFunding + investment.amount
            
            transaction.updateData(["fundingRaised": newFunding], forDocument: businessRef)
            
            // Save the investment
            let investmentRef = self.db.collection(Constants.Collections.investments).document(investment.id)
            
            // Convert investment to dictionary
            let investmentData: [String: Any] = [
                "id": investment.id,
                "investorId": investment.investorId,
                "businessId": investment.businessId,
                "amount": investment.amount,
                "equityPercentage": investment.equityPercentage,
                "status": investment.status.rawValue,
                "createdAt": Timestamp(date: investment.createdAt),
                "contractURL": investment.contractURL as Any,
                "transactionId": investment.transactionId as Any
            ]
            
            transaction.setData(investmentData, forDocument: investmentRef)
            
            // Update investor's investments array
            let investorRef = self.db.collection(Constants.Collections.investors).document(investment.investorId)
            transaction.updateData([
                "investmentsMade": FieldValue.arrayUnion([investment.id])
            ], forDocument: investorRef)
            
            return investment
            
        }) { result in
            switch result {
            case .success(let processedInvestment):
                completion(.success(processedInvestment ?? investment))
            case .failure(let error):
                completion(.failure(.creationFailed(error.localizedDescription)))
            }
        }
    }
    
    /// Update an investment's status
    /// - Parameters:
    ///   - investment: The investment with updated status
    ///   - completion: Result with the updated investment or error
    private func updateInvestmentStatus(investment: Investment,
                                     completion: @escaping (Result<Investment, InvestmentError>) -> Void) {
        
        let investmentRef = db.collection(Constants.Collections.investments).document(investment.id)
        
        var updateData: [String: Any] = [
            "status": investment.status.rawValue
        ]
        
        if let completedAt = investment.completedAt {
            updateData["completedAt"] = Timestamp(date: completedAt)
        }
        
        investmentRef.updateData(updateData) { error in
            if let error = error {
                completion(.failure(.updateFailed(error.localizedDescription)))
                return
            }
            
            completion(.success(investment))
        }
    }
    
    /// Calculate potential return on investment
    /// - Parameters:
    ///   - amount: Investment amount
    ///   - business: The business to invest in
    /// - Returns: Potential equity percentage and estimated value
    func calculatePotentialReturn(amount: Double, business: Business) -> (equityPercentage: Double, estimatedValue: Double) {
        // Calculate equity percentage
        let equityPercentage = (amount / business.fundingGoal) * business.equity
        
        // Estimated value based on simplified calculation
        // In a real app, this would use a more sophisticated valuation model
        let businessValuation = business.fundingGoal / (business.equity / 100)
        let estimatedValue = businessValuation * (equityPercentage / 100)
        
        return (equityPercentage, estimatedValue)
    }
}
