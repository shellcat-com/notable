"use client";

import { motion, useReducedMotion } from "motion/react";
import { DeviceFrame, EditorPreview } from "@/components/editor-preview";
import { SectionHeader } from "@/components/section-header";

export function ShowcaseSection() {
  const reduce = useReducedMotion();

  return (
    <section className="relative overflow-hidden border-b">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_80%_60%_at_50%_100%,color-mix(in_srgb,var(--brand-secondary)_12%,transparent),transparent_70%)]"
      />
      <div className="relative mx-auto max-w-6xl px-4 py-16 md:py-28">
        <SectionHeader
          kicker="Editor"
          align="center"
          title={
            <>
              A Capture studio you&apos;d expect from a{" "}
              <span className="pb-gradient-text">professional</span> tool.
            </>
          }
          subtitle="Fourteen annotation Tools, on-device Vision, Beautify, and one render pipeline — what you see is exactly what copies or saves."
        />
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 32 }}
          whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ type: "spring", stiffness: 160, damping: 26 }}
          className="relative mx-auto mt-14 max-w-4xl"
        >
          <div
            aria-hidden
            className="pointer-events-none absolute -inset-8 rounded-[2rem] bg-gradient-to-b from-[var(--brand-accent)]/10 via-[var(--brand-secondary)]/5 to-transparent blur-3xl"
          />
          <DeviceFrame tab="Parcel — Editor" url="parcel.parable.dev/editor">
            <EditorPreview />
          </DeviceFrame>
          <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
            {["On screen = saved", "Capture-point coords", "Sandboxed"].map(
              (tag) => (
                <span
                  key={tag}
                  className="rounded-full border border-white/15 bg-white/5 px-3 py-1 font-mono text-[11px] uppercase tracking-wider text-zinc-300"
                >
                  {tag}
                </span>
              )
            )}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
