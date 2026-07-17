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
        sans: ['"SF Pro Display"', 'Inter', 'system-ui', 'sans-serif'],
        mono: ['"SF Mono"', 'ui-monospace', 'monospace'],
      },
      animation: {
        aurora: 'aurora 18s ease-in-out infinite alternate',
        float: 'float 6s ease-in-out infinite',
      },
      keyframes: {
        aurora: {
          '0%': { transform: 'translate(-8%, -6%) scale(1.05)' },
          '100%': { transform: 'translate(8%, 6%) scale(1.15)' },
        },
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-8px)' },
        },
      },
    },
  },
  plugins: [],
};
