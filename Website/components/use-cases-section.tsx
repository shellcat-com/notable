"use client";

import * as React from "react";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";
import { cn } from "@/lib/utils";

const personas = [
  {
    tag: "Developers",
    title: "Bug reports that actually help",
    body: "Freeze the UI, arrow to the problem, censor API keys, and paste into Slack — full resolution, no cloud upload required.",
  },
  {
    tag: "Designers",
    title: "Ship-ready Captures",
    body: "Beautify with gradients, window chrome, and brand kits. What you see in the Editor is exactly what exports.",
  },
  {
    tag: "Support",
    title: "Redact before you share",
    body: "Auto-detect faces and regex PII with on-device Vision. Censor sensitive lines before the Capture leaves your Mac.",
  },
  {
    tag: "Writers",
    title: "Scroll long pages",
    body: "Stitch tall content with Scroll Capture and on-device Vision registration — no browser extension needed.",
  },
  {
    tag: "Educators",
    title: "Record walkthroughs",
    body: "Region recording with system audio, trim editor, and local GIF export for lightweight sharing.",
  },
  {
    tag: "Teams",
    title: "Optional upload",
    body: "Configure your own Supabase bucket once, upload from the Editor, and copy a public link.",
  },
] as const;

export function UseCasesSection() {
  const [active, setActive] = React.useState(0);
  const reduce = useReducedMotion();
  const current = personas[active];

  return (
    <section className="border-b bg-muted/10">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Use cases"
          title={
            <>
              Parcel is made{" "}
              <span className="pb-gradient-text">for you</span>.
            </>
          }
          subtitle="Pick a workflow — same app, different daily Capture jobs."
        />

        <div className="mt-12 grid gap-8 lg:grid-cols-[1fr_1.1fr] lg:gap-12">
          <div className="flex flex-wrap gap-2">
            {personas.map((p, i) => (
              <button
                key={p.tag}
                type="button"
                onClick={() => setActive(i)}
                aria-pressed={active === i}
                className={cn(
                  "rounded-full border px-3.5 py-1.5 text-sm transition-all",
                  active === i
                    ? "border-[var(--brand-accent)]/50 bg-[var(--brand-accent)]/15 text-[var(--brand-accent)]"
                    : "border-border/60 text-muted-foreground hover:border-border hover:text-foreground"
                )}
              >
                {p.tag}
              </button>
            ))}
          </div>

          <motion.div
            key={current.tag}
            initial={reduce ? false : { opacity: 0, x: 12 }}
            animate={reduce ? undefined : { opacity: 1, x: 0 }}
            transition={{ type: "spring", stiffness: 260, damping: 28 }}
            className="rounded-2xl border bg-card/80 p-8 backdrop-blur-sm"
          >
            <p className="font-mono text-[11px] uppercase tracking-widest text-[var(--brand-accent)]">
              For {current.tag}
            </p>
            <h3 className="mt-3 text-2xl font-semibold tracking-tight">
              {current.title}
            </h3>
            <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
              {current.body}
            </p>
            <Link
              href="/docs/getting-started"
              className="mt-6 inline-flex items-center gap-1.5 text-sm font-medium text-[var(--brand-secondary)] transition-colors hover:text-[var(--brand-accent)]"
            >
              Get started <ArrowRight className="size-4" />
            </Link>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
