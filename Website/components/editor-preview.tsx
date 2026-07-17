"use client";

import * as React from "react";
import {
  ChevronLeft,
  ChevronRight,
  EyeOff,
  Lock,
  MousePointer2,
  MoveUpRight,
  RotateCw,
  Search,
  Sparkles,
  Square,
  Type,
} from "lucide-react";
import { cn } from "@/lib/utils";

const BROWSER_DROP =
  "0 1px 2px rgba(0,0,0,0.08), 0 12px 28px -10px rgba(0,0,0,0.28), 0 34px 64px -28px rgba(0,0,0,0.34)";

function TrafficLights() {
  return (
    <div className="flex shrink-0 items-center gap-2">
      {["#ff5f57", "#febc2e", "#28c840"].map((c) => (
        <span key={c} className="size-3 rounded-full" style={{ backgroundColor: c }} />
      ))}
    </div>
  );
}

function UrlBar({ url }: { url: string }) {
  return (
    <div className="flex min-w-0 flex-1 items-center gap-2 rounded-lg border border-black/5 bg-white/80 px-3 py-1.5 text-xs text-neutral-500 dark:border-white/10 dark:bg-neutral-950/80 dark:text-neutral-400">
      <Lock className="size-3 shrink-0 opacity-60" strokeWidth={2.5} />
      <span className="truncate font-mono">{url}</span>
      <RotateCw className="ml-auto size-3 shrink-0 opacity-50" strokeWidth={2.5} />
    </div>
  );
}

export function DeviceFrame({
  url = "parcel.parable.dev/editor",
  tab = "Parcel — Editor",
  children,
  className,
}: {
  url?: string;
  tab?: string;
  children?: React.ReactNode;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "relative overflow-hidden rounded-xl border border-white/10 bg-neutral-900 text-neutral-100",
        className
      )}
      style={{ boxShadow: BROWSER_DROP }}
    >
      <div aria-hidden className="select-none">
        <div className="flex items-end gap-3 px-3.5 pt-3">
          <TrafficLights />
          <div className="flex min-w-0 items-center gap-1.5 rounded-t-lg border border-b-0 border-white/10 bg-neutral-950 px-3 py-1.5 text-xs font-medium">
            <span className="size-2 shrink-0 rounded-full bg-violet-500/80" />
            <span className="truncate">{tab}</span>
          </div>
        </div>
        <div className="flex items-center gap-2.5 border-t border-white/10 px-3.5 py-2">
          <div className="flex items-center gap-1 text-neutral-500">
            <ChevronLeft className="size-4" />
            <ChevronRight className="size-4" />
          </div>
          <UrlBar url={url} />
        </div>
      </div>
      <div className="relative overflow-hidden border-t border-white/10 bg-[#0a0c10] [aspect-ratio:16/10]">
        <div className="absolute inset-0">{children}</div>
        <div
          aria-hidden
          className="pointer-events-none absolute inset-x-0 top-0 h-8 bg-gradient-to-b from-black/30 to-transparent"
        />
      </div>
    </div>
  );
}

const TOOL_CHIPS = [
  { label: "Select", icon: MousePointer2 },
  { label: "Arrow", icon: MoveUpRight },
  { label: "Rect", icon: Square },
  { label: "Ellipse", icon: Square },
  { label: "Text", icon: Type },
  { label: "Censor", icon: EyeOff },
  { label: "Spotlight", icon: Sparkles },
  { label: "Loupe", icon: Search },
] as const;

export function EditorPreview() {
  const [activeTool, setActiveTool] = React.useState(0);

  React.useEffect(() => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) return;
    const id = window.setInterval(
      () => setActiveTool((i) => (i + 1) % TOOL_CHIPS.length),
      2400
    );
    return () => window.clearInterval(id);
  }, []);

  return (
    <div className="flex h-full flex-col p-3 md:p-4">
      <div className="mb-3 flex flex-wrap items-center gap-1.5">
        {TOOL_CHIPS.map((t, i) => {
          const Icon = t.icon;
          const active = i === activeTool;
          return (
            <span
              key={t.label}
              className={cn(
                "inline-flex items-center gap-1 rounded-md px-2 py-1 font-mono text-[10px] transition-all duration-300 md:text-xs",
                active
                  ? "bg-violet-500/25 text-violet-100 ring-1 ring-violet-500/40 shadow-[0_0_16px_rgba(139,92,246,0.25)]"
                  : "bg-white/5 text-white/55"
              )}
            >
              <Icon className="size-3 shrink-0 opacity-80" strokeWidth={2} />
              {t.label}
            </span>
          );
        })}
      </div>
      <div className="relative flex flex-1 overflow-hidden rounded-xl border border-white/10 bg-gradient-to-br from-[#151922] to-[#0c0e14] p-4">
        <div className="absolute inset-4 rounded-lg bg-[linear-gradient(135deg,#1e2430_0%,#12151c_50%,#1a1524_100%)] opacity-90" />
        <div className="relative z-10 flex w-full flex-col justify-between">
          <div className="space-y-2">
            <div className="h-2 w-24 rounded bg-white/15" />
            <div className="h-2 w-40 rounded bg-white/10" />
            <div className="h-2 w-32 rounded bg-white/8" />
          </div>
          <svg
            viewBox="0 0 400 120"
            className="mx-auto w-full max-w-md opacity-90"
            aria-hidden
          >
            <defs>
              <marker
                id="arrow"
                markerWidth="8"
                markerHeight="8"
                refX="6"
                refY="3"
                orient="auto"
              >
                <path d="M0,0 L6,3 L0,6 Z" fill="#5ee4b5" />
              </marker>
            </defs>
            <rect
              x="48"
              y="28"
              width="120"
              height="64"
              rx="6"
              fill="none"
              stroke="#8b5cf6"
              strokeWidth="2"
            />
            <line
              x1="200"
              y1="80"
              x2="320"
              y2="36"
              stroke="#5ee4b5"
              strokeWidth="2.5"
              markerEnd="url(#arrow)"
            />
            <rect
              x="260"
              y="52"
              width="88"
              height="36"
              rx="4"
              fill="#ec489933"
              stroke="#ec4899"
              strokeWidth="1.5"
              strokeDasharray="4 3"
            />
            <text
              x="268"
              y="74"
              fill="#f5c451"
              fontSize="11"
              fontFamily="ui-monospace, monospace"
            >
              REDACTED
            </text>
          </svg>
          <div className="flex items-center justify-between text-[10px] text-white/40 md:text-xs">
            <span className="font-mono">Capture coords · 2× retina</span>
            <span className="rounded-full bg-emerald-500/15 px-2 py-0.5 font-mono text-emerald-400">
              On screen = saved
            </span>
          </div>
        </div>
        <div className="absolute bottom-3 right-3 rounded-lg border border-white/10 bg-black/40 px-2 py-1.5 backdrop-blur">
          <div className="h-8 w-14 rounded bg-gradient-to-br from-violet-500/40 to-fuchsia-500/30" />
        </div>
      </div>
    </div>
  );
}
