"use client";

import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";
import { shortcuts } from "@/lib/site";

export function ShortcutsTable() {
  const reduce = useReducedMotion();

  return (
    <section id="shortcuts" className="relative border-b">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_60%_40%_at_80%_50%,color-mix(in_srgb,var(--brand-tertiary)_6%,transparent),transparent)]"
      />
      <div className="relative mx-auto max-w-6xl px-4 py-16 md:py-24">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <SectionHeader
            kicker="Shortcuts"
            title={
              <>
                Keyboard-first{" "}
                <span className="pb-gradient-text">design</span>.
              </>
            }
            subtitle="Every action has a shortcut. The global Capture hotkey is configurable in Preferences."
          />
          <Link
            href="/docs/shortcuts"
            className="inline-flex shrink-0 items-center gap-1.5 text-sm font-medium text-[var(--brand-secondary)] hover:text-[var(--brand-accent)]"
          >
            Full reference <ArrowRight className="size-4" />
          </Link>
        </div>
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 16 }}
          whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ type: "spring", stiffness: 220, damping: 26 }}
          className="mt-10 overflow-hidden rounded-2xl border bg-card/50"
        >
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-[var(--brand-secondary)]/[0.04] text-left">
                <th className="px-5 py-3.5 font-mono text-xs uppercase tracking-wider text-muted-foreground">
                  Shortcut
                </th>
                <th className="px-5 py-3.5 font-mono text-xs uppercase tracking-wider text-muted-foreground">
                  Action
                </th>
              </tr>
            </thead>
            <tbody>
              {shortcuts.map((row) => (
                <tr
                  key={row.keys}
                  className="group border-b border-border/60 transition-colors last:border-0 hover:bg-[var(--brand-secondary)]/[0.03]"
                >
                  <td className="px-5 py-3.5">
                    <kbd className="inline-flex rounded-md border border-[var(--brand-secondary)]/15 bg-muted/60 px-2.5 py-1 font-mono text-xs transition-colors group-hover:border-[var(--brand-secondary)]/30">
                      {row.keys}
                    </kbd>
                  </td>
                  <td className="px-5 py-3.5 text-muted-foreground transition-colors group-hover:text-foreground/90">
                    {row.action}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </motion.div>
      </div>
    </section>
  );
}
