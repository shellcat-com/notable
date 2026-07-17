import SwiftUI

/// Composites the (unchanged) AnnotatedCanvas onto the Beautify frame: background → shadowed
/// rounded window backing → chrome bar → the Capture layer at `innerOrigin`.
///
/// One composition drives BOTH the interactive display (scale = fit zoom) and export (scale = 1,
/// ImageRenderer.scale = capture.scale), so what is on screen === what is saved. Beautify points
/// and Capture points are the same unit; this view contributes ONLY the innerOrigin translation,
/// never a second scale. With `settings == .disabled` it collapses to a pass-through identical to
/// a bare AnnotatedCanvas.
struct BeautifyCanvas: View {
    let base: NSImage
    let blurred: CGImage
    let pixelated: CGImage
    let capturePointSize: CGSize
    let captureScale: CGFloat
    let settings: BeautifySettings
    /// View points per beautify point (== per Capture point).
    let scale: CGFloat
    var annotations: [Annotation]
    var draft: Annotation?

    var body: some View {
        let outer = settings.outerSize(for: capturePointSize)
        let window = settings.windowFrame(for: capturePointSize)
        let radius = settings.cornerRadius * scale
        let chromeH = settings.chromeHeight * scale

        ZStack(alignment: .topLeading) {
            backgroundLayer
                .frame(width: outer.width * scale, height: outer.height * scale)

            ZStack(alignment: .topLeading) {
                // Window silhouette: casts the shadow and supplies the chrome-bar fill.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(chromeBarFill)
                    .frame(width: window.width * scale, height: window.height * scale)
                    .modifier(WindowShadow(shadow: settings.shadow, scale: scale))

                if settings.chrome.enabled {
                    chromeBar(height: chromeH, width: window.width * scale)
                }

                AnnotatedCanvas(
                    base: base,
                    blurred: blurred,
                    pixelated: pixelated,
                    pointSize: capturePointSize,
                    scale: scale,
                    captureScale: captureScale,
                    annotations: annotations,
                    draft: draft
                )
                .clipShape(captureClip(radius: radius))
                .offset(y: chromeH)
            }
            .frame(width: window.width * scale, height: window.height * scale, alignment: .topLeading)
            .offset(x: window.minX * scale, y: window.minY * scale)
        }
        .frame(width: outer.width * scale, height: outer.height * scale, alignment: .topLeading)
    }

    // MARK: Layers

    @ViewBuilder
    private var backgroundLayer: some View {
        switch settings.background {
        case .none:
            Color.clear
        case .solid(let color):
            color.color
        case .gradient(let preset):
            preset.gradient
        }
    }

    private var chromeBarFill: Color {
        settings.chrome.style == .dark ? Color(white: 0.16) : Color(white: 0.93)
    }

    /// Square top corners meet the bar (the backing rect supplies the top rounding); rounded
    /// bottom corners match the window silhouette so the whole reads as one macOS window.
    private func captureClip(radius: CGFloat) -> AnyShape {
        if settings.chrome.enabled {
            return AnyShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: radius,
                    bottomTrailingRadius: radius,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
        }
        return AnyShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Generic traffic-light dots + optional centered title. Original drawing, no asset reuse.
    private func chromeBar(height: CGFloat, width: CGFloat) -> some View {
        ZStack {
            HStack(spacing: 8 * scale) {
                Circle().fill(Color(red: 1.00, green: 0.37, blue: 0.34))
                    .frame(width: 12 * scale, height: 12 * scale)
                Circle().fill(Color(red: 1.00, green: 0.74, blue: 0.18))
                    .frame(width: 12 * scale, height: 12 * scale)
                Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25))
                    .frame(width: 12 * scale, height: 12 * scale)
                Spacer(minLength: 0)
            }
            .padding(.leading, 14 * scale)

            if !settings.chrome.title.isEmpty {
                Text(settings.chrome.title)
                    .font(.system(size: 12 * scale, weight: .medium))
                    .foregroundStyle(
                        settings.chrome.style == .dark
                            ? Color.white.opacity(0.85)
                            : Color.black.opacity(0.55)
                    )
                    .lineLimit(1)
                    .padding(.horizontal, 40 * scale)
            }
        }
        .frame(width: width, height: height, alignment: .leading)
    }
}

/// Applies the window drop shadow, scaled with the composition.
struct WindowShadow: ViewModifier {
    let shadow: BeautifySettings.ShadowSettings
    let scale: CGFloat

    func body(content: Content) -> some View {
        if shadow.enabled {
            content.shadow(
                color: .black.opacity(shadow.opacity),
                radius: shadow.blur * scale,
                x: 0,
                y: shadow.yOffset * scale
            )
        } else {
            content
        }
    }
}
