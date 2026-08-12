# macOS 13–14 Fallback QA

Parcel’s primary development machine runs macOS 26. Capture and recording include fallback code paths for older macOS versions that **must be verified on real hardware or a VM** before claiming macOS 13.0+ support.

## Setup a macOS 13 VM

1. Install [UTM](https://mac.getutm.app/) or use Parallels with a macOS 13 Ventura IPSW.
2. Copy `Parcel.zip` (Release build) into the VM.
3. Grant **Screen Recording** in System Settings → Privacy & Security.
4. Quit and reopen Parcel.

## Paths under test

| Feature | macOS version | Implementation |
|---------|---------------|----------------|
| Capture | 13 | `SingleFrameStreamCapturer` in `Sources/Parcel/Capture/CaptureEngine.swift` |
| Recording | 13–14 | `LegacyRecordingWriter` in `Sources/Parcel/Recording/ScreenRecorder.swift` |
| Recording (native) | 15+ | `SCRecordingOutput` |

On macOS 14, Capture uses `SCScreenshotManager` but recording still uses the legacy writer.

## Minimum matrix (VM)

Run sections **1, 5, 8, 9** from [QA_CHECKLIST.md](QA_CHECKLIST.md).

Additional checks:

- [ ] Confirm Capture does **not** crash (SCStream fallback)
- [ ] Confirm recording produces playable MP4 with audio (AVFoundation writer)
- [ ] Translation button hidden or disabled (requires macOS 26+)

## Logging

If Capture fails on macOS 13, check Console.app for `Parcel:` messages from `CaptureEngine`.

## Sign-off

| Tester | macOS version | Date | Pass |
|--------|---------------|------|------|
| | 13.x | | ☐ |
| | 14.x | | ☐ |
