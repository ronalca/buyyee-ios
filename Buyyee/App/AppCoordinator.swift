//
//  AppCoordinator.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/26/26.
//

import SwiftUI

enum AppTab: String, CaseIterable {
    case shop    = "Shop"
    case cart    = "Cart"
    case history = "History"

    var systemImage: String {
        switch self {
        case .shop:    return "bag"
        case .cart:    return "cart"
        case .history: return "clock.arrow.circlepath"
        }
    }
}

@MainActor
final class AppCoordinator: ObservableObject {

    @Published var selectedTab: AppTab = .shop
    @Published var isCheckoutPresented: Bool = false

    func showCheckout() {
        isCheckoutPresented = true
    }

    func dismissCheckout() {
        isCheckoutPresented = false
    }

    func navigateToCart() {
        selectedTab = .cart
    }

    func handleOrderComplete() {
        dismissCheckout()
        selectedTab = .history
    }
}

struct AppCoordinatorView: View {

    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var container:   DependencyContainer

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {

            // SHOP TAB
            NavigationStack {
                ProductListView(viewModel: container.makeProductListViewModel())
            }
            .tabItem {
                Label(AppTab.shop.rawValue, systemImage: AppTab.shop.systemImage)
            }
            .tag(AppTab.shop)

            // CART TAB
            NavigationStack {
                CartView(viewModel: container.makeCartViewModel())
            }
            .tabItem {
                Label(AppTab.cart.rawValue, systemImage: AppTab.cart.systemImage)
            }
            .badge(container.cartRepository.cart.totalItems > 0
                   ? container.cartRepository.cart.totalItems
                   : 0)
            .tag(AppTab.cart)

            // HISTORY TAB (WIP)
//            NavigationStack {
//                TransactionHistoryView(viewModel: container.makeTransactionHistoryViewModel())
//            }
//            .tabItem {
//                Label(AppTab.history.rawValue, systemImage: AppTab.history.systemImage)
//            }
//            .tag(AppTab.history)
        }
        .tint(BuyyeeColors.primary)
        .sheet(isPresented: $coordinator.isCheckoutPresented) {
            NavigationStack {
                CheckoutView(viewModel: container.makeCheckoutViewModel())
            }
        }
    }
}
