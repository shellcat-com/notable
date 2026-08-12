import Link from "next/link";
import Image from "next/image";
import { Apple, ArrowDown, Code2 } from "lucide-react";
import { PrimaryButton } from "@/components/primary-button";
import { DOWNLOAD_URL, GITHUB_URL } from "@/lib/site";

export function HomeHero() {
  return (
    <section className="dark-surface relative -mt-[4.25rem] overflow-hidden border-b border-white/8 bg-[var(--brand-ink)] pt-[4.25rem] text-white">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_14%_18%,rgba(94,228,181,0.13),transparent_29%),radial-gradient(circle_at_84%_8%,rgba(139,92,246,0.18),transparent_31%),radial-gradient(circle_at_76%_92%,rgba(236,72,153,0.1),transparent_27%)]"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-[0.22] [background-image:linear-gradient(rgba(255,255,255,.035)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,.035)_1px,transparent_1px)] [background-size:64px_64px] [mask-image:linear-gradient(to_bottom,black,transparent_85%)]"
      />

      <div className="relative mx-auto grid min-h-[min(58rem,94vh)] max-w-7xl items-center gap-12 px-4 pb-16 pt-24 lg:grid-cols-[0.78fr_1.22fr] lg:px-8 lg:pb-24 lg:pt-28">
        <div className="relative z-10 max-w-2xl">
          <Link
            href="/docs/getting-started"
            className="inline-flex items-center gap-2 rounded-full border border-white/12 bg-white/[0.055] px-3 py-1.5 font-mono text-[11px] uppercase tracking-[0.16em] text-zinc-300 transition-colors hover:border-[var(--brand-accent)]/45 hover:text-white"
          >
            <span className="size-1.5 rounded-full bg-[var(--brand-accent)] shadow-[0_0_12px_var(--brand-accent)]" />
            Native macOS · From Parable
          </Link>

          <h1 className="mt-7 text-balance text-5xl font-semibold leading-[0.98] tracking-[-0.045em] text-white sm:text-6xl lg:text-[5.35rem]">
            Capture anything. Make it{" "}
            <em className="font-display font-normal not-italic text-[var(--brand-accent)]">
              unmistakable.
            </em>
          </h1>
          <p className="mt-7 max-w-xl text-pretty text-lg leading-8 text-zinc-300 sm:text-xl">
            Parcel is the native macOS Capture studio for fast Selection,
            precise Annotation, private redaction, and polished sharing—without
            cloud AI.
          </p>

          <div className="mt-9 flex flex-col gap-3 sm:flex-row sm:items-center">
            <PrimaryButton
              href={DOWNLOAD_URL}
              download
              className="min-h-12 gap-2.5 px-7 text-[15px]"
            >
              <Apple className="size-4" />
              Download Parcel for macOS
            </PrimaryButton>
            <a
              href="#workflow"
              className="inline-flex min-h-12 items-center justify-center gap-2 rounded-full border border-white/15 bg-white/[0.045] px-6 text-sm font-semibold text-zinc-100 transition-colors hover:border-white/30 hover:bg-white/[0.08]"
            >
              Watch the workflow
              <ArrowDown className="size-4" />
            </a>
          </div>

          <div className="mt-6 flex flex-wrap items-center gap-x-3 gap-y-2 font-mono text-[11px] text-zinc-400">
            <span>Free</span><span aria-hidden>·</span>
            <span>MIT licensed</span><span aria-hidden>·</span>
            <span>macOS 13+</span><span aria-hidden>·</span>
            <span>Apple Silicon and Intel</span>
          </div>
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-5 inline-flex items-center gap-2 text-xs text-zinc-400 transition-colors hover:text-white"
          >
            <Code2 className="size-3.5" />
            Inspect the source on GitHub
          </a>
        </div>

        <div className="relative mx-auto w-full max-w-4xl lg:translate-x-[4%]">
          <div
            aria-hidden
            className="absolute -inset-[10%] rounded-full bg-[radial-gradient(circle,rgba(139,92,246,.18),rgba(94,228,181,.08)_42%,transparent_72%)] blur-3xl"
          />
          <div className="relative rotate-[0.5deg] overflow-hidden rounded-[1.45rem] border border-white/15 bg-black/35 p-2 shadow-[0_40px_120px_rgba(0,0,0,.58)] sm:p-3">
            <div className="mb-2 flex items-center gap-2 px-2 py-1 sm:mb-3">
              <span className="size-2.5 rounded-full bg-[#ff5f57]" />
              <span className="size-2.5 rounded-full bg-[#febc2e]" />
              <span className="size-2.5 rounded-full bg-[#28c840]" />
              <span className="ml-2 font-mono text-[10px] text-white/45">
                Parcel workflow · local on your Mac
              </span>
            </div>
            <div className="relative aspect-[8/5] overflow-hidden rounded-xl bg-[#121319]">
              <Image
                src="/media/hero-workflow-poster.webp"
                width="1440"
                height="900"
                alt="Parcel Editor with Annotation and export controls"
                sizes="(max-width: 1024px) 100vw, 60vw"
                className="absolute inset-0 size-full object-cover"
              />
              <video
                autoPlay
                muted
                loop
                playsInline
                preload="metadata"
                poster="/media/hero-workflow-poster.webp"
                aria-label="Parcel workflow from frozen Capture through Annotation and polished export"
                className="absolute inset-0 size-full object-cover motion-reduce:hidden"
              >
                <source
                  src="/media/hero-workflow.mp4"
                  type="video/mp4"
                  media="(min-width: 768px) and (prefers-reduced-motion: no-preference)"
                />
              </video>
            </div>
          </div>
          <div className="absolute -bottom-5 left-3 rounded-2xl border border-white/12 bg-[#15171c]/92 px-4 py-3 shadow-2xl backdrop-blur-xl sm:-left-6 sm:bottom-8">
            <p className="text-xs font-semibold text-white">One render pipeline</p>
            <p className="mt-1 font-mono text-[10px] text-zinc-400">Canvas = copied = saved</p>
          </div>
          <div className="absolute right-2 top-10 hidden rounded-2xl border border-white/12 bg-[#15171c]/92 px-4 py-3 shadow-2xl backdrop-blur-xl sm:block xl:-right-8">
            <p className="text-xs font-semibold text-white">Private by default</p>
            <p className="mt-1 font-mono text-[10px] text-[var(--brand-accent)]">0 cloud AI calls</p>
          </div>
        </div>
      </div>
    </section>
  );
}
