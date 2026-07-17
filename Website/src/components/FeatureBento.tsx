'use client';

import * as React from 'react';
import { motion, useReducedMotion } from 'motion/react';
import {
  Camera,
  CloudUpload,
  Eye,
  History,
  PenTool,
  ScrollText,
  Sparkles,
  Video,
  type LucideIcon,
} from 'lucide-react';
import { cn } from '../lib/utils';

const ICONS: Record<string, LucideIcon> = {
  camera: Camera,
  pen: PenTool,
  scroll: ScrollText,
  video: Video,
  sparkles: Sparkles,
  eye: Eye,
  history: History,
  cloud: CloudUpload,
};

export type BentoSize = 'sm' | 'wide' | 'tall' | 'lg';

export interface BentoItem {
  id: string;
  title: string;
  body: string;
  size?: BentoSize;
  icon?: string;
  visual?: React.ReactNode;
}

function hexToRgba(hex: string, alpha: number) {
  const n = Number.parseInt(hex.replace('#', ''), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
}

export function FeatureBento({ items, eyebrow, title }: { items: BentoItem[]; eyebrow: string; title: string }) {
  const reduce = useReducedMotion() ?? false;
  const accent = '#8b5cf6';

  const onGlowMove = React.useCallback((e: React.PointerEvent<HTMLDivElement>) => {
    const el = e.currentTarget;
    const rect = el.getBoundingClientRect();
    el.style.setProperty('--mx', `${Math.round(e.clientX - rect.left)}px`);
    el.style.setProperty('--my', `${Math.round(e.clientY - rect.top)}px`);
  }, []);

  return (
    <section id="features" className="border-t border-white/8 py-24">
      <div className="mx-auto max-w-6xl px-6">
        <p className="section-kicker">{eyebrow}</p>
        <h2 className="mt-3 max-w-2xl text-3xl font-bold tracking-tight md:text-4xl">{title}</h2>
        <ul
          role="list"
          className="mt-12 grid list-none grid-cols-1 gap-4 sm:grid-cols-2 sm:[grid-auto-rows:minmax(10rem,auto)] lg:grid-cols-3 lg:[grid-auto-flow:dense]"
        >
          {items.map((item, i) => {
            const size = item.size ?? 'sm';
            const Icon = item.icon ? ICONS[item.icon] : null;
            const spansWide = size === 'wide' || size === 'lg';
            const spansTall = size === 'tall' || size === 'lg';

            return (
              <li key={item.id} className={cn(spansWide && 'sm:col-span-2', spansTall && 'sm:row-span-2')}>
                <motion.div
                  initial={reduce ? false : { opacity: 0, y: 22 }}
                  whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
                  viewport={{ once: true, amount: 0.15 }}
                  transition={
                    reduce
                      ? { duration: 0 }
                      : { type: 'spring', stiffness: 220, damping: 24, delay: Math.min(i * 0.07, 0.56) }
                  }
                  onPointerMove={reduce ? undefined : onGlowMove}
                  className="group relative flex h-full flex-col overflow-hidden rounded-2xl border border-white/10 bg-white/[0.02] p-6 backdrop-blur-sm transition-colors hover:border-white/25 hover:bg-white/[0.035]"
                  style={{ '--mx': '50%', '--my': '50%' } as React.CSSProperties}
                >
                  <div
                    aria-hidden
                    className="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-500 group-hover:opacity-100"
                    style={{
                      background: `radial-gradient(260px circle at var(--mx) var(--my), ${hexToRgba(accent, 0.16)}, transparent 72%)`,
                    }}
                  />
                  {item.visual && <div className="relative mb-5 min-h-24 flex-1">{item.visual}</div>}
                  {Icon && (
                    <div className="relative mb-4 inline-flex">
                      <span
                        aria-hidden
                        className="absolute inset-0 rounded-xl bg-violet/40 blur-md"
                        style={{ animation: reduce ? undefined : 'pulse 6s ease-in-out infinite' }}
                      />
                      <span className="relative flex size-10 items-center justify-center rounded-xl bg-white/[0.06] text-violet ring-1 ring-white/10">
                        <Icon className="size-5" strokeWidth={1.75} />
                      </span>
                    </div>
                  )}
                  <h3 className="text-lg font-semibold tracking-tight">{item.title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-white/60">{item.body}</p>
                </motion.div>
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
}
