import Foundation
import BatteryCore

func printJSON<T: Encodable>(_ value: T) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    print(String(decoding: try encoder.encode(value), as: UTF8.self))
}

func run() throws {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let controller = ChargeController()
    switch arguments.first ?? "help" {
    case "status": try printJSON(BatterySnapshot.read())
    case "diagnose": try printJSON(DiagnosticReport.collect())
    case "charge-status": try printJSON(controller.state())
    case "limit":
        guard arguments.count == 2, let limit = Int(arguments[1]) else {
            throw BatteryError.control("Uso: bathold limit <percentual>")
        }
        try printJSON(controller.setLimit(limit))
    case "disable": try controller.disable(); try printJSON(controller.state())
    case "charge-full":
        try controller.chargeToFull()
        print("Solicitação de carga completa enviada ao macOS. O sistema gerencia a retomada do limite.")
    case "verify-control":
        guard arguments.count == 2 else { throw BatteryError.control("Uso: bathold verify-control <arquivo de recuperação.json>") }
        let recovery = URL(fileURLWithPath: arguments[1])
        guard !FileManager.default.fileExists(atPath: recovery.path) else {
            throw BatteryError.control("Arquivo de recuperação já existe. Escolha outro caminho.")
        }
        let original = try controller.state()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(original).write(to: recovery, options: .atomic)
        guard let candidate = original.availableLimits.first(where: { $0 != original.limit && $0 < 100 }) else {
            throw BatteryError.control("Não há outro limite para verificar; configuração preservada.")
        }
        do {
            let changed = try controller.setLimit(candidate)
            try controller.restore(original)
            struct Verification: Encodable {
                let original: ChargeState
                let applied: ChargeState
                let restored: ChargeState
                let note: String
            }
            try printJSON(Verification(original: original, applied: changed, restored: controller.state(),
                note: "Escrita e restauração verificadas. Isto não comprova comportamento durante carga ou repouso."))
        } catch {
            let failure = error
            do { try controller.restore(original) }
            catch {
                throw BatteryError.control("Teste falhou e restauração também: \(error.localizedDescription). Recuperação: bathold restore \(recovery.path)")
            }
            throw failure
        }
    case "restore":
        guard arguments.count == 2 else { throw BatteryError.control("Uso: bathold restore <arquivo.json>") }
        let state = try JSONDecoder().decode(ChargeState.self, from: Data(contentsOf: URL(fileURLWithPath: arguments[1])))
        try controller.restore(state)
        try printJSON(controller.state())
    case "help", "--help", "-h":
        print("""
        BatHold — prova de conceito open source para macOS

        Leitura:
          status          Bateria, saúde estimada, ciclos, temperatura e potência
          diagnose        Diagnóstico de compatibilidade (JSON, sem identificadores)
          charge-status   Estado e limites oferecidos pelo macOS

        Controle nativo experimental (altera a configuração do macOS):
          limit 80        Aplica um limite aceito pelo sistema
          disable         Desativa o limite
          charge-full     Solicita carga completa temporária
          verify-control arquivo.json   Testa outro limite e restaura o anterior
          restore arquivo.json          Recupera a configuração salva pelo teste

        O backend usa PowerUI privado. Sem suporte, use os Ajustes de Bateria.
        """)
    default: throw BatteryError.control("Comando desconhecido. Use --help.")
    }
}

do { try run() }
catch {
    FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
    exit(1)
}
