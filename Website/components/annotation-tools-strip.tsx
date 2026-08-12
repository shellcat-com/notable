"use client";

import { motion, useReducedMotion } from "motion/react";
import { annotationTools } from "@/lib/site";

export function AnnotationToolsStrip() {
  const reduce = useReducedMotion();

  return (
    <motion.div
      initial={reduce ? false : { opacity: 0, y: 12 }}
      whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.4 }}
      transition={{ type: "spring", stiffness: 220, damping: 26 }}
      className="mt-10"
    >
      <p className="mb-4 font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
        Fourteen Tools · One toolbar
      </p>
      <div className="flex flex-wrap gap-2">
        {annotationTools.map((tool) => (
          <span
            key={tool}
            className="inline-flex items-center rounded-full border border-[var(--brand-secondary)]/15 bg-[var(--brand-secondary)]/[0.06] px-3 py-1.5 font-mono text-[11px] text-foreground/80 transition-colors hover:border-[var(--brand-accent)]/30 hover:bg-[var(--brand-accent)]/10 md:text-xs"
          >
            {tool}
          </span>
        ))}
      </div>
    </motion.div>
  );
}
