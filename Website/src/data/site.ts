export const tools = [
  'Select', 'Arrow', 'Rectangle', 'Ellipse', 'Text', 'Pencil', 'Censor',
  'Number', 'Stamp', 'Highlighter', 'Measure', 'Spotlight', 'Loupe', 'Eyedropper',
];

export const stats = [
  { value: '14', label: 'Annotation tools' },
  { value: '30', label: 'Beautify gradients' },
  { value: '4', label: 'Export formats' },
  { value: '0', label: 'Cloud AI calls' },
];

export const logos = [
  'ScreenCaptureKit', 'Vision', 'Core Image', 'AVFoundation', 'SwiftUI', 'Supabase',
];

export const features = [
  {
    id: 'capture',
    title: 'Instant Capture',
    body: 'Global hotkey freezes every display. Drag a region, snap to windows, or stitch all screens — pixels stay full resolution.',
    size: 'wide' as const,
    icon: 'camera',
  },
  {
    id: 'tools',
    title: '14 annotation tools',
    body: 'Arrows ×5 styles, ellipse, censor ×4 modes, stamps, spotlight, measure, and utility loupe + eyedropper.',
    size: 'sm' as const,
    icon: 'pen',
  },
  {
    id: 'scroll',
    title: 'Scroll Capture',
    body: 'Select a tall region from the Overlay, scroll the source, and stitch with on-device Vision registration.',
    size: 'sm' as const,
    icon: 'scroll',
  },
  {
    id: 'record',
    title: 'Screen recording',
    body: 'MP4 at 30/60/120 fps with system audio, trim editor, and local GIF export — no subscription recorder.',
    size: 'wide' as const,
    icon: 'video',
  },
  {
    id: 'beautify',
    title: 'Beautify',
    body: '30 gradient backgrounds, window chrome, padding, radius, shadow, and saved brand kits for consistent ship-ready Captures.',
    size: 'sm' as const,
    icon: 'sparkles',
  },
  {
    id: 'vision',
    title: 'Local Vision',
    body: 'OCR, QR, face detection, regex PII censoring, and on-device translation — nothing leaves your Mac unless you upload.',
    size: 'tall' as const,
    icon: 'eye',
  },
  {
    id: 'history',
    title: 'Capture history',
    body: 'Disk-backed documents restore annotations, adjustments, beautify, and output format — re-edit any past Capture.',
    size: 'sm' as const,
    icon: 'history',
  },
  {
    id: 'upload',
    title: 'Supabase upload',
    body: 'Configure your bucket once, upload from the Editor, and copy a public link. Real Storage — not a pretend button.',
    size: 'sm' as const,
    icon: 'cloud',
  },
];

export const workflow = [
  {
    step: '01',
    title: 'Freeze & select',
    body: 'Press ⌘⇧2 (configurable). ScreenCaptureKit captures every display; the Overlay lets you drag, snap, or scroll-capture.',
  },
  {
    step: '02',
    title: 'Mark up locally',
    body: 'Annotate, censor, beautify, and adjust in the Editor. Undo covers the Layer stack; settings stay document-level.',
  },
  {
    step: '03',
    title: 'Copy, save, or upload',
    body: 'PNG/JPEG/HEIC/TIFF export matches what you see on screen. Optional Supabase upload copies a link to the clipboard.',
  },
];

export const shortcuts = [
  { keys: '⌘⇧2', action: 'Capture region (configurable in Preferences)' },
  { keys: '⌘C', action: 'Copy Capture from Editor' },
  { keys: '⌘S', action: 'Save Capture' },
  { keys: '⌘Z / ⇧⌘Z', action: 'Undo / redo annotations' },
  { keys: 'Tab', action: 'Window snap in Overlay' },
  { keys: 'Esc', action: 'Cancel Overlay or exit utility tool' },
];

export const guides = [
  {
    title: 'Redact sensitive text locally',
    body: 'Inspect Capture → Recognize Text → Censor Detected Sensitive Text. Regex runs on-device via Vision.',
  },
  {
    title: 'Scroll a long page',
    body: 'In the Overlay choose Scroll Capture, drag a tall region, then add frames from the menu bar and finish.',
  },
  {
    title: 'Save a brand kit',
    body: 'Enable Beautify, tune padding and gradient, then save a named kit from the Beautify panel.',
  },
  {
    title: 'Upload to Supabase',
    body: 'Paste project URL, anon key, and bucket in Preferences. Upload from the Editor copies the link.',
  },
];

export const faqs = [
  {
    q: 'Does Parcel send my Captures to the cloud for AI?',
    a: 'No. OCR, face detection, translation, and redaction use Apple on-device frameworks only. Upload is optional and only when you configure Supabase.',
  },
  {
    q: 'Why does macOS ask for Screen Recording permission?',
    a: 'ScreenCaptureKit requires Screen Recording TCC before any Capture or recording. Quit and reopen Parcel after granting.',
  },
  {
    q: 'Is the download signed and notarized?',
    a: 'Release builds are Developer ID signed and notarized. Run Scripts/release.sh with your Apple Developer credentials, or download from parcel.parable.dev.',
  },
  {
    q: 'How do I configure Supabase upload?',
    a: 'Create a public Storage bucket, paste the project URL and anon key in Preferences, and set an optional custom public base URL.',
  },
];
