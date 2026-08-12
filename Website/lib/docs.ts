export type DocPage = {
  slug: string;
  title: string;
  description: string;
  section: string;
};

export const docSections: { title: string; pages: DocPage[] }[] = [
  {
    title: "Getting started",
    pages: [
      {
        slug: "",
        title: "Introduction",
        description: "What Parcel is and how it fits into your workflow.",
        section: "Getting started",
      },
      {
        slug: "getting-started",
        title: "Quick start",
        description: "Install, grant permissions, and take your first Capture.",
        section: "Getting started",
      },
      {
        slug: "shortcuts",
        title: "Keyboard shortcuts",
        description: "Global hotkeys, Overlay controls, and Editor commands.",
        section: "Getting started",
      },
    ],
  },
  {
    title: "Core workflows",
    pages: [
      {
        slug: "capture",
        title: "Capture & Selection",
        description: "Freeze-then-select, window snap, and scroll Capture.",
        section: "Core workflows",
      },
      {
        slug: "editor",
        title: "Editor & Annotations",
        description: "Tools, Layers, Beautify, Adjustments, and export.",
        section: "Core workflows",
      },
      {
        slug: "recording",
        title: "Screen recording",
        description: "Region recording, trim, GIF export, and audio.",
        section: "Core workflows",
      },
    ],
  },
  {
    title: "Privacy & integrations",
    pages: [
      {
        slug: "privacy",
        title: "Privacy & permissions",
        description: "On-device Vision, sandbox, and what leaves your Mac.",
        section: "Privacy & integrations",
      },
      {
        slug: "supabase",
        title: "Supabase upload",
        description: "Configure optional Storage upload from the Editor.",
        section: "Privacy & integrations",
      },
    ],
  },
];

export const allDocPages: DocPage[] = docSections.flatMap((s) => s.pages);

export function docHref(slug: string) {
  return slug ? `/docs/${slug}` : "/docs";
}

export function findDocPage(slug: string) {
  return allDocPages.find((p) => p.slug === slug);
}
