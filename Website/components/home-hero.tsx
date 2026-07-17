"use client";

import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { DitherAurora } from "@/components/parable/dither-aurora";
import { ShimmerButton } from "@/components/parable/shimmer-button";
import { VelocityMarquee } from "@/components/parable/velocity-marquee";
import { DeviceFrame, EditorPreview } from "@/components/editor-preview";
import { Badge } from "@/components/section-header";
import { DOWNLOAD_URL, logos, stats } from "@/lib/site";

const marqueeItems = logos.map((name) => (
  <span key={name} className="text-zinc-400">
    {name}
    <span className="mx-3 text-zinc-600">/</span>
  </span>
));

const fadeUp = {
  hidden: { opacity: 0, y: 18 },
  show: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: {
      type: "spring" as const,
      stiffness: 220,
      damping: 26,
      delay: i * 0.08,
    },
  }),
};

export function HomeHero() {
  const reduce = useReducedMotion();

  return (
    <section className="relative overflow-hidden border-b bg-[#0a0a0b]">
      <DitherAurora
        className="absolute inset-0"
        speed={0.12}
        pixelSize={4}
        aria-hidden
      >
        <span />
      </DitherAurora>
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-black/30"
      />

      <div className="relative mx-auto max-w-6xl px-4 pb-16 pt-12 md:pb-20 md:pt-16">
        <div className="grid items-center gap-12 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)] lg:gap-10">
          <motion.div
            initial={reduce ? false : "hidden"}
            animate="show"
            className="max-w-3xl"
          >
            <motion.p
              custom={0}
              variants={fadeUp}
              className="font-mono text-xs uppercase tracking-widest text-zinc-400"
            >
              Native macOS · MIT · Open source
            </motion.p>
            <motion.h1
              custom={1}
              variants={fadeUp}
              className="mt-4 text-4xl font-semibold leading-[1.05] tracking-tight text-zinc-50 md:text-6xl lg:text-7xl"
            >
              The{" "}
              <span className="bg-gradient-to-r from-violet-400 to-fuchsia-400 bg-clip-text text-transparent">
                Capture
              </span>{" "}
              studio Apple forgot to{" "}
              <em className="font-display font-normal not-italic text-zinc-200">
                ship
              </em>
              .
            </motion.h1>
            <motion.p
              custom={2}
              variants={fadeUp}
              className="mt-6 max-w-xl text-lg leading-relaxed text-zinc-300"
            >
              Freeze your screen, annotate with fourteen tools, censor with local
              Vision, beautify for ship-ready output, record, scroll-capture, and
              upload when you choose — from the Parable ecosystem.
            </motion.p>
            <motion.div custom={3} variants={fadeUp} className="mt-6 flex flex-wrap gap-2">
              <Badge variant="violet">macOS 13+</Badge>
              <Badge variant="mint">On-device only</Badge>
              <Badge>MIT License</Badge>
            </motion.div>
            <motion.div
              custom={4}
              variants={fadeUp}
              className="mt-8 flex flex-wrap items-center gap-4"
            >
              <ShimmerButton
                as="a"
                href={DOWNLOAD_URL}
                aria-label="Download Parcel for macOS"
                shimmerColor="#c4b5fd"
              >
                Download for macOS <ArrowRight className="size-4" />
              </ShimmerButton>
              <Link
                href="#workflow"
                className="inline-flex items-center gap-2 rounded-full border border-white/20 px-5 py-3 text-sm font-medium text-zinc-200 transition-colors hover:bg-white/10"
              >
                See how it works
              </Link>
            </motion.div>
            <motion.dl
              custom={5}
              variants={fadeUp}
              className="mt-10 grid grid-cols-2 gap-6 border-t border-white/10 pt-8 sm:grid-cols-4"
            >
              {stats.map((s) => (
                <div key={s.label}>
                  <dt className="font-mono text-3xl font-semibold tabular-nums tracking-tight text-zinc-50">
                    {s.value}
                  </dt>
                  <dd className="mt-1 text-sm text-zinc-400">{s.label}</dd>
                </div>
              ))}
            </motion.dl>
          </motion.div>

          <motion.div
            initial={reduce ? false : { opacity: 0, y: 24, scale: 0.98 }}
            animate={reduce ? undefined : { opacity: 1, y: 0, scale: 1 }}
            transition={{
              type: "spring",
              stiffness: 180,
              damping: 24,
              delay: 0.15,
            }}
            className="relative"
          >
            <div
              aria-hidden
              className="pointer-events-none absolute -inset-4 rounded-3xl bg-gradient-to-br from-violet-500/20 via-transparent to-fuchsia-500/15 blur-2xl"
            />
            <DeviceFrame>
              <EditorPreview />
            </DeviceFrame>
          </motion.div>
        </div>
      </div>

      <div className="relative border-t border-white/10 bg-black/40 py-4 backdrop-blur-sm">
        <VelocityMarquee
          items={marqueeItems}
          baseSpeed={40}
          className="text-base font-medium md:text-lg"
        />
      </div>
    </section>
  );
}
