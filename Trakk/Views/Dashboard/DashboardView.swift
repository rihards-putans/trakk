import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var showFoodLog = false
    @State private var showWeightHistory = false
    @State private var showSettings = false
    @State private var showChat = false
    @State private var showTextLog = false
    @State private var showBarcodeScanner = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Scrollable content
                ScrollView {
                    VStack(spacing: Theme.cardSpacing) {
                        // Header
                        headerSection

                        // Calorie ring card
                        CalorieRingView(
                            eaten: vm.todayEaten,
                            burned: vm.todayBurned,
                            target: vm.calorieTarget,
                            remaining: vm.caloriesRemaining
                        )

                        // Metric cards
                        MetricCardsView(
                            currentWeight: vm.currentWeight,
                            weightHistory: vm.weightHistory,
                            todayProtein: vm.todayProtein,
                            proteinTarget: vm.proteinTarget,
                            streak: vm.streak,
                            streakDays: vm.streakDays,
                            onWeightTap: { showWeightHistory = true }
                        )

                        // Food log preview
                        FoodLogPreviewView(
                            entries: vm.recentFoodEntries,
                            onSeeAll: { showFoodLog = true }
                        )

                        // Coach insight
                        CoachInsightView(
                            insight: vm.coachInsight,
                            isLoading: vm.isLoadingInsight,
                            onReply: { showChat = true }
                        )

                        // Bottom spacer for FAB
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 8)
                }

                // Floating action button
                FABView(
                    onBarcodeScan: { showBarcodeScanner = true },
                    onTextLog: { showTextLog = true }
                )
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(Theme.textMuted)
                    }
                }
            }
            // Push destinations
            .navigationDestination(isPresented: $showFoodLog) {
                Text("Task 11 — Food Log Full View")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background.ignoresSafeArea())
            }
            .navigationDestination(isPresented: $showWeightHistory) {
                Text("Task 12 — Weight History View")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background.ignoresSafeArea())
            }
            .navigationDestination(isPresented: $showSettings) {
                Text("Task 14 — Settings View")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background.ignoresSafeArea())
            }
            // Sheet destinations
            .sheet(isPresented: $showChat) {
                ChatSheetView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showTextLog) {
                ChatSheetView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // Full-screen cover
            .fullScreenCover(isPresented: $showBarcodeScanner) {
                Text("Task 13 — Barcode Scanner")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background.ignoresSafeArea())
            }
        }
        .task {
            await vm.refresh()
            await vm.loadCoachInsight()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.greeting)
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)

                if vm.dayCount > 0 {
                    Text("Day \(vm.dayCount) on Trakk")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textMuted)
                }
            }

            Spacer()

            // Streak badge
            if vm.streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.warning)
                    Text("\(vm.streak)")
                        .font(Font.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.warning)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.warning.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
