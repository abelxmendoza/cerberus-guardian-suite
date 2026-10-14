# CERBERUS

Landing page for the Guardian Security Suite: three separate open-source desktop projects by Abel Mendoza.

- [WindowsGuardianWatchdog](https://github.com/abelxmendoza/WindowsGuardianWatchdog)
- [LinuxGuardianWatchdog](https://github.com/abelxmendoza/LinuxGuardianWatchdog)
- [MacGuardianWatchdog](https://github.com/abelxmendoza/MacGuardianWatchdog)

The page is a static React app. It does not host installers, collect accounts, or talk to a database. Download buttons stay inactive until `src/data/releases.ts` points at a real GitHub Release asset with a version and SHA-256.

## Setup

```bash
npm install
npm run dev
```

## Checks

```bash
npm run typecheck
npm run lint
npm test
npm run build
npm run test:e2e
```

Playwright downloads Chromium on first use: `npx playwright install chromium`.

## Portfolio route

The intended public URL is `https://www.abelxmendoza.com/projects/cerberus`.

The live portfolio is a separate Create React App site. This repository does not replace that site. To mount this page at `/projects/cerberus/` without touching other routes:

```bash
VITE_BASE=/projects/cerberus/ npm run build
```

Copy the contents of `dist/` into the portfolio's `public/projects/cerberus/` directory, and add a link to `/projects/cerberus/`. Update the canonical URL and Open Graph image in `index.html` if the host or path changes. The Open Graph image is `public/og.webp`.

## Before enabling a public download

1. Publish a GitHub Release for that Guardian. Do not upload the file to the portfolio server.
2. Put the asset URL, version, SHA-256, file size, release date, and release notes URL in `src/data/releases.ts`.
3. Set `releaseStatus` to `beta` or `stable`. `development` and `unavailable` never render a download link.
4. The asset URL must match `https://github.com/abelxmendoza/<GuardianRepo>/releases/download/...`.

## Evidence

Copy on the page was checked against the three public repositories on 14 October 2026. No GitHub Release existed. No application screenshots were in the repositories, so the showcase uses the real logo artwork and labels it as such. Linux and macOS are MIT. The Windows repository had no `LICENSE` file.
