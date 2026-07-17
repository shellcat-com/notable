export const tools = [
  'Select', 'Arrow', 'Rectangle', 'Ellipse', 'Text', 'Pencil', 'Censor',
  'Number', 'Stamp', 'Highlighter', 'Measure', 'Spotlight', 'Loupe', 'Eyedropper',
];

export const features = [
  {
    title: 'Instant Capture',
    body: 'Global hotkey freezes your screen. Select any region, snap to windows, or stitch all displays.',
    span: 'md:col-span-2',
  },
  {
    title: '14 Annotation Tools',
    body: 'Arrows ×5 styles, ellipse, censor ×4 modes (blur, pixelate, solid, erase), stamps, spotlight, and measure.',
    span: '',
  },
  {
    title: 'Scroll Capture',
    body: 'Select a region from the overlay, scroll the source, and stitch a tall Capture with on-device Vision.',
    span: '',
  },
  {
    title: 'Screen Recording',
    body: 'MP4 display recording at 30/60/120 fps, system audio, trim editor, and local GIF export.',
    span: 'md:col-span-2',
  },
  {
    title: 'Beautify',
    body: '30 gradient backgrounds, window chrome, padding, radius, shadow, and saved brand kits.',
    span: '',
  },
  {
    title: 'Local Vision',
    body: 'OCR, QR, face detection, PII censoring, and on-device translation (macOS 15+) — nothing leaves your Mac unless you upload.',
    span: '',
  },
  {
    title: 'Capture History',
    body: 'Disk-backed, re-editable documents restore annotations, adjustments, beautify, and output format.',
    span: 'md:col-span-2',
  },
  {
    title: 'Supabase Upload',
    body: 'Configure your bucket once, then upload from the Editor and copy a public link instantly.',
    span: '',
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
    body: 'Open Inspect Capture → Recognize Text → Censor Detected Sensitive Text. Regex runs on-device.',
  },
  {
    title: 'Scroll a long page',
    body: 'In the Overlay click Scroll Capture, drag a tall region, then use the menu bar to add frames and finish.',
  },
  {
    title: 'Save a brand kit',
    body: 'Enable Beautify, tune padding and gradient, then save a named kit from the Beautify panel.',
  },
  {
    title: 'Upload to Supabase',
    body: 'Add your project URL, anon key, and bucket in Preferences. Upload from the Editor copies the link.',
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

export const stats = [
  { value: '14', label: 'Tools' },
  { value: '30', label: 'Gradients' },
  { value: '4', label: 'Export formats' },
  { value: '0', label: 'Cloud AI calls' },
];
