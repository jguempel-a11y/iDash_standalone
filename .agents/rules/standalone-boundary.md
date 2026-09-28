# Strict Project Boundary: Standalone iDash Only

## CRITICAL: Workspace Isolation
- **Active Workspace**: `c:\inetpub\wwwroot\iDash` ONLY (IIS Port 8181 / Tailscale Port 8443).
- **Git Repository**: `jguempel-a11y/iDash_standalone`.
- **Absolute Prohibition**:
  - **NEVER** inspect, read from, write to, or copy files from `C:\inetpub\wwwroot\AssetWorx.WebClient` (or any subfolder thereof).
  - **NEVER** perform bulk copies or synchronization between `AssetWorx.WebClient\iDash` and this standalone directory.
  - When the user wants to work on the legacy AssetWorx integration (`C:\inetpub\wwwroot\AssetWorx.WebClient\iDash`), they will open a dedicated separate workspace/session for that folder. Do NOT cross project boundaries.

## Branding & Content Guidelines
- **Product Name**: **iDash — Intelligent Distributed Asset Scanning Hub**.
- **Organization**: **ID Integration Inc.**
- **Prohibited Terms & Brandings**:
  - Zero references to `AssetWorx`, `Asset Worx`, `Impres`, `Team VIT`, or `InfinID` in user-facing code, UI, or documentation.
  - All documentation, user guides, setup manuals, and landing pages must feature solely **ID Integration Inc.** branding and copyright (`ID Integration Inc. © 2026`).

## Visual Assets & Screenshots
- All screenshots and documentation captures must be generated directly from the standalone application running on **`http://localhost:8181/`**.
- Any updated documentation screenshot must include version query strings (e.g. `?v=YYYYMMDD`) to ensure browser cache invalidation.
