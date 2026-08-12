import type { Metadata } from "next";
import { DocsShell } from "@/components/docs/docs-shell";

export const metadata: Metadata = {
  title: "Documentation",
  description:
    "User guides for Parcel — install, Capture, annotate, record, and upload on macOS.",
};

export default function DocsLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <main id="main" className="border-b">
      <div className="relative overflow-hidden border-b bg-[#0a0a0b]">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_50%_-10%,rgba(139,92,246,0.18),transparent_60%)]"
        />
        <div className="relative mx-auto max-w-7xl px-4 py-14 md:py-20">
          <p className="font-mono text-xs uppercase tracking-widest text-zinc-400">
            Parcel · User guides
          </p>
          <h1 className="mt-3 max-w-2xl text-3xl font-semibold tracking-tight text-zinc-50 md:text-4xl">
            Everything you need to{" "}
            <em className="font-display font-normal not-italic text-zinc-300">
              Capture
            </em>{" "}
            with confidence.
          </h1>
          <p className="mt-4 max-w-xl text-zinc-300">
            Install, permissions, workflows, and integrations — written for
            daily macOS use, not just contributors.
          </p>
        </div>
      </div>
      <DocsShell>{children}</DocsShell>
    </main>
  );
}
