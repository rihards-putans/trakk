import SwiftUI

struct FoodLogView: View {
    @StateObject private var vm = FoodLogViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Date picker
                DatePicker("", selection: $vm.selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Theme.primary)
                    .padding()
                    .onChange(of: vm.selectedDate) { _, _ in vm.load() }

                // Summary
                HStack {
                    Label("\(Int(vm.totalCalories)) kcal", systemImage: "flame")
                        .foregroundColor(Theme.consumed)
                    Spacer()
                    Label("\(Int(vm.totalProtein))g protein", systemImage: "fork.knife")
                        .foregroundColor(Theme.warning)
                }
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Entries
                if vm.entries.isEmpty {
                    Spacer()
                    Text("No entries for this day")
                        .foregroundColor(Theme.textMuted)
                    Spacer()
                } else {
                    List {
                        ForEach(vm.entries, id: \.id) { entry in
                            FoodEntryRow(entry: entry)
                                .listRowBackground(Theme.background)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                vm.delete(vm.entries[offset])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Food Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { vm.load() }
    }
}
