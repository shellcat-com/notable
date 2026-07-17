import type { Metadata } from "next";
import { Geist, Geist_Mono, Instrument_Serif } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { SiteNav } from "@/components/site-nav";
import { SiteFooter } from "@/components/site-footer";
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
    >
      <body className="flex min-h-full flex-col bg-background text-foreground">
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem
          disableTransitionOnChange
        >
          <SiteNav />
          <div className="flex-1">{children}</div>
          <SiteFooter />
        </ThemeProvider>
      </body>
    </html>
  );
}
