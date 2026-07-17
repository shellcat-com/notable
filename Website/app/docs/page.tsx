import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { docHref, docSections } from "@/lib/docs";

export default function DocsIndexPage() {
  return (
    <>
      <p className="docs-lead">
        Parcel is a native macOS Capture studio from the{" "}
        <a href="https://parable.dev">Parable</a> ecosystem. These guides cover
        what end users need — install, permissions, Capture workflows, and
        optional upload.
      </p>

      <h2>Start here</h2>
      <div className="not-prose my-8 grid gap-4 sm:grid-cols-2">
        <Link
          href="/docs/getting-started"
          className="group rounded-2xl border bg-card/80 p-5 transition-all hover:border-violet-500/25 hover:shadow-[0_8px_32px_rgba(139,92,246,0.08)]"
        >
          <p className="font-mono text-[11px] uppercase tracking-widest text-[var(--pb-mint)]">
            Recommended
          </p>
          <h3 className="mt-2 text-lg font-semibold">Quick start</h3>
          <p className="mt-2 text-sm text-muted-foreground">
            Download, grant Screen Recording, and take your first Capture in
            under two minutes.
          </p>
          <span className="mt-4 inline-flex items-center gap-1 text-sm text-violet-400">
            Read guide <ArrowRight className="size-4 transition-transform group-hover:translate-x-0.5" />
          </span>
        </Link>
        <Link
          href="/docs/shortcuts"
          className="group rounded-2xl border bg-card/80 p-5 transition-all hover:border-violet-500/25"
        >
          <p className="font-mono text-[11px] uppercase tracking-widest text-muted-foreground">
            Reference
          </p>
          <h3 className="mt-2 text-lg font-semibold">Keyboard shortcuts</h3>
          <p className="mt-2 text-sm text-muted-foreground">
            Global hotkey, Overlay controls, and Editor commands in one place.
          </p>
          <span className="mt-4 inline-flex items-center gap-1 text-sm text-violet-400">
            View shortcuts <ArrowRight className="size-4" />
          </span>
        </Link>
      </div>

      <h2>All guides</h2>
      <div className="not-prose space-y-8">
        {docSections.map((section) => (
          <div key={section.title}>
            <h3 className="mb-3 font-mono text-xs uppercase tracking-widest text-muted-foreground">
              {section.title}
            </h3>
            <ul className="divide-y rounded-2xl border bg-card/50">
              {section.pages.map((page) => (
                <li key={page.slug || "intro"}>
                  <Link
                    href={docHref(page.slug)}
                    className="flex items-center justify-between gap-4 px-5 py-4 transition-colors hover:bg-muted/30"
                  >
                    <div>
                      <p className="font-medium">{page.title}</p>
                      <p className="mt-0.5 text-sm text-muted-foreground">
                        {page.description}
                      </p>
                    </div>
                    <ArrowRight className="size-4 shrink-0 text-muted-foreground" />
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <h2>Contributor docs</h2>
      <p>
        Architecture, parity checklists, and agent guides live in the GitHub
        repository:
      </p>
      <ul>
        <li>
          <a href="https://github.com/bswxyz/notable/blob/main/docs/architecture.md">
            Architecture & render pipeline
          </a>
        </li>
        <li>
          <a href="https://github.com/bswxyz/notable/blob/main/docs/QA_CHECKLIST.md">
            QA checklist
          </a>
        </li>
        <li>
          <a href="https://github.com/bswxyz/notable/blob/main/AGENTS.md">
            Glossary & build guide
          </a>
        </li>
      </ul>
    </>
  );
}
