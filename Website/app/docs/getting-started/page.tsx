import { DocsBreadcrumb, DocsCallout } from "@/components/docs/docs-shell";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Quick start",
  description: "Install Parcel, grant Screen Recording, and take your first Capture.",
};

export default function GettingStartedPage() {
  return (
    <>
      <DocsBreadcrumb section="Getting started" title="Quick start" />
      <h1>Quick start</h1>
      <p className="docs-lead">
        Parcel lives in your menu bar. After install, grant Screen Recording once,
        quit and reopen — then press <kbd>⌘⇧2</kbd> to Capture.
      </p>

      <h2>1. Download & install</h2>
      <p>
        Download the signed Release build from the{" "}
        <a href="/downloads/Parcel.zip">direct download</a> or build from source
        with Xcode. Drag <strong>Parcel.app</strong> to Applications.
      </p>
      <DocsCallout variant="tip" title="Homebrew">
        Once published to a tap:{" "}
        <code>brew install --cask parcel</code>
      </DocsCallout>

      <h2>2. First launch</h2>
      <ol>
        <li>Complete the welcome onboarding flow.</li>
        <li>
          When prompted, open <strong>System Settings → Privacy & Security →
          Screen Recording</strong> and enable Parcel.
        </li>
        <li>
          <strong>Quit and reopen</strong> Parcel — TCC permissions only apply
          after restart.
        </li>
      </ol>

      <h2>3. Take your first Capture</h2>
      <ol>
        <li>
          Press <kbd>⌘⇧2</kbd> (configurable in Preferences) from any app.
        </li>
        <li>
          Every display freezes. Drag a region, press <kbd>Tab</kbd> to snap to
          a window, or choose Scroll Capture from the menu bar.
        </li>
        <li>
          Release to open the <strong>Editor</strong> with your Selection cropped
          at full resolution.
        </li>
        <li>
          Mark up, then <kbd>⌘C</kbd> to copy or <kbd>⌘S</kbd> to save. What you
          see on screen is exactly what exports.
        </li>
      </ol>

      <DocsCallout variant="note" title="No Accessibility permission">
        Parcel uses Carbon global hotkeys — not <code>CGEventTap</code> — so you
        never need Accessibility access for Capture.
      </DocsCallout>

      <h2>Next steps</h2>
      <ul>
        <li>
          <a href="/docs/capture">Capture & Selection</a> — scroll stitch, multi-display
        </li>
        <li>
          <a href="/docs/editor">Editor & Annotations</a> — all fourteen Tools
        </li>
        <li>
          <a href="/docs/shortcuts">Keyboard shortcuts</a> — full reference
        </li>
      </ul>
    </>
  );
}
