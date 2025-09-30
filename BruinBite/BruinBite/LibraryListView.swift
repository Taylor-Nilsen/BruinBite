import SwiftUI

struct LibraryListView: View {
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.libraries.isEmpty {
                ProgressView("Loading…").padding()
            } else if let err = viewModel.errorMessage, viewModel.libraries.isEmpty {
                VStack(spacing: 12) {
                    Text(err).multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await viewModel.load()
                        }
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.libraries) { library in
                        NavigationLink(destination: LibraryDetailView(library: library, distanceMiles: viewModel.distanceToLibrary(library))) {
                            LibraryRow(library: library, distance: viewModel.distanceToLibrary(library))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .navigationTitle("Study")
        .task {
            await viewModel.load()
        }
    }

    private struct LibraryRow: View {
        let library: LibraryLocation
        let distance: Double?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(library.name)
                        .appFont(.headline)
                    Spacer(minLength: 12)
                }
                
                if let distance = distance {
                    Text(String(format: "%.2f mi", distance))
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LibraryListView()
    }
}
