"use client";

import * as React from "react";
import { motion, useReducedMotion } from "motion/react";
import {
  Camera,
  CloudUpload,
  Cpu,
  Eye,
  History,
  MousePointer2,
  PenTool,
  ScanText,
  ScrollText,
  Shield,
  Sparkles,
  Video,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { AnnotationToolsStrip } from "@/components/annotation-tools-strip";
import { SectionHeader } from "@/components/section-header";
import { features } from "@/lib/site";

const ICONS: Record<string, LucideIcon> = {
  camera: Camera,
  mouse: MousePointer2,
  pen: PenTool,
  scroll: ScrollText,
  video: Video,
  shield: Shield,
  sparkles: Sparkles,
  scan: ScanText,
  eye: Eye,
  history: History,
  cloud: CloudUpload,
  cpu: Cpu,
};

export function FeatureBento() {
  const reduce = useReducedMotion();

  const onGlowMove = React.useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      const el = e.currentTarget;
      const rect = el.getBoundingClientRect();
      el.style.setProperty("--mx", `${Math.round(e.clientX - rect.left)}px`);
      el.style.setProperty("--my", `${Math.round(e.clientY - rect.top)}px`);
    },
    []
  );

  return (
    <section id="features" className="relative border-b bg-muted/20">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_70%_50%_at_50%_0%,color-mix(in_srgb,var(--brand-secondary)_7%,transparent),transparent_70%)]"
      />
      <div className="relative mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Capabilities"
          title={
            <>
              Everything you need.{" "}
              <span className="pb-gradient-text">Nothing you don&apos;t.</span>
            </>
          }
          subtitle="One menu bar app for Capture, annotation, censoring, beautify, recording, scroll-stitching, and optional upload — all on your Mac."
        />
        <AnnotationToolsStrip />
        <ul
          role="list"
          className="mt-12 grid list-none grid-cols-1 gap-4 sm:grid-cols-2 sm:[grid-auto-rows:minmax(10rem,auto)] lg:grid-cols-3 lg:[grid-auto-flow:dense]"
        >
          {features.map((item, i) => {
            const size = item.size ?? "sm";
            const Icon = item.icon ? ICONS[item.icon] : null;
            const spansWide = size === "wide";
            const spansTall = size === "tall";

            return (
              <li
                key={item.id}
                className={cn(
                  spansWide && "sm:col-span-2",
                  spansTall && "sm:row-span-2"
                )}
              >
                <motion.div
                  initial={reduce ? false : { opacity: 0, y: 22 }}
                  whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
                  viewport={{ once: true, amount: 0.15 }}
                  transition={
                    reduce
                      ? { duration: 0 }
                      : {
                          type: "spring",
                          stiffness: 220,
                          damping: 24,
                          delay: Math.min(i * 0.05, 0.5),
                        }
                  }
                  onPointerMove={reduce ? undefined : onGlowMove}
                  className="group relative flex h-full flex-col overflow-hidden rounded-2xl border bg-card/80 p-6 backdrop-blur-sm transition-all duration-300 hover:-translate-y-0.5 hover:border-[var(--brand-secondary)]/25 hover:shadow-[0_8px_32px_color-mix(in_srgb,var(--brand-secondary)_8%,transparent)]"
                  style={
                    { "--mx": "50%", "--my": "50%" } as React.CSSProperties
                  }
                >
                  <div
                    aria-hidden
                    className="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-500 group-hover:opacity-100"
                    style={{
                      background:
                        "radial-gradient(260px circle at var(--mx) var(--my), color-mix(in srgb, var(--brand-secondary) 12%, transparent), transparent 72%)",
                    }}
                  />
                  {Icon && (
                    <div className="relative mb-4 inline-flex">
                      <span
                        aria-hidden
                        className="absolute inset-0 rounded-xl bg-violet-500/30 blur-md opacity-0 transition-opacity group-hover:opacity-100"
                      />
                      <span className="relative flex size-10 items-center justify-center rounded-xl bg-[var(--brand-secondary)]/10 text-[var(--brand-secondary)] ring-1 ring-[var(--brand-secondary)]/20">
                        <Icon className="size-5" strokeWidth={1.75} />
                      </span>
                    </div>
                  )}
                  <h3 className="text-lg font-semibold tracking-tight">
                    {item.title}
                  </h3>
                  <p className="mt-2 flex-1 text-sm leading-relaxed text-foreground/75">
                    {item.body}
                  </p>
                </motion.div>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
