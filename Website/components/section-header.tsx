import * as React from "react";
import { cn } from "@/lib/utils";

export function SectionHeader({
  kicker,
  title,
  subtitle,
  className,
  align = "left",
}: {
  kicker?: string;
  title: React.ReactNode;
  subtitle?: string;
  className?: string;
  align?: "left" | "center";
}) {
  return (
    <div
      className={cn(
        "max-w-2xl",
        align === "center" && "mx-auto text-center",
        className
      )}
    >
      {kicker && (
        <p className="font-mono text-xs uppercase tracking-widest text-muted-foreground">
          {kicker}
        </p>
      )}
      <h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">
        {title}
      </h2>
      {subtitle && (
        <p className="mt-3 text-base leading-relaxed text-foreground/80">
          {subtitle}
        </p>
      )}
    </div>
  );
}

export function Badge({
  children,
  variant = "default",
}: {
  children: React.ReactNode;
  variant?: "default" | "violet" | "mint";
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full border px-2.5 py-0.5 font-mono text-[11px] uppercase tracking-wide",
        variant === "violet" &&
          "border-[var(--brand-secondary)]/30 bg-[var(--brand-secondary)]/10 text-violet-300",
        variant === "mint" &&
          "border-[var(--brand-accent)]/30 bg-[var(--brand-accent)]/10 text-[var(--brand-accent)]",
        variant === "default" && "border-border bg-muted/50 text-muted-foreground"
      )}
    >
      {children}
    </span>
  );
}
