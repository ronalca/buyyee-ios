//
//  MockAPIService.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/28/26.
//

import Foundation

final class MockAPIService: NetworkServiceProtocol, @unchecked Sendable {

    var shouldFailWithError: NetworkError?
    var artificialDelay: UInt64 = 800_000_000   // 800 milliSecond delay

    func fetchProducts() async throws -> [Product] {
        try await Task.sleep(nanoseconds: artificialDelay)
        try Task.checkCancellation()
        if let error = shouldFailWithError { throw error }
        return MockData.products
    }

    func fetchTransactions(page: Int) async throws -> APIResponse<[Transaction]> {
        try await Task.sleep(nanoseconds: artificialDelay)
        try Task.checkCancellation()
        if let error = shouldFailWithError { throw error }

        let pageSize = 3
        let all = MockData.transactions
        let totalPages = Int(ceil(Double(all.count) / Double(pageSize)))
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, all.count)

        guard startIndex < all.count else {
            return APIResponse(
                success: true, data: [], message: nil,
                pagination: PaginationInfo(
                    currentPage: page, totalPages: totalPages,
                    totalItems: all.count, itemsPerPage: pageSize
                )
            )
        }

        let pageData = Array(all[startIndex..<endIndex])
        return APIResponse(
            success: true, data: pageData, message: nil,
            pagination: PaginationInfo(
                currentPage: page, totalPages: totalPages,
                totalItems: all.count, itemsPerPage: pageSize
            )
        )
    }

    func submitOrder(cart: Cart, paymentMethod: any PaymentMethodProtocol) async throws -> Transaction {
        try await Task.sleep(nanoseconds: 500_000_000)
        try Task.checkCancellation()
        try await Task.sleep(nanoseconds: 500_000_000)
        try Task.checkCancellation()

        if let error = shouldFailWithError { throw error }

        let orderNumber = "BUY-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 1000...9999))"

        var installmentPlan: InstallmentPlan?
        var downPaymentAmt: Decimal?
        var monthlyPaymentAmt: Decimal?

        if let bnpl = paymentMethod as? BNPLPayment {
            installmentPlan   = bnpl.plan
            downPaymentAmt    = bnpl.downPaymentAmount
            monthlyPaymentAmt = bnpl.monthlyAmount
        }

        return Transaction(
            id: UUID(),
            orderNumber: orderNumber,
            items: cart.items,
            totalAmount: cart.subtotal,
            paymentMethodDescription: paymentMethod.displayName,
            status: .approved,
            createdAt: Date(),
            installmentPlan: installmentPlan,
            downPayment: downPaymentAmt,
            monthlyPayment: monthlyPaymentAmt
        )
    }
}
