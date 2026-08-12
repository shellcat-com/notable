import Link from "next/link";
import { ArrowRight, Check, LockKeyhole, ShieldCheck } from "lucide-react";

const localFacts = [
  "Vision recognition and face finding run locally",
  "Translation uses Apple on-device frameworks",
  "Supabase upload happens only when you configure and invoke it",
  "Sandboxed Release builds use minimal entitlements",
] as const;

export function PrivacySection() {
  return (
    <section id="privacy" aria-labelledby="privacy-title" className="scroll-mt-20 border-b bg-[#0c1110] text-white">
      <div className="relative overflow-hidden">
        <div aria-hidden className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_20%_35%,rgba(94,228,181,.14),transparent_34%),radial-gradient(circle_at_88%_70%,rgba(139,92,246,.13),transparent_32%)]" />
        <div className="relative mx-auto grid max-w-7xl items-center gap-12 px-4 py-20 md:py-28 lg:grid-cols-[0.9fr_1.1fr] lg:gap-20 lg:px-8 lg:py-32">
          <div className="max-w-xl">
            <div className="inline-flex items-center gap-2 rounded-full border border-white/12 bg-white/[0.055] px-3 py-1.5 font-mono text-[10px] uppercase tracking-[0.18em] text-[var(--brand-accent)]">
              <LockKeyhole className="size-3.5" />
              Privacy is architecture
            </div>
            <h2 id="privacy-title" className="mt-6 text-balance text-4xl font-semibold tracking-[-0.04em] sm:text-5xl lg:text-6xl">
              Your pixels stay on your Mac.
            </h2>
            <p className="mt-6 text-pretty text-lg leading-8 text-zinc-300">
              Parcel does not send a Capture to a cloud model. Recognition,
              redaction assistance, face detection, QR reading, and supported
              translation stay on-device unless you explicitly choose an upload.
            </p>
            <ul className="mt-8 space-y-3">
              {localFacts.map((fact) => (
                <li key={fact} className="flex items-start gap-3 text-sm text-zinc-200">
                  <span className="mt-0.5 grid size-5 shrink-0 place-items-center rounded-full bg-[var(--brand-accent)]/12 text-[var(--brand-accent)] ring-1 ring-[var(--brand-accent)]/25">
                    <Check className="size-3" strokeWidth={2.6} />
                  </span>
                  {fact}
                </li>
              ))}
            </ul>
            <Link href="/docs/privacy" className="mt-8 inline-flex items-center gap-2 text-sm font-semibold text-[var(--brand-accent)] hover:text-white">
              Read the privacy documentation <ArrowRight className="size-4" />
            </Link>
          </div>

          <div className="relative">
            <div aria-hidden className="absolute -inset-10 rounded-full bg-[var(--brand-accent)]/8 blur-3xl" />
            <div className="relative overflow-hidden rounded-[1.75rem] border border-white/12 bg-[#171b1a]/95 shadow-[0_40px_100px_rgba(0,0,0,.48)]">
              <div className="flex items-center justify-between border-b border-white/8 px-5 py-4">
                <div className="flex items-center gap-2.5">
                  <span className="size-2.5 rounded-full bg-[#ff5f57]" />
                  <span className="size-2.5 rounded-full bg-[#febc2e]" />
                  <span className="size-2.5 rounded-full bg-[#28c840]" />
                </div>
                <p className="font-mono text-[10px] uppercase tracking-[0.16em] text-zinc-500">Privacy &amp; Security</p>
              </div>
              <div className="grid gap-4 p-5 sm:p-7">
                <div className="rounded-2xl border border-white/10 bg-white/[0.045] p-5">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-start gap-4">
                      <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-[var(--brand-secondary)]/16 text-[var(--brand-secondary)]">
                        <ShieldCheck className="size-5" />
                      </span>
                      <div>
                        <h3 className="font-semibold">Screen Recording</h3>
                        <p className="mt-1 text-sm leading-6 text-zinc-400">Required by macOS so Parcel can make a Capture.</p>
                      </div>
                    </div>
                    <span className="rounded-full bg-[var(--brand-accent)]/12 px-2.5 py-1 font-mono text-[10px] uppercase tracking-wide text-[var(--brand-accent)]">Required</span>
                  </div>
                </div>

                <div className="rounded-2xl border border-white/10 bg-white/[0.025] p-5">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-start gap-4">
                      <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-white/[0.06] text-zinc-400">
                        <LockKeyhole className="size-5" />
                      </span>
                      <div>
                        <h3 className="font-semibold text-zinc-200">Accessibility</h3>
                        <p className="mt-1 text-sm leading-6 text-zinc-500">Not used. The global hotkey is registered through Carbon.</p>
                      </div>
                    </div>
                    <span className="font-mono text-xs text-zinc-500">—</span>
                  </div>
                </div>

                <div className="rounded-2xl border border-[var(--brand-accent)]/18 bg-[var(--brand-accent)]/[0.055] px-5 py-4">
                  <div className="flex items-center justify-between gap-4">
                    <div>
                      <p className="text-sm font-semibold text-white">Cloud AI requests</p>
                      <p className="mt-1 text-xs text-zinc-400">No Capture data sent for AI processing</p>
                    </div>
                    <span className="text-3xl font-semibold tracking-tight text-[var(--brand-accent)]">0</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
