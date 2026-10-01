import Foundation
import NativeCharge

public struct ChargeState: Codable, Equatable {
    public let availableLimits: [Int]
    public let limit: Int
    public let enabled: Bool
}

/// The app and CLI serialize calls on their own worker queue.
public final class ChargeController {
    private let native = BPNativeCharge()
    public init() {}
    public func state() throws -> ChargeState {
        let data = try native.snapshot()
        guard
              let limits = data["limits"] as? [Int], let limit = data["limit"] as? Int,
              let enabled = data["enabled"] as? Bool else {
            throw BatteryError.control("O serviço retornou um estado de carga inválido.")
        }
        return ChargeState(availableLimits: limits.sorted(), limit: limit, enabled: enabled)
    }
    @discardableResult public func setLimit(_ limit: Int) throws -> ChargeState {
        try native.setLimit(limit)
        let verified = try state()
        guard verified.limit == limit else { throw BatteryError.control("O macOS não confirmou o limite solicitado.") }
        // The native 100% choice can disable limiting; smaller limits must be enabled.
        guard limit == 100 || verified.enabled else { throw BatteryError.control("O limite foi salvo, mas não está ativo.") }
        return verified
    }
    public func disable() throws {
        try native.disable()
        guard try !state().enabled else { throw BatteryError.control("O macOS ainda informa um limite ativo.") }
    }
    public func chargeToFull() throws {
        try native.chargeToFull()
    }
    public func restore(_ previous: ChargeState) throws {
        // Restore both the remembered percentage and whether limiting was enabled.
        try setLimit(previous.limit)
        if !previous.enabled { try disable() }
        let current = try state()
        guard current.limit == previous.limit && current.enabled == previous.enabled else {
            throw BatteryError.control("A restauração não foi confirmada. Confira os Ajustes de Bateria.")
        }
    }
}
