//
//  Repositories.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/28/26.
//

import Foundation
import Combine

final class ProductRepository: ProductRepositoryProtocol, @unchecked Sendable {

    private let networkService: any NetworkServiceProtocol
    private var cache: [Product] = []
    private var cacheDate: Date?
    private let cacheTTL: TimeInterval = 5 * 60 // 5 min TTL

    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func getProducts() async throws -> [Product] {
        if let cached = freshCache() { return cached }
        let products = try await networkService.fetchProducts()
        cache = products
        cacheDate = Date()
        return products
    }

    func getProducts(for category: ProductCategory) async throws -> [Product] {
        let all = try await getProducts()
        return all.filter { $0.category == category }
    }

    func searchProducts(query: String) async throws -> [Product] {
        let all = try await getProducts()
        let lowercased = query.lowercased()
        return all.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.brand.lowercased().contains(lowercased) ||
            $0.category.rawValue.lowercased().contains(lowercased)
        }
    }

    private func freshCache() -> [Product]? {
        guard !cache.isEmpty, let date = cacheDate,
              Date().timeIntervalSince(date) < cacheTTL else { return nil }
        return cache
    }
}

final class CartRepository: CartRepositoryProtocol {

    @Published private(set) var cart: Cart = Cart()

    weak var delegate: (any CartRepositoryDelegate)?

    var cartPublisher: AnyPublisher<Cart, Never> {
        $cart.eraseToAnyPublisher()
    }

    func addProduct(_ product: Product) {
        cart.add(product: product)
        delegate?.cartDidUpdate(cart)
    }

    func removeItem(id: UUID) {
        cart.remove(itemID: id)
        delegate?.cartDidUpdate(cart)
    }

    func updateQuantity(itemID: UUID, quantity: Int) {
        cart.updateQuantity(itemID: itemID, quantity: quantity)
        delegate?.cartDidUpdate(cart)
    }

    func clearCart() {
        cart.clear()
        delegate?.cartDidUpdate(cart)
    }
}

final class TransactionRepository: TransactionRepositoryProtocol, @unchecked Sendable {

    private let networkService: any NetworkServiceProtocol
    private var cachedTransactions: [Transaction] = []

    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func getTransactions(page: Int) async throws -> APIResponse<[Transaction]> {
        do {
            let response = try await networkService.fetchTransactions(page: page)
            if let data = response.data {
                if page == 1 {
                    cachedTransactions = data
                } else {
                    cachedTransactions.append(contentsOf: data)
                }
            }
            return response
        } catch {
            throw error
        }
    }

    func submitOrder(cart: Cart, paymentMethod: any PaymentMethodProtocol) async throws -> Transaction {
        let transaction = try await networkService.submitOrder(cart: cart, paymentMethod: paymentMethod)
        cachedTransactions.insert(transaction, at: 0)
        return transaction
    }

    func getCachedTransactions() -> [Transaction] {
        return cachedTransactions
    }
}
