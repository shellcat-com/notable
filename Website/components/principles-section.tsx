"use client";

import { Cpu, Keyboard, Shield, Zap } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";

const principles = [
  {
    icon: Zap,
    title: "Built for speed",
    body: "ScreenCaptureKit freeze, Carbon hotkeys, and a native SwiftUI shell — no Electron, no web views.",
  },
  {
    icon: Keyboard,
    title: "Keyboard-first",
    body: "Configurable global hotkey, Overlay shortcuts, and Editor commands designed for daily muscle memory.",
  },
  {
    icon: Shield,
    title: "Private by default",
    body: "OCR, faces, translation, and regex redaction stay on your Mac. Zero cloud AI calls.",
  },
  {
    icon: Cpu,
    title: "One render pipeline",
    body: "Adjustments, censors, annotations, and Beautify compose once — display and export match exactly.",
  },
] as const;

export function PrinciplesSection() {
  const reduce = useReducedMotion();

  return (
    <section className="border-b bg-muted/15">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Philosophy"
          title="Opinionated software for people who ship Captures daily."
          subtitle="Inspired by tools like Linear and Monologue — native, fast, and respectful of your pixels."
        />
        <div className="mt-12 grid gap-px overflow-hidden rounded-2xl border bg-border/40 sm:grid-cols-2">
          {principles.map((item, i) => {
            const Icon = item.icon;
            return (
              <motion.div
                key={item.title}
                initial={reduce ? false : { opacity: 0 }}
                whileInView={reduce ? undefined : { opacity: 1 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05, duration: 0.4 }}
                className="group bg-card/80 p-8 transition-colors hover:bg-card"
              >
                <div className="mb-4 inline-flex size-10 items-center justify-center rounded-xl bg-[var(--brand-secondary)]/10 text-[var(--brand-secondary)] ring-1 ring-[var(--brand-secondary)]/20 transition-shadow group-hover:shadow-[0_0_24px_color-mix(in_srgb,var(--brand-secondary)_25%,transparent)]">
                  <Icon className="size-5" strokeWidth={1.75} />
                </div>
                <h3 className="text-lg font-semibold tracking-tight">
                  {item.title}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                  {item.body}
                </p>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
