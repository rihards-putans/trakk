import SwiftUI

struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var showFoodLog = false
    @State private var showWeightHistory = false
    @State private var showSettings = false
    @State private var showChat = false
    @State private var showTextLog = false
    @State private var showBarcodeScanner = false
    @State private var showCalorieHistory = false
    @State private var showSOS = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Scrollable content
                ScrollView {
                    VStack(spacing: Theme.cardSpacing) {
                        // Header
                        headerSection

                        // Calorie ring card (tap for history)
                        Button(action: { showCalorieHistory = true }) {
                            CalorieRingView(
                                eaten: vm.todayEaten,
                                burned: vm.todayBurned,
                                target: vm.calorieTarget,
                                remaining: vm.caloriesRemaining
                            )
                        }
                        .buttonStyle(.plain)

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

                        // Training day
                        TrainingDayView(
                            lastWorkoutDate: vm.lastWorkoutDate,
                            gymIntervalDays: vm.gymIntervalDays,
                            onMarkTraining: { Task { await vm.refresh() } }
                        )

                        // Food log preview
                        FoodLogPreviewView(
                            entries: vm.recentFoodEntries,
                            onSeeAll: { showFoodLog = true },
                            onDelete: { vm.deleteEntry($0) }
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
                    onTextLog: { showTextLog = true },
                    onSOS: { showSOS = true }
                )
            }
            .background(Theme.background.ignoresSafeArea())
            .refreshable { await vm.refresh() }
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
                FoodLogView()
            }
            .navigationDestination(isPresented: $showWeightHistory) {
                WeightHistoryView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showCalorieHistory) {
                CalorieHistoryView()
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
            // SOS sheet
            .sheet(isPresented: $showSOS) {
                SOSView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            // Full-screen cover
            .fullScreenCover(isPresented: $showBarcodeScanner) {
                BarcodeScannerView()
            }
            .onChange(of: showBarcodeScanner) { _, showing in
                if !showing { Task { await vm.refresh(); await vm.loadCoachInsight() } }
            }
            .onChange(of: showChat) { _, showing in
                if !showing { Task { await vm.refresh(); await vm.loadCoachInsight() } }
            }
            .onChange(of: showTextLog) { _, showing in
                if !showing { Task { await vm.refresh(); await vm.loadCoachInsight() } }
            }
            .onChange(of: showFoodLog) { _, showing in
                if !showing { Task { await vm.refresh() } }
            }
        }
        .task {
            await vm.refresh()
            await vm.loadCoachInsight()
        }
        .task(id: "healthkit-timer") {
            // Refresh HealthKit data every 60 seconds
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await vm.refresh()
            }
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
