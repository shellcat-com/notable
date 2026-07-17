import SwiftUI

/// The Adjust popover: preset chips + one slider per Core Image parameter, all on-device.
struct AdjustmentsPanel: View {
    @ObservedObject var model: EditorModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Adjust").font(.headline)
                Spacer()
                Button("Reset") { model.resetAdjustments() }
                    .disabled(model.adjustments.isNeutral)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AdjustmentPreset.all) { preset in
                        presetChip(preset)
                    }
                }
                .padding(.bottom, 2)
            }

            Divider()

            ForEach(AdjustmentParam.allCases) { param in
                slider(for: param)
            }
        }
        .padding(14)
        .frame(width: 300)
    }

    private func presetChip(_ preset: AdjustmentPreset) -> some View {
        let selected = model.adjustments == preset.adjustments
        return Button {
            model.applyPreset(preset)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: preset.symbol).font(.system(size: 14))
                Text(preset.name).font(.system(size: 10))
            }
            .frame(width: 52, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(selected ? Color.accentColor.opacity(0.22) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
            .foregroundStyle(selected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func slider(for param: AdjustmentParam) -> some View {
        VStack(spacing: 1) {
            HStack {
                Text(param.label).font(.system(size: 11))
                Spacer()
                Text(readout(param)).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { model.adjustments[keyPath: param.keyPath] },
                    set: { model.updateAdjustment(param.keyPath, $0) }
                ),
                in: param.range
            )
            // Double-click the label row to reset just this parameter.
            .contextMenu {
                Button("Reset \(param.label)") { model.updateAdjustment(param.keyPath, param.neutralValue) }
            }
        }
    }

    private func readout(_ param: AdjustmentParam) -> String {
        let value = model.adjustments[keyPath: param.keyPath]
        return String(format: "%.2f", value)
    }
}
