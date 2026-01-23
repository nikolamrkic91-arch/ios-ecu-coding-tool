import SwiftUI
import ECUCodingCore

struct BackupManagementView: View {
    @Environment(\.dismiss) var dismiss
    @State private var backups: [BackupMetadata] = []
    @State private var isLoading: Bool = false
    @State private var selectedBackup: BackupMetadata?
    @State private var showingRestoreConfirmation: Bool = false
    
    private let backupService = BackupService()
    
    var body: some View {
        NavigationStack {
            Group {
                if backups.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    backupList
                }
            }
            .navigationTitle("Backup Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        loadBackups()
                    }
                }
            }
            .task {
                loadBackups()
            }
            .alert("Restore Backup?", isPresented: $showingRestoreConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Restore", role: .destructive) {
                    restoreSelectedBackup()
                }
            } message: {
                if let backup = selectedBackup {
                    Text("Restore backup from \(backup.createdAt.formatted()) for module \(backup.module.name)?")
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Backups",
            systemImage: "externaldrive.badge.xmark",
            description: Text("Backups will appear here after coding operations")
        )
    }
    
    private var backupList: some View {
        List {
            ForEach(backups, id: \.checksum) { backup in
                BackupRow(backup: backup) {
                    selectedBackup = backup
                    showingRestoreConfirmation = true
                }
            }
        }
    }
    
    private func loadBackups() {
        isLoading = true
        defer { isLoading = false }
        
        // In production, load from BackupService storage
        // For now, show empty or test data
        backups = []
    }
    
    private func restoreSelectedBackup() {
        guard let backup = selectedBackup else { return }
        
        Task {
            do {
                // In production: try await backupService.restore(backup)
                print("Would restore backup: \(backup.module.name)")
            } catch {
                print("Error restoring backup: \(error)")
            }
        }
    }
}

struct BackupRow: View {
    let backup: BackupMetadata
    let onRestore: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.module.name)
                        .font(.headline)
                    
                    Text("VIN: \(backup.vin)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(backup.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Restore") {
                    onRestore()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if let cafdVersion = backup.cafdVersion {
                Text("CAFD: \(cafdVersion)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text("Checksum: \(backup.checksum.prefix(8))...")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospaced()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BackupManagementView()
}
