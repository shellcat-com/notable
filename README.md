# Notable

A native macOS screenshot & annotation tool, built from scratch in SwiftUI. Capture a region or a
window, mark it up, and get it onto your clipboard or saved as a file — fast, on-device, no cloud.

> **Working codename.** "Notable" is a placeholder; a final original name + icon is pending.

## Status

**Phase 1 — core loop** (in progress): hotkey capture → region / window-snap selection →
annotation editor → copy / save. Everything on-device (ScreenCaptureKit + Apple Vision later).
**No network AI, ever** — a hard project constraint.

## Requirements

- macOS 13.0+
- Xcode 15+ (developed against Xcode 26)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build & run

```sh
xcodegen generate
xcodebuild -project Notable.xcodeproj -scheme Notable -configuration Debug build
open "$(xcodebuild -project Notable.xcodeproj -scheme Notable -configuration Debug -showBuildSettings 2>/dev/null | awk -F' = ' '/ BUILT_PRODUCTS_DIR /{d=$2} / FULL_PRODUCT_NAME /{n=$2} END{print d"/"n}')"
```

Notable lives in the menu bar (no dock icon). Press **⌘⇧2** to capture. On first capture, grant
**Screen Recording** in System Settings → Privacy & Security, then reopen Notable.

## License

MIT — see [LICENSE](LICENSE).
