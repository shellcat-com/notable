import { DocsBreadcrumb, DocsCallout } from "@/components/docs/docs-shell";
import { annotationTools } from "@/lib/site";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Editor & Annotations",
  description: "Fourteen Tools, Layer stack, Beautify, Adjustments, and export.",
};

export default function EditorDocPage() {
  return (
    <>
      <DocsBreadcrumb section="Core workflows" title="Editor & Annotations" />
      <h1>Editor & Annotations</h1>
      <p className="docs-lead">
        The Editor is where you mark up a Capture, tune output, and copy or save.
        One render pipeline drives display and export —{" "}
        <strong>on screen = saved</strong>.
      </p>

      <h2>Fourteen Tools</h2>
      <p>Select a Tool from the toolbar to create Annotations:</p>
      <ul className="columns-1 sm:columns-2">
        {annotationTools.map((tool) => (
          <li key={tool}>{tool}</li>
        ))}
      </ul>

      <h2>Click-to-edit</h2>
      <p>
        Switch to <strong>Select</strong>, click any Annotation, and use the style
        bar to change stroke, color, arrow style, censor mode, or fill. Move and
        resize with handles. The Layer stack supports reorder via the layers
        panel.
      </p>

      <h2>Censor modes</h2>
      <ul>
        <li>
          <strong>Blur / Pixelate / Solid</strong> — standard redaction
        </li>
        <li>
          <strong>Erase</strong> — samples surrounding Capture pixels
        </li>
        <li>
          <strong>Auto-redact</strong> — regex PII and detected faces via on-device
          Vision
        </li>
      </ul>

      <h2>Beautify & Adjustments</h2>
      <p>
        <strong>Beautify</strong> wraps your Canvas with gradient backgrounds,
        window chrome, padding, radius, and shadow — plus saved brand kits.
        <strong> Adjustments</strong> run a Core Image chain on the base Capture
        (exposure, contrast, saturation, and more).
      </p>
      <DocsCallout variant="note">
        Adjustments and Beautify are document-level — outside the undo stack. Use
        each panel&apos;s Reset to revert.
      </DocsCallout>

      <h2>Export formats</h2>
      <p>
        Copy or save as PNG, JPEG, HEIC, or TIFF. Format and quality live in the
        output panel. Re-open any past Capture from history (<kbd>⌘⇧H</kbd>) with
        annotations and settings intact.
      </p>
    </>
  );
}
