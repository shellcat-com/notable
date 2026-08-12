/** Shared navigation — hash links use /# so they work from any route */
export const navLinks = [
  { href: "/#features", label: "Features" },
  { href: "/#workflow", label: "Workflow" },
  { href: "/#privacy", label: "Privacy" },
  { href: "/docs", label: "Docs", isRoute: true },
  { href: "/#install", label: "Install" },
] as const;

export type NavLink = (typeof navLinks)[number];
