# KIVA Academy

PropKiva's professional learning platform for property development training: **Learn. Qualify. Connect.**

This is a new React and TypeScript application. No earlier prototype is used as the production codebase.

## Stack

- React, TypeScript, Vite and Tailwind CSS
- Cloudflare Pages for the web application and Pages Functions for edge API routes
- Supabase Postgres, Auth, Storage and Realtime
- GitHub Actions for type checking and production builds

## Start locally

Requirements: Node.js 22 or newer.

```sh
npm ci
cp .env.example .env.local
npm run dev
```

The dashboard currently uses illustrative course cards. Supabase is optional for the visual shell until project configuration is provided. Use only a publishable key in browser code; never add service-role or secret keys to `VITE_*` variables.

## Supabase

The versioned migration under `supabase/migrations` defines an initial Academy data model and restrictive RLS policies. Review it against the actual staging project and its Data API exposure settings before applying it. Grading, certificate issue/revocation, provider verification, audit writes and meeting credentials are intentionally server-only workflows.

The migration is a foundation, not a production sign-off. Run migration validation, security policy tests and Supabase advisors against staging before production.

## Cloudflare Pages

The React build outputs to `dist`. The Cloudflare Pages build settings are:

- Production branch: `main`
- Build command: `npm run build`
- Build output directory: `dist`

`wrangler.jsonc` defines the Pages output directory. The `/api/health` Pages Function is a basic service check only; privileged business APIs will be added separately.

## Known integration gates

- Unified sign-in remains on PropKiva Account at `https://account.propkiva.com`. The Academy must not treat a redirect as authenticated SSO. Implement session exchange only after the Account service's confirmed handoff contract is available.
- Cloudflare deployment requires an authenticated Cloudflare connection and an Academy Pages project.
- A Supabase staging project and publishable URL/key are needed to validate migrations and live data access.
- KIVA Meetings SFU token issuance must be performed by a trusted server endpoint; do not expose account credentials or provider secrets in the browser.

## Scripts

- `npm run dev` — local development
- `npm run typecheck` — TypeScript validation
- `npm run build` — production build
