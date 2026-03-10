//
//  ParcelTrackingView.swift
//  Buyyee
//
//
//  Created by Rony Alcala on 2/26/26.
//

import SwiftUI


struct ParcelTrackingView: View {

    @ObservedObject var viewModel: ParcelTrackingViewModel

    var body: some View {
        ZStack(alignment: .bottom) {

            ParcelMapView(
                parcels:          viewModel.parcels,
                userCoordinate:   viewModel.userCoordinate,
                selectedParcel:   $viewModel.selectedParcel,
                onRegionChange:   { viewModel.mapRegion = $0 },
                onMapReady:       { viewModel.configureClusterManager(mapView: $0) }
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ParcelListCard(viewModel: viewModel)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.12), radius: 20, y: -4)
            )
        }
        .navigationTitle("My Parcels")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { viewModel.isSearchSheetPresented = true } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .sheet(isPresented: $viewModel.isSearchSheetPresented) {
            AddressSearchSheet(viewModel: viewModel)
        }
        .sheet(item: $viewModel.selectedParcel) { parcel in
            ParcelDetailSheet(parcel: parcel)
        }
        .onAppear    { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToParcel)) { note in
            guard let parcelID = note.userInfo?["parcel_id"] as? UUID else { return }
            viewModel.selectedParcel = viewModel.parcels.first { $0.id == parcelID }
        }
    }
}

struct ParcelListCard: View {
    @ObservedObject var viewModel: ParcelTrackingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Parcels").font(.headline)
                    HStack(spacing: 4) {
                        Circle().fill(BuyyeeColors.success).frame(width: 6, height: 6)
                        Text("Live updates active").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.parcels) { parcel in
                        ParcelCard(parcel: parcel, isSelected: viewModel.selectedParcel?.id == parcel.id)
                            .onTapGesture { viewModel.selectedParcel = parcel }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }
}

struct AddressSearchSheet: View {
    @ObservedObject var viewModel: ParcelTrackingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextField("Search delivery address…", text: Binding(
                    get:  { viewModel.searchQuery },
                    set:  { viewModel.onSearchQueryChanged($0) }
                ))
                .textFieldStyle(.roundedBorder)
                .padding()

                if viewModel.isSearching {
                    ProgressView().padding()
                }

                List(viewModel.searchResults) { result in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title).font(.subheadline)
                        Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.isSearchSheetPresented = false
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Find Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isSearchSheetPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ParcelCard: View {
    let parcel: Parcel
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: parcel.status.systemImage)
                    .foregroundStyle(parcel.status.tintColor)
                Text(parcel.trackingNumber)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }

            Text(parcel.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Circle().fill(parcel.status.tintColor).frame(width: 6, height: 6)
                Text(parcel.status.rawValue)
                    .font(.caption2.bold())
                    .foregroundStyle(parcel.status.tintColor)
            }

            if let eta = parcel.estimatedDelivery {
                Text(eta, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? BuyyeeColors.primary : Color(.systemGray5),
                                lineWidth: isSelected ? 2 : 1)
                )
        )
        .shadow(color: isSelected ? BuyyeeColors.primary.opacity(0.2) : .black.opacity(0.05),
                radius: isSelected ? 8 : 4)
    }
}

struct ParcelDetailSheet: View {
    let parcel: Parcel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Status banner
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(parcel.status.tintColor.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: parcel.status.systemImage)
                                .font(.title2)
                                .foregroundStyle(parcel.status.tintColor)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(parcel.status.rawValue).font(.headline)
                            Text("via \(parcel.courierName)")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Route
                    VStack(alignment: .leading, spacing: 6) {
                        Label("From", systemImage: "building.2")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(parcel.origin).font(.subheadline)
                        Divider()
                        Label("To", systemImage: "house")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(parcel.destination).font(.subheadline)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Timeline
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status Timeline").font(.headline).padding(.horizontal)

                        ForEach(parcel.statusHistory.reversed()) { event in
                            HStack(alignment: .top, spacing: 14) {
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(event.status.tintColor)
                                        .frame(width: 10, height: 10)
                                        .padding(.top, 4)
                                    Rectangle()
                                        .fill(Color(.systemGray4))
                                        .frame(width: 1)
                                        .frame(maxHeight: .infinity)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.status.rawValue).font(.subheadline.bold())
                                    Text(event.location).font(.caption).foregroundStyle(.secondary)
                                    if let note = event.note {
                                        Text(note).font(.caption2).foregroundStyle(.tertiary)
                                    }
                                    Text(event.timestamp, style: .relative)
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(parcel.trackingNumber)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Previews
#if DEBUG
#Preview("Parcel Tracking · Live") {
    NavigationStack {
        ParcelTrackingView(viewModel: ParcelTrackingViewModel(
            locationService:  MockCLLocationService(),
            webSocketService: MockParcelWebSocketService()
        ))
    }
}

#Preview("Parcel Detail") {
    ParcelDetailSheet(parcel: MockParcelData.parcels[0])
}

#Preview("Parcel Card") {
    HStack {
        ParcelCard(parcel: MockParcelData.parcels[0], isSelected: true)
        ParcelCard(parcel: MockParcelData.parcels[2], isSelected: false)
    }
    .padding()
}
#endif
