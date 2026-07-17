"use client";

import * as React from "react";
import { ChevronDown } from "lucide-react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";
import { ShimmerButton } from "@/components/parable/shimmer-button";
import { DOWNLOAD_URL, faqs } from "@/lib/site";
import { cn } from "@/lib/utils";

export function FaqSection() {
  const [open, setOpen] = React.useState<number | null>(0);
  const reduce = useReducedMotion();

  return (
    <section id="faq" className="border-b bg-muted/20">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader kicker="FAQ" title="Common questions." />
        <ul className="mt-10 divide-y rounded-2xl border bg-card">
          {faqs.map((item, i) => {
            const isOpen = open === i;
            return (
              <li key={item.q}>
                <button
                  type="button"
                  onClick={() => setOpen(isOpen ? null : i)}
                  aria-expanded={isOpen}
                  className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left transition-colors hover:bg-muted/30"
                >
                  <span className="font-medium">{item.q}</span>
                  <ChevronDown
                    className={cn(
                      "size-4 shrink-0 text-muted-foreground transition-transform duration-300",
                      isOpen && "rotate-180"
                    )}
                  />
                </button>
                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      initial={reduce ? false : { height: 0, opacity: 0 }}
                      animate={reduce ? undefined : { height: "auto", opacity: 1 }}
                      exit={reduce ? undefined : { height: 0, opacity: 0 }}
                      transition={{ duration: 0.25, ease: [0.22, 1, 0.36, 1] }}
                      className="overflow-hidden"
                    >
                      <p className="px-5 pb-4 text-sm leading-relaxed text-muted-foreground">
                        {item.a}
                      </p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}

export function CtaBanner() {
  return (
    <section className="relative overflow-hidden">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-gradient-to-br from-violet-600/10 via-transparent to-fuchsia-600/10"
      />
      <div className="relative mx-auto max-w-6xl px-4 py-20 text-center md:py-28">
        <h2 className="text-3xl font-semibold tracking-tight md:text-4xl">
          Ready to Capture?
        </h2>
        <p className="mx-auto mt-4 max-w-lg text-muted-foreground">
          Free, open source, and built for daily macOS work — private by default.
        </p>
        <ShimmerButton
          as="a"
          href={DOWNLOAD_URL}
          className="mt-8 inline-flex"
          shimmerColor="#c4b5fd"
        >
          Download Parcel
        </ShimmerButton>
      </div>
    </section>
  );
}
