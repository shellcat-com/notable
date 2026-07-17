"use client";

import { BookOpen } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";
import { guides } from "@/lib/site";

export function GuidesGrid() {
  const reduce = useReducedMotion();

  return (
    <section id="guides" className="border-b bg-muted/20">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Guides"
          title="Workflow recipes for daily Capture work."
        />
        <div className="mt-10 grid gap-4 sm:grid-cols-2">
          {guides.map((guide, i) => (
            <motion.article
              key={guide.title}
              initial={reduce ? false : { opacity: 0, y: 18 }}
              whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
              viewport={{ once: true, amount: 0.2 }}
              transition={{
                type: "spring",
                stiffness: 220,
                damping: 24,
                delay: i * 0.06,
              }}
              className="rounded-2xl border bg-card p-6"
            >
              <BookOpen className="size-5 text-violet-400" />
              <h3 className="mt-4 font-medium">{guide.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                {guide.body}
              </p>
            </motion.article>
          ))}
        </div>
      </div>
    </section>
  );
}
