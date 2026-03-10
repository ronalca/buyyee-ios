//
//  ParcelWebSocketService.swift
//  Buyyee
//
//  Created by Rony Alcala on 3/2/26.
//

import Combine
import Foundation

protocol ParcelWebSocketServiceProtocol: AnyObject {
    var updatePublisher: AnyPublisher<ParcelUpdateMessage, Never> { get }
    func connect(trackingNumbers: [String])
    func disconnect()
}

final class ParcelWebSocketService: ParcelWebSocketServiceProtocol {

    private let updateSubject = PassthroughSubject<ParcelUpdateMessage, Never>()
    var updatePublisher: AnyPublisher<ParcelUpdateMessage, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    private var webSocketTask: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private var isConnected = false
    private let wsURL = URL(string: "wss://echo.websocket.org")!

    func connect(trackingNumbers: [String]) {
        guard !isConnected else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: wsURL)
        webSocketTask?.resume()
        isConnected = true
        startReceiveLoop()
        startPingKeepalive()
    }

    private func startReceiveLoop() {
        Task { [weak self] in
            guard let self, self.isConnected else { return }
            do {
                let message = try await self.webSocketTask?.receive()
                self.handleMessage(message)
                self.startReceiveLoop()
            } catch {
                if self.isConnected {
                    print("[WebSocket] Receive error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message?) {
        guard let message else { return }
        switch message {
        case .string(let text):
            guard let data   = text.data(using: .utf8),
                  let update = try? JSONDecoder().decode(ParcelUpdateMessage.self, from: data)
            else { return }
            updateSubject.send(update)
        case .data(let data):
            guard let update = try? JSONDecoder().decode(ParcelUpdateMessage.self, from: data)
            else { return }
            updateSubject.send(update)
        @unknown default:
            break
        }
    }
    
    private func startPingKeepalive() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error { print("[WebSocket] Ping failed: \(error.localizedDescription)") }
            }
        }
    }

    func disconnect() {
        isConnected = false
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    deinit {
        pingTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

final class MockParcelWebSocketService: ParcelWebSocketServiceProtocol {

    private let updateSubject = PassthroughSubject<ParcelUpdateMessage, Never>()
    var updatePublisher: AnyPublisher<ParcelUpdateMessage, Never> {
        updateSubject.eraseToAnyPublisher()
    }
    private var simulationTimer: Timer?
    private var isConnected = false

    func connect(trackingNumbers: [String]) {
        guard !isConnected else { return }
        isConnected = true

        var step = 0
        let statuses: [ParcelStatus] = [.processing, .dispatched, .inTransit, .outForDelivery, .delivered]
        let coordinates: [(Double, Double)] = [
            (14.5547, 121.0504),
            (14.5510, 121.0455),
            (14.5473, 121.0410),
            (14.5451, 121.0385),
        ]

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
            guard let self, step < statuses.count * trackingNumbers.count else {
                self?.simulationTimer?.invalidate()
                return
            }
            let parcelIndex = step % trackingNumbers.count
            let statusIndex = step / trackingNumbers.count
            guard statusIndex < statuses.count else {
                self.simulationTimer?.invalidate()
                return
            }
            let coordIndex = min(statusIndex, coordinates.count - 1)
            self.updateSubject.send(ParcelUpdateMessage(
                trackingNumber: trackingNumbers[parcelIndex],
                status:         statuses[statusIndex],
                latitude:       coordinates[coordIndex].0,
                longitude:      coordinates[coordIndex].1,
                note:           nil,
                timestamp:      Date()
            ))
            step += 1
        }
    }

    func disconnect() {
        isConnected = false
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    deinit { simulationTimer?.invalidate() }
}
