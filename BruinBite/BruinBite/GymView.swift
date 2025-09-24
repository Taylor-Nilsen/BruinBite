import SwiftUI

struct GymView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Gym Info Coming Soon!")
                .font(.title2)
                .foregroundStyle(.secondary)
            Image(systemName: "figure.walk")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Gym")
    }
}