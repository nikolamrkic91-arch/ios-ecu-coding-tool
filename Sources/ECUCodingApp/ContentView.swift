import SwiftUI
import ECUCodingCore

struct ContentView: View {
    @State private var status: String = "Disconnected"
    @State private var lastResponse: String = "—"
    @State private var isWorking: Bool = false

    // Swap SimulatedTransport with ENETTransport(host: "192.168.2.1") when testing with hardware.
    private let transport = SimulatedTransport()
    private lazy var uds = UDSService(transport: transport)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("ECU Coding Tool")
                    .font(.largeTitle).bold()

                Text("Dealer-level coding with guardrails")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                statusRow

                Button {
                    Task { await connectAndPing() }
                } label: {
                    Label("Connect & Ping", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isWorking)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Read DTCs (Phase 1)", systemImage: "wrench.adjustable")
                    Label("VO/FA decode, SVT/NCD diff", systemImage: "doc.text.magnifyingglass")
                    Label("Backups before writes (Phase 2)", systemImage: "externaldrive.badge.checkmark")
                    Label("Remote utility (Phase 3)", systemImage: "antenna.radiowaves.left.and.right")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last response:")
                        .font(.headline)
                    Text(lastResponse)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }

    private var statusRow: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            Text(status)
                .font(.subheadline)
        }
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case "connected": return .green
        case "connecting": return .orange
        default: return .red
        }
    }

    @MainActor
    private func connectAndPing() async {
        isWorking = true
        defer { isWorking = false }

        status = "Connecting"
        do {
            try await transport.connect()
            status = "Connected"

            let payload = Data([0x22, 0xF1, 0x90]) // Example UDS ReadDataByIdentifier (VIN) service.
            let response = try await uds.request(service: payload[0], payload: payload.dropFirst())
            lastResponse = "OK: \(String(decoding: response, as: UTF8.self))"
        } catch {
            status = "Failed"
            lastResponse = "Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}
