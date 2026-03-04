//
//  MockData.swift
//  Buyyee
//
//  Created by Rony Alcala on 1/28/26.
//

import Foundation

enum MockData {

    // MARK: - Sample User
    static let currentUser = User(
        id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
        fullName: "Juan dela Cruz",
        email: "juan@buyyee.ph",
        phoneNumber: "+63 917 123 4567",
        creditLimit: Decimal(string: "150000")!,
        availableCredit: Decimal(string: "120000")!,
        isKYCVerified: true
    )

    // MARK: - Products (15 items across 5 categories)
    static let products: [Product] = [

        // LAPTOPS
        Product(id: UUID(), name: "MacBook Air M3", brand: "Apple",
                description: "15-inch, 8GB RAM, 256GB SSD. Fanless design with up to 18-hour battery life.",
                price: Decimal(string: "74990")!, category: .laptops,
                systemImage: "laptopcomputer", stockCount: 5, rating: 4.9, reviewCount: 312),

        Product(id: UUID(), name: "ThinkPad E14 Gen 5", brand: "Lenovo",
                description: "AMD Ryzen 7, 16GB RAM, 512GB SSD. Business-class reliability.",
                price: Decimal(string: "42990")!, category: .laptops,
                systemImage: "laptopcomputer", stockCount: 8, rating: 4.6, reviewCount: 178),

        Product(id: UUID(), name: "ROG Strix G16", brand: "ASUS",
                description: "Intel Core i9, RTX 4070, 32GB RAM. Dominate every game.",
                price: Decimal(string: "69990")!, category: .laptops,
                systemImage: "laptopcomputer", stockCount: 3, rating: 4.8, reviewCount: 95),

        // PC PARTS
        Product(id: UUID(), name: "RTX 4070 Ti Super", brand: "NVIDIA",
                description: "16GB GDDR6X, DLSS 3.5, Ray Tracing. Next-gen GPU performance.",
                price: Decimal(string: "47990")!, category: .desktopParts,
                systemImage: "cpu", stockCount: 4, rating: 4.7, reviewCount: 221),

        Product(id: UUID(), name: "Samsung 990 PRO 2TB", brand: "Samsung",
                description: "NVMe Gen 4 SSD. Up to 7,450 MB/s sequential read speed.",
                price: Decimal(string: "11490")!, category: .desktopParts,
                systemImage: "internaldrive", stockCount: 15, rating: 4.8, reviewCount: 445),

        Product(id: UUID(), name: "LG 27\" UltraGear 4K", brand: "LG",
                description: "27-inch IPS, 4K 144Hz, 1ms GTG. True-to-life color accuracy.",
                price: Decimal(string: "23990")!, category: .desktopParts,
                systemImage: "display", stockCount: 7, rating: 4.6, reviewCount: 133),

        // CONSOLES
        Product(id: UUID(), name: "PlayStation 5 Slim", brand: "Sony",
                description: "Disc edition. 825GB SSD, DualSense controller included.",
                price: Decimal(string: "27990")!, category: .gamingConsoles,
                systemImage: "gamecontroller.fill", stockCount: 2, rating: 4.9, reviewCount: 876),

        Product(id: UUID(), name: "Nintendo Switch OLED", brand: "Nintendo",
                description: "7-inch OLED screen, enhanced audio, 64GB storage.",
                price: Decimal(string: "19990")!, category: .gamingConsoles,
                systemImage: "gamecontroller", stockCount: 11, rating: 4.7, reviewCount: 654),

        Product(id: UUID(), name: "Xbox Series X", brand: "Microsoft",
                description: "1TB SSD, 4K 120fps, Xbox Game Pass compatible.",
                price: Decimal(string: "29990")!, category: .gamingConsoles,
                systemImage: "gamecontroller", stockCount: 6, rating: 4.8, reviewCount: 421),

        // PHONES & TABLETS
        Product(id: UUID(), name: "iPhone 16 Pro", brand: "Apple",
                description: "6.3-inch Super Retina XDR, A18 Pro chip, 48MP camera system.",
                price: Decimal(string: "71990")!, category: .smartphones,
                systemImage: "iphone", stockCount: 9, rating: 4.9, reviewCount: 1203),

        Product(id: UUID(), name: "Galaxy S24 Ultra", brand: "Samsung",
                description: "6.8-inch Dynamic AMOLED, built-in S Pen, 200MP AI camera.",
                price: Decimal(string: "69990")!, category: .smartphones,
                systemImage: "iphone", stockCount: 7, rating: 4.8, reviewCount: 987),

        Product(id: UUID(), name: "iPad Air M2", brand: "Apple",
                description: "11-inch Liquid Retina, M2 chip, Apple Pencil Pro compatible.",
                price: Decimal(string: "39990")!, category: .smartphones,
                systemImage: "ipad", stockCount: 12, rating: 4.8, reviewCount: 543),

        // AUDIO & PERIPHERALS
        Product(id: UUID(), name: "AirPods Pro 2", brand: "Apple",
                description: "Active Noise Cancellation, Adaptive Audio, MagSafe charging.",
                price: Decimal(string: "14990")!, category: .audio,
                systemImage: "airpodspro", stockCount: 20, rating: 4.7, reviewCount: 1876),

        Product(id: UUID(), name: "MX Master 3S", brand: "Logitech",
                description: "8K DPI sensor, ultra-quiet clicks, MagSpeed scrolling.",
                price: Decimal(string: "5495")!, category: .audio,
                systemImage: "computermouse", stockCount: 18, rating: 4.8, reviewCount: 732),

        Product(id: UUID(), name: "Keychron Q1 Pro", brand: "Keychron",
                description: "75% layout, QMK/VIA, hot-swappable, gasket-mounted.",
                price: Decimal(string: "9990")!, category: .audio,
                systemImage: "keyboard", stockCount: 9, rating: 4.9, reviewCount: 341)
    ]

    // MARK: - Sample Transactions (6 items for pagination testing)
    static let transactions: [Transaction] = [
        Transaction(
            id: UUID(), orderNumber: "BUY-2024001-1001",
            items: [CartItem(product: products[0], quantity: 1)],
            totalAmount: Decimal(string: "74990")!,
            paymentMethodDescription: "Buyyee Installments · 12 Months",
            status: .approved, createdAt: Date().addingTimeInterval(-86400),
            installmentPlan: .twelveMonths,
            downPayment: Decimal(string: "14998")!,
            monthlyPayment: Decimal(string: "5416")!
        ),
        Transaction(
            id: UUID(), orderNumber: "BUY-2024002-1002",
            items: [CartItem(product: products[6], quantity: 1)],
            totalAmount: Decimal(string: "27990")!,
            paymentMethodDescription: "Visa •••• 4242",
            status: .approved, createdAt: Date().addingTimeInterval(-172800),
            installmentPlan: nil, downPayment: nil, monthlyPayment: nil
        ),
        Transaction(
            id: UUID(), orderNumber: "BUY-2024003-1003",
            items: [CartItem(product: products[12], quantity: 2)],
            totalAmount: Decimal(string: "29980")!,
            paymentMethodDescription: "Buyyee Installments · 6 Months",
            status: .pending, createdAt: Date().addingTimeInterval(-259200),
            installmentPlan: .sixMonths,
            downPayment: Decimal(string: "5996")!,
            monthlyPayment: Decimal(string: "4164")!
        ),
        Transaction(
            id: UUID(), orderNumber: "BUY-2024004-1004",
            items: [CartItem(product: products[3], quantity: 1)],
            totalAmount: Decimal(string: "47990")!,
            paymentMethodDescription: "Mastercard •••• 5678",
            status: .declined, createdAt: Date().addingTimeInterval(-345600),
            installmentPlan: nil, downPayment: nil, monthlyPayment: nil
        ),
        Transaction(
            id: UUID(), orderNumber: "BUY-2024005-1005",
            items: [CartItem(product: products[9], quantity: 1), CartItem(product: products[12], quantity: 1)],
            totalAmount: Decimal(string: "86980")!,
            paymentMethodDescription: "Buyyee Installments · 12 Months",
            status: .approved, createdAt: Date().addingTimeInterval(-432000),
            installmentPlan: .twelveMonths,
            downPayment: Decimal(string: "17396")!,
            monthlyPayment: Decimal(string: "6296")!
        ),
        Transaction(
            id: UUID(), orderNumber: "BUY-2024006-1006",
            items: [CartItem(product: products[13], quantity: 1)],
            totalAmount: Decimal(string: "5495")!,
            paymentMethodDescription: "Maya •••• 9999",
            status: .refunded, createdAt: Date().addingTimeInterval(-518400),
            installmentPlan: nil, downPayment: nil, monthlyPayment: nil
        )
    ]

    // MARK: - Sample Saved Card
    static let savedCard = DebitCardPayment(
        cardNetwork: .visa,
        lastFourDigits: "4242"
    )
}
