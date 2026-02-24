//
//  CartFeature.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/29/26.
//

import SwiftUI
import Combine

struct CartView: View {

    @StateObject var viewModel: CartViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        Group {
            if viewModel.cart.isEmpty {
                EmptyStateView(
                    systemImage: "cart",
                    title: "Your Cart is Empty",
                    message: "Add some gadgets to get started!",
                    actionTitle: "Shop Now"
                ) {
                    coordinator.selectedTab = .shop
                }
            } else {
                cartContent
            }
        }
        .navigationTitle("My Cart")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cartContent: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.cart.items) { item in
                    CartItemRow(
                        item: item,
                        onQuantityChange: { newQty in
                            viewModel.updateQuantity(itemID: item.id, quantity: newQty)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        viewModel.removeItem(id: viewModel.cart.items[index].id)
                    }
                }
            }
            .listStyle(.plain)

            checkoutFooter
        }
    }

    private var checkoutFooter: some View {
        VStack(spacing: 12) {
            BuyeeeDivider()

            HStack {
                Text("\(viewModel.cart.totalItems) item\(viewModel.cart.totalItems == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    PriceText(amount: viewModel.cart.subtotal, font: .title2.weight(.bold),
                              color: BuyyeeColors.primary)
                }
            }
            .padding(.horizontal)

            LoadingButton(title: "Checkout with Buyyee", isLoading: false) {
                coordinator.showCheckout()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(BuyyeeColors.cardBG)
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Product icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(BuyyeeColors.subtleBG)
                    .frame(width: 64, height: 64)
                Image(systemName: item.product.systemImage)
                    .font(.title2)
                    .foregroundStyle(BuyyeeColors.primary)
            }

            // Product details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.product.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)
                PriceText(amount: item.product.price, font: .subheadline.weight(.semibold),
                          color: BuyyeeColors.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                PriceText(amount: item.subtotal, font: .caption.weight(.semibold))

                HStack(spacing: 0) {
                    Button {
                        onQuantityChange(item.quantity - 1)
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption.weight(.bold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(item.quantity <= 1)

                    Text("\(item.quantity)")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 28)

                    Button {
                        onQuantityChange(item.quantity + 1)
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
                .background(BuyyeeColors.subtleBG, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .cardStyle()
    }
}
