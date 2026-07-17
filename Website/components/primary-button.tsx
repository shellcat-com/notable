import type { ReactNode } from "react";
import Link from "next/link";
import { cn } from "@/lib/utils";

type PrimaryButtonProps = {
  href: string;
  children: ReactNode;
  className?: string;
  variant?: "accent" | "white";
  external?: boolean;
};

/** High-contrast CTA — Discord/Linear pattern (readable on dark aurora) */
export function PrimaryButton({
  href,
  children,
  className,
  variant = "accent",
  external,
}: PrimaryButtonProps) {
  const styles =
    variant === "accent"
      ? "bg-[var(--brand-accent)] text-[var(--brand-ink)] shadow-[0_0_40px_color-mix(in_srgb,var(--brand-accent)_35%,transparent)] hover:brightness-110"
      : "bg-white text-[var(--brand-ink)] shadow-[0_8px_32px_rgba(0,0,0,0.35)] hover:bg-zinc-100";

  const Comp = external ? "a" : Link;
  const extra = external
    ? { target: "_blank", rel: "noopener noreferrer" }
    : {};

  return (
    <Comp
      href={href}
      className={cn(
        "inline-flex items-center justify-center gap-2 rounded-full px-7 py-3.5 text-sm font-semibold transition-all active:scale-[0.98]",
        styles,
        className
      )}
      {...extra}
    >
      {children}
    </Comp>
  );
}
