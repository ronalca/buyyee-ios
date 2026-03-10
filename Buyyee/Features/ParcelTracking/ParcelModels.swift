//
//  ParcelModels.swift
//  Buyyee
//
//  Created by Rony Alcala on 2/28/26.
//

import CoreLocation
import MapKit
import SwiftUICore

enum ParcelStatus: String, Codable, Equatable, CaseIterable {
    case orderPlaced    = "Order Placed"
    case processing     = "Processing"
    case dispatched     = "Dispatched"
    case inTransit      = "In Transit"
    case outForDelivery = "Out for Delivery"
    case delivered      = "Delivered"
    case failed         = "Delivery Failed"
    case returned       = "Returned to Sender"

    var systemImage: String {
        switch self {
        case .orderPlaced:    return "checkmark.circle"
        case .processing:     return "shippingbox"
        case .dispatched:     return "arrow.up.forward.circle"
        case .inTransit:      return "truck.box"
        case .outForDelivery: return "bicycle"
        case .delivered:      return "checkmark.seal.fill"
        case .failed:         return "exclamationmark.circle.fill"
        case .returned:       return "arrow.uturn.left.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .delivered:      return BuyyeeColors.success
        case .failed:         return BuyyeeColors.error
        case .returned:       return BuyyeeColors.error
        case .outForDelivery: return BuyyeeColors.secondary
        default:              return BuyyeeColors.primary
        }
    }

    var shouldNotify: Bool {
        switch self {
        case .dispatched, .outForDelivery, .delivered, .failed: return true
        default: return false
        }
    }
}

struct Parcel: Identifiable, Codable, Equatable {
    let id: UUID
    let trackingNumber: String
    let description: String
    let origin: String
    let destination: String
    var status: ParcelStatus
    var currentLocation: ParcelCoordinate?
    var estimatedDelivery: Date?
    var statusHistory: [ParcelStatusEvent]
    var courierName: String

    struct ParcelCoordinate: Codable, Equatable {
        let latitude: Double
        let longitude: Double
        var clCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}

struct ParcelStatusEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let status: ParcelStatus
    let timestamp: Date
    let location: String
    let note: String?

    init(status: ParcelStatus, timestamp: Date, location: String, note: String? = nil) {
        self.id        = UUID()
        self.status    = status
        self.timestamp = timestamp
        self.location  = location
        self.note      = note
    }
}

struct ParcelUpdateMessage: Codable {
    let trackingNumber: String
    let status: ParcelStatus
    let latitude: Double?
    let longitude: Double?
    let note: String?
    let timestamp: Date
}

struct AddressSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    let mapItem: MKMapItem
}

// Mock parcel test data
enum MockParcelData {
    static let parcels: [Parcel] = [
        Parcel(
            id: UUID(),
            trackingNumber: "BUY-TRK-001",
            description: "MacBook Air M3 · Order BUY-2024001",
            origin: "Buyyee Warehouse, BGC, Taguig",
            destination: "Ayala Ave, Makati City",
            status: .outForDelivery,
            currentLocation: .init(latitude: 14.5495, longitude: 121.0440),
            estimatedDelivery: Date().addingTimeInterval(3600),
            statusHistory: [
                ParcelStatusEvent(status: .orderPlaced,    timestamp: Date().addingTimeInterval(-86400 * 2), location: "Buyyee HQ"),
                ParcelStatusEvent(status: .processing,     timestamp: Date().addingTimeInterval(-86400),     location: "BGC Warehouse"),
                ParcelStatusEvent(status: .dispatched,     timestamp: Date().addingTimeInterval(-7200),      location: "BGC Warehouse"),
                ParcelStatusEvent(status: .inTransit,      timestamp: Date().addingTimeInterval(-3600),      location: "C5 Road Hub"),
                ParcelStatusEvent(status: .outForDelivery, timestamp: Date().addingTimeInterval(-1800),      location: "Makati Distribution"),
            ],
            courierName: "Carlos R."
        ),
        Parcel(
            id: UUID(),
            trackingNumber: "BUY-TRK-002",
            description: "AirPods Pro 2 × 2 · Order BUY-2024003",
            origin: "Buyyee Warehouse, BGC, Taguig",
            destination: "Quezon City, Metro Manila",
            status: .inTransit,
            currentLocation: .init(latitude: 14.5800, longitude: 121.0200),
            estimatedDelivery: Date().addingTimeInterval(86400),
            statusHistory: [
                ParcelStatusEvent(status: .orderPlaced, timestamp: Date().addingTimeInterval(-86400),  location: "Buyyee HQ"),
                ParcelStatusEvent(status: .processing,  timestamp: Date().addingTimeInterval(-43200),  location: "BGC Warehouse"),
                ParcelStatusEvent(status: .dispatched,  timestamp: Date().addingTimeInterval(-7200),   location: "BGC Warehouse"),
                ParcelStatusEvent(status: .inTransit,   timestamp: Date().addingTimeInterval(-3600),   location: "EDSA Hub"),
            ],
            courierName: "Maria S."
        ),
        Parcel(
            id: UUID(),
            trackingNumber: "BUY-TRK-003",
            description: "MX Master 3S · Order BUY-2024006",
            origin: "Buyyee Warehouse, BGC, Taguig",
            destination: "Pasig City, Metro Manila",
            status: .delivered,
            currentLocation: .init(latitude: 14.5764, longitude: 121.0851),
            estimatedDelivery: Date().addingTimeInterval(-3600),
            statusHistory: [
                ParcelStatusEvent(status: .orderPlaced,    timestamp: Date().addingTimeInterval(-86400 * 3), location: "Buyyee HQ"),
                ParcelStatusEvent(status: .processing,     timestamp: Date().addingTimeInterval(-86400 * 2), location: "BGC Warehouse"),
                ParcelStatusEvent(status: .dispatched,     timestamp: Date().addingTimeInterval(-86400),     location: "BGC Warehouse"),
                ParcelStatusEvent(status: .inTransit,      timestamp: Date().addingTimeInterval(-7200),      location: "Ortigas Hub"),
                ParcelStatusEvent(status: .outForDelivery, timestamp: Date().addingTimeInterval(-3600),      location: "Pasig Distribution"),
                ParcelStatusEvent(status: .delivered,      timestamp: Date().addingTimeInterval(-1800),      location: "Pasig City", note: "Left at front door"),
            ],
            courierName: "Jose M."
        )
    ]
}
