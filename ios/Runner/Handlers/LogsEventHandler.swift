//
//  LogsEventHandler.swift
//  Sing-Box-Test
//
//  Created by Saad Suleman on 20/10/2025.
//

import Foundation
import Combine
import Libbox

@MainActor
final class LogsEventHandler: ObservableObject {
    static let shared = LogsEventHandler()
    
    @Published var logs: [String] = []
    
    private var commandClient: CommandClient?
    private var cancellable: AnyCancellable?
    
    private init() {}
    
    /// Starts listening for logs from Libcore CommandClient
    func startListening() {
        FileManager.default.changeCurrentDirectoryPath(FilePath.sharedDirectory.path)
        commandClient = CommandClient(.log)
        commandClient?.connect()
        
        cancellable = commandClient?.$logList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLogs in
                guard let self = self else { return }
                self.logs = newLogs
            }
        
        print("[LogsEventHandler] Started listening for logs")
    }
    
    /// Stops listening for logs
    func stopListening() {
        commandClient?.disconnect()
        cancellable?.cancel()
        commandClient = nil
        print("[LogsEventHandler] Stopped listening for logs")
    }
}
