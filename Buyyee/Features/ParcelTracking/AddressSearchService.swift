//
//  AddressSearchService.swift
//  Buyyee
//
//  Created by Rony Alcala on 3/2/26.
//

import MapKit

final class AddressSearchService {
    private var currentSearchTask: Task<[AddressSearchResult], Error>?

    func search(query: String, region: MKCoordinateRegion) async throws -> [AddressSearchResult] {
        currentSearchTask?.cancel()

        let task = Task<[AddressSearchResult], Error> {
            let request                  = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region               = region
            request.resultTypes          = [.address, .pointOfInterest]

            let response = try await MKLocalSearch(request: request).start()

            return response.mapItems.prefix(8).map { item in
                AddressSearchResult(
                    title:     item.name ?? "Unknown",
                    subtitle:  item.placemark.formattedAddress ?? "",
                    coordinate: item.placemark.coordinate,
                    mapItem:   item
                )
            }
        }

        currentSearchTask = task
        return try await task.value
    }
}

extension MKPlacemark {
    var formattedAddress: String? {
        [subThoroughfare, thoroughfare, locality, administrativeArea]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
