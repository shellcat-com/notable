import type { CSSProperties } from "react";
import type { Metadata } from "next";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { SiteNav } from "@/components/site-nav";
import { SiteFooter } from "@/components/site-footer";
import { MobileDownloadBar } from "@/components/mobile-download-bar";
import { theme } from "@/lib/theme";
import { SITE_URL } from "@/lib/site";

const brandStyle = {
  "--brand-accent": theme.accent,
  "--brand-secondary": theme.secondary,
  "--brand-tertiary": theme.tertiary,
  "--brand-gold": theme.gold,
  "--brand-ink": theme.ink,
  "--brand-surface": theme.surface,
  "--brand-elevated": theme.elevated,
} as CSSProperties;

export const metadata: Metadata = {
  title: {
    default: "Parcel — Capture anything. Make it unmistakable.",
    template: "%s · Parcel",
  },
  description:
    "The native macOS Capture studio for fast Selection, precise Annotation, private redaction, recording, and polished sharing—without cloud AI.",
  metadataBase: new URL(SITE_URL),
  applicationName: "Parcel",
  keywords: [
    "macOS Capture app",
    "screen recording",
    "Annotation",
    "on-device OCR",
    "private redaction",
    "Scroll Capture",
  ],
  category: "productivity",
  openGraph: {
    title: "Parcel — Capture anything. Make it unmistakable.",
    description:
      "Native macOS Capture, precise Annotation, local redaction, recording, and polished output. Free and MIT licensed.",
    url: SITE_URL,
    siteName: "Parcel",
    images: [{ url: "/og.svg", width: 1200, height: 630 }],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Parcel — Capture anything. Make it unmistakable.",
    description:
      "A native macOS Capture studio with no cloud AI.",
    images: ["/og.svg"],
  },
  icons: { icon: "/favicon.svg" },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className="h-full"
      style={brandStyle}
    >
      <body className="flex min-h-full flex-col bg-background pb-20 text-foreground md:pb-0">
        <a
          href="#main"
          className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[100] focus:rounded-lg focus:bg-[var(--brand-accent)] focus:px-4 focus:py-2 focus:text-sm focus:font-medium focus:text-[var(--brand-ink)]"
        >
          Skip to content
        </a>
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem
          disableTransitionOnChange
        >
          <SiteNav />
          <div className="flex-1">{children}</div>
          <SiteFooter />
          <MobileDownloadBar />
        </ThemeProvider>
      </body>
    </html>
  );
}
