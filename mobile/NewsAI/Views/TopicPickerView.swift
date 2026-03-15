import SwiftUI

struct TopicPickerView: View {
    @StateObject private var vm: PreferencesViewModel
    let onSaved: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    init(userId: String, onSaved: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: PreferencesViewModel(userId: userId))
        self.onSaved = onSaved
    }

    private var selectedTopicObjects: [Topic] {
        Topic.all.filter { vm.selectedTopics.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("What do you want to read?")
                            .font(.title2.weight(.semibold))
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Topic.all) { topic in
                                TopicCard(
                                    topic: topic,
                                    isSelected: vm.selectedTopics.contains(topic.id)
                                ) {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        if vm.selectedTopics.contains(topic.id) {
                                            vm.selectedTopics.remove(topic.id)
                                        } else {
                                            vm.selectedTopics.insert(topic.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Sub-interests for selected topics
                        if !selectedTopicObjects.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Get specific")
                                    .font(.title3.weight(.semibold))
                                    .padding(.horizontal)

                                ForEach(selectedTopicObjects) { topic in
                                    SubInterestSection(
                                        topic: topic,
                                        selectedSubInterests: vm.selectedSubInterests
                                    ) { sub in
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            vm.toggleSubInterest(sub)
                                        }
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Interests")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        Task { await vm.save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(vm.selectedTopics.isEmpty || vm.isSaving)
                }
            }
            .overlay {
                if vm.isSaving {
                    ProgressView("Saving…")
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .onChange(of: vm.savedSuccessfully) {
                if vm.savedSuccessfully { onSaved() }
            }
        }
    }
}

// ─── Sub-interest section per topic ──────────────────────────────────────────

private struct SubInterestSection: View {
    let topic: Topic
    let selectedSubInterests: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: topic.symbol)
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                Text(topic.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topic.subInterests, id: \.self) { sub in
                        SubInterestChip(
                            title: sub,
                            isSelected: selectedSubInterests.contains(sub)
                        ) {
                            onToggle(sub)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// ─── Chip button ─────────────────────────────────────────────────────────────

private struct SubInterestChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .primary)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(Color.accentColor.gradient)
                    } else {
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                    }
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : Color(.separator).opacity(0.3), lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
    }
}

// ─── Topic tile ───────────────────────────────────────────────────────────────

private struct TopicCard: View {
    let topic: Topic
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: topic.symbol)
                    .font(.system(size: 28))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? .white : .accentColor)
                Text(topic.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.accentColor.gradient)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Color(.separator).opacity(0.3), lineWidth: 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
