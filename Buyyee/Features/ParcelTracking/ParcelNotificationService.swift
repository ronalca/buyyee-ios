//
//  ParcelNotificationService.swift
//  Buyyee
//
//  Created by Rony Alcala on 3/2/26.
//

import UserNotifications

final class ParcelNotificationService: NSObject {

    static let trackingCategoryID = "PARCEL_TRACKING"

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
        } catch {
            return false
        }
    }

    func scheduleStatusNotification(for parcel: Parcel, newStatus: ParcelStatus) {
        guard newStatus.shouldNotify else { return }

        let content                  = UNMutableNotificationContent()
        content.title                = "Parcel Update · \(parcel.trackingNumber)"
        content.body                 = statusBody(parcel: parcel, status: newStatus)
        content.sound                = .default
        content.badge                = 1
        content.categoryIdentifier   = Self.trackingCategoryID
        content.userInfo             = ["parcel_id": parcel.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "parcel-\(parcel.id.uuidString)-\(newStatus.rawValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[Notifications] Schedule failed: \(error.localizedDescription)") }
        }
    }
    
    func registerNotificationCategories() {
        let trackAction = UNNotificationAction(
            identifier: "TRACK_ACTION",
            title: "Track Now",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.trackingCategoryID,
            actions: [trackAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private func statusBody(parcel: Parcel, status: ParcelStatus) -> String {
        switch status {
        case .dispatched:     return "\(parcel.description) has left the warehouse."
        case .outForDelivery: return "Your parcel is out for delivery! Expected today."
        case .delivered:      return "\(parcel.description) has been delivered. ✓"
        case .failed:         return "Delivery attempt failed. We'll try again tomorrow."
        default:              return "Status updated to \(status.rawValue)."
        }
    }
}

extension ParcelNotificationService: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let parcelIDString = userInfo["parcel_id"] as? String,
           let parcelID       = UUID(uuidString: parcelIDString) {
            NotificationCenter.default.post(
                name: .navigateToParcel,
                object: nil,
                userInfo: ["parcel_id": parcelID]
            )
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let navigateToParcel = Notification.Name("navigateToParcel")
}
