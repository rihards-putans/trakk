import SwiftUI
import VisionKit

struct BarcodeScannerView: View {
    @StateObject private var vm = BarcodeScannerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch vm.state {
            case .scanning:
                DataScannerRepresentable { barcode in
                    Task { await vm.lookupBarcode(barcode) }
                }
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }

            case .loading:
                ProgressView("Looking up product...")
                    .tint(Theme.primary)
                    .foregroundColor(Theme.textPrimary)

            case .found(let product):
                ProductResultView(product: product, onLog: {
                    vm.logProduct(product)
                    dismiss()
                }, onRescan: { vm.reset() })

            case .notFound:
                VStack(spacing: 16) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textMuted)
                    Text("Product not found")
                        .font(Theme.headingFont)
                        .foregroundColor(Theme.textPrimary)
                    Text("Enter the details from the package:")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textMuted)

                    TextField("Product name", text: $vm.manualName)
                        .textFieldStyle(.plain).padding(12)
                        .background(Theme.cardSurface).cornerRadius(10)
                        .foregroundColor(Theme.textPrimary)

                    TextField("Calories", text: $vm.manualCalories)
                        .textFieldStyle(.plain).padding(12)
                        .background(Theme.cardSurface).cornerRadius(10)
                        .keyboardType(.numberPad)
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: 12) {
                        Button("Log") {
                            vm.logManualEntry()
                            dismiss()
                        }
                        .frame(maxWidth: .infinity).padding(12)
                        .background(Theme.primary).foregroundColor(.white).cornerRadius(10)
                        .disabled(vm.manualName.isEmpty || vm.manualCalories.isEmpty)

                        Button("Scan again") { vm.reset() }
                            .frame(maxWidth: .infinity).padding(12)
                            .background(Theme.cardSurface).foregroundColor(Theme.textMuted).cornerRadius(10)
                    }
                }
                .padding(32)

            case .error(let msg):
                VStack(spacing: 16) {
                    Text(msg).foregroundColor(Theme.consumed)
                    Button("Try again") { vm.reset() }
                        .foregroundColor(Theme.primary)
                }
            }
        }
    }
}

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onBarcodeFound: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean8, .ean13, .upce])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onBarcodeFound: onBarcodeFound) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcodeFound: (String) -> Void
        private var hasScanned = false

        init(onBarcodeFound: @escaping (String) -> Void) { self.onBarcodeFound = onBarcodeFound }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !hasScanned else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item, let value = barcode.payloadStringValue {
                    hasScanned = true
                    dataScanner.stopScanning()
                    onBarcodeFound(value)
                    return
                }
            }
        }
    }
}
