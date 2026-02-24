//
//  CheckoutFeature.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/29/26.
//

import SwiftUI

struct CheckoutView: View {

    @StateObject var viewModel: CheckoutViewModel
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch viewModel.step {
            case .paymentMethod:
                PaymentMethodSelectionView(viewModel: viewModel)
            case .bnplPlanSelection:
                BNPLPlanSelectionView(viewModel: viewModel)
            case .cardSelection:
                CardSelectionView(viewModel: viewModel)
            case .reviewOrder:
                ReviewOrderView(viewModel: viewModel)
            case .processing:
                ProcessingView()
            case .success(let transaction):
                SuccessView(transaction: transaction) {
                    coordinator.handleOrderComplete()
                }
            case .failure(let message):
                FailureView(message: message) {
                    viewModel.goBack()
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if canGoBack {
                    Button("Back") { viewModel.goBack() }
                } else if viewModel.step == .paymentMethod {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var navigationTitle: String {
        switch viewModel.step {
        case .paymentMethod:     return "Choose Payment"
        case .bnplPlanSelection: return "Select Plan"
        case .cardSelection:     return "Card Details"
        case .reviewOrder:       return "Review Order"
        case .processing:        return "Processing"
        case .success:           return "Order Confirmed"
        case .failure:           return "Payment Failed"
        }
    }

    private var canGoBack: Bool {
        switch viewModel.step {
        case .bnplPlanSelection, .cardSelection, .reviewOrder: return true
        default: return false
        }
    }
}

struct PaymentMethodSelectionView: View {
    @ObservedObject var viewModel: CheckoutViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Order summary header
                VStack(spacing: 4) {
                    Text("Order Total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    PriceText(amount: viewModel.cart.subtotal, font: .largeTitle.weight(.bold),
                              color: BuyyeeColors.primary)
                    Text("\(viewModel.cart.totalItems) item\(viewModel.cart.totalItems == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // BNPL Option
                PaymentOptionCard(
                    iconName: "calendar.badge.checkmark",
                    title: "Buyyee Installments",
                    subtitle: "Pay in 3, 6, or 12 monthly installments",
                    badge: "0% interest available",
                    isSelected: viewModel.selectedPaymentOption == .bnpl,
                    isDisabled: viewModel.bnplEligibility?.isEligible == false
                ) {
                    viewModel.selectPaymentOption(.bnpl)
                }

                if let eligibility = viewModel.bnplEligibility, !eligibility.isEligible {
                    Text(eligibility.reason ?? "BNPL not available for this order.")
                        .font(.caption)
                        .foregroundStyle(BuyyeeColors.error)
                        .padding(.horizontal)
                }

                // Debit Card Option
                PaymentOptionCard(
                    iconName: "creditcard",
                    title: "Debit Card",
                    subtitle: "Visa, Mastercard, or Maya",
                    badge: "Full payment",
                    isSelected: viewModel.selectedPaymentOption == .debitCard,
                    isDisabled: false
                ) {
                    viewModel.selectPaymentOption(.debitCard)
                }
            }
            .padding()
        }
    }
}

struct PaymentOptionCard: View {
    let iconName: String
    let title: String
    let subtitle: String
    let badge: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(isDisabled ? .gray : BuyyeeColors.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        (isDisabled ? Color.gray : BuyyeeColors.primary).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 10)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isDisabled ? .gray : .primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(badge)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isDisabled ? .gray : BuyyeeColors.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? BuyyeeColors.primary : .gray)
            }
            .padding(16)
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? BuyyeeColors.primary : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct BNPLPlanSelectionView: View {
    @ObservedObject var viewModel: CheckoutViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Down payment: \(CurrencyFormatter.shared.string(from: viewModel.downPayment))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                ForEach(viewModel.availablePlans, id: \.plan.id) { option in
                    PlanCard(
                        plan: option.plan,
                        monthly: option.monthly,
                        down: option.down,
                        total: viewModel.cart.subtotal,
                        isSelected: viewModel.selectedPlan == option.plan
                    ) {
                        viewModel.selectedPlan = option.plan
                    }
                }

                LoadingButton(title: "Continue", isLoading: false) {
                    viewModel.confirmPlanSelection()
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

struct PlanCard: View {
    let plan: InstallmentPlan
    let monthly: Decimal
    let down: Decimal
    let total: Decimal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(plan.displayLabel)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? BuyyeeColors.primary : .gray)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Monthly")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        PriceText(amount: monthly, font: .title3.weight(.bold),
                                  color: BuyyeeColors.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Down Payment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        PriceText(amount: down, font: .subheadline.weight(.semibold))
                    }
                }
            }
            .padding(14)
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? BuyyeeColors.primary : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CardSelectionView: View {
    @ObservedObject var viewModel: CheckoutViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                ForEach(CardNetwork.allCases, id: \.self) { network in
                    Button {
                        viewModel.selectedCardNetwork = network
                    } label: {
                        HStack {
                            Image(systemName: network.iconName)
                                .font(.title2)
                                .foregroundStyle(BuyyeeColors.primary)
                                .frame(width: 44)
                            Text(network.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: viewModel.selectedCardNetwork == network
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.selectedCardNetwork == network
                                                 ? BuyyeeColors.primary : .gray)
                        }
                        .padding()
                        .cardStyle()
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(viewModel.selectedCardNetwork == network
                                        ? BuyyeeColors.primary : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Text("Card ending in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("•••• \(viewModel.lastFourDigits)")
                        .font(.subheadline.weight(.semibold))
                }

                LoadingButton(title: "Continue", isLoading: false) {
                    viewModel.confirmCardSelection()
                }
            }
            .padding()
        }
    }
}

struct ReviewOrderView: View {
    @ObservedObject var viewModel: CheckoutViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Order items
                VStack(spacing: 8) {
                    SectionHeader(title: "Order Items")
                    ForEach(viewModel.cart.items) { item in
                        HStack {
                            Image(systemName: item.product.systemImage)
                                .foregroundStyle(BuyyeeColors.primary)
                                .frame(width: 32)
                            VStack(alignment: .leading) {
                                Text(item.product.name).font(.subheadline)
                                Text("Qty: \(item.quantity)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            PriceText(amount: item.subtotal, font: .subheadline.weight(.semibold))
                        }
                        .padding(.horizontal)
                    }
                }

                BuyeeeDivider()

                // Payment breakdown
                VStack(spacing: 8) {
                    SectionHeader(title: "Payment Breakdown")

                    if viewModel.selectedPaymentOption == .bnpl {
                        ReviewRow(label: "Total", value: CurrencyFormatter.shared.string(from: viewModel.cart.subtotal))
                        ReviewRow(label: "Down Payment (20%)", value: CurrencyFormatter.shared.string(from: viewModel.downPayment))
                        ReviewRow(label: "Financed Amount", value: CurrencyFormatter.shared.string(from: viewModel.financedAmount))
                        ReviewRow(label: "Monthly Payment (\(viewModel.selectedPlan.months) months)",
                                  value: CurrencyFormatter.shared.string(from: viewModel.selectedMonthlyPayment),
                                  isHighlighted: true)
                    } else {
                        ReviewRow(label: "Total Charge", value: CurrencyFormatter.shared.string(from: viewModel.cart.subtotal), isHighlighted: true)
                        ReviewRow(label: "Card", value: "\(viewModel.selectedCardNetwork.rawValue) •••• \(viewModel.lastFourDigits)")
                    }
                }

                // Biometric notice
                HStack(spacing: 8) {
                    Image(systemName: "faceid")
                        .foregroundStyle(BuyyeeColors.primary)
                    Text("Face ID required to confirm payment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(BuyyeeColors.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))

                LoadingButton(title: "Confirm & Pay", isLoading: false) {
                    viewModel.submitPayment()
                }
            }
            .padding()
        }
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(isHighlighted ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(isHighlighted ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(isHighlighted ? .subheadline.weight(.bold) : .subheadline)
                .foregroundStyle(isHighlighted ? BuyyeeColors.primary : .primary)
        }
        .padding(.horizontal)
    }
}

struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Processing your payment…")
                .font(.headline)
            Text("Please wait and don't close this screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SuccessView: View {
    let transaction: Transaction
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(BuyyeeColors.success.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(BuyyeeColors.success)
                }
                .padding(.top, 32)

                Text("Payment Successful!")
                    .font(.title2.weight(.bold))

                VStack(spacing: 8) {
                    Text("Order #\(transaction.orderNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BuyyeeColors.primary)

                    PriceText(amount: transaction.totalAmount, font: .title3.weight(.bold))

                    StatusBadge(status: transaction.status)
                }
                .padding()
                .cardStyle()

                if let plan = transaction.installmentPlan,
                   let monthly = transaction.monthlyPayment {
                    VStack(spacing: 4) {
                        Text("Your \(plan.rawValue) plan is active")
                            .font(.subheadline.weight(.semibold))
                        Text("Monthly payment: \(CurrencyFormatter.shared.string(from: monthly))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(BuyyeeColors.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                }

                LoadingButton(title: "Done", isLoading: false, action: onDone)
            }
            .padding()
        }
    }
}

struct FailureView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(BuyyeeColors.error.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(BuyyeeColors.error)
            }

            Text("Payment Failed")
                .font(.title2.weight(.bold))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            LoadingButton(title: "Try Again", isLoading: false, action: onRetry)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
