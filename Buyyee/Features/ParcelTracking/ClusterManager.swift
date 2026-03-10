//
//  ClusterManager.swift
//  Buyyee
//
//  Created by Rony Alcala on 3/2/26.
//

import MapKit

protocol ClusterManagerProtocol: AnyObject {
    func addItems(_ items: [any MKAnnotation])
    func removeItems(_ items: [any MKAnnotation])
    func clearItems()
    func cluster()
    func setMapView(_ mapView: MKMapView)
}

final class MockClusterManager: ClusterManagerProtocol {

    private(set) var items: [any MKAnnotation] = []
    private weak var mapView: MKMapView?

    func setMapView(_ mapView: MKMapView) { self.mapView = mapView }

    func addItems(_ items: [any MKAnnotation])    { self.items.append(contentsOf: items) }

    func removeItems(_ items: [any MKAnnotation]) {
        let ids = items.compactMap { ($0 as? ParcelAnnotation)?.annotationID }
        self.items.removeAll { ann in
            guard let p = ann as? ParcelAnnotation else { return false }
            return ids.contains(p.annotationID)
        }
    }

    func clearItems() { items.removeAll() }

    func cluster() {
        guard let mapView else { return }
        mapView.removeAnnotations(mapView.annotations.filter { $0 is ParcelAnnotation })
        mapView.addAnnotations(items.compactMap { $0 as? MKAnnotation })
    }
}
