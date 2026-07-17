# MCP setup for design research

## Parable (connected)

Use the `user-parable` MCP in Cursor to list components and templates:

- Hero: `dither-aurora`, `hero-section`
- Blocks: `feature-bento`, `device-frame`, `faq-accordion`, `cta-banner`
- Install: `npx shadcn@latest add https://parable-three.vercel.app/r/<slug>.json`

The marketing site uses Parable-inspired Aurora + bento patterns in Astro.

## Mobbin (connected)

Configured in `~/.cursor/mcp.json` and `.cursor/mcp.json`:

```json
"mobbin": {
  "type": "http",
  "url": "https://api.mobbin.com/mcp",
  "headers": {}
}
```

OAuth via Cursor → Settings → Tools & MCP → **Connect** on Mobbin. Use for macOS screenshot app UI references.

## Higgsfield (connected)

```json
"higgsfield": {
  "url": "https://mcp.higgsfield.ai/mcp"
}
```

OAuth on first generation request. Use for app icon, OG stills, and lifestyle marketing images.
