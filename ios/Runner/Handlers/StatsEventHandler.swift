//
//  StatsEventHandler.swift
//  Sing-Box-Test
//
//  Created by Saad Suleman on 20/10/2025.
//

import Foundation
import Combine
import Libbox

/// Broadcasts live VPN stats updates from Libcore CommandClient without Flutter
@MainActor
final class StatsEventHandler: ObservableObject {
    
    static let shared = StatsEventHandler()
    
    @Published var stats: [String: Any] = [:]
    
    private var commandClient: CommandClient?
    private var cancellable: AnyCancellable?
    
    private init() {}
    
    /// Notification name for status updates (for any listener)
    static let statsDidUpdate = Notification.Name("statsDidUpdate")
    
    /// Start listening for status updates
    func startListening() {
        FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
        
        commandClient = CommandClient(.status)
        commandClient?.connect()
        
        cancellable = commandClient?.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                self.handleStatus(status)
            }
        
        print("[StatsEventHandler] Started listening for stats")
    }
     
    /// Stop listening for status updates
    func stopListening() {
        commandClient?.disconnect()
        cancellable?.cancel()
        commandClient = nil
        print("[StatsEventHandler] Stopped listening for stats")
    }
    
    /// Handle incoming status updates and broadcast them
    private func handleStatus(_ message: LibboxStatusMessage?) {
        guard let message else { return }
        
        let data: [String: Any] = [
            "connectionsIn": message.connectionsIn,
            "connectionsOut": message.connectionsOut,
            "uplink": message.uplink,
            "downlink": message.downlink,
            "uplinkTotal": message.uplinkTotal,
            "downlinkTotal": message.downlinkTotal
        ]
        
        // Update published property (for SwiftUI bindings)
        stats = data
        
        // Post notification for other listeners (if needed)
        NotificationCenter.default.post(
            name: Self.statsDidUpdate,
            object: nil,
            userInfo: data
        )
        
        print("[StatsEventHandler] Stats updated → \(data)")
    }
}
