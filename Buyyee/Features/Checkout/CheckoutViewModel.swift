//
//  CheckoutViewModel.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/30/26.
//

import SwiftUI

enum CheckoutStep: Equatable {
    case paymentMethod
    case bnplPlanSelection
    case cardSelection
    case reviewOrder
    case processing
    case success(Transaction)
    case failure(String)

    static func == (lhs: CheckoutStep, rhs: CheckoutStep) -> Bool {
        switch (lhs, rhs) {
        case (.paymentMethod, .paymentMethod),
             (.bnplPlanSelection, .bnplPlanSelection),
             (.cardSelection, .cardSelection),
             (.reviewOrder, .reviewOrder),
             (.processing, .processing):
            return true
        case (.success, .success), (.failure, .failure):
            return true
        default:
            return false
        }
    }
}

enum PaymentOption {
    case bnpl
    case debitCard
}

@MainActor
final class CheckoutViewModel: ObservableObject {

    @Published private(set) var step: CheckoutStep = .paymentMethod
    @Published private(set) var cart: Cart = Cart()
    @Published var selectedPaymentOption: PaymentOption = .bnpl
    @Published var selectedPlan: InstallmentPlan = .threeMonths
    @Published var selectedCardNetwork: CardNetwork = .visa
    @Published var lastFourDigits: String = "4242"

    @Published private(set) var bnplEligibility: BNPLEligibility?
    @Published private(set) var availablePlans: [(plan: InstallmentPlan, monthly: Decimal, down: Decimal)] = []

    private let cartRepository: any CartRepositoryProtocol
    private let transactionRepository: any TransactionRepositoryProtocol
    private let biometricService: any BiometricServiceProtocol
    private let bnplCalculator: any BNPLCalculatorProtocol
    let currentUser: User

    init(cartRepository: any CartRepositoryProtocol,
         transactionRepository: any TransactionRepositoryProtocol,
         biometricService: any BiometricServiceProtocol,
         bnplCalculator: any BNPLCalculatorProtocol,
         currentUser: User) {
        self.cartRepository = cartRepository
        self.transactionRepository = transactionRepository
        self.biometricService = biometricService
        self.bnplCalculator = bnplCalculator
        self.currentUser = currentUser
        self.cart = cartRepository.cart
        prepareBNPLOptions()
    }

    private func prepareBNPLOptions() {
        let total = cart.subtotal
        bnplEligibility = bnplCalculator.checkEligibility(amount: total, user: currentUser)

        availablePlans = InstallmentPlan.allCases.map { plan in
            let financed = bnplCalculator.financedAmount(for: total)
            let down = bnplCalculator.downPayment(for: total)
            let monthly = bnplCalculator.monthlyPayment(principal: financed, plan: plan)
            return (plan: plan, monthly: monthly, down: down)
        }
    }

    func selectPaymentOption(_ option: PaymentOption) {
        selectedPaymentOption = option
        step = option == .bnpl ? .bnplPlanSelection : .cardSelection
    }

    func confirmPlanSelection() {
        step = .reviewOrder
    }

    func confirmCardSelection() {
        step = .reviewOrder
    }

    func goBack() {
        switch step {
        case .bnplPlanSelection, .cardSelection:
            step = .paymentMethod
        case .reviewOrder:
            step = selectedPaymentOption == .bnpl ? .bnplPlanSelection : .cardSelection
        default:
            break
        }
    }

    func submitPayment() {
        step = .processing

        Task {
            do {
                let authReason = "Confirm your payment of \(CurrencyFormatter.shared.string(from: cart.subtotal))"
                let authenticated = try await biometricService.authenticate(reason: authReason)

                guard authenticated else {
                    step = .failure("Authentication was cancelled.")
                    return
                }

                let paymentMethod = buildPaymentMethod()
                let transaction = try await transactionRepository.submitOrder(
                    cart: cart,
                    paymentMethod: paymentMethod
                )

                cartRepository.clearCart()

                await MainActor.run {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    step = .success(transaction)
                }

            } catch {
                step = .failure(AppError.from(error).message)
            }
        }
    }

    private func buildPaymentMethod() -> any PaymentMethodProtocol {
        if selectedPaymentOption == .bnpl {
            let financed = bnplCalculator.financedAmount(for: cart.subtotal)
            let down = bnplCalculator.downPayment(for: cart.subtotal)
            let monthly = bnplCalculator.monthlyPayment(principal: financed, plan: selectedPlan)
            let schedule = bnplCalculator.generateSchedule(principal: financed, plan: selectedPlan)
            return BNPLPayment(
                plan: selectedPlan,
                downPaymentAmount: down,
                monthlyAmount: monthly,
                schedule: schedule
            )
        } else {
            return DebitCardPayment(
                cardNetwork: selectedCardNetwork,
                lastFourDigits: lastFourDigits
            )
        }
    }

    var downPayment: Decimal { bnplCalculator.downPayment(for: cart.subtotal) }
    var financedAmount: Decimal { bnplCalculator.financedAmount(for: cart.subtotal) }
    var selectedMonthlyPayment: Decimal {
        bnplCalculator.monthlyPayment(
            principal: bnplCalculator.financedAmount(for: cart.subtotal),
            plan: selectedPlan
        )
    }
}
