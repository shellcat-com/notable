import SwiftUI

/// The Beautify popover: master toggle, background (none/solid/gradient), padding, corner radius,
/// shadow, and window chrome. All controls are directly reversible (no undo entry); Reset restores
/// defaults.
struct BeautifyPanel: View {
    @ObservedObject var model: EditorModel

    private enum BackgroundKind: String, CaseIterable, Identifiable {
        case none, solid, gradient
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    private let gridColumns = Array(repeating: GridItem(.fixed(40), spacing: 8), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Beautify", isOn: $model.beautifyEnabled).font(.headline)
                Spacer()
                Button("Reset") { model.beautify = BeautifySettings() }
            }

            Group {
                backgroundSection
                Divider()
                slidersSection
                Divider()
                shadowSection
                Divider()
                chromeSection
            }
            .disabled(!model.beautifyEnabled)
            .opacity(model.beautifyEnabled ? 1 : 0.5)
        }
        .padding(14)
        .frame(width: 320)
    }

    // MARK: Background

    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Background", selection: backgroundKind) {
                ForEach(BackgroundKind.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch backgroundKind.wrappedValue {
            case .none:
                EmptyView()
            case .solid:
                ColorPicker("Color", selection: solidColorBinding, supportsOpacity: false)
                    .font(.system(size: 12))
            case .gradient:
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(GradientPreset.all) { preset in
                            gradientSwatch(preset)
                        }
                    }
                }
                .frame(height: 120)
            }
        }
    }

    private func gradientSwatch(_ preset: GradientPreset) -> some View {
        let isSelected: Bool = {
            if case let .gradient(current) = model.beautify.background { return current.id == preset.id }
            return false
        }()
        return Button {
            model.beautify.background = .gradient(preset)
        } label: {
            RoundedRectangle(cornerRadius: 6)
                .fill(preset.gradient)
                .frame(width: 40, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isSelected ? Color.accentColor : Color.black.opacity(0.12),
                                      lineWidth: isSelected ? 2 : 0.5)
                )
                .overlay(alignment: .center) {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .help(preset.name)
    }

    // MARK: Sliders

    private var slidersSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            labeledSlider("Padding", value: $model.beautify.padding, range: 0...160)
            labeledSlider("Corner Radius", value: $model.beautify.cornerRadius, range: 0...40)
        }
    }

    // MARK: Shadow

    private var shadowSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Shadow", isOn: $model.beautify.shadow.enabled).font(.system(size: 12, weight: .medium))
            if model.beautify.shadow.enabled {
                // Blur clamped to padding so the shadow always fits the padding band.
                labeledSlider("Blur", value: $model.beautify.shadow.blur, range: 0...max(1, model.beautify.padding))
                labeledSlider("Opacity", value: shadowOpacityBinding, range: 0...1)
            }
        }
    }

    // MARK: Chrome

    private var chromeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Window Chrome", isOn: $model.beautify.chrome.enabled).font(.system(size: 12, weight: .medium))
            if model.beautify.chrome.enabled {
                TextField("Title", text: $model.beautify.chrome.title)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                Picker("Style", selection: $model.beautify.chrome.style) {
                    ForEach(BeautifySettings.ChromeStyle.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
    }

    // MARK: Helpers

    private func labeledSlider(_ label: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.system(size: 12)).frame(width: 92, alignment: .leading)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue))").font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary).frame(width: 28, alignment: .trailing)
        }
    }

    private var shadowOpacityBinding: Binding<CGFloat> {
        Binding(
            get: { CGFloat(model.beautify.shadow.opacity * 100) },
            set: { model.beautify.shadow.opacity = Double($0) / 100 }
        )
    }

    private var backgroundKind: Binding<BackgroundKind> {
        Binding(
            get: {
                switch model.beautify.background {
                case .none: return .none
                case .solid: return .solid
                case .gradient: return .gradient
                }
            },
            set: { kind in
                switch kind {
                case .none: model.beautify.background = .none
                case .solid:
                    if case .solid = model.beautify.background { } else { model.beautify.background = .solid(.white) }
                case .gradient:
                    if case .gradient = model.beautify.background { } else {
                        model.beautify.background = .gradient(GradientPreset.defaultPreset)
                    }
                }
            }
        )
    }

    private var solidColorBinding: Binding<Color> {
        Binding(
            get: {
                if case let .solid(color) = model.beautify.background { return color.color }
                return .white
            },
            set: { model.beautify.background = .solid(RGBAColor($0)) }
        )
    }
}
