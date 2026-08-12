import Image from "next/image";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { focusedCapabilities } from "@/lib/site";

export function FocusedCapabilities() {
  return (
    <section id="features" aria-labelledby="features-title" className="scroll-mt-20 border-b bg-background">
      <div className="mx-auto max-w-7xl px-4 py-16 md:py-24 lg:px-8 lg:py-28">
        <div className="flex flex-col justify-between gap-6 md:flex-row md:items-end">
          <div>
            <p className="font-mono text-[11px] uppercase tracking-[0.22em] text-muted-foreground">Capabilities</p>
            <h2 id="features-title" className="mt-4 max-w-3xl text-balance text-4xl font-semibold tracking-[-0.035em] md:text-6xl">
              A complete Capture workflow. No feature fog.
            </h2>
          </div>
          <Link href="/docs" className="inline-flex items-center gap-2 text-sm font-semibold text-muted-foreground transition-colors hover:text-foreground">
            Explore the documentation <ArrowRight className="size-4" />
          </Link>
        </div>

        <div className="mt-12 grid gap-5 md:grid-cols-2 lg:grid-cols-3">
          {focusedCapabilities.map((capability) => (
            <article key={capability.id} className="group overflow-hidden rounded-3xl border bg-card shadow-sm transition-transform duration-300 hover:-translate-y-1 hover:shadow-xl">
              <div className="relative aspect-[16/9] overflow-hidden border-b bg-muted">
                <Image
                  src={capability.mediaSrc}
                  width={1440}
                  height={900}
                  alt={capability.mediaAlt}
                  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
                  className="size-full object-cover transition-transform duration-700 group-hover:scale-[1.035]"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/28 via-transparent to-transparent" aria-hidden />
              </div>
              <div className="p-6 md:p-7">
                <p className="font-mono text-[10px] font-semibold uppercase tracking-[0.18em] text-violet-700 dark:text-violet-400">{capability.eyebrow}</p>
                <h3 className="mt-2 text-xl font-semibold tracking-tight">{capability.title}</h3>
                <p className="mt-3 text-sm leading-6 text-muted-foreground">{capability.body}</p>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
