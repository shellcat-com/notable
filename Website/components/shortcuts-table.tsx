"use client";

import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";
import { shortcuts } from "@/lib/site";

export function ShortcutsTable() {
  const reduce = useReducedMotion();

  return (
    <section className="border-b">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <SectionHeader
          kicker="Shortcuts"
          title="Keyboard-first from Capture to export."
        />
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 16 }}
          whileInView={reduce ? undefined : { opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ type: "spring", stiffness: 220, damping: 26 }}
          className="mt-8 overflow-hidden rounded-2xl border"
        >
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/40 text-left">
                <th className="px-5 py-3 font-mono text-xs uppercase tracking-wider text-muted-foreground">
                  Shortcut
                </th>
                <th className="px-5 py-3 font-mono text-xs uppercase tracking-wider text-muted-foreground">
                  Action
                </th>
              </tr>
            </thead>
            <tbody>
              {shortcuts.map((row) => (
                <tr key={row.keys} className="border-b last:border-0">
                  <td className="px-5 py-3.5">
                    <kbd className="rounded-md border bg-muted/60 px-2 py-1 font-mono text-xs">
                      {row.keys}
                    </kbd>
                  </td>
                  <td className="px-5 py-3.5 text-muted-foreground">
                    {row.action}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </motion.div>
      </div>
    </section>
  );
}
