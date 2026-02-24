//
//  ProductListViewModel.swift
//  Buyyee
//
//  Created by Rony Alcala on 2/30/26.
//

import SwiftUI
import Combine

enum ViewState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case empty
    case error(AppError)
}

@MainActor
final class ProductListViewModel: ObservableObject {

    @Published private(set) var viewState: ViewState<[Product]> = .idle
    @Published var searchText: String = ""
    @Published var selectedCategory: ProductCategory? = nil

    private let productRepository: any ProductRepositoryProtocol
    private let cartRepository: any CartRepositoryProtocol

    private var loadTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    init(productRepository: any ProductRepositoryProtocol,
         cartRepository: any CartRepositoryProtocol) {
        self.productRepository = productRepository
        self.cartRepository = cartRepository
    }

    deinit {
        loadTask?.cancel()
        searchTask?.cancel()
    }

    func loadProducts() {
        loadTask?.cancel()
        loadTask = Task {
            viewState = .loading
            do {
                let products: [Product]
                if let category = selectedCategory {
                    products = try await productRepository.getProducts(for: category)
                } else {
                    products = try await productRepository.getProducts()
                }
                guard !Task.isCancelled else { return }
                viewState = products.isEmpty ? .empty : .loaded(products)
            } catch is CancellationError {
                return
            } catch {
                viewState = .error(AppError.from(error))
            }
        }
    }

    func searchProducts(query: String) {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            loadProducts()
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300 milisecond debounce delay
            guard !Task.isCancelled else { return }
            viewState = .loading
            do {
                let products = try await productRepository.searchProducts(query: query)
                guard !Task.isCancelled else { return }
                viewState = products.isEmpty ? .empty : .loaded(products)
            } catch is CancellationError {
                return
            } catch {
                viewState = .error(AppError.from(error))
            }
        }
    }

    func selectCategory(_ category: ProductCategory?) {
        selectedCategory = category
        loadProducts()
    }

    func addToCart(_ product: Product) {
        cartRepository.addProduct(product)
    }
}
