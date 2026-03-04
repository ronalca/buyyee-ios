//
//  BNPLCalculatorTests.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/30/26.
//

import XCTest
@testable import Buyyee

final class BNPLCalculatorTests: XCTestCase {

    var sut: BNPLCalculator!  

    override func setUp() {
        super.setUp()
        sut = BNPLCalculator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_downPayment_is20Percent_ofTotal() {
        let total = Decimal(string: "10000")!

        let downPayment = sut.downPayment(for: total)

        XCTAssertEqual(downPayment, Decimal(string: "2000")!)
    }

    func test_financedAmount_is80Percent_ofTotal() {
        let total = Decimal(string: "50000")!
        let financed = sut.financedAmount(for: total)
        XCTAssertEqual(financed, Decimal(string: "40000")!)
    }

    func test_monthlyPayment_threeMonthPlan_zeroInterest_equalsDivision() {
        // Arrange: ₱10,000 financed at 0% over 3 months = ₱3,333.33/month
        let principal = Decimal(string: "10000")!

        // Act
        let monthly = sut.monthlyPayment(principal: principal, plan: .threeMonths)

        // Assert: 10000 / 3 = 3333.33 (rounded to cents)
        XCTAssertEqual(monthly, Decimal(string: "3333.33")!)
    }

    func test_schedule_threeMonthPlan_hasCorrectCount() {
        let principal = Decimal(string: "10000")!
        let schedule = sut.generateSchedule(principal: principal, plan: .threeMonths)
        XCTAssertEqual(schedule.count, 3)
    }

    func test_schedule_threeMonthPlan_zeroInterestOnAllRows() {
        let principal = Decimal(string: "10000")!
        let schedule = sut.generateSchedule(principal: principal, plan: .threeMonths)

        for item in schedule {
            XCTAssertEqual(item.interestComponent, .zero,
                           "3-month plan is 0% — all interest components should be zero")
        }
    }

    func test_schedule_threeMonthPlan_remainingBalanceReachesZero() {
        let principal = Decimal(string: "9999")!
        let schedule = sut.generateSchedule(principal: principal, plan: .threeMonths)

        XCTAssertEqual(schedule.last?.remainingBalance, .zero,
                       "After final payment, remaining balance should be exactly zero")
    }

    func test_monthlyPayment_sixMonthPlan_withInterest_isGreaterThanSimpleDivision() {
        let principal = Decimal(string: "40000")!

        let monthly = sut.monthlyPayment(principal: principal, plan: .sixMonths)
        let simpleDivision = principal / Decimal(6)

        // Assert: With interest, monthly payment must be higher than simple division
        XCTAssertGreaterThan(monthly, simpleDivision,
                             "12% p.a. interest should increase monthly payment above simple division")
    }

    func test_schedule_sixMonthPlan_hasCorrectCount() {
        let principal = Decimal(string: "40000")!
        let schedule = sut.generateSchedule(principal: principal, plan: .sixMonths)
        XCTAssertEqual(schedule.count, 6)
    }

    func test_schedule_sixMonthPlan_interestDecreaseOverTime() {
        let principal = Decimal(string: "40000")!
        let schedule = sut.generateSchedule(principal: principal, plan: .sixMonths)

        for i in 1..<schedule.count {
            XCTAssertGreaterThanOrEqual(
                schedule[i-1].interestComponent,
                schedule[i].interestComponent,
                "Interest should decrease (or stay equal) each month in amortization"
            )
        }
    }

    func test_schedule_twelveMonthPlan_remainingBalanceIsMonotonicallyDecreasing() {
        let principal = Decimal(string: "60000")!
        let schedule = sut.generateSchedule(principal: principal, plan: .twelveMonths)

        for i in 1..<schedule.count {
            XCTAssertLessThan(
                schedule[i].remainingBalance,
                schedule[i-1].remainingBalance,
                "Remaining balance should decrease each month"
            )
        }
    }

    func test_eligibility_exceedsCreditLimit_isNotEligible() {
        // Arrange: User has ₱50,000 credit; order needs ₱80,000 financed
        let amount = Decimal(string: "100000")!  // 80% financed = ₱80,000
        let user = User(
            id: UUID(),
            fullName: "Maria Santos",
            email: "maria@email.com",
            phoneNumber: "+63 917 000 0000",
            creditLimit: Decimal(string: "50000")!,
            availableCredit: Decimal(string: "50000")!,
            isKYCVerified: true
        )

        let result = sut.checkEligibility(amount: amount, user: user)

        XCTAssertFalse(result.isEligible)
        XCTAssertNotNil(result.reason)
    }

    func test_eligibility_kycNotVerified_isNotEligible() {
        let amount = Decimal(string: "5000")!
        let user = User(
            id: UUID(),
            fullName: "Pedro Penduko",
            email: "pedro@email.com",
            phoneNumber: "+63 917 111 1111",
            creditLimit: Decimal(string: "100000")!,
            availableCredit: Decimal(string: "100000")!,
            isKYCVerified: false   // KYC not verified
        )

        let result = sut.checkEligibility(amount: amount, user: user)

        XCTAssertFalse(result.isEligible)
        XCTAssertTrue(result.reason?.contains("verification") ?? false,
                      "KYC failure reason should mention verification")
    }

    func test_eligibility_validScenario_isEligible() {
        // Arrange: Valid amount, sufficient credit, KYC verified
        let amount = Decimal(string: "20000")!
        let user = makeEligibleUser()

        let result = sut.checkEligibility(amount: amount, user: user)

        XCTAssertTrue(result.isEligible)
        XCTAssertNil(result.reason)
        XCTAssertGreaterThan(result.maxEligibleAmount, .zero)
    }

    func test_monthlyPayment_exactlyDivisible_noCentsRemainder() {
        // ₱30,000 / 3 months = exactly ₱10,000/month (no remainder)
        let principal = Decimal(string: "30000")!
        let monthly = sut.monthlyPayment(principal: principal, plan: .threeMonths)
        XCTAssertEqual(monthly, Decimal(string: "10000")!)
    }

    func test_schedule_dueDates_incrementByOneMonthEach() {
        let principal = Decimal(string: "10000")!
        let startDate = Date()
        let schedule = sut.generateSchedule(principal: principal, plan: .threeMonths)

        let calendar = Calendar.current

        for (index, item) in schedule.enumerated() {
            let expectedMonth = calendar.date(byAdding: .month, value: index + 1, to: startDate)!
            let expectedComponents = calendar.dateComponents([.year, .month], from: expectedMonth)
            let actualComponents = calendar.dateComponents([.year, .month], from: item.dueDate)

            XCTAssertEqual(expectedComponents.year, actualComponents.year)
            XCTAssertEqual(expectedComponents.month, actualComponents.month,
                           "Month \(index + 1) due date should be exactly 1 month after previous")
        }
    }

    private func makeEligibleUser() -> User {
        User(
            id: UUID(),
            fullName: "Marry Grace Piattos",
            email: "mgpiattos@email.com",
            phoneNumber: "+63 967 123 4567",
            creditLimit: Decimal(string: "150000")!,
            availableCredit: Decimal(string: "120000")!,
            isKYCVerified: true
        )
    }
}
