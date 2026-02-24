//  Models.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/27/26.
//

import Foundation

enum ProductCategory: String, CaseIterable, Codable, Identifiable {
    case laptops        = "Laptops"
    case desktopParts   = "PC Parts"
    case gamingConsoles = "Consoles"
    case smartphones    = "Phones & Tablets"
    case audio          = "Audio & Peripherals"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .laptops:        return "laptopcomputer"
        case .desktopParts:   return "cpu"
        case .gamingConsoles: return "gamecontroller"
        case .smartphones:    return "iphone"
        case .audio:          return "airpodspro"
        }
    }
}

struct Product: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    let brand: String
    let description: String
    let price: Decimal
    let category: ProductCategory
    let systemImage: String
    let stockCount: Int
    let rating: Double
    let reviewCount: Int
    var isInStock: Bool { stockCount > 0 }
}

struct CartItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let product: Product
    var quantity: Int

    var subtotal: Decimal { product.price * Decimal(quantity) }

    init(product: Product, quantity: Int = 1) {
        self.id = UUID()
        self.product = product
        self.quantity = quantity
    }
}

struct Cart: Sendable {
    var items: [CartItem] = []

    var totalItems: Int { items.reduce(0) { $0 + $1.quantity } }
    var subtotal: Decimal { items.reduce(.zero) { $0 + $1.subtotal } }
    var isEmpty: Bool { items.isEmpty }

    mutating func add(product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(product: product))
        }
    }

    mutating func remove(itemID: UUID) {
        items.removeAll { $0.id == itemID }
    }

    mutating func updateQuantity(itemID: UUID, quantity: Int) {
        guard quantity > 0 else { remove(itemID: itemID); return }
        if let index = items.firstIndex(where: { $0.id == itemID }) {
            items[index].quantity = quantity
        }
    }

    mutating func clear() { items.removeAll() }
}

enum InstallmentPlan: String, CaseIterable, Codable, Identifiable, Sendable {
    case threeMonths  = "3 Months"
    case sixMonths    = "6 Months"
    case twelveMonths = "12 Months"

    var id: String { rawValue }

    var months: Int {
        switch self {
        case .threeMonths:  return 3
        case .sixMonths:    return 6
        case .twelveMonths: return 12
        }
    }

    var annualInterestRate: Decimal {
        switch self {
        case .threeMonths:  return .zero
        case .sixMonths:    return Decimal(string: "0.12")!
        case .twelveMonths: return Decimal(string: "0.12")!
        }
    }

    var displayLabel: String {
        switch self {
        case .threeMonths:  return "3 Months · 0% interest"
        case .sixMonths:    return "6 Months · 12% p.a."
        case .twelveMonths: return "12 Months · 12% p.a."
        }
    }
}

struct InstallmentScheduleItem: Identifiable, Codable, Sendable {
    let id: UUID
    let monthNumber: Int
    let dueDate: Date
    let principalComponent: Decimal
    let interestComponent: Decimal
    let monthlyPayment: Decimal
    let remainingBalance: Decimal

    init(monthNumber: Int, dueDate: Date, principalComponent: Decimal,
         interestComponent: Decimal, monthlyPayment: Decimal, remainingBalance: Decimal) {
        self.id = UUID()
        self.monthNumber = monthNumber
        self.dueDate = dueDate
        self.principalComponent = principalComponent
        self.interestComponent = interestComponent
        self.monthlyPayment = monthlyPayment
        self.remainingBalance = remainingBalance
    }
}

enum TransactionStatus: String, Codable, CaseIterable, Sendable {
    case pending   = "Pending"
    case approved  = "Approved"
    case declined  = "Declined"
    case refunded  = "Refunded"
    case cancelled = "Cancelled"

    var systemImage: String {
        switch self {
        case .pending:   return "clock"
        case .approved:  return "checkmark.circle.fill"
        case .declined:  return "xmark.circle.fill"
        case .refunded:  return "arrow.uturn.left.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
}

struct Transaction: Identifiable, Codable, Sendable {
    let id: UUID
    let orderNumber: String
    let items: [CartItem]
    let totalAmount: Decimal
    let paymentMethodDescription: String
    let status: TransactionStatus
    let createdAt: Date
    let installmentPlan: InstallmentPlan?
    let downPayment: Decimal?
    let monthlyPayment: Decimal?

    enum CodingKeys: String, CodingKey {
        case id
        case orderNumber              = "order_number"
        case items
        case totalAmount              = "total_amount"
        case paymentMethodDescription = "payment_method_description"
        case status
        case createdAt                = "created_at"
        case installmentPlan          = "installment_plan"
        case downPayment              = "down_payment"
        case monthlyPayment           = "monthly_payment"
    }
}

struct User: Codable, Sendable {
    let id: UUID
    let fullName: String
    let email: String
    let phoneNumber: String
    let creditLimit: Decimal
    let availableCredit: Decimal
    let isKYCVerified: Bool
}

struct AuthToken: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    var isExpired: Bool { Date() >= expiresAt }
}

struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    let success: Bool
    let data: T?
    let message: String?
    let pagination: PaginationInfo?
}

struct PaginationInfo: Codable, Sendable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let itemsPerPage: Int

    var hasNextPage: Bool { currentPage < totalPages }

    enum CodingKeys: String, CodingKey {
        case currentPage  = "current_page"
        case totalPages   = "total_pages"
        case totalItems   = "total_items"
        case itemsPerPage = "items_per_page"
    }
}

struct BNPLEligibility: Sendable {
    let isEligible: Bool
    let reason: String?
    let maxEligibleAmount: Decimal

    static let notEligible = BNPLEligibility(
        isEligible: false,
        reason: "Not eligible for BNPL at this time.",
        maxEligibleAmount: .zero
    )
}
