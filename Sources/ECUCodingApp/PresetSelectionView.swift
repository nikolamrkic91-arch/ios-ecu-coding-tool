import SwiftUI
import ECUCodingCore

struct PresetSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: PresetCategoryFilter = .all
    @State private var showingPresetDetail: CodingPreset?
    
    private let allPresets = PresetService.getAvailablePresets()
    
    private var filteredPresets: [CodingPreset] {
        if selectedCategory == .all {
            return allPresets
        }
        return allPresets.filter { $0.category.rawValue == selectedCategory.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryPicker
                
                List(filteredPresets) { preset in
                    PresetRow(preset: preset) {
                        showingPresetDetail = preset
                    }
                }
            }
            .navigationTitle("Coding Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $showingPresetDetail) { preset in
                PresetDetailView(preset: preset)
            }
        }
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == .all
                ) {
                    selectedCategory = .all
                }
                
                ForEach(PresetCategoryFilter.allDefinedCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
    }
}

enum PresetCategoryFilter: String, CaseIterable {
    case all = "All"
    case comfort = "Comfort"
    case lighting = "Lighting"
    case performance = "Performance"
    case multimedia = "Multimedia"
    case safety = "Safety"
    
    static var allDefinedCases: [PresetCategoryFilter] {
        [.comfort, .lighting, .performance, .multimedia, .safety]
    }
}

struct PresetRow: View {
    let preset: CodingPreset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(preset.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    RiskBadge(risk: preset.riskLevel)
                }
                
                Text(preset.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Image(systemName: categoryIcon(for: preset.category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(preset.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private func categoryIcon(for category: PresetCategory) -> String {
        switch category {
        case .comfort: return "leaf.fill"
        case .lighting: return "lightbulb.fill"
        case .performance: return "gauge.high"
        case .multimedia: return "play.rectangle.fill"
        case .safety: return "shield.fill"
        case .other: return "square.grid.2x2"
        }
    }
}

struct PresetDetailView: View {
    @Environment(\.dismiss) var dismiss
    let preset: CodingPreset
    @State private var showingApplyConfirmation: Bool = false
    @State private var isApplying: Bool = false
    
    private let simulatedOperationDelay: UInt64 = 2_000_000_000  // 2 seconds
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    changesSection
                    warningSection
                    
                    applyButton
                }
                .padding()
            }
            .navigationTitle(preset.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Apply Preset?", isPresented: $showingApplyConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Apply", role: .destructive) {
                    applyPreset()
                }
            } message: {
                Text("This will create a backup and apply the preset changes. This operation cannot be undone except by restoring the backup.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(preset.description)
                .font(.body)
            
            HStack {
                Text("Category:")
                    .font(.subheadline).bold()
                Text(preset.category.rawValue)
                    .font(.subheadline)
            }
            
            HStack {
                Text("Risk Level:")
                    .font(.subheadline).bold()
                RiskBadge(risk: preset.riskLevel)
            }
            
            if !preset.supportedChassis.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Supported Chassis:")
                        .font(.subheadline).bold()
                    Text(preset.supportedChassis.map { $0.rawValue }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Text("Reversible:")
                    .font(.subheadline).bold()
                Image(systemName: preset.reversible ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(preset.reversible ? .green : .red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var changesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Changes")
                .font(.headline)
            
            if let voChanges = preset.voChanges, !voChanges.add.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Adding VO Options:")
                        .font(.subheadline).bold()
                    ForEach(voChanges.add) { option in
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            Text(option.code)
                                .monospaced()
                            if let desc = option.description {
                                Text("- \(desc)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            
            if let fdlChanges = preset.fdlChanges, !fdlChanges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FDL Parameter Changes:")
                        .font(.subheadline).bold()
                    ForEach(fdlChanges, id: \.parameter.path) { change in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(change.parameter.name)
                                .font(.caption).bold()
                            HStack {
                                if let old = change.oldValue {
                                    Text("\(old) →")
                                        .foregroundStyle(.secondary)
                                }
                                Text(change.newValue)
                                    .foregroundStyle(.blue)
                            }
                            .font(.caption)
                            .monospaced()
                        }
                    }
                }
            }
            
            if !preset.affectedModules.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Affected Modules:")
                        .font(.subheadline).bold()
                    Text(preset.affectedModules.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Important")
                    .font(.headline)
            }
            
            Text("• A backup will be created automatically before applying changes")
            Text("• Ensure charger is connected and ignition is on")
            Text("• Do not disconnect during the coding process")
            Text("• Test all affected functions after completion")
        }
        .font(.caption)
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var applyButton: some View {
        Button {
            showingApplyConfirmation = true
        } label: {
            HStack {
                if isApplying {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                Text(isApplying ? "Applying..." : "Apply Preset")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isApplying)
        .controlSize(.large)
    }
    
    private func applyPreset() {
        isApplying = true
        
        Task {
            // In production, would call PresetService.applyPreset()
            try? await Task.sleep(nanoseconds: simulatedOperationDelay)
            
            await MainActor.run {
                isApplying = false
                dismiss()
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct RiskBadge: View {
    let risk: ModuleRiskLevel
    
    private var color: Color {
        switch risk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var body: some View {
        Text(risk.rawValue.capitalized)
            .font(.caption).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(6)
    }
}

#Preview {
    PresetSelectionView()
}
