import Image from "next/image";
import { Check } from "lucide-react";
import { productStories } from "@/lib/site";
import { cn } from "@/lib/utils";

const tones = {
  paper: "bg-[#f2f0eb] text-[#151618] dark:bg-[#e9e7e2] dark:text-[#151618]",
  ink: "dark-surface bg-[#0b0c0f] text-white",
  mist: "bg-[#e8f3ef] text-[#121816] dark:bg-[#dfece8] dark:text-[#121816]",
};

export function WorkflowShowcase() {
  return (
    <section id="workflow" aria-labelledby="workflow-title" className="scroll-mt-20">
      <div className="border-b bg-background px-4 py-16 text-center md:py-24">
        <p className="font-mono text-[11px] uppercase tracking-[0.22em] text-muted-foreground">Workflow</p>
        <h2 id="workflow-title" className="mx-auto mt-4 max-w-3xl text-balance text-4xl font-semibold tracking-[-0.035em] md:text-6xl">
          From frozen pixels to a clear point.
        </h2>
        <p className="mx-auto mt-5 max-w-2xl text-pretty text-base leading-7 text-muted-foreground md:text-lg">
          Parcel keeps the path short: make a Selection, add the right Annotation, and send the result where it needs to go.
        </p>
      </div>

      {productStories.map((story) => (
        <article key={story.id} className={cn("border-b", tones[story.tone])}>
          <div className="mx-auto grid max-w-7xl items-center gap-10 px-4 py-16 md:py-24 lg:grid-cols-2 lg:gap-16 lg:px-8 lg:py-32">
            <div className={cn("max-w-xl", story.reverse && "lg:order-2 lg:pl-8")}>
              <p className={cn(
                "font-mono text-[11px] font-semibold uppercase tracking-[0.2em]",
                story.tone === "ink" ? "text-zinc-400" : "text-[#505451]"
              )}>{story.eyebrow}</p>
              <h3 className="mt-4 text-balance text-4xl font-semibold tracking-[-0.04em] md:text-5xl">{story.title}</h3>
              <p className={cn(
                "mt-5 text-pretty text-base leading-7 md:text-lg md:leading-8",
                story.tone === "ink" ? "text-zinc-300" : "text-[#454a47]"
              )}>{story.body}</p>
              <ul className="mt-8 space-y-3">
                {story.details.map((detail) => (
                  <li key={detail} className="flex items-start gap-3 text-sm font-medium">
                    <span className="mt-0.5 grid size-5 shrink-0 place-items-center rounded-full border border-current/20 bg-current/[0.06]">
                      <Check className="size-3" strokeWidth={2.5} />
                    </span>
                    {detail}
                  </li>
                ))}
              </ul>
            </div>
            <figure className={cn("relative", story.reverse && "lg:order-1")}>
              <div className="absolute -inset-6 rounded-[2.5rem] bg-current opacity-[0.035] blur-2xl" aria-hidden />
              <Image
                src={story.mediaSrc}
                width={1440}
                height={900}
                alt={story.mediaAlt}
                sizes="(max-width: 1024px) 100vw, 50vw"
                className="relative w-full rounded-2xl border border-current/10 shadow-[0_30px_80px_rgba(0,0,0,.2)]"
              />
            </figure>
          </div>
        </article>
      ))}
    </section>
  );
}
