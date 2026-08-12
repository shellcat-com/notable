import { DocsBreadcrumb, DocsCallout } from "@/components/docs/docs-shell";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Supabase upload",
  description: "Configure optional Storage upload from the Editor.",
};

export default function SupabaseDocPage() {
  return (
    <>
      <DocsBreadcrumb section="Privacy & integrations" title="Supabase upload" />
      <h1>Supabase upload</h1>
      <p className="docs-lead">
        Upload is optional. Configure your own Supabase Storage bucket once —
        then upload from the Editor and copy a public link.
      </p>

      <h2>Setup</h2>
      <ol>
        <li>
          Create a Supabase project and a <strong>public</strong> Storage bucket.
        </li>
        <li>
          Open <strong>Preferences → Upload</strong> in Parcel.
        </li>
        <li>
          Paste your project URL, anon key, bucket name, and optional custom
          public base URL.
        </li>
        <li>Save — Parcel stores credentials locally on your Mac.</li>
      </ol>

      <h2>Upload from the Editor</h2>
      <p>
        After marking up a Capture, choose Upload from the Editor toolbar. Parcel
        writes to your bucket via the Supabase Storage REST API and copies the
        public URL to the clipboard.
      </p>

      <DocsCallout variant="warning" title="Your credentials">
        Use a bucket policy appropriate for your content. The anon key is stored
        in UserDefaults — treat it like any client-side secret with RLS policies
        that match your threat model.
      </DocsCallout>

      <h2>Troubleshooting</h2>
      <ul>
        <li>Verify the bucket is public or your base URL resolves correctly.</li>
        <li>Check object size limits on your Supabase plan.</li>
        <li>
          Ensure network access is allowed — sandboxed builds use standard HTTPS.
        </li>
      </ul>
    </>
  );
}
