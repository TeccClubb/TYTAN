//
//  VPNHandler.swift
//  Sing-Box-Test
//
//  Created by Saad Suleman on 20/10/2025.
//

import Foundation
import Combine
import Libbox

@MainActor
final class VPNHandler: ObservableObject {
    
    static let shared = VPNHandler()
    private var cancelBag: Set<AnyCancellable> = []
    
    private init() {}
    
    // MARK: - Setup
    func setup() async throws {
        try await VPNManager.shared.setup()
        print("[VPNHandler] Setup completed")
    }
    
    // MARK: - Start VPN
    func start(config: String) async throws {
        VPNConfig.shared.activeConfigPath = config
        print("[VPNHandler] Starting VPN with config: \(config)")
        
        var error: NSError?
        // let config = MobileBuildConfig(path, VPNConfig.shared.configOptions, &error)
        
        if let error {
            throw NSError(domain: "VPNHandler", code: error.code, userInfo: [
                NSLocalizedDescriptionKey: "Build config failed: \(error.description)"
            ])
        }
        
        try await VPNManager.shared.setup()
        try await VPNManager.shared.connect(with: config, disableMemoryLimit: VPNConfig.shared.disableMemoryLimit)
        print("[VPNHandler] VPN Connected")
    }
    
    // MARK: - Restart VPN
    func restart(path: String) async throws {
        VPNConfig.shared.activeConfigPath = path
        print("[VPNHandler] Restarting VPN…")
        
        VPNManager.shared.disconnect()
        await waitForStop()
        
        var error: NSError?
        // let config = MobileBuildConfig(path, VPNConfig.shared.configOptions, &error)
        
        if let error {
            throw NSError(domain: "VPNHandler", code: error.code, userInfo: [
                NSLocalizedDescriptionKey: "Build config failed: \(error.description)"
            ])
        }
        
        try await VPNManager.shared.setup()
        try await VPNManager.shared.connect(with: path, disableMemoryLimit: VPNConfig.shared.disableMemoryLimit)
        print("[VPNHandler] VPN Restarted")
    }
    
    // MARK: - Stop / Reset
    func stop() {
        VPNManager.shared.disconnect()
        print("[VPNHandler] VPN Disconnected")
    }
    
    func reset() {
        VPNManager.shared.reset()
        print("[VPNHandler] VPN Reset")
    }
    
    // MARK: - URL Test / Outbound
    func urlTest(group: String?) {
        FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
        do {
            try LibboxNewStandaloneCommandClient()?.urlTest(group)
            print("[VPNHandler] URL test for group: \(group ?? "nil")")
        } catch {
            print("[VPNHandler] URL Test error: \(error.localizedDescription)")
        }
    }
    
    func selectOutbound(group: String, outbound: String) {
        FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
        do {
            try LibboxNewStandaloneCommandClient()?.selectOutbound(group, outboundTag: outbound)
            print("[VPNHandler] Selected outbound: \(outbound) for group: \(group)")
        } catch {
            print("[VPNHandler] Select Outbound error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Wait for disconnect
    private func waitForStop() async {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = VPNManager.shared.$state
                .filter { $0 == .disconnected }
                .first()
                .delay(for: 0.5, scheduler: RunLoop.main)
                .sink { _ in
                    continuation.resume()
                    cancellable?.cancel()
                }
        }
    }
}

