//
//  AppErrors.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/27/26.
//

import Foundation

enum NetworkError: LocalizedError, Sendable {
    case noInternetConnection
    case timeout
    case serverError(statusCode: Int, message: String?)
    case decodingFailed(underlying: String)
    case requestCancelled
    case unauthorized
    case notFound

    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection. Please check your network and try again."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverError(let code, let message):
            return message ?? "Server error (\(code)). Please try again later."
        case .decodingFailed(let underlying):
            return "Failed to process server response. \(underlying)"
        case .requestCancelled:
            return "Request was cancelled."
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .notFound:
            return "The requested resource was not found."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection: return "Turn on Wi-Fi or mobile data."
        case .unauthorized:         return "Tap to log in again."
        default:                    return "Pull down to refresh."
        }
    }
}

enum PaymentError: LocalizedError, Sendable {
    case insufficientCredit(required: Decimal, available: Decimal)
    case biometricAuthFailed
    case biometricNotAvailable
    case belowMinimumAmount(minimum: Decimal)
    case exceedsMaximumAmount(maximum: Decimal)
    case kycNotVerified
    case invalidCardDetails
    case paymentDeclined(reason: String?)
    case orderSubmissionFailed

    var errorDescription: String? {
        switch self {
        case .insufficientCredit(let required, let available):
            let formatter = CurrencyFormatter.shared
            return "Insufficient credit. Required: \(formatter.string(from: required)), Available: \(formatter.string(from: available))"
        case .biometricAuthFailed:
            return "Biometric authentication failed. Please try again."
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device."
        case .belowMinimumAmount(let min):
            return "Minimum BNPL amount is \(CurrencyFormatter.shared.string(from: min))."
        case .exceedsMaximumAmount(let max):
            return "Maximum BNPL amount is \(CurrencyFormatter.shared.string(from: max))."
        case .kycNotVerified:
            return "KYC verification required for BNPL. Please complete your profile."
        case .invalidCardDetails:
            return "Invalid card details. Please check and try again."
        case .paymentDeclined(let reason):
            return reason ?? "Payment was declined. Please use a different payment method."
        case .orderSubmissionFailed:
            return "Failed to submit your order. Please try again."
        }
    }
}

enum ValidationError: LocalizedError, Sendable {
    case emptyCart
    case emptyField(fieldName: String)
    case invalidFormat(fieldName: String, expected: String)
    case valueTooShort(fieldName: String, minimum: Int)

    var errorDescription: String? {
        switch self {
        case .emptyCart:
            return "Your cart is empty. Add items before checking out."
        case .emptyField(let name):
            return "\(name) cannot be empty."
        case .invalidFormat(let name, let expected):
            return "\(name) format is invalid. Expected: \(expected)."
        case .valueTooShort(let name, let min):
            return "\(name) must be at least \(min) characters."
        }
    }
}

enum KeychainError: LocalizedError, Sendable {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:           return "Keychain item not found."
        case .duplicateItem:          return "Keychain item already exists."
        case .invalidData:            return "Could not encode/decode keychain data."
        case .unexpectedStatus(let s): return "Unexpected keychain status: \(s)."
        }
    }
}

struct AppError: LocalizedError, Sendable {
    let title: String
    let message: String
    let isRetryable: Bool

    var errorDescription: String? { message }

    static func from(_ error: any Error) -> AppError {
        switch error {
        case let e as NetworkError:
            return AppError(
                title: "Connection Error",
                message: e.localizedDescription,
                isRetryable: e != .unauthorized
            )
        case let e as PaymentError:
            return AppError(
                title: "Payment Error",
                message: e.localizedDescription,
                isRetryable: false
            )
        case let e as ValidationError:
            return AppError(
                title: "Validation Error",
                message: e.localizedDescription,
                isRetryable: false
            )
        case let e as KeychainError:
            return AppError(
                title: "Security Error",
                message: e.localizedDescription,
                isRetryable: false
            )
        default:
            return AppError(
                title: "Unexpected Error",
                message: error.localizedDescription,
                isRetryable: true
            )
        }
    }
}

extension NetworkError: Equatable {
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noInternetConnection, .noInternetConnection): return true
        case (.timeout, .timeout):                           return true
        case (.requestCancelled, .requestCancelled):         return true
        case (.unauthorized, .unauthorized):                 return true
        case (.notFound, .notFound):                         return true
        case (.serverError(let lc, _), .serverError(let rc, _)): return lc == rc
        default: return false
        }
    }
}
