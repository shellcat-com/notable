"use client";

import * as React from "react";
import { Apple } from "lucide-react";
import { DitherAurora } from "@/components/parable/dither-aurora";
import { PrimaryButton } from "@/components/primary-button";
import { DOWNLOAD_URL, faqs, theme } from "@/lib/site";
import { ChevronDown } from "lucide-react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";
import { cn } from "@/lib/utils";

export function FaqSection() {
  const [open, setOpen] = React.useState<number | null>(0);
  const reduce = useReducedMotion();

  return (
    <section id="faq" className="border-b bg-muted/15">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader kicker="FAQ" title="Common questions." />
        <ul className="mt-10 divide-y overflow-hidden rounded-2xl border border-border/80 bg-card/90 backdrop-blur-sm">
          {faqs.map((item, i) => {
            const isOpen = open === i;
            return (
              <li key={item.q}>
                <button
                  type="button"
                  onClick={() => setOpen(isOpen ? null : i)}
                  aria-expanded={isOpen}
                  className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left transition-colors hover:bg-muted/40"
                >
                  <span className="font-medium text-foreground">{item.q}</span>
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
                      <p className="px-5 pb-4 text-sm leading-relaxed text-foreground/75">
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
    <section className="dark-surface relative overflow-hidden border-t border-white/5">
      <DitherAurora
        className="absolute inset-0 bg-[var(--brand-ink)] opacity-50"
        speed={0.06}
        pixelSize={5}
        colors={[...theme.aurora]}
        background={theme.ink}
        aria-hidden
      >
        <span />
      </DitherAurora>

      {/* Radial scrim — keeps text readable (Linear/Perplexity pattern) */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_70%_60%_at_50%_50%,rgba(0,0,0,0.55)_0%,rgba(7,7,8,0.92)_100%)]"
      />

      <div className="relative mx-auto max-w-3xl px-4 py-24 text-center md:py-32">
        <div className="mx-auto max-w-xl rounded-3xl border border-white/10 bg-black/25 px-6 py-12 backdrop-blur-md md:px-10 md:py-14">
          <p className="font-mono text-xs font-medium uppercase tracking-[0.2em] text-zinc-300">
            Free · Open source · MIT
          </p>
          <h2 className="mt-5 text-3xl font-semibold tracking-tight text-white md:text-5xl lg:text-6xl">
            Ready to{" "}
            <span className="pb-gradient-text pb-gradient-glow">Capture</span>?
          </h2>
          <p className="mx-auto mt-5 max-w-md text-base leading-relaxed text-zinc-200 md:text-lg">
            Private by default. Built for daily macOS work — from the Parable
            ecosystem.
          </p>
          <div className="mt-10 flex flex-col items-center gap-3">
            <PrimaryButton href={DOWNLOAD_URL} className="gap-2.5 px-8">
              <Apple className="size-4" />
              Download Parcel for macOS
            </PrimaryButton>
            <p className="font-mono text-xs text-zinc-400">
              Compatible with Apple Silicon and Intel · macOS 13+
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
