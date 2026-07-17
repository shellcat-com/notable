"use client";

import Link from "next/link";
import { ArrowUpRight, BookOpen } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";

const guideLinks = [
  {
    title: "Redact sensitive text locally",
    body: "Inspect Capture → Recognize Text → Censor Detected Sensitive Text. Regex runs on-device via Vision.",
    href: "/docs/editor",
  },
  {
    title: "Scroll a long page",
    body: "In the Overlay choose Scroll Capture, drag a tall region, then add frames from the menu bar and finish.",
    href: "/docs/capture",
  },
  {
    title: "Click-to-edit any annotation",
    body: "Switch to Select, click an Annotation, then use the style bar to change stroke, color, arrow style, or censor mode.",
    href: "/docs/editor",
  },
  {
    title: "Record with system audio",
    body: "Choose Record Region from the menu bar, drag a Selection in the Overlay, then save. MP4 includes system audio.",
    href: "/docs/recording",
  },
  {
    title: "Translate text on-device",
    body: "Inspect Capture → Recognize Text → Translate On-Device. Uses Apple Translation on macOS 26+ — nothing leaves your Mac.",
    href: "/docs/privacy",
  },
  {
    title: "Save a brand kit",
    body: "Enable Beautify, tune padding and gradient, then save a named kit from the Beautify panel.",
    href: "/docs/editor",
  },
  {
    title: "Upload to Supabase",
    body: "Paste project URL, anon key, and bucket in Preferences. Upload from the Editor copies the link.",
    href: "/docs/supabase",
  },
  {
    title: "Export a recording as GIF",
    body: "After stopping a recording, open the trim window and export GIF for lightweight sharing.",
    href: "/docs/recording",
  },
] as const;

export function GuidesGrid() {
  const reduce = useReducedMotion();

  return (
    <section id="guides" className="border-b bg-muted/20">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <div className="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
          <SectionHeader
            kicker="Guides"
            title={
              <>
                Recipes for daily{" "}
                <span className="pb-gradient-text">Capture</span> work.
              </>
            }
            subtitle="Each card links to the full guide in the docs."
          />
          <Link
            href="/docs"
            className="inline-flex shrink-0 items-center gap-1.5 text-sm font-medium text-[var(--brand-secondary)] transition-colors hover:text-[var(--brand-accent)]"
          >
            All documentation <ArrowUpRight className="size-4" />
          </Link>
        </div>
        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {guideLinks.map((guide, i) => (
            <motion.div
              key={guide.title}
              initial={reduce ? false : { opacity: 0, y: 18 }}
              whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
              viewport={{ once: true, amount: 0.15 }}
              transition={{
                type: "spring",
                stiffness: 220,
                damping: 24,
                delay: Math.min(i * 0.04, 0.32),
              }}
            >
              <Link
                href={guide.href}
                className="group relative flex h-full flex-col rounded-2xl border bg-card/80 p-5 backdrop-blur-sm transition-all duration-300 hover:-translate-y-0.5 hover:border-[var(--brand-accent)]/25 hover:shadow-[0_8px_32px_color-mix(in_srgb,var(--brand-accent)_8%,transparent)]"
              >
                <div className="flex items-start justify-between gap-2">
                  <BookOpen className="size-5 shrink-0 text-[var(--brand-accent)]" />
                  <ArrowUpRight className="size-4 shrink-0 text-muted-foreground/0 transition-all group-hover:text-[var(--brand-accent)]/80" />
                </div>
                <h3 className="mt-3 text-sm font-medium leading-snug">
                  {guide.title}
                </h3>
                <p className="mt-2 flex-1 text-sm leading-relaxed text-foreground/75">
                  {guide.body}
                </p>
              </Link>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
