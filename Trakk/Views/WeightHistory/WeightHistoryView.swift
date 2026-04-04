import SwiftUI
import Charts

struct WeightHistoryView: View {
    @StateObject private var vm = WeightHistoryViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                // Period picker
                Picker("Period", selection: $vm.selectedPeriod) {
                    ForEach(WeightHistoryViewModel.Period.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: vm.selectedPeriod) { _, _ in Task { await vm.load() } }

                // Chart
                if vm.dataPoints.isEmpty {
                    Spacer()
                    Text("No weight data yet").foregroundColor(Theme.textMuted)
                    Spacer()
                } else {
                    Chart {
                        ForEach(vm.dataPoints, id: \.date) { point in
                            LineMark(x: .value("Date", point.date), y: .value("Weight", point.kg))
                                .foregroundStyle(Theme.primary)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", point.date), y: .value("Weight", point.kg))
                                .foregroundStyle(Theme.primary)
                                .symbolSize(20)
                        }
                        RuleMark(y: .value("Goal", vm.goalWeight))
                            .foregroundStyle(Theme.positive.opacity(0.5))
                            .lineStyle(StrokeStyle(dash: [5, 5]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("Goal: \(String(format: "%.0f", vm.goalWeight))kg")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.positive)
                            }
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .chartXAxis { AxisMarks(values: .automatic) { _ in AxisValueLabel().foregroundStyle(Theme.textMuted) } }
                    .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Theme.textMuted); AxisGridLine().foregroundStyle(Theme.inactive) } }
                    .frame(height: 250)
                    .padding(.horizontal)
                }

                // Rate badge
                if let rate = vm.ratePerWeek {
                    HStack {
                        Image(systemName: rate <= 0 ? "arrow.down.right" : "arrow.up.right")
                        Text(String(format: "%.2f kg/week", rate))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(rate <= 0 ? Theme.positive : Theme.consumed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.cardSurface)
                    .cornerRadius(20)
                }

                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load() }
    }
}
