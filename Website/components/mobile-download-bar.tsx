"use client";

import * as React from "react";
import { Apple } from "lucide-react";
import { DOWNLOAD_URL } from "@/lib/site";

/** Sticky download bar on mobile after scrolling past hero — Windsurf/Affinity pattern */
export function MobileDownloadBar() {
  const [visible, setVisible] = React.useState(false);

  React.useEffect(() => {
    const onScroll = () => setVisible(window.scrollY > 480);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  if (!visible) return null;

  return (
    <div
      className="fixed inset-x-0 bottom-0 z-50 border-t border-white/10 bg-[var(--brand-ink)]/95 p-3 backdrop-blur-xl md:hidden"
      role="region"
      aria-label="Download Parcel"
    >
      <a
        href={DOWNLOAD_URL}
        download
        className="flex w-full items-center justify-center gap-2 rounded-xl bg-[var(--brand-accent)] py-3.5 text-sm font-semibold text-[var(--brand-ink)]"
      >
        <Apple className="size-4" />
        Download for macOS
      </a>
    </div>
  );
}
