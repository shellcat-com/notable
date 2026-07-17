'use client';

import { AnimatedGrid } from './AnimatedGrid';
import { FeatureBento } from './FeatureBento';
import { FaqAccordion, CtaBanner } from './FaqCta';
import { HeroSection, DeviceFrame, EditorPreview } from './HeroBlock';
import {
  SiteNav,
  LogoStrip,
  WorkflowSteps,
  ShortcutsTable,
  GuidesGrid,
  PrivacySection,
  InstallSection,
  SiteFooter,
} from './SiteSections';
import {
  features,
  stats,
  logos,
  workflow,
  shortcuts,
  guides,
  faqs,
} from '../data/site';

export default function ParcelPage() {
  return (
    <>
      <SiteNav />
      <main id="top">
        <AnimatedGrid className="min-h-0">
          <HeroSection
            eyebrow="Native macOS · MIT · Open source"
            title="The Capture studio Apple forgot to ship."
            accentWord="Capture"
            subtitle="From Parable — freeze your screen, annotate with fourteen tools, censor with local Vision, beautify for ship-ready output, record, scroll-capture, and upload when you choose."
            primaryLabel="Download for macOS"
            primaryHref="/downloads/Parcel.zip"
            secondaryLabel="See how it works"
            secondaryHref="#workflow"
            stats={stats}
          >
            <DeviceFrame url="parcel.parable.dev/editor" tab="Parcel — Editor">
              <EditorPreview />
            </DeviceFrame>
          </HeroSection>
        </AnimatedGrid>

        <LogoStrip logos={logos} />

        <FeatureBento
          eyebrow="Capabilities"
          title="One menu bar app. Every hard part of Capture solved."
          items={features}
        />

        <WorkflowSteps steps={workflow} />

        <PrivacySection />

        <ShortcutsTable rows={shortcuts} />

        <GuidesGrid guides={guides} />

        <InstallSection />

        <FaqAccordion items={faqs} />

        <CtaBanner
          title="Ready to Capture?"
          subtitle="Free, open source, and built for daily macOS work — private by default."
          href="/downloads/Parcel.zip"
          label="Download Parcel"
        />
      </main>
      <SiteFooter />
    </>
  );
}
