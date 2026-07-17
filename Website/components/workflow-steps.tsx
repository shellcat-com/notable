"use client";

import { Camera, ClipboardCopy, PenLine } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";
import { workflow } from "@/lib/site";

const STEP_ICONS = [Camera, PenLine, ClipboardCopy];

export function WorkflowSteps() {
  const reduce = useReducedMotion();

  return (
    <section id="workflow" className="border-b">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Workflow"
          title="Freeze, mark up, ship — in three steps."
        />
        <div className="mt-10 grid grid-cols-1 gap-5 md:grid-cols-3">
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
                className="rounded-2xl border bg-card p-6"
              >
                <div className="flex items-center justify-between">
                  <Icon className="size-5 text-muted-foreground" />
                  <span className="font-mono text-xs text-muted-foreground">
                    {step.step}
                  </span>
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
