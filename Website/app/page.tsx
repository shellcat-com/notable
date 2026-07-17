import type { Metadata } from "next";
import { HomeHero } from "@/components/home-hero";
import { StatsBand } from "@/components/stats-band";
import { ShowcaseSection } from "@/components/showcase-section";
import { FeatureBento } from "@/components/feature-bento";
import { UseCasesSection } from "@/components/use-cases-section";
import { PrinciplesSection } from "@/components/principles-section";
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
    <main id="main">
      <HomeHero />
      <StatsBand />
      <ShowcaseSection />
      <FeatureBento />
      <UseCasesSection />
      <PrinciplesSection />
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
