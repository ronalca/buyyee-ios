//
//  CLLocationService.swift
//  Buyyee
//
//  Created by Rony Alcala on 3/2/26.
//

import CoreLocation
import Combine

protocol CLLocationServiceProtocol: AnyObject {
    var userLocationPublisher: AnyPublisher<CLLocationCoordinate2D, Never> { get }
    var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func startMonitoringSignificantLocationChanges()
    func stopUpdatingLocation()
}

final class CLLocationService: NSObject, CLLocationServiceProtocol {

    private let manager = CLLocationManager()

    private let locationSubject = CurrentValueSubject<CLLocationCoordinate2D, Never>(
        CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842) // Manila default
    )
    private let authSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.notDetermined)

    var userLocationPublisher: AnyPublisher<CLLocationCoordinate2D, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        authSubject.eraseToAnyPublisher()
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestWhenInUseAuthorization()          { manager.requestWhenInUseAuthorization() }
    func startUpdatingLocation()                   { manager.startUpdatingLocation() }

    func startMonitoringSignificantLocationChanges() { manager.startMonitoringSignificantLocationChanges() }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
    }
}

extension CLLocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        locationSubject.send(latest.coordinate)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authSubject.send(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[CLLocationService] Location error: \(error.localizedDescription)")
    }
}

final class MockCLLocationService: CLLocationServiceProtocol {

    private let locationSubject = CurrentValueSubject<CLLocationCoordinate2D, Never>(
        CLLocationCoordinate2D(latitude: 14.5547, longitude: 121.0244)
    )
    private let authSubject = CurrentValueSubject<CLAuthorizationStatus, Never>(.authorizedWhenInUse)

    var userLocationPublisher: AnyPublisher<CLLocationCoordinate2D, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    var authorizationPublisher: AnyPublisher<CLAuthorizationStatus, Never> {
        authSubject.eraseToAnyPublisher()
    }

    func requestWhenInUseAuthorization()           { authSubject.send(.authorizedWhenInUse) }
    func startUpdatingLocation()                    {}
    func startMonitoringSignificantLocationChanges() {}
    func stopUpdatingLocation()                     {}
}
