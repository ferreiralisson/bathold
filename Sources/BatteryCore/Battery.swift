import Foundation
import IOKit

public struct BatterySnapshot: Codable {
    public let percent: Int
    public let pluggedIn: Bool
    public let charging: Bool
    public let cycles: Int?
    public let healthPercent: Double?
    public let temperatureCelsius: Double?
    public let powerWatts: Double?
    public let timestamp: Date

    public static func parse(_ properties: [String: Any]) throws -> Self {
        func number(_ key: String) -> NSNumber? { properties[key] as? NSNumber }
        guard let current = number("CurrentCapacity"), let maximum = number("MaxCapacity"),
              maximum.doubleValue > 0 else { throw BatteryError.unavailable }
        let detail = properties["BatteryData"] as? [String: Any] ?? [:]
        let full = (detail["NominalChargeCapacity"] as? NSNumber)?.doubleValue
        let design = (detail["DesignCapacity"] as? NSNumber)?.doubleValue
        let health = full.flatMap { full in design.flatMap { $0 > 0 ? min(100, full / $0 * 100) : nil } }
        let rawTemperature = number("Temperature")?.doubleValue
            ?? (detail["Temperature"] as? NSNumber)?.doubleValue
        // AppleSmartBattery reports temperature in hundredths of a Kelvin.
        let temperature = rawTemperature.map { $0 / 100 - 273.15 }.flatMap { (-20...100).contains($0) ? $0 : nil }
        // Negative amperage may arrive as an unsigned 64-bit two's-complement value.
        let amps = number("Amperage").map { Double(Int64(bitPattern: $0.uint64Value)) }
        let volts = number("Voltage")?.doubleValue
        let watts = amps.flatMap { a in volts.map { a * $0 / 1_000_000 } }
        return Self(percent: min(100, max(0, Int((current.doubleValue / maximum.doubleValue * 100).rounded()))),
                    pluggedIn: number("ExternalConnected")?.boolValue ?? false,
                    charging: number("IsCharging")?.boolValue ?? false,
                    cycles: number("CycleCount")?.intValue, healthPercent: health,
                    temperatureCelsius: temperature, powerWatts: watts, timestamp: Date())
    }

    public static func read() throws -> Self {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { throw BatteryError.unavailable }
        defer { IOObjectRelease(service) }
        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let data = properties?.takeRetainedValue() as? [String: Any] else { throw BatteryError.unavailable }
        return try parse(data)
    }
}

public enum BatteryError: LocalizedError {
    case unavailable
    case control(String)
    public var errorDescription: String? {
        switch self {
        case .unavailable: return "Não foi possível ler a bateria deste Mac."
        case .control(let message): return message
        }
    }
}
