import Link from "next/link";
import { Apple, ArrowRight, Check, Code2, ShieldCheck } from "lucide-react";
import { ParcelMark } from "@/components/site-nav";
import { DOWNLOAD_URL, GITHUB_URL, faqs } from "@/lib/site";

const requirements = [
  "macOS 13.0 or later",
  "Apple Silicon and Intel",
  "Screen Recording permission",
] as const;

export function DownloadClose() {
  return (
    <section id="install" aria-labelledby="install-title" className="scroll-mt-20 border-b bg-background">
      <div className="mx-auto max-w-7xl px-4 py-16 md:py-24 lg:px-8 lg:py-28">
        <div className="relative overflow-hidden rounded-[2rem] bg-[#0b0c0f] px-5 py-14 text-white shadow-[0_40px_100px_rgba(0,0,0,.22)] sm:px-10 md:py-20 lg:px-16">
          <div aria-hidden className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_18%_20%,rgba(94,228,181,.18),transparent_31%),radial-gradient(circle_at_85%_75%,rgba(139,92,246,.22),transparent_36%)]" />
          <div aria-hidden className="pointer-events-none absolute inset-0 opacity-[.15] [background-image:linear-gradient(rgba(255,255,255,.06)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,.06)_1px,transparent_1px)] [background-size:52px_52px]" />
          <div className="relative grid items-end gap-12 lg:grid-cols-[1.2fr_.8fr]">
            <div className="max-w-3xl">
              <ParcelMark className="size-14 rounded-2xl" />
              <p className="mt-7 font-mono text-[11px] uppercase tracking-[0.2em] text-[var(--brand-accent)]">Free · Open source · Native</p>
              <h2 id="install-title" className="mt-4 text-balance text-4xl font-semibold tracking-[-0.045em] sm:text-5xl lg:text-7xl">
                Download Parcel. Keep your Capture workflow yours.
              </h2>
              <p className="mt-6 max-w-2xl text-pretty text-lg leading-8 text-zinc-300">
                One universal build for modern Macs, signed and notarized for a straightforward first launch. Sparkle handles later updates.
              </p>
              <div className="mt-9 flex flex-col gap-3 sm:flex-row">
                <a href={DOWNLOAD_URL} download className="inline-flex min-h-12 items-center justify-center gap-2.5 rounded-full bg-[var(--brand-accent)] px-7 text-sm font-semibold text-[var(--brand-ink)] shadow-[0_0_40px_rgba(94,228,181,.2)] transition-all hover:brightness-110 active:scale-[.98]">
                  <Apple className="size-4" /> Download Parcel for macOS
                </a>
                <a href={GITHUB_URL} target="_blank" rel="noopener noreferrer" className="inline-flex min-h-12 items-center justify-center gap-2 rounded-full border border-white/15 bg-white/[0.05] px-6 text-sm font-semibold transition-colors hover:border-white/30 hover:bg-white/[0.09]">
                  <Code2 className="size-4" /> View source
                </a>
              </div>
            </div>

            <div className="rounded-3xl border border-white/12 bg-white/[0.055] p-6 backdrop-blur-xl sm:p-7">
              <div className="flex items-center gap-3">
                <span className="grid size-10 place-items-center rounded-xl bg-[var(--brand-accent)]/12 text-[var(--brand-accent)]"><ShieldCheck className="size-5" /></span>
                <div><p className="text-sm font-semibold">Ready for your Mac</p><p className="mt-0.5 text-xs text-zinc-400">Signed · Notarized · Sandboxed</p></div>
              </div>
              <ul className="mt-6 space-y-3">
                {requirements.map((requirement) => (
                  <li key={requirement} className="flex items-center gap-3 text-sm text-zinc-300"><Check className="size-4 text-[var(--brand-accent)]" />{requirement}</li>
                ))}
              </ul>
              <Link href="/docs/getting-started" className="mt-7 inline-flex items-center gap-2 text-sm font-semibold text-white hover:text-[var(--brand-accent)]">
                Open the quick start guide <ArrowRight className="size-4" />
              </Link>
            </div>
          </div>
        </div>

        <div className="mx-auto mt-16 max-w-4xl md:mt-24">
          <div className="text-center">
            <p className="font-mono text-[11px] uppercase tracking-[0.2em] text-muted-foreground">Before you install</p>
            <h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">Three useful answers.</h2>
          </div>
          <div className="mt-8 divide-y overflow-hidden rounded-2xl border bg-card">
            {faqs.slice(0, 3).map((item, index) => (
              <details key={item.q} className="group px-5 py-4" open={index === 0}>
                <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-medium marker:content-none">
                  {item.q}<span className="font-mono text-lg text-muted-foreground transition-transform group-open:rotate-45">+</span>
                </summary>
                <p className="max-w-3xl pt-3 text-sm leading-6 text-muted-foreground">{item.a}</p>
              </details>
            ))}
          </div>
          <p className="mt-5 text-center text-sm text-muted-foreground">
            Need a deeper answer? <Link href="/docs" className="font-semibold text-foreground underline-offset-4 hover:underline">Browse the full documentation.</Link>
          </p>
        </div>
      </div>
    </section>
  );
}
