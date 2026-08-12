import type { Metadata } from "next";
import { HomeHero } from "@/components/home-hero";
import { VerifiedProof } from "@/components/verified-proof";
import { WorkflowShowcase } from "@/components/workflow-showcase";
import { FocusedCapabilities } from "@/components/focused-capabilities";
import { PrivacySection } from "@/components/privacy-section";
import { DownloadClose } from "@/components/download-close";
import { DOWNLOAD_URL, SITE_URL } from "@/lib/site";

export const metadata: Metadata = {
  alternates: { canonical: "/" },
};

export default function HomePage() {
  const softwareApplicationJsonLd = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "Parcel",
    applicationCategory: "MultimediaApplication",
    operatingSystem: "macOS 13 or later",
    description:
      "A native macOS Capture studio for Selection, Annotation, local redaction, Beautify, recording, and export.",
    url: SITE_URL,
    downloadUrl: new URL(DOWNLOAD_URL, SITE_URL).toString(),
    softwareVersion: "1.0",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
    isAccessibleForFree: true,
  };

  return (
    <main id="main">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(softwareApplicationJsonLd) }}
      />
      <HomeHero />
      <VerifiedProof />
      <WorkflowShowcase />
      <FocusedCapabilities />
      <PrivacySection />
      <DownloadClose />
    </main>
  );
}
