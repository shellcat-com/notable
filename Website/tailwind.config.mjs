/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        ink: '#0b0d12',
        panel: '#12151c',
        line: '#252a36',
        coral: '#ff6b5a',
        mint: '#5ee4b5',
        gold: '#f5c451',
        violet: '#8b5cf6',
        fuchsia: '#ec4899',
      },
      fontFamily: {
        sans: ['Inter', '"SF Pro Display"', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', '"SF Mono"', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [],
};
