import { DocsBreadcrumb, DocsCallout } from "@/components/docs/docs-shell";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy & permissions",
  description: "On-device Vision, sandbox entitlements, and what leaves your Mac.",
};

export default function PrivacyDocPage() {
  return (
    <>
      <DocsBreadcrumb section="Privacy & integrations" title="Privacy & permissions" />
      <h1>Privacy & permissions</h1>
      <p className="docs-lead">
        Parcel is private by default. OCR, face detection, translation, and regex
        redaction use Apple on-device frameworks only — no cloud AI, no telemetry.
      </p>

      <h2>What stays local</h2>
      <ul>
        <li>All Capture and recording pixels</li>
        <li>Vision OCR, QR, face finding, and translation (macOS 15+/26+)</li>
        <li>Regex PII inspection and auto-redact suggestions</li>
        <li>Capture history documents on disk</li>
      </ul>

      <h2>Permissions Parcel uses</h2>
      <div className="not-prose my-6 space-y-3">
        <div className="flex items-center justify-between rounded-xl border bg-card p-4">
          <div>
            <p className="font-medium">Screen Recording</p>
            <p className="text-sm text-muted-foreground">
              Required — ScreenCaptureKit for Capture and recording
            </p>
          </div>
          <span className="rounded-full bg-amber-500/15 px-3 py-1 font-mono text-xs text-amber-400">
            Required
          </span>
        </div>
        <div className="flex items-center justify-between rounded-xl border bg-card p-4">
          <div>
            <p className="font-medium">Accessibility</p>
            <p className="text-sm text-muted-foreground">
              Not used — Carbon hotkeys avoid event taps
            </p>
          </div>
          <span className="font-mono text-xs text-muted-foreground">Not needed</span>
        </div>
      </div>

      <h2>Sandbox</h2>
      <p>
        Release builds are sandboxed with user-selected file read/write for Save
        panels. Upload uses HTTPS to your configured Supabase project only when
        you trigger it.
      </p>

      <DocsCallout variant="note" title="Hard rule">
        Parcel never sends Captures to a network LLM or third-party AI service.
        Any future &quot;AI&quot; feature must be provably on-device.
      </DocsCallout>
    </>
  );
}
