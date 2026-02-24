//
//  CartViewModel.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/29/26.
//

import SwiftUI
import Combine

@MainActor
final class CartViewModel: ObservableObject {

    @Published private(set) var cart: Cart = Cart()

    private let cartRepository: any CartRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(cartRepository: any CartRepositoryProtocol) {
        self.cartRepository = cartRepository
        
        cartRepository.cartPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedCart in
                self?.cart = updatedCart
            }
            .store(in: &cancellables)

        self.cart = cartRepository.cart
    }

    func removeItem(id: UUID) {
        cartRepository.removeItem(id: id)
    }

    func updateQuantity(itemID: UUID, quantity: Int) {
        cartRepository.updateQuantity(itemID: itemID, quantity: quantity)
    }

    func clearCart() {
        cartRepository.clearCart()
    }
}
