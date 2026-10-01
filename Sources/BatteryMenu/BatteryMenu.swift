import AppKit
import SwiftUI
import BatteryCore

@MainActor
final class BatteryModel: ObservableObject {
    @Published var battery: BatterySnapshot?
    @Published var charge: ChargeState?
    @Published var message: String?
    @Published var busy = false
    private let worker = DispatchQueue(label: "software.bathold.worker")
    private var timer: Timer?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification,
            object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
    }

    func refresh() { perform(nil) }
    func apply(_ value: Int) { perform { try $0.setLimit(value); return "Limite de \(value)% confirmado pelo macOS." } }
    func disable() { perform { try $0.disable(); return "Limite desativado." } }
    func chargeFull() { perform { try $0.chargeToFull(); return "Carga completa solicitada. O macOS gerencia a retomada do limite." } }

    private func perform(_ action: ((ChargeController) throws -> String)? ) {
        guard !busy else { return }
        busy = true
        worker.async { [weak self] in
            let controller = ChargeController()
            var notice: String?
            var actionFailed = false
            do { notice = try action?(controller) }
            catch { notice = error.localizedDescription; actionFailed = true }
            let batteryResult = Result { try BatterySnapshot.read() }
            let chargeResult = Result { try controller.state() }
            if case .failure(let error) = chargeResult, notice == nil { notice = error.localizedDescription }
            if case .failure(let error) = batteryResult, notice == nil { notice = error.localizedDescription }
            let newNotice = notice
            let failed = actionFailed
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.battery = try? batteryResult.get()
                self.charge = failed ? nil : try? chargeResult.get()
                if newNotice != nil { self.message = newNotice }
                self.busy = false
            }
        }
    }
}

struct BatteryPanel: View {
    @ObservedObject var model: BatteryModel
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: model.battery?.charging == true ? "battery.100percent.bolt" : "battery.75percent")
                    .font(.largeTitle).foregroundStyle(.green)
                VStack(alignment: .leading) {
                    Text("BatHold").font(.headline)
                    Text(model.battery.map { "\($0.percent)% · \($0.pluggedIn ? "Na tomada" : "Na bateria")" } ?? "Lendo bateria…")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.busy { ProgressView().controlSize(.small) }
            }
            if let battery = model.battery {
                ProgressView(value: Double(battery.percent), total: 100).tint(.green)
                HStack {
                    metric("Saúde estimada", battery.healthPercent.map { String(format: "%.0f%%", $0) } ?? "—")
                    Spacer()
                    metric("Ciclos", battery.cycles.map(String.init) ?? "—")
                    Spacer()
                    metric("Temperatura", battery.temperatureCelsius.map { String(format: "%.1f °C", $0) } ?? "—")
                }
                if let watts = battery.powerWatts {
                    Text(String(format: "%@ %.1f W", watts < 0 ? "Descarga:" : "Carga:", abs(watts)))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Divider()
            if let charge = model.charge {
                Text(charge.enabled ? "Limite ativo: \(charge.limit)%" : "Limite desativado").font(.headline)
                HStack(spacing: 6) {
                    ForEach(charge.availableLimits, id: \.self) { limit in
                        Button("\(limit)%") { model.apply(limit) }
                            .buttonStyle(.bordered)
                            .tint(charge.limit == limit && charge.enabled ? .green : .accentColor)
                    }
                }.disabled(model.busy)
                HStack {
                    Button("Carregar até 100% agora") { model.chargeFull() }
                    Button("Desativar limite") { model.disable() }
                }.disabled(model.busy)
                Text("O macOS pode carregar até 100% ocasionalmente para ajustar a estimativa da bateria.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Controle de carga indisponível").font(.headline)
                Text("Você pode continuar acompanhando a bateria e configurar o limite nos Ajustes do macOS.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let message = model.message {
                Text(message).font(.caption).fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            Text("Prova de conceito · controle nativo experimental")
                .font(.caption2).foregroundStyle(.secondary)
            HStack {
                Button("Ajustes de Bateria") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension")!)
                }
                Button("Atualizar") { model.refresh() }.disabled(model.busy)
                Spacer()
                Button("Sair") { NSApplication.shared.terminate(nil) }
            }.font(.caption)
        }.padding(20).frame(width: 410)
    }
    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
    }
}

@main
struct BatHoldApp: App {
    @StateObject private var model = BatteryModel()
    var body: some Scene {
        MenuBarExtra {
            BatteryPanel(model: model)
        } label: {
            Label(model.battery.map { "\($0.percent)%" } ?? "BatHold", systemImage: "battery.75percent")
        }.menuBarExtraStyle(.window)
    }
}
