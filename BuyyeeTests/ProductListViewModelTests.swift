//
//  ProductListViewModelTests.swift
//  Buyyee
//
//  Created by Rony Alcala on 2/30/26.
//

import XCTest
@testable import Buyyee
import Combine

final class MockProductRepository: ProductRepositoryProtocol {

    var stubbedProducts: [Product] = []
    var shouldThrowError: Error?

    var getProductsCallCount: Int = 0
    var getProductsForCategoryCallCount: Int = 0
    var searchProductsCallCount: Int = 0

    func getProducts() async throws -> [Product] {
        getProductsCallCount += 1
        if let error = shouldThrowError { throw error }
        return stubbedProducts
    }

    func getProducts(for category: ProductCategory) async throws -> [Product] {
        getProductsForCategoryCallCount += 1
        if let error = shouldThrowError { throw error }
        return stubbedProducts.filter { $0.category == category }
    }

    func searchProducts(query: String) async throws -> [Product] {
        searchProductsCallCount += 1
        if let error = shouldThrowError { throw error }
        let lowercased = query.lowercased()
        return stubbedProducts.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.brand.lowercased().contains(lowercased)
        }
    }
}

final class MockCartRepository: CartRepositoryProtocol {
    var cart: Cart = Cart()
    var cartPublisher: AnyPublisher<Cart, Never> { Just(cart).eraseToAnyPublisher() }
    weak var delegate: CartRepositoryDelegate?
    var addedProducts: [Product] = []

    func addProduct(_ product: Product) { addedProducts.append(product) }
    func removeItem(id: UUID) {}
    func updateQuantity(itemID: UUID, quantity: Int) {}
    func clearCart() {}
}

@MainActor
final class ProductListViewModelTests: XCTestCase {

    var sut: ProductListViewModel!
    var mockProductRepository: MockProductRepository!
    var mockCartRepository: MockCartRepository!

    override func setUp() {
        super.setUp()
        mockProductRepository = MockProductRepository()
        mockCartRepository = MockCartRepository()
        sut = ProductListViewModel(
            productRepository: mockProductRepository,
            cartRepository: mockCartRepository
        )
    }

    override func tearDown() {
        sut = nil
        mockProductRepository = nil
        mockCartRepository = nil
        super.tearDown()
    }

    func test_initialState_isIdle() {
        if case .idle = sut.viewState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .idle on init, got \(sut.viewState)")
        }
    }

    func test_loadProducts_withProducts_transitionsToLoaded() async {
        mockProductRepository.stubbedProducts = makeMockProducts(count: 3)

        await sut.loadProducts().value

        if case .loaded(let products) = sut.viewState {
            XCTAssertEqual(products.count, 3)
        } else {
            XCTFail("Expected .loaded(3 products), got \(sut.viewState)")
        }
    }

    func test_loadProducts_emptyResponse_transitionsToEmpty() async {
        mockProductRepository.stubbedProducts = []

        await sut.loadProducts().value

        if case .empty = sut.viewState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .empty for zero products, got \(sut.viewState)")
        }
    }

    func test_loadProducts_networkError_transitionsToError() async {
        mockProductRepository.shouldThrowError = NetworkError.noInternetConnection

        await sut.loadProducts().value

        if case .error(let appError) = sut.viewState {
            XCTAssertFalse(appError.message.isEmpty,
                           "Error state should carry a non-empty user-facing message")
        } else {
            XCTFail("Expected .error, got \(sut.viewState)")
        }
    }

    func test_loadProducts_callsGetProductsOnRepository() async {
        mockProductRepository.stubbedProducts = makeMockProducts(count: 1)

        await sut.loadProducts().value

        XCTAssertEqual(mockProductRepository.getProductsCallCount, 1)
    }

    func test_selectCategory_setsSelectedCategory() async {
        mockProductRepository.stubbedProducts = makeMockProducts(count: 5)

        await sut.selectCategory(.laptops).value

        XCTAssertEqual(sut.selectedCategory, .laptops)
    }

    func test_selectCategory_callsGetProductsForCategory() async {
        mockProductRepository.stubbedProducts = makeMockProducts(count: 5)

        await sut.selectCategory(.laptops).value

        XCTAssertEqual(mockProductRepository.getProductsForCategoryCallCount, 1)
        XCTAssertEqual(mockProductRepository.getProductsCallCount, 0,
                       "With a category set, getProducts() (no filter) should NOT be called")
    }

    func test_selectCategory_nil_callsGetProductsWithNoFilter() async {
        mockProductRepository.stubbedProducts = makeMockProducts(count: 5)

        await sut.selectCategory(.laptops).value
        await sut.selectCategory(nil).value

        XCTAssertNil(sut.selectedCategory)
        XCTAssertEqual(mockProductRepository.getProductsCallCount, 1)
    }

    func test_loadProducts_calledTwice_refreshesData() async {
        mockProductRepository.stubbedProducts = makeMockProducts(count: 3)
        await sut.loadProducts().value
        XCTAssertEqual(mockProductRepository.getProductsCallCount, 1)
        
        await sut.loadProducts().value
        XCTAssertEqual(mockProductRepository.getProductsCallCount, 2)
    }

    func test_loadProducts_afterError_canSucceedOnRetry() async {
        mockProductRepository.shouldThrowError = NetworkError.timeout
        await sut.loadProducts().value

        if case .error = sut.viewState { } else {
            XCTFail("Expected .error after first failing load")
        }

        mockProductRepository.shouldThrowError = nil
        mockProductRepository.stubbedProducts = makeMockProducts(count: 2)
        await sut.loadProducts().value

        if case .loaded(let products) = sut.viewState {
            XCTAssertEqual(products.count, 2)
        } else {
            XCTFail("Expected .loaded after successful retry, got \(sut.viewState)")
        }
    }

    func test_addToCart_callsRepositoryAddProduct() {
        let product = makeMockProducts(count: 1).first!
        sut.addToCart(product)

        XCTAssertEqual(mockCartRepository.addedProducts.count, 1)
        XCTAssertEqual(mockCartRepository.addedProducts.first?.id, product.id)
    }

    func test_addToCart_multipleProducts_allRecorded() {
        let products = makeMockProducts(count: 3)

        products.forEach { sut.addToCart($0) }
        XCTAssertEqual(mockCartRepository.addedProducts.count, 3)
    }

    func test_searchProducts_returnsMatchingProducts() async {
        mockProductRepository.stubbedProducts = [
            makeProduct(name: "MacBook Air M3", category: .laptops),
            makeProduct(name: "iPhone 16 Pro", category: .smartphones)
        ]

        await sut.searchProducts(query: "MacBook").value

        if case .loaded(let products) = sut.viewState {
            XCTAssertEqual(products.count, 1)
            XCTAssertTrue(products.first!.name.contains("MacBook"))
        } else {
            XCTFail("Expected .loaded with 1 MacBook result, got \(sut.viewState)")
        }
    }

    func test_searchProducts_emptyQuery_fallsBackToLoadProducts() async {
        mockProductRepository.stubbedProducts = makeMockProducts(count: 4)

        await sut.searchProducts(query: "   ").value

        XCTAssertEqual(mockProductRepository.searchProductsCallCount, 0)
        XCTAssertEqual(mockProductRepository.getProductsCallCount, 1)
    }

    func test_searchProducts_callsSearchOnRepository() async {
        mockProductRepository.stubbedProducts = makeMockProducts(count: 3)

        await sut.searchProducts(query: "Test").value

        XCTAssertEqual(mockProductRepository.searchProductsCallCount, 1)
    }

    private func makeMockProducts(count: Int) -> [Product] {
        (0..<count).map { i in makeProduct(name: "Test Product \(i)", category: .laptops) }
    }

    private func makeProduct(name: String, category: ProductCategory) -> Product {
        Product(
            id: UUID(),
            name: name,
            brand: "TestBrand",
            description: "Test description",
            price: Decimal(string: "10000")!,
            category: category,
            systemImage: "laptopcomputer",
            stockCount: 10,
            rating: 4.5,
            reviewCount: 100
        )
    }
}
