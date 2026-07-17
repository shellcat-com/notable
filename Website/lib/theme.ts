/**
 * Parcel brand theme — change colors here, everything else follows.
 * Used by components via CSS variables set in globals.css.
 */
export const theme = {
  /** Primary accent — CTAs, active states, glow */
  accent: "#5ee4b5",
  /** Secondary accent — gradients, icons */
  secondary: "#8b5cf6",
  /** Tertiary — gradient stops, highlights */
  tertiary: "#ec4899",
  /** Warm highlight — stamps, badges */
  gold: "#f5c451",

  /** Page backgrounds */
  ink: "#070708",
  surface: "#111113",
  elevated: "#18181b",

  /** Hero aurora gradient stops */
  aurora: ["#8b5cf6", "#5ee4b5", "#ec4899"] as const,

  /** Typography */
  display: "var(--font-instrument-serif)",
  sans: "var(--font-geist-sans)",
  mono: "var(--font-geist-mono)",

  /** Motion */
  easeOut: "cubic-bezier(0.22, 1, 0.36, 1)",
  easeSnap: "cubic-bezier(0.16, 1, 0.3, 1)",
} as const;

export type Theme = typeof theme;
