'use client';

import * as React from 'react';
import { motion, useReducedMotion } from 'motion/react';
import { cn } from '../lib/utils';

export function SiteNav() {
  const [scrolled, setScrolled] = React.useState(false);

  React.useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <header
      className={cn(
        'fixed inset-x-0 top-0 z-50 transition-[background-color,border-color,backdrop-filter] duration-300',
        scrolled ? 'border-b border-white/10 bg-ink/80 backdrop-blur-xl' : 'border-b border-transparent bg-transparent',
      )}
    >
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <a href="#top" className="group flex items-center gap-2.5 font-semibold tracking-tight">
          <span className="relative flex size-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet/30 to-fuchsia/20 ring-1 ring-white/15">
            <img src="/favicon.svg" alt="" width={20} height={20} className="rounded-sm" />
          </span>
          Parcel
        </a>
        <nav className="hidden items-center gap-8 text-sm text-white/60 md:flex">
          {[
            ['Features', '#features'],
            ['Privacy', '#privacy'],
            ['Workflow', '#workflow'],
            ['Guides', '#guides'],
          ].map(([label, href]) => (
            <a key={href} href={href} className="transition-colors hover:text-white">
              {label}
            </a>
          ))}
          <a href="https://github.com/bswxyz/notable" className="transition-colors hover:text-white">
            GitHub
          </a>
        </nav>
        <a href="/downloads/Parcel.zip" className="btn-primary px-4 py-2 text-sm" download>
          Download
        </a>
      </div>
    </header>
  );
}

export function LogoStrip({ logos }: { logos: string[] }) {
  return (
    <section className="border-y border-white/8 bg-white/[0.02] py-8">
      <div className="mx-auto max-w-6xl px-6">
        <p className="text-center font-mono text-[11px] uppercase tracking-[0.22em] text-white/40">
          Built on native Apple frameworks
        </p>
        <div className="mt-5 flex flex-wrap items-center justify-center gap-x-8 gap-y-3">
          {logos.map((name) => (
            <span key={name} className="font-mono text-sm text-white/35 transition-colors hover:text-white/55">
              {name}
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}

export function WorkflowSteps({
  steps,
}: {
  steps: { step: string; title: string; body: string }[];
}) {
  const reduce = useReducedMotion() ?? false;

  return (
    <section id="workflow" className="border-t border-white/8 py-24">
      <div className="mx-auto max-w-6xl px-6">
        <p className="section-kicker">How it works</p>
        <h2 className="mt-3 max-w-xl text-3xl font-bold tracking-tight md:text-4xl">
          From frozen pixels to shipped Capture in three steps
        </h2>
        <ol className="mt-14 grid gap-6 md:grid-cols-3">
          {steps.map((s, i) => (
            <motion.li
              key={s.step}
              initial={reduce ? false : { opacity: 0, y: 20 }}
              whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
              viewport={{ once: true, amount: 0.2 }}
              transition={{ delay: i * 0.1, type: 'spring', stiffness: 220, damping: 26 }}
              className="relative rounded-2xl border border-white/10 bg-gradient-to-b from-white/[0.04] to-transparent p-6"
            >
              <span className="font-mono text-sm text-violet">{s.step}</span>
              <h3 className="mt-3 text-lg font-semibold">{s.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-white/60">{s.body}</p>
              {i < steps.length - 1 && (
                <span
                  aria-hidden
                  className="absolute -right-3 top-1/2 hidden h-px w-6 bg-gradient-to-r from-violet/50 to-transparent md:block"
                />
              )}
            </motion.li>
          ))}
        </ol>
      </div>
    </section>
  );
}

export function ShortcutsTable({ rows }: { rows: { keys: string; action: string }[] }) {
  return (
    <section className="border-t border-white/8 py-24">
      <div className="mx-auto max-w-6xl px-6">
        <p className="section-kicker">Keyboard-first</p>
        <h2 className="mt-3 text-3xl font-bold tracking-tight">Every action has a shortcut</h2>
        <div className="mt-10 overflow-hidden rounded-2xl border border-white/10 bg-white/[0.02]">
          <table className="w-full text-left text-sm">
            <tbody>
              {rows.map((row) => (
                <tr key={row.keys} className="border-b border-white/8 last:border-0">
                  <td className="w-48 px-5 py-3.5 font-mono text-mint">{row.keys}</td>
                  <td className="px-5 py-3.5 text-white/70">{row.action}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
}

export function GuidesGrid({ guides }: { guides: { title: string; body: string }[] }) {
  return (
    <section id="guides" className="border-t border-white/8 py-24">
      <div className="mx-auto max-w-6xl px-6">
        <p className="section-kicker">Guides</p>
        <h2 className="mt-3 text-3xl font-bold tracking-tight">Common Capture workflows</h2>
        <div className="mt-10 grid gap-4 md:grid-cols-2">
          {guides.map((g, i) => (
            <article
              key={g.title}
              className="group rounded-2xl border border-white/10 bg-white/[0.02] p-6 transition-colors hover:border-violet/35 hover:bg-white/[0.04]"
            >
              <span className="font-mono text-xs text-violet/80">0{i + 1}</span>
              <h3 className="mt-2 font-semibold">{g.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-white/60">{g.body}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

export function PrivacySection() {
  return (
    <section id="privacy" className="border-t border-white/8 py-24">
      <div className="mx-auto grid max-w-6xl gap-12 px-6 lg:grid-cols-2 lg:items-center">
        <div>
          <p className="section-kicker">Private by default</p>
          <h2 className="mt-3 text-3xl font-bold tracking-tight md:text-4xl">
            No cloud dependency. <span className="text-white/50">No network AI.</span>
          </h2>
          <p className="mt-5 leading-relaxed text-white/65">
            History, brand kits, Vision inspection, adjustments, and export stay on your Mac. Upload is real Supabase
            Storage when you configure it — never a pretend one-click share.
          </p>
          <ul className="mt-8 space-y-3 text-sm text-white/55">
            {[
              'ScreenCaptureKit capture & recording',
              'Vision OCR, faces, QR — on-device only',
              'Optional Supabase upload you control',
            ].map((line) => (
              <li key={line} className="flex items-center gap-2">
                <span className="size-1.5 rounded-full bg-mint" />
                {line}
              </li>
            ))}
          </ul>
        </div>
        <figure className="relative overflow-hidden rounded-2xl border border-white/10 bg-panel p-1">
          <div
            aria-hidden
            className="pointer-events-none absolute -inset-px rounded-2xl opacity-60"
            style={{
              background: 'conic-gradient(from 180deg, transparent, rgba(139,92,246,0.5), transparent 30%)',
            }}
          />
          <div className="relative rounded-[14px] bg-panel p-4">
            <img src="/assets/notable-permission.svg" alt="Screen Recording permission guidance" className="w-full rounded-lg" />
            <figcaption className="mt-3 text-center text-xs text-white/45">
              Grant Screen Recording, then quit and reopen Parcel.
            </figcaption>
          </div>
        </figure>
      </div>
    </section>
  );
}

export function InstallSection() {
  return (
    <section id="install" className="border-t border-white/8 py-24">
      <div className="mx-auto max-w-6xl px-6">
        <p className="section-kicker">Install</p>
        <h2 className="mt-3 text-3xl font-bold tracking-tight">Try the current Mac build</h2>
        <div className="mt-10 grid gap-5 md:grid-cols-2">
          <div className="rounded-2xl border border-violet/25 bg-gradient-to-br from-violet/10 to-transparent p-6">
            <h3 className="font-semibold">Direct download</h3>
            <p className="mt-2 text-sm text-white/60">Unzip, open, grant Screen Recording, quit and reopen.</p>
            <a href="/downloads/Parcel.zip" className="btn-primary mt-5" download>
              Parcel.zip
            </a>
          </div>
          <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6">
            <h3 className="font-semibold">Homebrew</h3>
            <code className="mt-4 block rounded-xl border border-white/10 bg-ink px-4 py-3 font-mono text-xs text-mint">
              brew install --cask parcel
            </code>
            <p className="mt-3 text-xs text-white/45">Requires the cask in this repo or a published tap.</p>
          </div>
        </div>
      </div>
    </section>
  );
}

export function SiteFooter() {
  return (
    <footer className="border-t border-white/8 py-12">
      <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-6 text-sm text-white/45 md:flex-row">
        <p>Parcel by Parable · MIT License</p>
        <div className="flex gap-6">
          <a href="https://github.com/bswxyz/notable" className="transition-colors hover:text-mint">
            GitHub
          </a>
          <a href="https://parable.dev" className="transition-colors hover:text-mint">
            Parable
          </a>
        </div>
      </div>
    </footer>
  );
}
