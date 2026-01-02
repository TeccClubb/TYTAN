//
//  ExtensionProvider.swift
//  SingBoxPacketTunnel
//
//  Created by GFWFighter on 7/25/1402 AP.
//

import Foundation
import Libbox
import NetworkExtension

open class ExtensionProvider: NEPacketTunnelProvider {
    public static let errorFile = FilePath.workingDirectory.appendingPathComponent("network_extension_error")

    private var commandServer: LibboxCommandServer!
    private var boxService: LibboxBoxService!
    private var systemProxyAvailable = false
    private var systemProxyEnabled = false
    private var platformInterface: ExtensionPlatformInterface!
    private var config: String!
    
    // MARK: - Fixed: Use completion handler instead of async throws
    override open func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        LibboxClearServiceError()
        try? FileManager.default.removeItem(at: ExtensionProvider.errorFile)
        try? FileManager.default.removeItem(at: FilePath.workingDirectory.appendingPathComponent("TestLog"))
        
        let disableMemoryLimit = (options?["DisableMemoryLimit"] as? NSString as? String ?? "NO") == "YES"
        
        guard let configString = options?["Config"] as? NSString as? String else {
            writeFatalError("(packet-tunnel) error: config not provided")
            completionHandler(NSError(domain: "ExtensionProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Config not provided"]))
            return
        }
        guard let validConfig = SingBox.setupConfig(config: configString) else {
            writeFatalError("(packet-tunnel) error: config is invalid")
            completionHandler(NSError(domain: "ExtensionProvider", code: -2, userInfo: [NSLocalizedDescriptionKey: "Config is invalid"]))
            return
        }
        self.config = validConfig

        do {
            try FileManager.default.createDirectory(at: FilePath.workingDirectory, withIntermediateDirectories: true)
        } catch {
            writeFatalError("(packet-tunnel) error: create working directory: \(error.localizedDescription)")
            completionHandler(error)
            return
        }
        
        var error: NSError?
        let options = LibboxSetupOptions()
        options.basePath = FilePath.sharedDirectory.relativePath
        options.workingPath = FilePath.workingDirectory.relativePath
        options.tempPath = FilePath.cacheDirectory.relativePath

        LibboxSetup(options, &error)
        LibboxRedirectStderr(FilePath.cacheDirectory.appendingPathComponent("stderr.log").relativePath, &error)
        if let error {
            writeError("(packet-tunnel) redirect stderr error: \(error.localizedDescription)")
        }

        LibboxSetMemoryLimit(!disableMemoryLimit)

        if platformInterface == nil {
            platformInterface = ExtensionPlatformInterface(self)
        }
        
        commandServer = LibboxNewCommandServer(platformInterface, Int32(30))
        do {
            try commandServer.start()
        } catch {
            writeFatalError("(packet-tunnel): log server start error: \(error.localizedDescription)")
            completionHandler(error)
            return
        }
        
        writeMessage("(packet-tunnel) log server started")
        
        // MARK: - Fixed: Wrap async work in Task
        Task {
            await startService()
            completionHandler(nil)
        }
    }

    func writeMessage(_ message: String) {
        if let commandServer {
            commandServer.writeMessage(message)
        } else {
            NSLog(message)
        }
    }

    func writeError(_ message: String) {
        writeMessage(message)
        try? message.write(to: ExtensionProvider.errorFile, atomically: true, encoding: .utf8)
    }

    public func writeFatalError(_ message: String) {
        #if DEBUG
            NSLog(message)
        #endif
        writeError(message)
        cancelTunnelWithError(NSError(domain: message, code: 0))
    }

    private func startService() async {
        let configContent = config
        var error: NSError?
        let service = LibboxNewService(configContent, platformInterface, &error)
        if let error {
            writeError("(packet-tunnel) error: create service: \(error.localizedDescription)")
            return
        }
        guard let service else {
            return
        }
        do {
            try service.start()
        } catch {
            writeError("(packet-tunnel) error: start service: \(error.localizedDescription)")
            return
        }
        boxService = service
        commandServer.setService(service)
    }

    private func stopService() {
        if let service = boxService {
            do {
                try service.close()
            } catch {
                writeError("(packet-tunnel) error: stop service: \(error.localizedDescription)")
            }
            boxService = nil
            commandServer.setService(nil)
        }
        if let platformInterface {
            platformInterface.reset()
        }
    }

    func reloadService() async {
        writeMessage("(packet-tunnel) reloading service")
        reasserting = true
        defer {
            reasserting = false
        }
        stopService()
        await startService()
    }
    
    func postServiceClose() {
        boxService = nil
    }
    
    // MARK: - Fixed: Use completion handler instead of async
    override open func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        writeMessage("(packet-tunnel) stopping, reason: \(reason)")
        
        // MARK: - Fixed: Wrap async work in Task
        Task {
            stopService()
            if let server = commandServer {
                try? await Task.sleep(nanoseconds: 100 * NSEC_PER_MSEC)
                try? server.close()
                commandServer = nil
            }
            completionHandler()
        }
    }

    override open func handleAppMessage(_ messageData: Data) async -> Data? {
        messageData
    }

    override open func sleep() async {
        if let boxService {
            boxService.pause()
        }
    }

    override open func wake() {
        if let boxService {
            boxService.wake()
        }
    }
}
