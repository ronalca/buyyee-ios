//
//  ProductListFeature.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/29/26.
//

import SwiftUI
import Combine

struct ProductListView: View {

    @StateObject var viewModel: ProductListViewModel
    @EnvironmentObject private var coordinator: AppCoordinator

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView("Loading products…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let products):
                productGrid(products: products)

            case .empty:
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "No Products Found",
                    message: "Try a different search term or category."
                )

            case .error(let error):
                EmptyStateView(
                    systemImage: "wifi.exclamationmark",
                    title: error.title,
                    message: error.message,
                    actionTitle: error.isRetryable ? "Try Again" : nil,
                    action: error.isRetryable ? { viewModel.loadProducts() } : nil
                )
            }
        }
        .navigationTitle("Buyyee")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search products…")
        .onChange(of: viewModel.searchText) { _, newValue in
            if newValue.isEmpty {
                viewModel.loadProducts()
            } else {
                viewModel.searchProducts(query: newValue)
            }
        }
        .refreshable {
            viewModel.loadProducts()
        }
        .onAppear {
            viewModel.loadProducts()
        }
    }

    @ViewBuilder
    private func productGrid(products: [Product]) -> some View {
        ScrollView {
            // Category filter chips
            categoryFilters
                .padding(.horizontal)
                .padding(.top, 8)

            // Product grid
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(products) { product in
                    ProductCardView(product: product) {
                        viewModel.addToCart(product)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip<String>(
                    label: "All",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectCategory(nil)
                }
                ForEach(ProductCategory.allCases) { category in
                    FilterChip<ProductCategory>(
                        label: category.rawValue,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct ProductCardView: View {
    let product: Product
    let onAddToCart: () -> Void

    @State private var isAdded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Product image (SF Symbol)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(BuyyeeColors.subtleBG)
                    .frame(height: 110)
                Image(systemName: product.systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(BuyyeeColors.primary)
            }

            // Brand
            Text(product.brand)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Name
            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Rating
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                Text(String(format: "%.1f", product.rating))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("(\(product.reviewCount))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Price
            PriceText(amount: product.price, font: .subheadline.weight(.bold))

            // Add to cart button
            // HIG: 44pt height ensures comfortable touch target.
            Button {
                onAddToCart()
                isAdded = true
                // Reset button after 1.5s
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isAdded = false
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isAdded ? "checkmark" : "cart.badge.plus")
                        .font(.caption)
                    Text(isAdded ? "Added!" : "Add to Cart")
                        .font(.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .foregroundStyle(.white)
                .background(isAdded ? BuyyeeColors.success : BuyyeeColors.primary,
                            in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isAdded)
            .disabled(!product.isInStock)
        }
        .padding(12)
        .cardStyle()
    }
}
