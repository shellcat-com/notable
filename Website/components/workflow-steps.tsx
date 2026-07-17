"use client";

import { Camera, ClipboardCopy, PenLine } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";
import { workflow } from "@/lib/site";
import { cn } from "@/lib/utils";

const STEP_ICONS = [Camera, PenLine, ClipboardCopy];

export function WorkflowSteps() {
  const reduce = useReducedMotion();

  return (
    <section id="workflow" className="relative border-b">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_80%_50%_at_50%_-20%,color-mix(in_srgb,var(--brand-secondary)_8%,transparent),transparent)]"
      />
      <div className="relative mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Workflow"
          title={
            <>
              Freeze, mark up,{" "}
              <span className="pb-gradient-text">ship</span> — in three steps.
            </>
          }
        />
        <div className="relative mt-12 grid grid-cols-1 gap-5 md:grid-cols-3">
          <div
            aria-hidden
            className="pointer-events-none absolute left-[16.67%] right-[16.67%] top-9 hidden h-px bg-gradient-to-r from-transparent via-[var(--brand-secondary)]/40 to-transparent md:block"
          />
          {workflow.map((step, i) => {
            const Icon = STEP_ICONS[i] ?? Camera;
            return (
              <motion.div
                key={step.step}
                initial={reduce ? false : { opacity: 0, y: 20 }}
                whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.2 }}
                transition={{
                  type: "spring",
                  stiffness: 220,
                  damping: 24,
                  delay: i * 0.08,
                }}
                className="group relative rounded-2xl border bg-card/80 p-6 backdrop-blur-sm transition-colors hover:border-[var(--brand-secondary)]/30 hover:bg-card"
              >
                <div className="flex items-center justify-between">
                  <span
                    className={cn(
                      "inline-flex size-10 items-center justify-center rounded-xl font-mono text-sm font-semibold",
                      "bg-[var(--brand-secondary)]/15 text-[var(--brand-secondary)] ring-1 ring-[var(--brand-secondary)]/25",
                      "transition-shadow group-hover:shadow-[0_0_24px_color-mix(in_srgb,var(--brand-secondary)_20%,transparent)]"
                    )}
                  >
                    {step.step}
                  </span>
                  <Icon className="size-5 text-muted-foreground transition-colors group-hover:text-[var(--brand-accent)]" />
                </div>
                <h3 className="mt-4 text-base font-medium">{step.title}</h3>
                <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">
                  {step.body}
                </p>
              </motion.div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
