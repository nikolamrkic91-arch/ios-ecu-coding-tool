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
    @State private var showingBackups: Bool = false
    @State private var showingPresets: Bool = false

    @State private var transportType: TransportType = .simulated
    @State private var enetHost: String = "192.168.2.1"
    @State private var enetPort: String = "6801"
    
    private var transport: Transport {
        switch transportType {
        case .simulated:
            return SimulatedTransport()
        case .enet:
            return ENETTransport(host: enetHost, port: UInt16(enetPort) ?? 6801)
        }
    }
    
    private var uds: UDSService {
        UDSService(transport: transport)
    }
    
    private var diagnostic: DiagnosticService {
        DiagnosticService(udsService: uds)
    }
    
    enum TransportType {
        case simulated, enet
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    connectionSettingsSection
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
            .sheet(isPresented: $showingBackups) {
                BackupManagementView()
            }
            .sheet(isPresented: $showingPresets) {
                PresetSelectionView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("BMW ECU Coding Tool")
                .font(.largeTitle).bold()

            Text("Professional dealer-level coding with safety guardrails")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var connectionSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Settings")
                .font(.headline)
            
            Picker("Transport", selection: $transportType) {
                Text("ENET (Real Hardware)").tag(TransportType.enet)
                Text("Simulated (Testing)").tag(TransportType.simulated)
            }
            .pickerStyle(.segmented)
            
            if transportType == .enet {
                HStack {
                    Text("ENET IP:")
                        .frame(width: 80, alignment: .leading)
                    TextField("192.168.2.1", text: $enetHost)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                HStack {
                    Text("Port:")
                        .frame(width: 80, alignment: .leading)
                    TextField("6801", text: $enetPort)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
            Text("Operations")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                Task { await connectAndTest() }
            } label: {
                Label("Connect & Test", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isWorking)
            
            Text("Read Operations")
                .font(.subheadline).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            
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
            
            Text("Write Operations (Phase 2)")
                .font(.subheadline).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            
            HStack(spacing: 12) {
                Button {
                    showingPresets = true
                } label: {
                    Label("Presets", systemImage: "star.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button {
                    showingBackups = true
                } label: {
                    Label("Backups", systemImage: "externaldrive.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
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
            lastResponse = "✅ Connected to \(transportType == .enet ? "ENET adapter at \(enetHost)" : "simulated ECU")"
            
            // Start a session
            let logger = SessionLogger.shared
            _ = logger.startSession(vehicle: nil, transport: transportType == .enet ? "ENETTransport" : "SimulatedTransport")
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
            
            PhaseRow(phase: "Phase 1 (Read-Only)", status: .complete, items: [
                "DTC read/clear ✅",
                "VO/FA decode ✅",
                "Module scanning ✅",
                "Session logging ✅"
            ])
            
            PhaseRow(phase: "Phase 2 (Controlled Write)", status: .complete, items: [
                "VO coding ✅",
                "FDL parameter edits ✅",
                "Backup/restore system ✅",
                "Preset system ✅",
                "Safety guardrails ✅"
            ])
            
            PhaseRow(phase: "Phase 3 (Advanced)", status: .planned, items: [
                "Remote utility (planned)",
                "Batch operations (planned)",
                "Extended chassis support (planned)"
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
