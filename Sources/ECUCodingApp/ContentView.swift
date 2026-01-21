import SwiftUI
import ECUCodingCore

struct ContentView: View {
    @State private var status: String = "Disconnected"
    @State private var lastResponse: String = "—"
    @State private var dtcs: [DTC] = []
    @State private var voOptions: [VOEntry] = []
    @State private var isWorking: Bool = false
    @State private var showingDTCs: Bool = false
    @State private var showingVO: Bool = false

    // Swap SimulatedTransport with ENETTransport(host: "192.168.2.1") when testing with hardware.
    private let transport = SimulatedTransport()
    private lazy var uds = UDSService(transport: transport)
    private lazy var diagnostic = DiagnosticService(udsService: uds)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statusSection
                    actionsSection
                    resultsSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("ECU Coding")
            .sheet(isPresented: $showingDTCs) {
                DTCListView(dtcs: dtcs)
            }
            .sheet(isPresented: $showingVO) {
                VOListView(options: voOptions)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("ECU Coding Tool")
                .font(.largeTitle).bold()

            Text("Dealer-level BMW coding with guardrails")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var statusSection: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            Text(status)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await connectAndTest() }
            } label: {
                Label("Connect & Test", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWorking)
            
            HStack(spacing: 12) {
                Button {
                    Task { await readDTCs() }
                } label: {
                    Label("Read DTCs", systemImage: "wrench.adjustable")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isWorking || status != "Connected")
                
                Button {
                    Task { await readVO() }
                } label: {
                    Label("Read VO", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isWorking || status != "Connected")
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !dtcs.isEmpty {
                ResultCard(
                    title: "DTCs Found",
                    count: dtcs.count,
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                ) {
                    showingDTCs = true
                }
            }
            
            if !voOptions.isEmpty {
                ResultCard(
                    title: "VO Options",
                    count: voOptions.count,
                    icon: "list.bullet.rectangle",
                    color: .blue
                ) {
                    showingVO = true
                }
            }
            
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
            
            PhaseStatusView()
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
    private func connectAndTest() async {
        isWorking = true
        defer { isWorking = false }

        status = "Connecting"
        do {
            try await transport.connect()
            status = "Connected"
            lastResponse = "✅ Connected to simulated ECU"
            
            // Start a session
            let logger = SessionLogger.shared
            _ = logger.startSession(vehicle: nil, transport: "SimulatedTransport")
            logger.logOperation(SessionOperation(
                type: .connect,
                description: "Connected to ECU",
                success: true
            ))
        } catch {
            status = "Failed"
            lastResponse = "❌ Error: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func readDTCs() async {
        isWorking = true
        defer { isWorking = false }
        
        do {
            let foundDTCs = try await diagnostic.readDTCs()
            dtcs = foundDTCs
            lastResponse = "✅ Found \(foundDTCs.count) DTC(s)"
            
            SessionLogger.shared.logOperation(SessionOperation(
                type: .readDTC,
                description: "Read \(foundDTCs.count) DTCs",
                success: true
            ))
            
            if !foundDTCs.isEmpty {
                showingDTCs = true
            }
        } catch {
            lastResponse = "❌ Error reading DTCs: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func readVO() async {
        isWorking = true
        defer { isWorking = false }
        
        // Simulate reading VO
        let mockVOString = "5AR,6AC,423,2TB,609"
        voOptions = VOParser.parse(voString: mockVOString)
        lastResponse = "✅ Read \(voOptions.count) VO option(s)"
        
        SessionLogger.shared.logOperation(SessionOperation(
            type: .readVO,
            description: "Read VO options",
            success: true
        ))
        
        if !voOptions.isEmpty {
            showingVO = true
        }
    }
}

struct ResultCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text("\(count) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct PhaseStatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Implementation Status")
                .font(.headline)
            
            PhaseRow(phase: "Phase 1", status: .inProgress, items: [
                "DTC read/clear ✅",
                "VO/FA decode ✅",
                "Module scanning ✅",
                "Session logging ✅"
            ])
            
            PhaseRow(phase: "Phase 2", status: .planned, items: [
                "VO coding (controlled write)",
                "FDL edits with validation",
                "Mandatory backups"
            ])
            
            PhaseRow(phase: "Phase 3", status: .planned, items: [
                "Remote utility",
                "Batch operations"
            ])
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct PhaseRow: View {
    let phase: String
    let status: PhaseStatus
    let items: [String]
    
    enum PhaseStatus {
        case complete, inProgress, planned
        
        var color: Color {
            switch self {
            case .complete: return .green
            case .inProgress: return .orange
            case .planned: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .complete: return "checkmark.circle.fill"
            case .inProgress: return "clock.fill"
            case .planned: return "circle"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: status.icon)
                    .foregroundStyle(status.color)
                Text(phase)
                    .font(.subheadline).bold()
            }
            
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DTCListView: View {
    @Environment(\.dismiss) var dismiss
    let dtcs: [DTC]
    
    var body: some View {
        NavigationStack {
            List(dtcs) { dtc in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dtc.code)
                            .font(.headline)
                            .foregroundStyle(dtc.status.isActive ? .red : .secondary)
                        
                        Spacer()
                        
                        Text(dtc.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
                    Text(dtc.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        if dtc.status.isActive {
                            StatusBadge(text: "Active", color: .red)
                        }
                        if dtc.status.isConfirmed {
                            StatusBadge(text: "Confirmed", color: .orange)
                        }
                        if dtc.status.isPending {
                            StatusBadge(text: "Pending", color: .yellow)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Diagnostic Trouble Codes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VOListView: View {
    @Environment(\.dismiss) var dismiss
    let options: [VOEntry]
    
    var body: some View {
        NavigationStack {
            List(options) { option in
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.code)
                        .font(.headline)
                    
                    if let description = option.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Vehicle Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(4)
    }
}

#Preview {
    ContentView()
}
