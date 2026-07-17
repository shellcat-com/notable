"use client";

import * as React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { BookOpen, ChevronRight, Menu, X } from "lucide-react";
import { docHref, docSections } from "@/lib/docs";
import { cn } from "@/lib/utils";

export function DocsShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = React.useState(false);

  const isActive = (slug: string) => {
    const href = docHref(slug);
    return pathname === href;
  };

  return (
    <div className="mx-auto flex w-full max-w-7xl flex-1 gap-0 px-4 lg:gap-10">
      <aside className="hidden w-56 shrink-0 lg:block">
        <div className="sticky top-20 pb-16 pt-2">
          <p className="mb-4 flex items-center gap-2 font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
            <BookOpen className="size-3.5" />
            Documentation
          </p>
          <nav className="space-y-6">
            {docSections.map((section) => (
              <div key={section.title}>
                <p className="mb-2 px-2 font-mono text-[10px] uppercase tracking-widest text-muted-foreground/80">
                  {section.title}
                </p>
                <ul className="space-y-0.5">
                  {section.pages.map((page) => {
                    const href = docHref(page.slug);
                    const active = isActive(page.slug);
                    return (
                      <li key={page.slug || "intro"}>
                        <Link
                          href={href}
                          className={cn(
                            "flex items-center gap-2 rounded-lg px-2.5 py-2 text-sm transition-colors",
                            active
                              ? "bg-violet-500/10 font-medium text-violet-300 ring-1 ring-violet-500/20"
                              : "text-muted-foreground hover:bg-muted/50 hover:text-foreground"
                          )}
                        >
                          {active && (
                            <span className="size-1.5 shrink-0 rounded-full bg-[var(--pb-mint)]" />
                          )}
                          {page.title}
                        </Link>
                      </li>
                    );
                  })}
                </ul>
              </div>
            ))}
          </nav>
        </div>
      </aside>

      <div className="min-w-0 flex-1 pb-20 pt-2">
        <div className="mb-6 flex items-center justify-between lg:hidden">
          <p className="font-mono text-xs uppercase tracking-widest text-muted-foreground">
            Docs
          </p>
          <button
            type="button"
            onClick={() => setMobileOpen((o) => !o)}
            aria-expanded={mobileOpen}
            className="inline-flex size-9 items-center justify-center rounded-lg border text-muted-foreground"
          >
            {mobileOpen ? <X className="size-4" /> : <Menu className="size-4" />}
          </button>
        </div>

        {mobileOpen && (
          <nav className="mb-8 space-y-4 rounded-2xl border bg-card p-4 lg:hidden">
            {docSections.map((section) => (
              <div key={section.title}>
                <p className="mb-2 font-mono text-[10px] uppercase tracking-widest text-muted-foreground">
                  {section.title}
                </p>
                <ul className="space-y-0.5">
                  {section.pages.map((page) => (
                    <li key={page.slug || "intro"}>
                      <Link
                        href={docHref(page.slug)}
                        onClick={() => setMobileOpen(false)}
                        className={cn(
                          "block rounded-lg px-2 py-2 text-sm",
                          isActive(page.slug)
                            ? "bg-violet-500/10 text-violet-300"
                            : "text-muted-foreground"
                        )}
                      >
                        {page.title}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </nav>
        )}

        <article className="docs-prose">{children}</article>
      </div>
    </div>
  );
}

export function DocsBreadcrumb({
  section,
  title,
}: {
  section: string;
  title: string;
}) {
  return (
    <div className="mb-6 flex items-center gap-2 text-sm text-muted-foreground">
      <Link href="/docs" className="transition-colors hover:text-foreground">
        Docs
      </Link>
      <ChevronRight className="size-3.5 opacity-50" />
      <span className="font-mono text-[11px] uppercase tracking-wide text-[var(--pb-mint)]">
        {section}
      </span>
      <ChevronRight className="size-3.5 opacity-50" />
      <span className="text-foreground/80">{title}</span>
    </div>
  );
}

export function DocsCallout({
  variant = "note",
  title,
  children,
}: {
  variant?: "note" | "tip" | "warning";
  title?: string;
  children: React.ReactNode;
}) {
  const styles = {
    note: "border-violet-500/25 bg-violet-500/5",
    tip: "border-[var(--pb-mint)]/30 bg-[var(--pb-mint)]/5",
    warning: "border-amber-500/30 bg-amber-500/5",
  };

  return (
    <aside
      className={cn(
        "my-6 rounded-xl border px-4 py-3 text-sm leading-relaxed",
        styles[variant]
      )}
    >
      {title && <p className="mb-1 font-medium text-foreground">{title}</p>}
      <div className="text-muted-foreground [&_strong]:text-foreground">
        {children}
      </div>
    </aside>
  );
}
