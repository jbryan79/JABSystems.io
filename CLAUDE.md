# JAB Systems

## Company Overview

**Website:** https://jabsystems.io
**Email:** info@jabsystems.io

JAB Systems builds enterprise-grade administration tools and custom automation for small and mid-sized businesses. Every tool is designed to be customizable with movable modules and updatable themes.

## Project Structure

```
JABSystems/
├── index.html              # Main landing page with tools grid
├── styles.css              # Global styles (currently inline in index.html)
├── styles/
│   └── tools.css           # Shared tools grid & detail page styles
├── tools/
│   └── admin-toolkit/
│       └── index.html      # JAB Admin Toolkit detail page with screenshot carousel
├── js/
│   └── interactions.js     # Modal popups, hover effects, random fun facts
├── assets/
│   ├── jab-logo.png        # Main logo
│   ├── favicon.ico         # Site favicon
│   ├── toolkit-preview.png # Legacy preview image
│   └── screenshots/        # Tool screenshot images
│       ├── 01-dashboard.png
│       ├── 02-system-health.png
│       ├── 03-network-tools.png
│       ├── 04-storage-tools.png
│       ├── 05-sql-tools.png
│       ├── 06-app-relocation.png
│       └── 07-settings.png
├── README.md               # Project readme
└── LICENSE                 # License file
```

## Tech Stack

- HTML5
- CSS3 (custom styles, no framework)
- Vanilla JavaScript (modal interactions, carousel)
- Static site (no build step currently)

## Key Features

- **Customizable Tools:** All tools support module repositioning and theme customization
- **JAB Admin Toolkit:** Featured product - unified administrative toolkit for system health, network diagnostics, storage hygiene, SQL operations, and application analysis
- **Interactive Tools Grid:** Homepage displays all tools with hover effects and micro-interactions
- **Coming Soon Modal:** Placeholder tools reveal random fun facts on click (modal with backdrop blur)
- **Tool Detail Pages:** Each tool has a dedicated page (`/tools/[tool-name]/`) with:
  - Hero section with tool icon, title, tagline, and status badge
  - Horizontal screenshot carousel with scroll-snap and navigation arrows
  - Features grid highlighting capabilities
  - CTA section for early access requests
  - Keyboard navigation support (arrow keys for carousel, Escape to close modals)

## Development Guidelines

- Keep the site lightweight and fast-loading
- Maintain clean, semantic HTML
- Use vanilla CSS without heavy frameworks
- Prioritize mobile responsiveness
- Follow accessibility best practices

## Deployment

Static site hosted at jabsystems.io

## Contact

For inquiries or early access: info@jabsystems.io
