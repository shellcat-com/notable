import { DocsBreadcrumb, DocsCallout } from "@/components/docs/docs-shell";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Screen recording",
  description: "Region recording, trim editor, GIF export, and audio options.",
};

export default function RecordingDocPage() {
  return (
    <>
      <DocsBreadcrumb section="Core workflows" title="Screen recording" />
      <h1>Screen recording</h1>
      <p className="docs-lead">
        Record a screen region as MP4 with system audio, optional microphone on
        macOS 15+, click highlights, trim, and local GIF export.
      </p>

      <h2>Start a recording</h2>
      <ol>
        <li>
          Choose <strong>Record Region</strong> from the menu bar (or the
          equivalent menu item).
        </li>
        <li>Drag a Selection in the Overlay — same freeze-then-select model.</li>
        <li>
          Recording runs at 30, 60, or 120 fps with system audio included.
        </li>
        <li>Stop from the menu bar control or hotkey.</li>
      </ol>

      <h2>Trim & export</h2>
      <p>
        After stopping, the trim window opens. Set in/out points, then save MP4
        or export a lightweight GIF for sharing.
      </p>

      <h2>macOS 15+ extras</h2>
      <ul>
        <li>Microphone capture alongside system audio</li>
        <li>Click highlights during recording</li>
      </ul>

      <DocsCallout variant="tip">
        On macOS 13, an AVFoundation fallback path exists but is written-but-untested
        on the primary dev machine. See the repo&apos;s{" "}
        <a href="https://github.com/bswxyz/notable/blob/main/docs/MACOS13_VM_QA.md">
          macOS 13 QA notes
        </a>
        .
      </DocsCallout>
    </>
  );
}
