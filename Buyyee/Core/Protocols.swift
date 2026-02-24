//
//  Protocols.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/27/26.
//

import Foundation
import Combine

protocol NetworkServiceProtocol: Sendable {
    func fetchProducts() async throws -> [Product]
    func fetchTransactions(page: Int) async throws -> APIResponse<[Transaction]>
    func submitOrder(cart: Cart, paymentMethod: any PaymentMethodProtocol) async throws -> Transaction
}

protocol KeychainServiceProtocol: Sendable {
    func save(_ data: Data, forKey key: String) throws
    func load(forKey key: String) throws -> Data
    func delete(forKey key: String) throws
}

protocol BiometricServiceProtocol: Sendable {
    var biometricType: BiometricType { get }
    func authenticate(reason: String) async throws -> Bool
}

enum BiometricType: Sendable {
    case faceID
    case touchID
    case none
}

protocol ProductRepositoryProtocol: Sendable {
    func getProducts() async throws -> [Product]
    func getProducts(for category: ProductCategory) async throws -> [Product]
    func searchProducts(query: String) async throws -> [Product]
}

protocol CartRepositoryProtocol: AnyObject {
    var cart: Cart { get }
    var cartPublisher: AnyPublisher<Cart, Never> { get }
    func addProduct(_ product: Product)
    func removeItem(id: UUID)
    func updateQuantity(itemID: UUID, quantity: Int)
    func clearCart()
}

protocol TransactionRepositoryProtocol: Sendable {
    func getTransactions(page: Int) async throws -> APIResponse<[Transaction]>
    func submitOrder(cart: Cart, paymentMethod: any PaymentMethodProtocol) async throws -> Transaction
    func getCachedTransactions() -> [Transaction]
}

protocol BNPLCalculatorProtocol: Sendable {
    func monthlyPayment(principal: Decimal, plan: InstallmentPlan) -> Decimal
    func downPayment(for total: Decimal) -> Decimal
    func financedAmount(for total: Decimal) -> Decimal
    func generateSchedule(principal: Decimal, plan: InstallmentPlan) -> [InstallmentScheduleItem]
    func checkEligibility(amount: Decimal, user: User) -> BNPLEligibility
}

protocol PaymentMethodProtocol: Sendable {
    var displayName: String { get }
    var iconName: String { get }
    var requiresBiometrics: Bool { get }
}

struct BNPLPayment: PaymentMethodProtocol, Sendable {
    let plan: InstallmentPlan
    let downPaymentAmount: Decimal
    let monthlyAmount: Decimal
    let schedule: [InstallmentScheduleItem]

    var displayName: String { "Buyyee Installments · \(plan.rawValue)" }
    var iconName: String { "calendar.badge.checkmark" }
    var requiresBiometrics: Bool { true }
}

enum CardNetwork: String, CaseIterable, Sendable {
    case visa       = "Visa"
    case mastercard = "Mastercard"
    case maya       = "Maya"

    var iconName: String {
        switch self {
        case .visa:       return "creditcard"
        case .mastercard: return "creditcard.fill"
        case .maya:       return "creditcard.and.123"
        }
    }
}

struct DebitCardPayment: PaymentMethodProtocol, Sendable {
    let cardNetwork: CardNetwork
    let lastFourDigits: String

    var displayName: String { "\(cardNetwork.rawValue) •••• \(lastFourDigits)" }
    var iconName: String { cardNetwork.iconName }
    var requiresBiometrics: Bool { true }
}

protocol CartRepositoryDelegate: AnyObject {
    func cartDidUpdate(_ cart: Cart)
}
