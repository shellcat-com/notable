"use client";

import Link from "next/link";
import { Check, Download, Terminal } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { CopyButton } from "@/components/copy-button";
import { PrimaryButton } from "@/components/primary-button";
import { SectionHeader } from "@/components/section-header";
import { DOWNLOAD_URL, HOMEBREW_CMD } from "@/lib/site";

const requirements = [
  "macOS 13.0 or later",
  "Screen Recording permission",
  "Quit & reopen after first grant",
  "No Accessibility permission needed",
] as const;

export function InstallSection() {
  const reduce = useReducedMotion();

  return (
    <section id="install" className="relative border-b">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_50%_40%_at_20%_80%,color-mix(in_srgb,var(--brand-secondary)_6%,transparent),transparent)]"
      />
      <div className="relative mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Install"
          title="Install in seconds."
          subtitle="Signed, notarized Release builds. Grant Screen Recording on first launch."
        />
        <div className="mt-10 grid gap-6 lg:grid-cols-3">
          <motion.div
            initial={reduce ? false : { opacity: 0, y: 16 }}
            whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ type: "spring", stiffness: 220, damping: 26 }}
            className="group rounded-2xl border bg-[var(--brand-ink)] p-6 text-zinc-200 lg:col-span-1"
          >
            <p className="font-mono text-[10px] uppercase tracking-widest text-zinc-500">
              Requirements
            </p>
            <ul className="mt-4 space-y-3">
              {requirements.map((req) => (
                <li key={req} className="flex items-start gap-2.5 text-sm text-zinc-400">
                  <Check className="mt-0.5 size-4 shrink-0 text-[var(--brand-accent)]" />
                  {req}
                </li>
              ))}
            </ul>
            <Link
              href="/docs/getting-started"
              className="mt-6 inline-block text-sm text-[var(--brand-accent)] hover:underline"
            >
              Step-by-step guide →
            </Link>
          </motion.div>

          <motion.div
            initial={reduce ? false : { opacity: 0, y: 16 }}
            whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ type: "spring", stiffness: 220, damping: 26, delay: 0.05 }}
            className="group rounded-2xl border bg-card/80 p-6 backdrop-blur-sm transition-all hover:border-[var(--brand-secondary)]/25 lg:col-span-1"
          >
            <div className="flex size-10 items-center justify-center rounded-xl bg-[var(--brand-secondary)]/10 text-[var(--brand-secondary)] ring-1 ring-[var(--brand-secondary)]/20">
              <Download className="size-5" />
            </div>
            <h3 className="mt-4 font-medium">Direct download</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
              Open the zip and drag Parcel to Applications. Sparkle handles
              updates.
            </p>
            <PrimaryButton href={DOWNLOAD_URL} className="mt-6 w-full">
              Download Parcel.zip
            </PrimaryButton>
          </motion.div>

          <motion.div
            initial={reduce ? false : { opacity: 0, y: 16 }}
            whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ type: "spring", stiffness: 220, damping: 26, delay: 0.1 }}
            className="group rounded-2xl border bg-card/80 p-6 backdrop-blur-sm transition-all hover:border-[var(--brand-accent)]/25 lg:col-span-1"
          >
            <div className="flex size-10 items-center justify-center rounded-xl bg-[var(--brand-accent)]/10 text-[var(--brand-accent)] ring-1 ring-[var(--brand-accent)]/20">
              <Terminal className="size-5" />
            </div>
            <p className="mt-4 font-mono text-xs uppercase tracking-widest text-muted-foreground">
              Homebrew
            </p>
            <h3 className="mt-2 font-medium">Install via cask</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
              Once published to a tap, one command installs Parcel.
            </p>
            <div className="mt-6 flex items-center gap-2 rounded-xl border border-[var(--brand-accent)]/10 bg-muted/40 py-2 pl-4 pr-2">
              <code className="min-w-0 flex-1 overflow-x-auto whitespace-nowrap font-mono text-[13px] [scrollbar-width:none]">
                {HOMEBREW_CMD}
              </code>
              <CopyButton value={HOMEBREW_CMD} label="Copy Homebrew command" />
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
