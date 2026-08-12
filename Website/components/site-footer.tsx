import Link from "next/link";
import { DOWNLOAD_URL, GITHUB_URL } from "@/lib/site";
import { ParcelMark } from "@/components/site-nav";

const footerLinks = {
  Product: [
    { label: "Features", href: "/#features" },
    { label: "Workflow", href: "/#workflow" },
    { label: "Privacy", href: "/#privacy" },
    { label: "Install", href: "/#install" },
    { label: "Download", href: DOWNLOAD_URL, download: true },
  ],
  Docs: [
    { label: "Documentation", href: "/docs" },
    { label: "Quick start", href: "/docs/getting-started" },
    { label: "Shortcuts", href: "/docs/shortcuts" },
    { label: "Privacy", href: "/docs/privacy" },
  ],
  Ecosystem: [
    { label: "GitHub", href: GITHUB_URL, external: true },
    { label: "Parable UI", href: "https://github.com/bswxyz/parable", external: true },
    { label: "Parable.dev", href: "https://parable.dev", external: true },
  ],
} as const;

export function SiteFooter() {
  return (
    <footer className="relative mt-auto overflow-hidden border-t border-border/40 bg-[var(--brand-ink)] text-zinc-300">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-[var(--brand-accent)]/40 to-transparent"
      />

      <div className="mx-auto max-w-6xl px-4 py-16">
        <div className="grid gap-12 lg:grid-cols-[1.2fr_2fr]">
          <div>
            <Link href="/" className="inline-flex items-center gap-2.5">
              <ParcelMark className="size-9 rounded-xl" />
              <span className="text-sm font-semibold text-white">Parcel</span>
            </Link>
            <p className="mt-4 max-w-xs text-sm leading-relaxed text-zinc-400">
              The native macOS Capture studio from{" "}
              <a
                href="https://parable.dev"
                className="text-zinc-200 underline underline-offset-4"
              >
                Parable
              </a>
              . MIT licensed — no cloud AI, ever.
            </p>
          </div>

          <nav className="grid grid-cols-2 gap-8 sm:grid-cols-3">
            {Object.entries(footerLinks).map(([group, links]) => (
              <div key={group}>
                <p className="font-mono text-[10px] uppercase tracking-widest text-zinc-400">
                  {group}
                </p>
                <ul className="mt-3 space-y-2.5">
                  {links.map((link) => (
                    <li key={link.label}>
                      {"external" in link && link.external ? (
                        <a
                          href={link.href}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-sm text-zinc-400 transition-colors hover:text-white"
                        >
                          {link.label}
                        </a>
                      ) : "download" in link && link.download ? (
                        <a
                          href={link.href}
                          download
                          className="text-sm text-zinc-400 transition-colors hover:text-white"
                        >
                          {link.label}
                        </a>
                      ) : link.href.startsWith("/") ? (
                        <Link
                          href={link.href}
                          className="text-sm text-zinc-400 transition-colors hover:text-white"
                        >
                          {link.label}
                        </Link>
                      ) : (
                        <a
                          href={link.href}
                          className="text-sm text-zinc-400 transition-colors hover:text-white"
                        >
                          {link.label}
                        </a>
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </nav>
        </div>

        <div className="mt-14 flex flex-col items-center justify-between gap-4 border-t border-white/8 pt-6 text-xs text-zinc-400 sm:flex-row">
          <p>© {new Date().getFullYear()} Parable · MIT License</p>
          <p className="font-mono">
            SwiftUI · ScreenCaptureKit · Next.js
          </p>
        </div>
      </div>
    </footer>
  );
}
