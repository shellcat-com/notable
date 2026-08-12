import { theme } from "./theme";

export type ProductStory = {
  id: "freeze" | "explain" | "share";
  eyebrow: string;
  title: string;
  body: string;
  details: readonly string[];
  mediaSrc: string;
  mediaAlt: string;
  tone: "paper" | "ink" | "mist";
  reverse?: boolean;
};

export const productStories: readonly ProductStory[] = [
  {
    id: "freeze",
    eyebrow: "01 · Capture",
    title: "Freeze exactly what you saw.",
    body: "Press one global hotkey and every display becomes a full-resolution frozen Capture. Drag a Selection, snap to a window, or continue into Scroll Capture without racing the screen.",
    details: [
      "Region, window, display, and Scroll Capture",
      "Tab-to-snap window Selection",
      "Full-resolution pixels across every display",
    ],
    mediaSrc: "/media/workflow-overlay.webp",
    mediaAlt:
      "Parcel Overlay with Window mode selected around a frozen application window",
    tone: "paper",
  },
  {
    id: "explain",
    eyebrow: "02 · Editor",
    title: "Make the point obvious.",
    body: "Open the Editor with the right Tool already close at hand. Add an Arrow, highlight a region, Censor sensitive details, or reorder the Layer stack while the original Capture remains untouched.",
    details: [
      "Fourteen focused Annotation Tools",
      "Click-to-edit styles, color, size, and position",
      "Annotation-only undo and redo",
    ],
    mediaSrc: "/media/workflow-editor.webp",
    mediaAlt:
      "Parcel Editor showing Arrow, Rectangle, Censor, and Layer controls",
    tone: "ink",
    reverse: true,
  },
  {
    id: "share",
    eyebrow: "03 · Output",
    title: "Share something polished.",
    body: "Apply a saved brand kit, add window chrome and padding, then copy or export exactly what the Canvas shows. Recordings, local files, and optional Supabase links follow the same direct workflow.",
    details: [
      "Beautify backgrounds and saved brand kits",
      "PNG, JPEG, HEIC, and TIFF output",
      "Optional upload only when you choose it",
    ],
    mediaSrc: "/media/workflow-export.webp",
    mediaAlt:
      "Parcel output view showing a polished Capture and local export options",
    tone: "mist",
  },
] as const;

export const proofPoints = [
  { value: "Native", label: "SwiftUI app" },
  { value: "Local", label: "On-device Vision" },
  { value: "Zero", label: "Cloud AI calls" },
  { value: "MIT", label: "Open source" },
] as const;

export const focusedCapabilities = [
  {
    id: "capture-modes",
    eyebrow: "Capture",
    title: "Choose only what matters",
    body: "Capture a region, window, display, or long scrolling surface from one frozen Overlay.",
    mediaSrc: "/media/workflow-overlay.webp",
    mediaAlt: "Parcel window Selection in the Overlay",
  },
  {
    id: "annotation-tools",
    eyebrow: "Annotation",
    title: "Fourteen Tools, one clear Canvas",
    body: "Arrows, Text, Pencil, Measure, Spotlight, Loupe, and more stay editable after creation.",
    mediaSrc: "/media/workflow-editor.webp",
    mediaAlt: "Parcel Annotation toolbar and Canvas",
  },
  {
    id: "local-vision",
    eyebrow: "Censor",
    title: "Protect details on your Mac",
    body: "Blur, pixelate, erase, recognize text, find faces, read QR codes, and translate locally.",
    mediaSrc: "/media/workflow-editor.webp",
    mediaAlt: "Censor Annotation and local inspection controls in Parcel",
  },
  {
    id: "recording",
    eyebrow: "Recording",
    title: "Record the walkthrough too",
    body: "Capture a region at up to 120 fps with system audio, click highlights, trimming, and GIF export.",
    mediaSrc: "/media/workflow-overlay.webp",
    mediaAlt: "Parcel Overlay with the Record mode available",
  },
  {
    id: "beautify",
    eyebrow: "Beautify",
    title: "Turn utility into presentation",
    body: "Add padding, gradients, window chrome, radius, and shadow, then save the combination as a brand kit.",
    mediaSrc: "/media/workflow-export.webp",
    mediaAlt: "A polished Parcel Capture using a saved Beautify brand kit",
  },
  {
    id: "history-share",
    eyebrow: "History",
    title: "Re-edit instead of starting over",
    body: "Open past Capture documents with their Annotations and settings, then save locally or upload by choice.",
    mediaSrc: "/media/workflow-export.webp",
    mediaAlt: "Parcel output controls for copying, saving, and optional sharing",
  },
] as const;

export const stats = [
  { value: "14", label: "Annotation tools" },
  { value: "30", label: "Beautify gradients" },
  { value: "120", label: "Max fps recording" },
  { value: "0", label: "Cloud AI calls" },
];

export const logos = [
  "ScreenCaptureKit",
  "Vision",
  "Core Image",
  "AVFoundation",
  "SwiftUI",
  "Supabase",
];

export const annotationTools = [
  "Arrow ×5 styles",
  "Rectangle",
  "Ellipse",
  "Text",
  "Pencil",
  "Highlighter",
  "Number",
  "Censor ×4 modes",
  "Stamp",
  "Measure",
  "Spotlight",
  "Loupe",
  "Eyedropper",
];

export const features = [
  {
    id: "capture",
    title: "Instant Capture",
    body: "Global hotkey freezes every display. Drag a region, snap to windows with Tab, or stitch all screens — pixels stay full resolution.",
    size: "wide" as const,
    icon: "camera",
  },
  {
    id: "edit",
    title: "Click-to-edit annotations",
    body: "Select any Annotation and edit stroke, style, color, and fill in real time. Full undo/redo on the Layer stack — rotate, resize, and reposition without switching Tools.",
    size: "sm" as const,
    icon: "mouse",
  },
  {
    id: "tools",
    title: "14 annotation tools",
    body: "Arrows ×5 styles, ellipse, censor ×4 modes, stamps, spotlight, measure, and utility loupe + eyedropper — all in one toolbar.",
    size: "sm" as const,
    icon: "pen",
  },
  {
    id: "scroll",
    title: "Scroll Capture",
    body: "Select a tall region from the Overlay, scroll the source, and stitch with on-device Vision registration. Live preview as frames stack.",
    size: "sm" as const,
    icon: "scroll",
  },
  {
    id: "record",
    title: "Screen recording",
    body: "Select a region from the Overlay, then record MP4 at 30/60/120 fps with system audio, microphone on macOS 15+, click highlights, trim editor, and local GIF export.",
    size: "wide" as const,
    icon: "video",
  },
  {
    id: "censor",
    title: "Smart censor",
    body: "Pixelate, blur, solid fill, or erase. Auto-redact regex PII, censor detected faces, and erase mode matches surrounding Capture pixels.",
    size: "sm" as const,
    icon: "shield",
  },
  {
    id: "beautify",
    title: "Beautify",
    body: "30 gradient backgrounds, window chrome with traffic lights, padding, radius, shadow, and saved brand kits for ship-ready Captures.",
    size: "sm" as const,
    icon: "sparkles",
  },
  {
    id: "ocr",
    title: "OCR & translate",
    body: "Extract text with Apple Vision. Copy to clipboard, translate on-device (macOS 26+), or censor sensitive lines — all local.",
    size: "sm" as const,
    icon: "scan",
  },
  {
    id: "vision",
    title: "Local Vision",
    body: "QR detection, face finding, and regex PII inspection — nothing leaves your Mac unless you choose to upload.",
    size: "tall" as const,
    icon: "eye",
  },
  {
    id: "history",
    title: "Capture history",
    body: "Disk-backed documents restore annotations, adjustments, beautify, and output format — re-edit any past Capture from ⌘⇧H.",
    size: "sm" as const,
    icon: "history",
  },
  {
    id: "upload",
    title: "Supabase upload",
    body: "Configure your bucket once, upload from the Editor, and copy a public link. Real Storage — not a pretend button.",
    size: "sm" as const,
    icon: "cloud",
  },
  {
    id: "native",
    title: "Lightweight & native",
    body: "Pure SwiftUI + ScreenCaptureKit. No Electron, no web views, no bloat. Lives quietly in your menu bar with Sparkle updates.",
    size: "wide" as const,
    icon: "cpu",
  },
];

export const workflow = [
  {
    step: "01",
    title: "Freeze & select",
    body: "Press ⌘⇧2 (configurable). ScreenCaptureKit captures every display; the Overlay lets you drag, snap, or scroll-capture.",
  },
  {
    step: "02",
    title: "Mark up locally",
    body: "Annotate, censor, beautify, and adjust in the Editor. Undo covers the Layer stack; settings stay document-level.",
  },
  {
    step: "03",
    title: "Copy, save, or upload",
    body: "PNG/JPEG/HEIC/TIFF export matches what you see on screen. Optional Supabase upload copies a link to the clipboard.",
  },
];

export const shortcuts = [
  { keys: "⌘⇧2", action: "Capture region (configurable in Preferences)" },
  { keys: "⌘⇧H", action: "Open Capture history" },
  { keys: "⌘C", action: "Copy Capture from Editor" },
  { keys: "⌘S", action: "Save Capture" },
  { keys: "⌘Z / ⇧⌘Z", action: "Undo / redo annotations" },
  { keys: "Tab", action: "Window snap in Overlay" },
  { keys: "Shift", action: "Constrain shape while drawing" },
  { keys: "Space", action: "Reposition shape while drawing" },
  { keys: "Esc", action: "Cancel Overlay or exit utility tool" },
];

export const guides = [
  {
    title: "Redact sensitive text locally",
    body: "Inspect Capture → Recognize Text → Censor Detected Sensitive Text. Regex runs on-device via Vision.",
  },
  {
    title: "Scroll a long page",
    body: "In the Overlay choose Scroll Capture, drag a tall region, then add frames from the menu bar and finish.",
  },
  {
    title: "Click-to-edit any annotation",
    body: "Switch to Select, click an Annotation, then use the style bar to change stroke, color, arrow style, or censor mode.",
  },
  {
    title: "Record with system audio",
    body: "Choose Record Region from the menu bar, drag a Selection in the Overlay, then save. MP4 includes system audio; on macOS 15+ microphone and click highlights are available.",
  },
  {
    title: "Translate text on-device",
    body: "Inspect Capture → Recognize Text → Translate On-Device. Uses Apple Translation on macOS 26+ — nothing leaves your Mac.",
  },
  {
    title: "Save a brand kit",
    body: "Enable Beautify, tune padding and gradient, then save a named kit from the Beautify panel.",
  },
  {
    title: "Upload to Supabase",
    body: "Paste project URL, anon key, and bucket in Preferences. Upload from the Editor copies the link.",
  },
  {
    title: "Export a recording as GIF",
    body: "After stopping a recording, open the trim window and export GIF for lightweight sharing.",
  },
];

export const faqs = [
  {
    q: "Does Parcel send my Captures to the cloud for AI?",
    a: "No. OCR, face detection, translation, and redaction use Apple on-device frameworks only. Upload is optional and only when you configure Supabase.",
  },
  {
    q: "Why does macOS ask for Screen Recording permission?",
    a: "ScreenCaptureKit requires Screen Recording TCC before any Capture or recording. Quit and reopen Parcel after granting.",
  },
  {
    q: "Is the download signed and notarized?",
    a: "Release builds are Developer ID signed and notarized. Run Scripts/release.sh with your Apple Developer credentials, or download from parcel.parable.dev.",
  },
  {
    q: "How do I configure Supabase upload?",
    a: "Create a public Storage bucket, paste the project URL and anon key in Preferences, and set an optional custom public base URL.",
  },
  {
    q: "What annotation tools are included?",
    a: "Fourteen Tools: Select plus Arrow (5 styles), Rectangle, Ellipse, Text, Pencil, Highlighter, Number, Censor (blur/pixelate/solid/erase), Stamp, Measure, Spotlight, Loupe, and Eyedropper.",
  },
];

export const DOWNLOAD_URL = "/downloads/Parcel.zip";
export const HOMEBREW_CMD = "brew install --cask parcel";
export const GITHUB_URL = "https://github.com/bswxyz/notable";
export const SITE_URL =
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://parcel.parable.dev";

/** Brand theme re-export — edit lib/theme.ts to change site-wide colors */
export { theme };
