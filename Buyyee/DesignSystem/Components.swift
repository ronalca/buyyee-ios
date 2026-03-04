//
//  DesignSystem.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/27/26.
//

import SwiftUI

enum BuyyeeColors {
    static let primary   = Color(red: 0.063, green: 0.725, blue: 0.506)   // Teal #10B981
    static let secondary = Color(red: 0.961, green: 0.620, blue: 0.043)   // Orange #F59E0B
    static let success   = Color(red: 0.133, green: 0.773, blue: 0.369)   // Green
    static let error     = Color(red: 0.937, green: 0.267, blue: 0.267)   // Red
    static let cardBG    = Color(.systemBackground)
    static let subtleBG  = Color(.secondarySystemBackground)
    static let warning   = Color(.systemTeal)
}

struct FilterChip<T: Hashable>: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : BuyyeeColors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? BuyyeeColors.primary : BuyyeeColors.primary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct StatusBadge: View {
    let status: TransactionStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.caption2)
            Text(status.rawValue)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.12), in: Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .approved: return BuyyeeColors.success
        case .pending:  return BuyyeeColors.secondary
        case .declined: return BuyyeeColors.error
        case .refunded: return .purple
        case .cancelled: return .gray
        }
    }
}

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(.white)
            .background(BuyyeeColors.primary, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }
}

struct PriceText: View {
    let amount: Decimal
    var font: Font = .title3.weight(.bold)
    var color: Color = .primary

    var body: some View {
        Text(CurrencyFormatter.shared.string(from: amount))
            .font(font)
            .foregroundStyle(color)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(BuyyeeColors.primary.opacity(0.5))

            Text(title)
                .font(.title3.weight(.semibold))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(BuyyeeColors.primary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(BuyyeeColors.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

struct BuyeeeDivider: View {
    var body: some View {
        Divider()
            .padding(.horizontal)
    }
}
