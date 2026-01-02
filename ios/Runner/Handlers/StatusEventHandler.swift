//
//  StatusEventHandler.swift
//  Runner
//
//  Created by GFWFighter on 10/24/23.
//

import Foundation
import Combine

/// Broadcasts VPN connection status updates (without Flutter)
public class StatusEventHandler {
    
    public static let shared = StatusEventHandler()
    
    /// Notification name for VPN status updates
    public static let vpnStatusDidChange = Notification.Name("vpnStatusDidChange")
    
    private var cancellable: AnyCancellable?
    
    private init() {
        observeVPNStatus()
    }
    
    private func observeVPNStatus() {
        cancellable = VPNManager.shared.$state.sink { status in
            let message: String
            
            switch status {
            case .reasserting, .connecting:
                message = "Starting"
            case .connected:
                message = "Started"
            case .disconnecting:
                message = "Stopping"
            case .disconnected, .invalid:
                message = "Stopped"
            @unknown default:
                message = "Stopped"
            }
            
            // Post notification to anyone listening
            NotificationCenter.default.post(
                name: Self.vpnStatusDidChange,
                object: nil,
                userInfo: ["status": message]
            )
            
            print("📡 VPN Status changed → \(message)")
        }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
