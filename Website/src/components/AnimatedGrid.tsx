'use client';

import * as React from 'react';
import { cn } from '../lib/utils';

function hexToRgba(hex: string, alpha: number): string {
  let h = hex.replace('#', '').trim();
  if (h.length === 3) h = h.split('').map((c) => c + c).join('');
  const n = Number.parseInt(h, 16);
  if (h.length !== 6 || Number.isNaN(n)) return `rgba(139, 92, 246, ${alpha})`;
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
}

function useInjectedKeyframes(id: string, css: string) {
  React.useEffect(() => {
    if (typeof document === 'undefined' || document.getElementById(id)) return;
    const el = document.createElement('style');
    el.id = id;
    el.textContent = css;
    document.head.appendChild(el);
  }, [id, css]);
}

const KEYFRAMES = `
@keyframes pb-grid-pulse {
  0%, 100% { opacity: 0; transform: translate(-50%, -50%) scale(0.55); }
  50% { opacity: var(--pb-ag-peak, 0.5); transform: translate(-50%, -50%) scale(1); }
}
@media (prefers-reduced-motion: reduce) {
  [data-pb-grid-dot] { animation: none !important; opacity: 0 !important; }
}
`;

function mulberry32(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export interface AnimatedGridProps extends React.HTMLAttributes<HTMLDivElement> {
  cellSize?: number;
  glowColor?: string;
  radius?: number;
  children?: React.ReactNode;
}

export function AnimatedGrid({
  cellSize = 36,
  glowColor = '#8b5cf6',
  radius = 220,
  className,
  children,
  style,
  ...props
}: AnimatedGridProps) {
  const rootRef = React.useRef<HTMLDivElement>(null);
  const [reduced, setReduced] = React.useState(false);
  useInjectedKeyframes('pb-animated-grid-kf', KEYFRAMES);

  React.useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setReduced(mq.matches);
    const onChange = (e: MediaQueryListEvent) => setReduced(e.matches);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);

  React.useEffect(() => {
    if (reduced) return;
    const root = rootRef.current;
    if (!root) return;
    let raf = 0;
    const onMove = (e: PointerEvent) => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        const rect = root.getBoundingClientRect();
        root.style.setProperty('--mx', `${e.clientX - rect.left}px`);
        root.style.setProperty('--my', `${e.clientY - rect.top}px`);
      });
    };
    root.addEventListener('pointermove', onMove);
    return () => {
      cancelAnimationFrame(raf);
      root.removeEventListener('pointermove', onMove);
    };
  }, [reduced]);

  const line = hexToRgba('#ffffff', 0.08);
  const glowLine = hexToRgba(glowColor, 0.55);
  const glowFill = hexToRgba(glowColor, 0.14);
  const rng = mulberry32(42);
  const dots = Array.from({ length: 14 }, (_, i) => ({
    left: `${Math.round(rng() * 100)}%`,
    top: `${Math.round(rng() * 100)}%`,
    delay: `${(i * 0.7).toFixed(1)}s`,
  }));

  const gridStyle = {
    '--mx': '50%',
    '--my': '40%',
    '--pb-ag-peak': '0.45',
    backgroundImage: `
      linear-gradient(to right, ${line} 1px, transparent 1px),
      linear-gradient(to bottom, ${line} 1px, transparent 1px)
    `,
    backgroundSize: `${cellSize}px ${cellSize}px`,
    ...style,
  } as React.CSSProperties;

  return (
    <div
      ref={rootRef}
      className={cn('relative isolate min-h-[520px] overflow-hidden bg-ink', className)}
      style={gridStyle}
      {...props}
    >
      <div aria-hidden className="pointer-events-none absolute inset-0">
        {!reduced && (
          <div
            className="absolute inset-0 opacity-90"
            style={{
              backgroundImage: `
                linear-gradient(to right, ${glowLine} 1px, transparent 1px),
                linear-gradient(to bottom, ${glowLine} 1px, transparent 1px)
              `,
              backgroundSize: `${cellSize}px ${cellSize}px`,
              WebkitMaskImage: `radial-gradient(${radius}px circle at var(--mx) var(--my), black, transparent 72%)`,
              maskImage: `radial-gradient(${radius}px circle at var(--mx) var(--my), black, transparent 72%)`,
            }}
          />
        )}
        <div
          className="absolute inset-0"
          style={{
            background: reduced
              ? `radial-gradient(420px circle at 50% 38%, ${glowFill}, transparent 70%)`
              : `radial-gradient(${radius * 1.4}px circle at var(--mx) var(--my), ${glowFill}, transparent 68%)`,
          }}
        />
        {!reduced &&
          dots.map((d, i) => (
            <span
              key={i}
              data-pb-grid-dot
              className="absolute size-1 rounded-full bg-violet/80"
              style={{
                left: d.left,
                top: d.top,
                animation: 'pb-grid-pulse 5s ease-in-out infinite',
                animationDelay: d.delay,
              }}
            />
          ))}
        <div className="absolute inset-x-0 bottom-0 h-40 bg-gradient-to-t from-ink to-transparent" />
      </div>
      <div className="relative z-10">{children}</div>
    </div>
  );
}
