"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Menu, Moon, Sun, X } from "lucide-react";
import { useTheme } from "next-themes";
import { cn } from "@/lib/utils";
import { DOWNLOAD_URL, GITHUB_URL } from "@/lib/site";
import { navLinks } from "@/lib/nav";

function GithubMark() {
  return (
    <svg viewBox="0 0 16 16" aria-hidden className="size-4" fill="currentColor">
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0016 8c0-4.42-3.58-8-8-8z" />
    </svg>
  );
}

const LINKS = navLinks;

function ParcelMark({ className }: { className?: string }) {
  return (
    <span
      className={cn(
        "relative grid size-7 shrink-0 place-items-center overflow-hidden rounded-lg ring-1 ring-white/10",
        className
      )}
    >
      <span className="absolute inset-0 bg-gradient-to-br from-[var(--brand-secondary)] via-[var(--brand-tertiary)]/70 to-[var(--brand-accent)]/60" />
      <span className="relative text-[11px] font-black text-white">P</span>
    </span>
  );
}

export function SiteNav() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = React.useState(false);
  const [scrolled, setScrolled] = React.useState(false);
  const isHome = pathname === "/";

  React.useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header className="sticky top-0 z-50 px-4 pt-3">
      <div
        className={cn(
          "mx-auto flex h-12 max-w-6xl items-center gap-3 rounded-2xl border px-3 transition-all duration-300",
          scrolled || !isHome
            ? "border-border/50 bg-background/80 shadow-[0_8px_32px_rgba(0,0,0,0.12)] backdrop-blur-xl"
            : "border-white/10 bg-black/35 shadow-[0_8px_40px_rgba(0,0,0,0.35)] backdrop-blur-xl"
        )}
      >
        <Link href="/" className="flex items-center gap-2.5">
          <ParcelMark />
          <span className="text-sm font-semibold tracking-tight">Parcel</span>
        </Link>

        <nav className="ml-1 hidden items-center md:flex">
          {LINKS.map((l) =>
            "isRoute" in l && l.isRoute ? (
              <Link
                key={l.href}
                href={l.href}
                className="rounded-lg px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
              >
                {l.label}
              </Link>
            ) : (
              <a
                key={l.href}
                href={l.href}
                className="rounded-lg px-3 py-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
              >
                {l.label}
              </a>
            )
          )}
        </nav>

        <div className="ml-auto flex items-center gap-1.5">
          <ThemeToggle />
          <a
            href={GITHUB_URL}
            target="_blank"
            rel="noopener noreferrer"
            aria-label="GitHub"
            className="hidden size-8 items-center justify-center rounded-lg border border-border/60 text-muted-foreground transition-colors hover:text-foreground sm:inline-flex"
          >
            <GithubMark />
          </a>
          <Link
            href={DOWNLOAD_URL}
            className="hidden items-center justify-center rounded-full bg-[var(--brand-accent)] px-4 py-2 text-xs font-semibold text-[var(--brand-ink)] transition-all hover:brightness-110 sm:inline-flex"
          >
            Download
          </Link>
          <button
            onClick={() => setMobileOpen((o) => !o)}
            aria-label="Toggle navigation menu"
            aria-expanded={mobileOpen}
            className="inline-flex size-8 items-center justify-center rounded-lg border border-border/60 text-muted-foreground md:hidden"
          >
            {mobileOpen ? <X className="size-4" /> : <Menu className="size-4" />}
          </button>
        </div>
      </div>

      {mobileOpen && (
        <nav className="mx-auto mt-2 max-w-6xl rounded-2xl border border-border/60 bg-background/95 p-3 backdrop-blur-xl md:hidden">
          {LINKS.map((l) =>
            "isRoute" in l && l.isRoute ? (
              <Link
                key={l.href}
                href={l.href}
                onClick={() => setMobileOpen(false)}
                className="block rounded-lg px-3 py-2.5 text-sm text-muted-foreground hover:bg-muted/50"
              >
                {l.label}
              </Link>
            ) : (
              <a
                key={l.href}
                href={l.href}
                onClick={() => setMobileOpen(false)}
                className="block rounded-lg px-3 py-2.5 text-sm text-muted-foreground hover:bg-muted/50"
              >
                {l.label}
              </a>
            )
          )}
          <a
            href={DOWNLOAD_URL}
            className="mt-2 block rounded-xl bg-[var(--brand-accent)] px-4 py-2.5 text-center text-sm font-semibold text-[var(--brand-ink)]"
          >
            Download for macOS
          </a>
        </nav>
      )}
    </header>
  );
}

function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => setMounted(true), []);

  if (!mounted) {
    return <span aria-hidden className="inline-block size-8" />;
  }

  const dark = resolvedTheme === "dark";

  return (
    <button
      type="button"
      onClick={() => setTheme(dark ? "light" : "dark")}
      aria-label="Toggle theme"
      className="inline-flex size-8 items-center justify-center rounded-lg border border-border/60 text-muted-foreground transition-colors hover:text-foreground"
    >
      {dark ? <Sun className="size-4" /> : <Moon className="size-4" />}
    </button>
  );
}

export { ParcelMark };
