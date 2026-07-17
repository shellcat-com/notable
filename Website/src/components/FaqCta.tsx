'use client';

import * as React from 'react';
import { motion, AnimatePresence, useReducedMotion } from 'motion/react';
import { Plus } from 'lucide-react';
import { cn } from '../lib/utils';

export function FaqAccordion({ items }: { items: { q: string; a: string }[] }) {
  const reduce = useReducedMotion() ?? false;
  const [open, setOpen] = React.useState<number | null>(0);

  return (
    <section className="border-t border-white/8 py-24">
      <div className="mx-auto max-w-3xl px-6">
        <p className="section-kicker">FAQ</p>
        <h2 className="mt-3 text-3xl font-bold tracking-tight">Questions before you install</h2>
        <div className="mt-10 divide-y divide-white/10 rounded-2xl border border-white/10 bg-white/[0.02]">
          {items.map((item, i) => {
            const isOpen = open === i;
            return (
              <div key={item.q}>
                <button
                  type="button"
                  aria-expanded={isOpen}
                  onClick={() => setOpen(isOpen ? null : i)}
                  className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left transition-colors hover:bg-white/[0.03]"
                >
                  <span className="font-medium">{item.q}</span>
                  <Plus
                    className={cn('size-5 shrink-0 text-white/40 transition-transform duration-300', isOpen && 'rotate-45')}
                    strokeWidth={2}
                  />
                </button>
                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      initial={reduce ? false : { height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={reduce ? undefined : { height: 0, opacity: 0 }}
                      transition={reduce ? { duration: 0 } : { type: 'spring', stiffness: 260, damping: 28 }}
                      className="overflow-hidden"
                    >
                      <p className="px-5 pb-4 text-sm leading-relaxed text-white/60">{item.a}</p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export function CtaBanner({
  title,
  subtitle,
  href,
  label,
}: {
  title: string;
  subtitle: string;
  href: string;
  label: string;
}) {
  return (
    <section className="px-6 pb-24">
      <div className="relative mx-auto max-w-6xl overflow-hidden rounded-3xl border border-violet/30 px-8 py-14 text-center">
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(139,92,246,0.22),transparent_55%),radial-gradient(ellipse_at_bottom,rgba(236,72,153,0.15),transparent_50%)]"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 opacity-[0.35]"
          style={{
            backgroundImage: 'radial-gradient(circle at 1px 1px, rgba(255,255,255,0.12) 1px, transparent 0)',
            backgroundSize: '20px 20px',
            maskImage: 'linear-gradient(to bottom, black, transparent)',
          }}
        />
        <div className="relative">
          <h2 className="text-3xl font-bold tracking-tight md:text-4xl">{title}</h2>
          <p className="mx-auto mt-3 max-w-xl text-white/65">{subtitle}</p>
          <a href={href} className="btn-primary mt-8" download={href.endsWith('.zip')}>
            {label}
          </a>
        </div>
      </div>
    </section>
  );
}
