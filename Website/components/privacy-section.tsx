"use client";

import Link from "next/link";
import { Shield } from "lucide-react";
import { motion, useReducedMotion } from "motion/react";
import { SectionHeader } from "@/components/section-header";

export function PrivacySection() {
  const reduce = useReducedMotion();

  return (
    <section id="privacy" className="border-b bg-muted/15">
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-24">
        <div className="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
          <motion.div
            initial={reduce ? false : { opacity: 0, x: -20 }}
            whileInView={reduce ? undefined : { opacity: 1, x: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ type: "spring", stiffness: 200, damping: 26 }}
          >
            <SectionHeader
              kicker="Privacy"
              title={
                <>
                  Your pixels stay on your{" "}
                  <span className="pb-gradient-text">Mac</span>.
                </>
              }
              subtitle="OCR, face detection, translation, and regex redaction run through Apple on-device frameworks. No cloud AI, no telemetry, no surprise uploads."
            />
            <ul className="mt-8 space-y-3 text-sm text-muted-foreground">
              <li className="flex items-start gap-3">
                <Shield className="mt-0.5 size-4 shrink-0 text-[var(--brand-accent)]" />
                Vision and Core ML process Captures locally
              </li>
              <li className="flex items-start gap-3">
                <Shield className="mt-0.5 size-4 shrink-0 text-[var(--brand-accent)]" />
                Supabase upload is optional and user-configured
              </li>
              <li className="flex items-start gap-3">
                <Shield className="mt-0.5 size-4 shrink-0 text-[var(--brand-accent)]" />
                Sandboxed Release builds with minimal entitlements
              </li>
            </ul>
            <Link
              href="/docs/privacy"
              className="mt-6 inline-block text-sm font-medium text-[var(--brand-secondary)] hover:text-[var(--brand-accent)]"
            >
              Privacy documentation →
            </Link>
          </motion.div>

          <motion.div
            initial={reduce ? false : { opacity: 0, x: 20 }}
            whileInView={reduce ? undefined : { opacity: 1, x: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ type: "spring", stiffness: 200, damping: 26 }}
            className="overflow-hidden rounded-2xl border bg-card shadow-xl"
          >
            <div className="border-b bg-muted/50 px-4 py-3">
              <p className="font-mono text-xs text-muted-foreground">
                System Settings → Privacy & Security
              </p>
            </div>
            <div className="space-y-4 p-6">
              <div className="flex items-center justify-between rounded-xl border bg-background p-4">
                <div>
                  <p className="text-sm font-medium">Screen Recording</p>
                  <p className="text-xs text-muted-foreground">Required for Capture</p>
                </div>
                <span className="rounded-full bg-[var(--brand-accent)]/15 px-3 py-1 font-mono text-xs text-[var(--brand-accent)]">
                  Required
                </span>
              </div>
              <div className="flex items-center justify-between rounded-xl border bg-background p-4 opacity-70">
                <div>
                  <p className="text-sm font-medium">Accessibility</p>
                  <p className="text-xs text-muted-foreground">Not used by Parcel</p>
                </div>
                <span className="font-mono text-xs text-muted-foreground">—</span>
              </div>
              <p className="text-center font-mono text-[11px] text-muted-foreground">
                Carbon hotkeys · no Accessibility permission needed
              </p>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
