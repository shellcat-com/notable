import { cn } from "@/lib/utils";

export function SectionHeader({
  kicker,
  title,
  subtitle,
  className,
}: {
  kicker?: string;
  title: string;
  subtitle?: string;
  className?: string;
}) {
  return (
    <div className={cn("max-w-2xl", className)}>
      {kicker && (
        <p className="font-mono text-xs uppercase tracking-widest text-muted-foreground">
          {kicker}
        </p>
      )}
      <h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">
        {title}
      </h2>
      {subtitle && (
        <p className="mt-3 text-base leading-relaxed text-muted-foreground">
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
          "border-violet-500/30 bg-violet-500/10 text-violet-300",
        variant === "mint" &&
          "border-emerald-500/30 bg-emerald-500/10 text-emerald-300",
        variant === "default" && "border-border bg-muted/50 text-muted-foreground"
      )}
    >
      {children}
    </span>
  );
}
