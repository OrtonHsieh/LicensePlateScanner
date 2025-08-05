//
//  LicensePlateSannerView.swift
//  LicensePlateScanner
//
//  Created by OrtonHsieh on 2025/8/5.
//

import SwiftUI
import VisionKit            // iOS 16+

struct LicensePlateScannerView: UIViewControllerRepresentable {
    /// 偵測到新車牌時的回呼
    var onDetect: (_ message: String, _ shouldDismiss: Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],  // 只掃文字
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {
        // No incremental updates needed for this simple scanner MVP
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let parent: LicensePlateScannerView
        init(parent: LicensePlateScannerView) { self.parent = parent }

        /// 點擊反白文字（iOS 16）也能觸發
        func dataScanner(_ scanner: DataScannerViewController,
                         didTapOn item: RecognizedItem) {
            handle(item, scanner: scanner)
        }

        // ——— 私有 ———
        private func handle(_ item: RecognizedItem, scanner: DataScannerViewController) {
            guard case .text(let t) = item else { return }
            let original = t.transcript
            let plate = sanitize(original.replacingOccurrences(of: " ", with: ""))
            guard isLicensePlate(plate) else { return }
            print("Detected text: \(plate)")
            UIPasteboard.general.string = plate
            scanner.stopScanning()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.onDetect("已複製車牌 \(plate)", true)
            }
        }

        /// 正規化字串：將非英文字母與數字全部替換成連字號，最後轉大寫
        private func sanitize(_ s: String) -> String {
            // 將非英文字母與數字全部替換成連字號，最後轉大寫
            let replaced = s.replacingOccurrences(
                of: #"[^A-Za-z0-9]"#,
                with: "",
                options: .regularExpression
            )
            let up = replaced.uppercased()
            // 將易誤判的英文字轉成數字：O→0, I→1
            let corrected = up
                .replacingOccurrences(of: "O", with: "0")
                .replacingOccurrences(of: "I", with: "1")
            return corrected
        }

        /// 驗證台灣車牌（汽車 & 機車多格式）
        private func isLicensePlate(_ s: String) -> Bool {
            let patterns = [
                #"^[A-Z]{3}\d{4}$"#,     // 汽車：ABC1234
                #"^\d{4}[A-Z]{3}$"#,     // 汽車：1234ABC
                #"^[A-Z]{2}\d{4}$"#,     // 機車：AB1234
                #"^[A-Z]{2}\d{3}$"#      // 機車：AB123
            ]
            return patterns.contains { pat in
                s.range(of: pat, options: .regularExpression) != nil
            }
        }
    }
}
