import Foundation
import IOKit

enum SMCError: Error {
    case driverNotFound, failedToOpen, notPrivileged
    case keyNotFound(code: String)
    case unknown(kIOReturn: kern_return_t, SMCResult: UInt8)
}

public struct KeyProbe: Codable {
    public let key: String
    public let readable: Bool
    public let bytes: [UInt8]?
    public let detail: String
}

public struct DiagnosticReport: Codable {
    public let generatedAt: Date
    public let macOS: String
    public let model: String
    public let firmware: String
    public let administrator: Bool
    public let battery: BatterySnapshot?
    public let batteryError: String?
    public let nativeCharge: ChargeState?
    public let nativeError: String?
    public let smc: [KeyProbe]
    public let notes: [String]

    public static func collect() -> Self {
        let batteryResult = Result { try BatterySnapshot.read() }
        let nativeResult = Result { try ChargeController().state() }
        let probes: [KeyProbe]
        do {
            try SMCKit.open()
            defer { SMCKit.close() }
            probes = ["CH0B", "CH0C", "CHTE", "bfF0", "bfD0", "bfE0", "CH0I"].map { code in
                do {
                    let info = try SMCKit.keyInformation(FourCharCode(fromString: code))
                    guard (1...32).contains(info.size) else { throw BatteryError.control("Tamanho inesperado da chave.") }
                    var data = try SMCKit.readData(SMCKey(code: FourCharCode(fromString: code), info: info))
                    let bytes = withUnsafeBytes(of: &data) { Array($0.prefix(Int(info.size))) }
                    return KeyProbe(key: code, readable: true, bytes: bytes, detail: "Leitura aceita; escrita não testada.")
                } catch {
                    return KeyProbe(key: code, readable: false, bytes: nil, detail: String(describing: error))
                }
            }
        } catch { probes = [KeyProbe(key: "AppleSMC", readable: false, bytes: nil, detail: String(describing: error))] }
        return Self(generatedAt: Date(), macOS: ProcessInfo.processInfo.operatingSystemVersionString,
                    model: registryText("IODeviceTree:/", key: "model"),
                    firmware: registryText("IODeviceTree:/chosen", key: "system-firmware-version"),
                    administrator: geteuid() == 0, battery: try? batteryResult.get(),
                    batteryError: batteryResult.failureDescription,
                    nativeCharge: try? nativeResult.get(), nativeError: nativeResult.failureDescription,
                    smc: probes, notes: [
                        "Diagnóstico somente de leitura: não altera carga nem alimentação.",
                        "Chave legível não comprova permissão de escrita.",
                        "Falha de privilégio sem root não comprova bloqueio também para root.",
                        "O backend PowerUI é privado, experimental e pode mudar entre versões do macOS.",
                        "Não são coletados número de série, UUID, localização ou identificadores pessoais."
                    ])
    }
}

private func registryText(_ path: String, key: String) -> String {
    let entry = IORegistryEntryFromPath(kIOMainPortDefault, path)
    guard entry != 0 else { return "indisponível" }
    defer { IOObjectRelease(entry) }
    guard let value = IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else { return "indisponível" }
    if let string = value as? String { return string }
    if let data = value as? Data { return String(decoding: data.prefix { $0 != 0 }, as: UTF8.self) }
    return "indisponível"
}

private extension Result {
    var failureDescription: String? {
        if case .failure(let error) = self { return error.localizedDescription }
        return nil
    }
}
