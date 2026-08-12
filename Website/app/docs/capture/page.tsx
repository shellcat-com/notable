import { DocsBreadcrumb, DocsCallout } from "@/components/docs/docs-shell";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Capture & Selection",
  description: "Freeze-then-select Capture, window snap, and scroll stitching.",
};

export default function CaptureDocPage() {
  return (
    <>
      <DocsBreadcrumb section="Core workflows" title="Capture & Selection" />
      <h1>Capture & Selection</h1>
      <p className="docs-lead">
        Parcel freezes every display with ScreenCaptureKit, then lets you choose
        a <strong>Selection</strong> from those pixels — region drag, window snap,
        or scroll stitch.
      </p>

      <h2>Freeze-then-select</h2>
      <p>
        On hotkey, Parcel captures full-resolution images of all displays and
        shows them in the <strong>Overlay</strong> — a borderless full-screen
        panel per display. You work on frozen pixels, not a live view.
      </p>
      <ul>
        <li>
          <strong>Region</strong> — click and drag any rectangle
        </li>
        <li>
          <strong>Window snap</strong> — hover a highlighted window and click, or
          press <kbd>Tab</kbd> to cycle targets
        </li>
        <li>
          <strong>Cancel</strong> — <kbd>Esc</kbd> dismisses the Overlay with no
          Editor
        </li>
      </ul>

      <h2>Scroll Capture</h2>
      <p>
        For tall content that does not fit on screen, choose{" "}
        <strong>Scroll Capture</strong> from the menu bar while the Overlay is
        active:
      </p>
      <ol>
        <li>Drag a tall Selection region in the Overlay.</li>
        <li>Scroll the source content and add frames from the menu bar.</li>
        <li>
          Parcel stitches frames with on-device Vision registration — live preview
          as frames stack.
        </li>
        <li>Finish to open the stitched Capture in the Editor.</li>
      </ol>

      <h2>Multi-display</h2>
      <p>
        One Overlay panel appears per display. Your Selection is cropped from the
        display where you release — pixels stay at native resolution and retina
        scale.
      </p>

      <DocsCallout variant="warning" title="Screen Recording permission">
        ScreenCaptureKit requires Screen Recording TCC. If Capture fails after an
        update, re-check System Settings and quit/reopen Parcel. Use a stable
        Developer ID signing identity so permission persists across updates.
      </DocsCallout>
    </>
  );
}
