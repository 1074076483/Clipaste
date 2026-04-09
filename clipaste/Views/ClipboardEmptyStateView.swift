import SwiftUI

struct ClipboardEmptyStateView: View {
    @ObservedObject var viewModel: ClipboardViewModel

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: isSearching ? "doc.text.magnifyingglass" : "tray.fill")
                    .font(.system(size: 48, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: 6) {
                Text(titleKey)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitleKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
        .padding(.bottom, 40)
    }

    private var isSearching: Bool {
        !viewModel.searchInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isLoading: Bool {
        viewModel.isInitialHistoryLoading && !isSearching
    }

    private var titleKey: LocalizedStringKey {
        if isLoading {
            return "Loading Clipboard History…"
        }

        return isSearching ? "No Matches Found" : "Clipboard Empty"
    }

    private var subtitleKey: LocalizedStringKey {
        if isLoading {
            return "Recent items will appear first while the full history finishes loading."
        }

        return isSearching ? "Try a different search term" : "Copied text, images and links will appear here"
    }
}
