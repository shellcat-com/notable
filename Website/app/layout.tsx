import type { CSSProperties } from "react";
import type { Metadata } from "next";
import { Geist, Geist_Mono, Instrument_Serif } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { SiteNav } from "@/components/site-nav";
import { SiteFooter } from "@/components/site-footer";
import { MobileDownloadBar } from "@/components/mobile-download-bar";
import { theme } from "@/lib/theme";
import { SITE_URL } from "@/lib/site";

const geistSans = Geist({ variable: "--font-geist-sans", subsets: ["latin"] });
const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});
const instrumentSerif = Instrument_Serif({
  variable: "--font-instrument-serif",
  subsets: ["latin"],
  weight: "400",
  style: "italic",
});

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
    default: "Parcel — native macOS Capture studio",
    template: "%s · Parcel",
  },
  description:
    "Freeze your screen, annotate with fourteen tools, censor with on-device Vision, beautify, record, and upload — from Parable. No cloud AI, ever.",
  metadataBase: new URL(SITE_URL),
  openGraph: {
    title: "Parcel — native macOS Capture studio",
    description:
      "The Capture studio Apple forgot to ship. MIT licensed, on-device only.",
    url: SITE_URL,
    siteName: "Parcel",
    images: [{ url: "/og.svg", width: 1200, height: 630 }],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Parcel — native macOS Capture studio",
    description:
      "Freeze, annotate, censor, beautify, record — no cloud AI, ever.",
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
      className={`${geistSans.variable} ${geistMono.variable} ${instrumentSerif.variable} h-full`}
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
