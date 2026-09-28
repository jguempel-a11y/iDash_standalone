# iDash Standalone Development Instructions

## STRICT WORKSPACE BOUNDARY: NO ASSETWORX
1. **Current Directory**: `c:\inetpub\wwwroot\iDash` (Standalone iDash on IIS port 8181 / Tailscale port 8443).
2. **Git Repository**: `jguempel-a11y/iDash_standalone`.
3. **DO NOT ACCESS OR COPY**:
   - **NEVER** read from, write to, or copy files from `C:\inetpub\wwwroot\AssetWorx.WebClient`.
   - Never run bulk copy/rsync/robocopy between the AssetWorx sub-application and this standalone directory.
   - If the user wishes to work on `AssetWorx.WebClient\iDash`, that must happen in a completely separate session opened directly in that folder.
4. **BRANDING**:
   - Strictly **ID Integration Inc.** and **iDash (Intelligent Distributed Asset Scanning Hub)**.
   - Zero references to AssetWorx, Impres, Team VIT, or InfinID.
5. **SCREENSHOTS**:
   - Must only be taken from `http://localhost:8181/`.
   - Must include cache-busting version parameters in HTML image tags.
