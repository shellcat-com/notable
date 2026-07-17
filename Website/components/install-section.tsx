"use client";

import { Download } from "lucide-react";
import { CopyButton } from "@/components/copy-button";
import { SectionHeader } from "@/components/section-header";
import { ShimmerButton } from "@/components/parable/shimmer-button";
import { DOWNLOAD_URL, HOMEBREW_CMD } from "@/lib/site";

export function InstallSection() {
  return (
    <section id="install" className="border-b">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Install"
          title="Download Parcel for macOS."
          subtitle="Requires macOS 13.0 or later. Grant Screen Recording on first launch, then quit and reopen."
        />
        <div className="mt-10 grid gap-6 md:grid-cols-2">
          <div className="rounded-2xl border bg-card p-6">
            <div className="flex size-10 items-center justify-center rounded-xl bg-violet-500/10 text-violet-400">
              <Download className="size-5" />
            </div>
            <h3 className="mt-4 font-medium">Direct download</h3>
            <p className="mt-2 text-sm text-muted-foreground">
              Signed Release builds from GitHub Actions. Unzip and drag Parcel to
              Applications.
            </p>
            <ShimmerButton
              as="a"
              href={DOWNLOAD_URL}
              className="mt-6 w-full justify-center"
              shimmerColor="#a78bfa"
            >
              Download Parcel.zip
            </ShimmerButton>
          </div>

          <div className="rounded-2xl border bg-card p-6">
            <p className="font-mono text-xs uppercase tracking-widest text-muted-foreground">
              Homebrew
            </p>
            <h3 className="mt-3 font-medium">Install via cask</h3>
            <p className="mt-2 text-sm text-muted-foreground">
              Once the cask is published to a tap, install with Homebrew.
            </p>
            <div className="mt-6 flex items-center gap-2 rounded-xl border bg-muted/40 py-2 pl-4 pr-2">
              <code className="min-w-0 flex-1 overflow-x-auto whitespace-nowrap font-mono text-[13px] text-foreground/90 [scrollbar-width:none]">
                {HOMEBREW_CMD}
              </code>
              <CopyButton value={HOMEBREW_CMD} label="Copy Homebrew command" />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
