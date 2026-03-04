//
//  BuyyeeApp.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/26/26.
//

import SwiftUI

@MainActor
final class DependencyContainer: ObservableObject {

    // MARK: Services (concrete types, created once)
    let networkService: any NetworkServiceProtocol
    let keychainService: any KeychainServiceProtocol
    let biometricService: any BiometricServiceProtocol
    let bnplCalculator: any BNPLCalculatorProtocol

    // MARK: Repositories (depend on services)
    let productRepository: any ProductRepositoryProtocol
    let cartRepository: CartRepository
    let transactionRepository: any TransactionRepositoryProtocol

    init() {
        let network = MockAPIService()
        networkService   = network
        keychainService  = KeychainService()
        biometricService = BiometricService()
        bnplCalculator   = BNPLCalculator()

        productRepository     = ProductRepository(networkService: network)
        cartRepository        = CartRepository()
        transactionRepository = TransactionRepository(networkService: network)
    }

    func makeProductListViewModel() -> ProductListViewModel {
        ProductListViewModel(
            productRepository: productRepository,
            cartRepository: cartRepository
        )
    }

    func makeCartViewModel() -> CartViewModel {
        CartViewModel(cartRepository: cartRepository)
    }

    func makeCheckoutViewModel() -> CheckoutViewModel {
        CheckoutViewModel(
            cartRepository: cartRepository,
            transactionRepository: transactionRepository,
            biometricService: biometricService,
            bnplCalculator: bnplCalculator,
            currentUser: MockData.currentUser
        )
    }

//    func makeTransactionHistoryViewModel() -> TransactionHistoryViewModel {
//        TransactionHistoryViewModel(transactionRepository: transactionRepository)
//    }
}

@main
struct BuyyeeApp: App {
    @StateObject private var container = DependencyContainer()
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(container)
                .environmentObject(coordinator)
        }
    }
}
