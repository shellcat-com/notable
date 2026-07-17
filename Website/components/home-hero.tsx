"use client";

import Link from "next/link";
import { Apple, ArrowRight } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { DitherAurora } from "@/components/parable/dither-aurora";
import { VelocityMarquee } from "@/components/parable/velocity-marquee";
import { PrimaryButton } from "@/components/primary-button";
import { ParcelMark } from "@/components/site-nav";
import { Badge } from "@/components/section-header";
import { DOWNLOAD_URL, GITHUB_URL, logos, theme } from "@/lib/site";

const marqueeItems = logos.map((name) => (
  <span key={name} className="text-zinc-400">
    {name}
    <span className="mx-3 text-zinc-600">/</span>
  </span>
));

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  show: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: {
      type: "spring" as const,
      stiffness: 220,
      damping: 28,
      delay: i * 0.07,
    },
  }),
};

export function HomeHero() {
  const reduce = useReducedMotion();

  return (
    <section className="dark-surface relative -mt-[4.25rem] overflow-hidden border-b border-white/5 pt-[4.25rem]">
      <DitherAurora
        className="absolute inset-0 bg-[var(--brand-ink)]"
        speed={0.09}
        pixelSize={4}
        colors={[...theme.aurora]}
        background={theme.ink}
        aria-hidden
      >
        <span />
      </DitherAurora>

      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_50%_40%_at_50%_0%,color-mix(in_srgb,var(--brand-accent)_14%,transparent),transparent_70%)]"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-[var(--brand-ink)]"
      />

      <div className="relative mx-auto max-w-6xl px-4 pb-10 pt-16 md:pb-14 md:pt-24">
        <motion.div
          initial={reduce ? false : "hidden"}
          animate="show"
          className="mx-auto max-w-3xl text-center"
        >
          <motion.div custom={0} variants={fadeUp} className="flex justify-center">
            <Link
              href="/docs/getting-started"
              className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs text-zinc-300 transition-colors hover:border-[var(--brand-accent)]/30 hover:bg-white/8"
            >
              <span className="rounded-full bg-[var(--brand-accent)]/20 px-2 py-0.5 font-mono text-[10px] uppercase tracking-wider text-[var(--brand-accent)]">
                v1.0
              </span>
              MIT licensed · Quick start guide
              <ArrowRight className="size-3 opacity-60" />
            </Link>
          </motion.div>

          <motion.div custom={1} variants={fadeUp} className="mt-8 flex justify-center">
            <ParcelMark className="size-16 rounded-2xl ring-1 ring-white/15" />
          </motion.div>

          <motion.p
            custom={2}
            variants={fadeUp}
            className="mt-6 font-mono text-xs uppercase tracking-[0.25em] text-zinc-300"
          >
            Native macOS · From Parable
          </motion.p>
          <motion.h1
            custom={3}
            variants={fadeUp}
            className="mt-4 text-4xl font-semibold leading-[1.02] tracking-tight text-white md:text-6xl lg:text-7xl"
          >
            Capture, mark up, and{" "}
            <em className="font-display font-normal not-italic text-zinc-200">
              ship
            </em>
            .
          </motion.h1>
          <motion.p
            custom={4}
            variants={fadeUp}
            className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-zinc-200 md:text-xl"
          >
            The menu bar studio for freeze-then-select Capture, fourteen Tools,
            on-device Vision, Beautify, and recording — no cloud AI, ever.
          </motion.p>
          <motion.div
            custom={5}
            variants={fadeUp}
            className="mt-6 flex flex-wrap items-center justify-center gap-2"
          >
            <Badge variant="mint">On-device only</Badge>
            <Badge variant="violet">macOS 13+</Badge>
            <Badge>MIT License</Badge>
          </motion.div>
          <motion.div
            custom={6}
            variants={fadeUp}
            className="mt-10 flex flex-wrap items-center justify-center gap-3"
          >
            <PrimaryButton href={DOWNLOAD_URL} className="gap-2.5 px-7 py-3.5">
              <Apple className="size-4" />
              Download for macOS
              <ArrowRight className="size-4 opacity-80" />
            </PrimaryButton>
            <Link
              href="/#features"
              className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/5 px-6 py-3.5 text-sm font-medium text-zinc-100 transition-all hover:border-[var(--brand-accent)]/50 hover:bg-white/10"
            >
              Explore features
            </Link>
          </motion.div>
          <motion.p
            custom={7}
            variants={fadeUp}
            className="mt-4 font-mono text-xs text-zinc-400"
          >
            Requires macOS 13.0+ · Apple Silicon & Intel ·{" "}
            <a
              href={GITHUB_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="text-zinc-300 underline-offset-2 hover:text-white hover:underline"
            >
              Source on GitHub
            </a>
          </motion.p>
        </motion.div>
      </div>

      <div className="relative border-t border-white/8 bg-black/40 py-3 backdrop-blur-sm">
        <VelocityMarquee
          items={marqueeItems}
          baseSpeed={32}
          className="text-sm font-medium md:text-base"
        />
      </div>
    </section>
  );
}
