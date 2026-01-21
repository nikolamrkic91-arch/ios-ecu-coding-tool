import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("ECU Coding Tool")
                    .font(.largeTitle).bold()

                Text("Dealer-level coding with guardrails")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Read DTCs (Phase 1)", systemImage: "wrench.adjustable")
                    Label("VO/FA decode, SVT/NCD diff", systemImage: "doc.text.magnifyingglass")
                    Label("Backups before writes (Phase 2)", systemImage: "externaldrive.badge.checkmark")
                    Label("Remote utility (Phase 3)", systemImage: "antenna.radiowaves.left.and.right")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
