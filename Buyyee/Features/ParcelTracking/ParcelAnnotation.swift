//
//  ParcelAnnotation.swift
//  Buyyee
//
//  Created by Rony Alcala on 2/28/26.
//

import MapKit

final class ParcelAnnotation: NSObject, MKAnnotation {

    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    let parcel: Parcel
    let annotationID: UUID

    init(parcel: Parcel) {
        self.parcel       = parcel
        self.annotationID = parcel.id
        self.coordinate   = parcel.currentLocation?.clCoordinate
            ?? CLLocationCoordinate2D(latitude: 14.5547, longitude: 121.0504)
        self.title     = parcel.trackingNumber
        self.subtitle  = parcel.status.rawValue
        super.init()
    }

    // Animate coordinate change — MapKit interpolates the movement via KVO.
    func updateCoordinate(to newCoordinate: CLLocationCoordinate2D) {
        UIView.animate(withDuration: 1.2, delay: 0, options: .curveEaseInOut) { [weak self] in
            self?.coordinate = newCoordinate
        }
    }
}
