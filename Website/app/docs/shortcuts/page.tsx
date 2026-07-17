import { DocsBreadcrumb, DocsCallout } from "@/components/docs/docs-shell";
import { shortcuts } from "@/lib/site";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Keyboard shortcuts",
  description: "Global hotkeys, Overlay controls, and Editor commands for Parcel.",
};

export default function ShortcutsDocPage() {
  return (
    <>
      <DocsBreadcrumb section="Getting started" title="Keyboard shortcuts" />
      <h1>Keyboard shortcuts</h1>
      <p className="docs-lead">
        Default bindings below. Change the Capture hotkey in{" "}
        <strong>Preferences → Hotkey</strong>.
      </p>

      <div className="not-prose my-8 overflow-hidden rounded-2xl border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b bg-muted/40 text-left">
              <th className="px-4 py-3 font-mono text-xs uppercase tracking-widest text-muted-foreground">
                Keys
              </th>
              <th className="px-4 py-3 font-mono text-xs uppercase tracking-widest text-muted-foreground">
                Action
              </th>
            </tr>
          </thead>
          <tbody>
            {shortcuts.map((row) => (
              <tr key={row.keys} className="border-b last:border-0">
                <td className="px-4 py-3">
                  <kbd className="docs-kbd">{row.keys}</kbd>
                </td>
                <td className="px-4 py-3 text-muted-foreground">{row.action}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h2>While drawing Annotations</h2>
      <ul>
        <li>
          <kbd>Shift</kbd> — constrain proportions (square, circle, straight line)
        </li>
        <li>
          <kbd>Space</kbd> — reposition shape while drawing
        </li>
        <li>
          <kbd>Esc</kbd> — cancel current draw or exit utility Tool
        </li>
      </ul>

      <DocsCallout variant="note">
        Undo (<kbd>⌘Z</kbd>) covers <strong>Annotation content only</strong> —
        create, delete, move, resize, and restyle. Adjustments and Beautify are
        document-level settings with panel Resets.
      </DocsCallout>
    </>
  );
}
