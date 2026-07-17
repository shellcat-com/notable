"use client";

import { motion, useReducedMotion } from "motion/react";
import { stats } from "@/lib/site";

export function StatsBand() {
  const reduce = useReducedMotion();

  return (
    <section
      aria-label="Key metrics"
      className="relative border-b border-border/40 bg-[var(--brand-ink)]"
    >
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[linear-gradient(90deg,transparent_0%,color-mix(in_srgb,var(--brand-accent)_6%,transparent)_50%,transparent_100%)]"
      />
      <div className="relative mx-auto max-w-6xl px-4 py-10 md:py-12">
        <dl className="grid grid-cols-2 gap-8 sm:grid-cols-4 sm:gap-6">
          {stats.map((s, i) => (
            <motion.div
              key={s.label}
              initial={reduce ? false : { opacity: 0, y: 12 }}
              whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{
                type: "spring",
                stiffness: 240,
                damping: 28,
                delay: i * 0.06,
              }}
              className="relative text-center sm:text-left"
            >
              {i > 0 && (
                <div
                  aria-hidden
                  className="absolute -left-3 top-1/2 hidden h-10 w-px -translate-y-1/2 bg-border/60 sm:block"
                />
              )}
              <dt className="font-mono text-4xl font-semibold tabular-nums tracking-tight text-zinc-50 md:text-5xl">
                {s.value}
              </dt>
              <dd className="mt-1.5 text-sm text-zinc-300">{s.label}</dd>
            </motion.div>
          ))}
        </dl>
      </div>
    </section>
  );
}
