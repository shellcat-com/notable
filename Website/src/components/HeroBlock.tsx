'use client';

import * as React from 'react';
import { motion, useReducedMotion } from 'motion/react';
import { ArrowRight, ChevronLeft, ChevronRight, Lock, RotateCw } from 'lucide-react';
import { cn } from '../lib/utils';

function hexToRgba(hex: string, alpha: number): string {
  let h = hex.replace('#', '').trim();
  if (h.length === 3) h = h.split('').map((c) => c + c).join('');
  const n = Number.parseInt(h, 16);
  if (h.length !== 6 || Number.isNaN(n)) return `rgba(139, 92, 246, ${alpha})`;
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
}

function useInjectedKeyframes(id: string, css: string) {
  React.useEffect(() => {
    if (typeof document === 'undefined' || document.getElementById(id)) return;
    const el = document.createElement('style');
    el.id = id;
    el.textContent = css;
    document.head.appendChild(el);
  }, [id, css]);
}

const KEYFRAMES = `
@keyframes pb-hero-glow-a {
  0%, 100% { transform: translate3d(0,0,0) scale(1); opacity: 0.45; }
  50% { transform: translate3d(6%,9%,0) scale(1.12); opacity: 0.62; }
}
@keyframes pb-hero-glow-b {
  0%, 100% { transform: translate3d(0,0,0) scale(1); opacity: 0.38; }
  50% { transform: translate3d(-7%,-8%,0) scale(1.1); opacity: 0.55; }
}
@media (prefers-reduced-motion: reduce) {
  [data-pb-hero-glow] { animation: none !important; transform: none !important; }
}
`;

export interface HeroStat {
  value: string;
  label: string;
}

export interface HeroSectionProps {
  eyebrow?: string;
  title: React.ReactNode;
  accentWord?: string;
  subtitle?: React.ReactNode;
  primaryHref?: string;
  primaryLabel?: string;
  secondaryHref?: string;
  secondaryLabel?: string;
  stats?: HeroStat[];
  children?: React.ReactNode;
  className?: string;
}

function renderAccentedTitle(title: React.ReactNode, accentWord?: string) {
  if (typeof title !== 'string' || !accentWord) return title;
  const idx = title.indexOf(accentWord);
  if (idx === -1) return title;
  return (
    <>
      {title.slice(0, idx)}
      <span className="bg-gradient-to-r from-violet to-fuchsia bg-clip-text text-transparent">{accentWord}</span>
      {title.slice(idx + accentWord.length)}
    </>
  );
}

const fadeUp = {
  hidden: { opacity: 0, y: 18 },
  show: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { type: 'spring' as const, stiffness: 220, damping: 26, delay: i * 0.08 },
  }),
};

export function HeroSection({
  eyebrow,
  title,
  accentWord,
  subtitle,
  primaryHref,
  primaryLabel,
  secondaryHref,
  secondaryLabel,
  stats,
  children,
  className,
}: HeroSectionProps) {
  useInjectedKeyframes('pb-hero-kf', KEYFRAMES);
  const reduce = useReducedMotion() ?? false;

  return (
    <section className={cn('relative px-6 pb-8 pt-28 md:pb-12 md:pt-32', className)}>
      <div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden">
        <div
          data-pb-hero-glow
          className="absolute -left-24 top-0 size-[480px] rounded-full blur-[100px]"
          style={{
            background: hexToRgba('#8b5cf6', 0.35),
            animation: reduce ? undefined : 'pb-hero-glow-a 16s ease-in-out infinite alternate',
          }}
        />
        <div
          data-pb-hero-glow
          className="absolute -right-32 top-24 size-[420px] rounded-full blur-[100px]"
          style={{
            background: hexToRgba('#ec4899', 0.28),
            animation: reduce ? undefined : 'pb-hero-glow-b 18s ease-in-out infinite alternate',
          }}
        />
      </div>

      <div className="relative mx-auto max-w-6xl">
        <motion.div
          initial={reduce ? false : 'hidden'}
          animate="show"
          className="max-w-3xl"
        >
          {eyebrow && (
            <motion.p custom={0} variants={fadeUp} className="section-kicker mb-4">
              {eyebrow}
            </motion.p>
          )}
          <motion.h1
            custom={1}
            variants={fadeUp}
            className="text-4xl font-bold tracking-tight md:text-6xl md:leading-[1.05]"
          >
            {renderAccentedTitle(title, accentWord)}
          </motion.h1>
          {subtitle && (
            <motion.p custom={2} variants={fadeUp} className="mt-6 max-w-2xl text-lg leading-relaxed text-white/65">
              {subtitle}
            </motion.p>
          )}
          <motion.div custom={3} variants={fadeUp} className="mt-8 flex flex-wrap gap-3">
            {primaryLabel && primaryHref && (
              <a href={primaryHref} className="btn-primary group" download={primaryHref.endsWith('.zip')}>
                {primaryLabel}
                <ArrowRight className="size-4 transition-transform group-hover:translate-x-0.5" strokeWidth={2.5} />
              </a>
            )}
            {secondaryLabel && secondaryHref && (
              <a href={secondaryHref} className="btn-secondary">
                {secondaryLabel}
              </a>
            )}
          </motion.div>
          {stats && stats.length > 0 && (
            <motion.dl
              custom={4}
              variants={fadeUp}
              className="mt-10 grid grid-cols-2 gap-6 border-t border-white/10 pt-8 sm:grid-cols-4"
            >
              {stats.map((s) => (
                <div key={s.label}>
                  <dt className="font-mono text-3xl font-semibold tabular-nums tracking-tight">{s.value}</dt>
                  <dd className="mt-1 text-sm text-white/50">{s.label}</dd>
                </div>
              ))}
            </motion.dl>
          )}
        </motion.div>
        {children && <div className="mt-14 md:mt-16">{children}</div>}
      </div>
    </section>
  );
}

const BROWSER_DROP =
  '0 1px 2px rgba(0,0,0,0.08), 0 12px 28px -10px rgba(0,0,0,0.28), 0 34px 64px -28px rgba(0,0,0,0.34)';

function TrafficLights() {
  return (
    <div className="flex shrink-0 items-center gap-2">
      {['#ff5f57', '#febc2e', '#28c840'].map((c) => (
        <span key={c} className="size-3 rounded-full" style={{ backgroundColor: c }} />
      ))}
    </div>
  );
}

function UrlBar({ url }: { url: string }) {
  return (
    <div className="flex min-w-0 flex-1 items-center gap-2 rounded-lg border border-black/5 bg-white/80 px-3 py-1.5 text-xs text-neutral-500 dark:border-white/10 dark:bg-neutral-950/80 dark:text-neutral-400">
      <Lock className="size-3 shrink-0 opacity-60" strokeWidth={2.5} />
      <span className="truncate font-mono">{url}</span>
      <RotateCw className="ml-auto size-3 shrink-0 opacity-50" strokeWidth={2.5} />
    </div>
  );
}

export function DeviceFrame({
  url = 'parcel.parable.dev',
  tab = 'Parcel — Editor',
  children,
  className,
}: {
  url?: string;
  tab?: string;
  children?: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        'relative overflow-hidden rounded-xl border border-white/10 bg-neutral-900 text-neutral-100',
        className,
      )}
      style={{ boxShadow: BROWSER_DROP }}
    >
      <div aria-hidden className="select-none">
        <div className="flex items-end gap-3 px-3.5 pt-3">
          <TrafficLights />
          <div className="flex min-w-0 items-center gap-1.5 rounded-t-lg border border-b-0 border-white/10 bg-neutral-950 px-3 py-1.5 text-xs font-medium">
            <span className="size-2 shrink-0 rounded-full bg-violet/80" />
            <span className="truncate">{tab}</span>
          </div>
        </div>
        <div className="flex items-center gap-2.5 border-t border-white/10 px-3.5 py-2">
          <div className="flex items-center gap-1 text-neutral-500">
            <ChevronLeft className="size-4" />
            <ChevronRight className="size-4" />
          </div>
          <UrlBar url={url} />
        </div>
      </div>
      <div className="relative overflow-hidden border-t border-white/10 bg-[#0a0c10] [aspect-ratio:16/10]">
        <div className="absolute inset-0">{children}</div>
        <div
          aria-hidden
          className="pointer-events-none absolute inset-x-0 top-0 h-8 bg-gradient-to-b from-black/30 to-transparent"
        />
      </div>
    </div>
  );
}

export function EditorPreview() {
  const toolChips = ['Select', 'Arrow', 'Rect', 'Text', 'Censor', 'Beautify', 'Loupe'];
  return (
    <div className="flex h-full flex-col p-3 md:p-4">
      <div className="mb-3 flex flex-wrap items-center gap-1.5">
        {toolChips.map((t, i) => (
          <span
            key={t}
            className={cn(
              'rounded-md px-2 py-1 font-mono text-[10px] md:text-xs',
              i === 0 ? 'bg-violet/25 text-violet-100 ring-1 ring-violet/40' : 'bg-white/5 text-white/55',
            )}
          >
            {t}
          </span>
        ))}
      </div>
      <div className="relative flex flex-1 overflow-hidden rounded-xl border border-white/10 bg-gradient-to-br from-[#151922] to-[#0c0e14] p-4">
        <div className="absolute inset-4 rounded-lg bg-[linear-gradient(135deg,#1e2430_0%,#12151c_50%,#1a1524_100%)] opacity-90" />
        <div className="relative z-10 flex w-full flex-col justify-between">
          <div className="space-y-2">
            <div className="h-2 w-24 rounded bg-white/15" />
            <div className="h-2 w-40 rounded bg-white/10" />
            <div className="h-2 w-32 rounded bg-white/8" />
          </div>
          <svg viewBox="0 0 400 120" className="mx-auto w-full max-w-md opacity-90" aria-hidden>
            <defs>
              <marker id="arrow" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
                <path d="M0,0 L6,3 L0,6 Z" fill="#5ee4b5" />
              </marker>
            </defs>
            <rect x="48" y="28" width="120" height="64" rx="6" fill="none" stroke="#8b5cf6" strokeWidth="2" />
            <line x1="200" y1="80" x2="320" y2="36" stroke="#5ee4b5" strokeWidth="2.5" markerEnd="url(#arrow)" />
            <rect x="260" y="52" width="88" height="36" rx="4" fill="#ec489933" stroke="#ec4899" strokeWidth="1.5" strokeDasharray="4 3" />
            <text x="268" y="74" fill="#f5c451" fontSize="11" fontFamily="ui-monospace, monospace">REDACTED</text>
          </svg>
          <div className="flex items-center justify-between text-[10px] text-white/40 md:text-xs">
            <span className="font-mono">Capture coords · 2× retina</span>
            <span className="rounded-full bg-mint/15 px-2 py-0.5 font-mono text-mint">On screen = saved</span>
          </div>
        </div>
        <div className="absolute bottom-3 right-3 rounded-lg border border-white/10 bg-black/40 px-2 py-1.5 backdrop-blur">
          <div className="h-8 w-14 rounded bg-gradient-to-br from-violet/40 to-fuchsia/30" />
        </div>
      </div>
    </div>
  );
}
