import type { Metadata } from "next";
import { HomeHero } from "@/components/home-hero";
import { FeatureBento } from "@/components/feature-bento";
import { WorkflowSteps } from "@/components/workflow-steps";
import { PrivacySection } from "@/components/privacy-section";
import { ShortcutsTable } from "@/components/shortcuts-table";
import { GuidesGrid } from "@/components/guides-grid";
import { InstallSection } from "@/components/install-section";
import { FaqSection, CtaBanner } from "@/components/faq-section";

export const metadata: Metadata = {
  alternates: { canonical: "/" },
};

export default function HomePage() {
  return (
    <main>
      <HomeHero />
      <FeatureBento />
      <WorkflowSteps />
      <PrivacySection />
      <ShortcutsTable />
      <GuidesGrid />
      <InstallSection />
      <FaqSection />
      <CtaBanner />
    </main>
  );
}
