//
//  BNPLCalculator.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/27/26.
//

import Foundation

final class CurrencyFormatter: @unchecked Sendable {
    static let shared = CurrencyFormatter()
    private let formatter: NumberFormatter

    private init() {
        formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₱"
        formatter.currencyCode = "PHP"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
    }

    func string(from decimal: Decimal) -> String {
        formatter.string(from: decimal as NSDecimalNumber) ?? "₱0.00"
    }
}

// Amortization formula: M = P × [r(1+r)^n] / [(1+r)^n - 1]
final class BNPLCalculator: BNPLCalculatorProtocol, @unchecked Sendable {

    static let downPaymentRate: Decimal   = Decimal(string: "0.20")!
    static let minimumBNPLAmount: Decimal = 500
    static let maximumBNPLAmount: Decimal = 150_000

    func downPayment(for total: Decimal) -> Decimal {
        roundToCentavo(total * BNPLCalculator.downPaymentRate)
    }

    func financedAmount(for total: Decimal) -> Decimal {
        roundToCentavo(total - downPayment(for: total))
    }

    func monthlyPayment(principal: Decimal, plan: InstallmentPlan) -> Decimal {
//        let numMonths = plan.months
        let annualRate = plan.annualInterestRate

        if annualRate == .zero {
            return roundToCentavo(principal / Decimal(plan.months))
        }

        let rate = annualRate / 12
        let onePlusR = NSDecimalNumber(decimal: 1 + rate)
        let onePlusRPowN = onePlusR.raising(toPower: plan.months).decimalValue
        let numerator = principal * rate * onePlusRPowN
        let denominator = onePlusRPowN - 1
        guard denominator != .zero else { return .zero }
        return roundToCentavo(numerator / denominator)
    }

    func generateSchedule(principal: Decimal, plan: InstallmentPlan) -> [InstallmentScheduleItem] {
//        let n = plan.months
        let monthlyRate = plan.annualInterestRate / 12
        let payment = monthlyPayment(principal: principal, plan: plan)
        var schedule: [InstallmentScheduleItem] = []
        var balance = principal
        let calendar = Calendar.current
        let today = Date()

        for month in 1...plan.months {
            let dueDate = calendar.date(byAdding: .month, value: month, to: today) ?? today
            let interestComponent = roundToCentavo(balance * monthlyRate)
            let principalComponent = plan.annualInterestRate == .zero ? payment : payment - interestComponent
            let isLast = month == plan.months
            let adjPrincipal = isLast ? balance : principalComponent
            let adjPayment = isLast ? roundToCentavo(adjPrincipal + interestComponent) : payment
            balance -= adjPrincipal

            schedule.append(InstallmentScheduleItem(
                monthNumber: month,
                dueDate: dueDate,
                principalComponent: adjPrincipal,
                interestComponent: interestComponent,
                monthlyPayment: adjPayment,
                remainingBalance: max(.zero, balance)
            ))
        }
        return schedule
    }

    func checkEligibility(amount: Decimal, user: User) -> BNPLEligibility {
        guard user.isKYCVerified else {
            return BNPLEligibility(isEligible: false,
                reason: "KYC verification required to use BNPL.",
                maxEligibleAmount: .zero)
        }
        guard amount >= BNPLCalculator.minimumBNPLAmount else {
            return BNPLEligibility(isEligible: false,
                reason: "Minimum BNPL amount is \(CurrencyFormatter.shared.string(from: BNPLCalculator.minimumBNPLAmount)).",
                maxEligibleAmount: BNPLCalculator.minimumBNPLAmount)
        }
        let financed = financedAmount(for: amount)
        guard financed <= user.availableCredit else {
            return BNPLEligibility(isEligible: false,
                reason: "Financed amount exceeds your available credit of \(CurrencyFormatter.shared.string(from: user.availableCredit)).",
                maxEligibleAmount: user.availableCredit)
        }
        guard amount <= BNPLCalculator.maximumBNPLAmount else {
            return BNPLEligibility(isEligible: false,
                reason: "Maximum BNPL amount is \(CurrencyFormatter.shared.string(from: BNPLCalculator.maximumBNPLAmount)).",
                maxEligibleAmount: BNPLCalculator.maximumBNPLAmount)
        }
        return BNPLEligibility(isEligible: true, reason: nil,
            maxEligibleAmount: min(user.availableCredit, BNPLCalculator.maximumBNPLAmount))
    }

    private func roundToCentavo(_ value: Decimal) -> Decimal {
        var result = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, 2, .bankers)
        return rounded
    }
}
